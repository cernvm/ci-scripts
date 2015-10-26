#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION    ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION   ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_PACKAGE           ] || die "CVMFS_PACKAGE missing"
[ ! -z $CVMFS_CI_PLATFORM_LABEL ] || die "CVMFS_CI_PLATFORM_LABEL missing"
[ ! -z $CVMFS_BUILD_PLATFORM    ] || die "CVMFS_BUILD_PLATFORM missing"
[ ! -z $CVMFS_BUILD_ARCH        ] || die "CVMFS_BUILD_ARCH missing"
[ ! -z $CVMFS_NIGHTLY_BUILD     ] || die "CVMFS_NIGHTLY_BUILD missing"
[ ! -z $BUILD_NUMBER            ] || die "BUILD_NUMBER missing"

# setup a fresh build workspace
if [ -d $CVMFS_BUILD_LOCATION ]; then
  echo "removing previous build location..."
  sudo rm -fR "$CVMFS_BUILD_LOCATION"
fi
echo "creating a fresh build location in ${CVMFS_BUILD_LOCATION}..."
mkdir -p "$CVMFS_BUILD_LOCATION"
chmod 0777 "$CVMFS_BUILD_LOCATION"

# figure out if we a doing a nightly build
nightly_number=
if [ x"$CVMFS_NIGHTLY_BUILD" = x"true" ]; then
  echo "creating a nightly build..."
  nightly_number=${BUILD_NUMBER}
fi

# run the build
echo "looking for build script to invoke..."
build_script="${CVMFS_SOURCE_LOCATION}/ci/build_package.sh"

# check if the script exists and is executable
[ -f $build_script ] || die "Build script '${build_script}' not found"
[ -x $build_script ] || die "Build script '${build_script}' not executable"

echo "switching to $CVMFS_BUILD_LOCATION and invoking build script..."
cd "$CVMFS_BUILD_LOCATION"

# check if we should run in a dockerized environment and set up the build script
# invocation accordingly
command_tmpl=""
desired_architecture="$(extract_arch $CVMFS_BUILD_ARCH)"
if is_docker_host; then
  echo "building on docker for ${desired_architecture}..."
  docker_image_name="${CVMFS_BUILD_PLATFORM}_${desired_architecture}"
  command_tmpl="${CVMFS_SOURCE_LOCATION}/ci/build_on_docker.sh \
                    ${CVMFS_SOURCE_LOCATION}                   \
                    ${CVMFS_BUILD_LOCATION}                    \
                    ${docker_image_name}                       \
                    $build_script                              \
                    $CVMFS_PACKAGE                             \
                    $nightly_number" # Note: build_on_docker.sh calls the
                                     #       build script with the right
                                     #       parameter by convention!
                                     #       (compare: else-branch)
else
  echo "building bare metal for ${desired_architecture}..."
  command_tmpl="$build_script ${CVMFS_SOURCE_LOCATION} ${CVMFS_BUILD_LOCATION} \
                              $CVMFS_PACKAGE $nightly_number"
fi

# run the build script
echo "++ $command_tmpl"
$command_tmpl

# chown build result directory after building on docker
if is_docker_host; then
  echo "chown-ing $CVMFS_BUILD_LOCATION to $(whoami)"
  sudo chown $(whoami) -R $CVMFS_BUILD_LOCATION
fi
