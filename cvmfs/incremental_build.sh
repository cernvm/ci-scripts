#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $WORKSPACE                 ] || die "WORKSPACE missing"
[ ! -z $CVMFS_BUILD_LOCATION      ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION     ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_BUILD_CLEAN         ] || die "CVMFS_BUILD_CLEAN missing"
[ ! -z $CERNVM_CI_SCRIPT_LOCATION ] || die "CERNVM_CI_SCRIPT_LOCATION missing"

# setup a fresh build workspace on first execution or on request
if [ ! -d "$CVMFS_BUILD_LOCATION" ] || [ x"$CVMFS_BUILD_CLEAN" = x"true" ]; then
  echo "recreating build location: $CVMFS_BUILD_LOCATION"
  rm -fR "$CVMFS_BUILD_LOCATION"
  mkdir -p "$CVMFS_BUILD_LOCATION"
fi

if [ x"$CVMFS_EXTERNALS_CLEAN" = x"true" ]; then
  echo "recreating externals in: $CVMFS_SOURCE_LOCATION/externals_[build|install]"
  rm -fR "$CVMFS_SOURCE_LOCATION/externals_build"
  rm -fR "$CVMFS_SOURCE_LOCATION/externals_install"
fi

# run the build
command_tmpl=""
desired_architecture="$(extract_arch $CVMFS_BUILD_ARCH)"
if is_docker_host; then
  echo "incremental build on docker for ${desired_architecture}..."
  docker_image_name="${CVMFS_BUILD_PLATFORM}_${desired_architecture}"
  command_tmpl="${CERNVM_CI_SCRIPT_LOCATION}/docker/run_on_docker.sh \
    ${WORKSPACE}                                                     \
    ${docker_image_name}                                             \
    ${CVMFS_SOURCE_LOCATION}/ci/build_incremental_multi.sh           \
    ${CVMFS_SOURCE_LOCATION}                                         \
    ${CVMFS_BUILD_LOCATION}                                          \
    $(get_number_of_cpu_cores)"
else
  echo "incremental build (bare metal) for ${desired_architecture}..."
  command_tmpl="${CVMFS_SOURCE_LOCATION}/ci/build_incremental_multi.sh \
    "$CVMFS_SOURCE_LOCATION" \
    "$CVMFS_BUILD_LOCATION" \
    $(get_number_of_cpu_cores)"
fi

echo "++ $command_tmpl"
$command_tmpl

