#/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $WORKSPACE ]             || die "WORKSPACE missing"
[ ! -z $CVMFS_BUILD_LOCATION  ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_BUILD_CLEAN     ] || die "CVMFS_BUILD_CLEAN missing"

CONTAINER_BUILD_SCRIPT="ci/jenkins/build_container.sh"

# setup a fresh build workspace on first execution or on request
if [ ! -d "$CVMFS_BUILD_LOCATION" ] || [ x"$CVMFS_BUILD_CLEAN" = x"true" ]; then
  rm -fR "$CVMFS_BUILD_LOCATION"
  mkdir -p "$CVMFS_BUILD_LOCATION"
fi

# run the build
command_tmpl=""
desired_architecture="$(extract_arch $CVMFS_BUILD_ARCH)"
if is_docker_host; then
  echo "creating cvmfs graphdriver plugin container on docker for ${desired_architecture} and sending output to $CVMFS_BUILD_LOCATION..."
  docker_image_name="${CVMFS_BUILD_PLATFORM}_${desired_architecture}"
  command_tmpl="${CERNVM_CI_SCRIPT_LOCATION}/docker/run_on_docker.sh \
    ${WORKSPACE}                                                     \
    ${docker_image_name}                                             \
    ${CVMFS_SOURCE_LOCATION}/${CONTAINER_BUILD_SCRIPT}               \
    ${CVMFS_BUILD_LOCATION}"
else
  echo "building on bare metal unsupported"
  exit 1
fi

# run the build script
echo "++ $command_tmpl"
$command_tmpl
