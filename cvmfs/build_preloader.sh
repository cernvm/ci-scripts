#/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

BUILD_SCRIPT="ci/build_preloader.sh"

# sanity checks
[ ! -z $WORKSPACE ]             || die "WORKSPACE missing"
[ ! -z $CVMFS_BUILD_LOCATION  ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION ] || die "CVMFS_SOURCE_LOCATION missing"
if [ "x$CVMFS_BUILD_CLEAN" = "x" ]; then
 CVMFS_BUILD_CLEAN=true
fi

# setup a fresh build workspace on first execution or on request
if [ ! -d "$CVMFS_BUILD_LOCATION" ] || [ x"$CVMFS_BUILD_CLEAN" = x"true" ]; then
  rm -fR "$CVMFS_BUILD_LOCATION"
  mkdir -p "$CVMFS_BUILD_LOCATION"
fi

# run the build
command_tmpl=""
desired_architecture="$(extract_arch $CVMFS_BUILD_ARCH)"
if is_docker_host; then
  echo "creating doxygen documentation on docker for ${desired_architecture} and sending output to $CVMFS_BUILD_LOCATION..."
  docker_image_name="${CVMFS_BUILD_PLATFORM}_${desired_architecture}"
  command_tmpl="${CERNVM_CI_SCRIPT_LOCATION}/docker/run_on_docker.sh \
    ${WORKSPACE}                                                     \
    ${docker_image_name}                                             \
    ${CVMFS_SOURCE_LOCATION}/${BUILD_SCRIPT}                         \
    ${CVMFS_BUILD_LOCATION}"
else
  echo "running CppLint bare metal for ${desired_architecture}..."
  command_tmpl="${CVMFS_SOURCE_LOCATION}/${BUILD_SCRIPT} ${CVMFS_BUILD_LOCATION}"
fi

# run the build script
echo "++ $command_tmpl"
$command_tmpl
