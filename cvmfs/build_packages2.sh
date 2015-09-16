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

# setup a fresh build workspace
if [ -d $CVMFS_BUILD_LOCATION ]; then
  echo "removing previous build location..."
  sudo rm -fR "$CVMFS_BUILD_LOCATION"
fi
echo "creating a fresh build location in ${CVMFS_BUILD_LOCATION}..."
mkdir -p "$CVMFS_BUILD_LOCATION"
chmod 0777 "$CVMFS_BUILD_LOCATION"

# run the build
echo "looking for build script to invoke..."
build_script="${CVMFS_SOURCE_LOCATION}/ci/build_package.sh"

# check if the script exists and is executable
[ -f $build_script ] || die "Build script '${build_script}' not found"
[ -x $build_script ] || die "Build script '${build_script}' not executable"

echo "switching to $CVMFS_BUILD_LOCATION and invoking build script..."
cd "$CVMFS_BUILD_LOCATION"

# parse the command line arguments (keep quotation marks)
args="$CVMFS_PACKAGE"
while [ $# -gt 0 ]; do
  if echo "$1" | grep -q "[[:space:]]"; then
    args="$args \"$1\""
  else
    args="$args $1"
  fi
  shift 1
done

# check if we should run in a dockerized environment and set up the build script
# invocation accordingly
command_tmpl=""
if [ x"$CVMFS_CI_PLATFORM_LABEL" = x"docker" ]; then
  docker_image_name="${CVMFS_BUILD_PLATFORM}_${CVMFS_BUILD_ARCH}"
  command_tmpl="${CVMFS_SOURCE_LOCATION}/ci/build_on_docker.sh \
                    ${CVMFS_SOURCE_LOCATION}                   \
                    ${CVMFS_BUILD_LOCATION}                    \
                    ${docker_image_name}                       \
                    $build_script $args" # Note: build_on_docker.sh calls the
                                         #       build script with the right
                                         #       parameter by convention!
                                         #       (compare: else-branch)
else
  command_tmpl="$build_script ${CVMFS_SOURCE_LOCATION} ${CVMFS_BUILD_LOCATION} $args"
fi

# run the build script
echo "++ $command_tmpl"
$command_tmpl
