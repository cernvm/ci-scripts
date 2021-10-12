#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $WORKSPACE ]                              || die "WORKSPACE MISSING"
[ ! -z $CVMFS_SOURCE_LOCATION ]                  || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_RUN_UNITTESTS ]                    || die "CVMFS_RUN_UNITTESTS missing"
[ ! -z $CVMFS_UNITTESTS_BINARY ]                 || die "CVMFS_UNITTESTS_BINARY missing"
[ ! -z $CVMFS_SHRINKWRAP_TEST_BINARY ]           || die "CVMFS_SHRINKWRAP_TEST_BINARY missing"
[ ! -z $CVMFS_UNITTESTS_RESULT_LOCATION ]        || die "CVMFS_UNITTESTS_RESULT_LOCATION missing"
[ ! -z $CERNVM_CI_SCRIPT_LOCATION ]              || die "CERNVM_CI_SCRIPT_LOCATION missing"

# check if there is already a result file and clean it up
if [ -f $CVMFS_UNITTESTS_RESULT_LOCATION ]; then
  echo "cleaning up old unittest results..."
  rm -f $CVMFS_UNITTESTS_RESULT_LOCATION
fi
if [ -d $CVMFS_UNITTESTS_PYTHON_RESULT_LOCATION ]; then
  echo "cleaning up old python unittest results..."
  rm -fR $CVMFS_UNITTESTS_PYTHON_RESULT_LOCATION
fi

desired_architecture="$(extract_arch $CVMFS_BUILD_ARCH)"
docker_image_name="${CVMFS_BUILD_PLATFORM}_${desired_architecture}"

# check if unittests actually should be run
if [ x"$CVMFS_RUN_UNITTESTS" = x"true" ]; then
  echo "running googletest unittests..."

  if is_docker_host; then
    echo "running unit tests on docker for ${desired_architecture}"
    command_tmpl="${CERNVM_CI_SCRIPT_LOCATION}/docker/run_on_docker.sh \
      ${WORKSPACE} \
      ${docker_image_name} \
      ${CVMFS_SOURCE_LOCATION}/ci/run_unittests.sh"
  else
    echo "running unit tests bare metal"
    command_tmpl="${CVMFS_SOURCE_LOCATION}/ci/run_unittests.sh"
  fi
  [ ! -z "$CVMFS_LIBRARY_PATH" ]          && command_tmpl="$command_tmpl -l $CVMFS_LIBRARY_PATH"
  [ x"$CVMFS_UNITTESTS_QUICK" = x"true" ] && command_tmpl="$command_tmpl -q"
  [ ! -z "$CVMFS_UNITTESTS_CACHEPLUGINS" ] && command_tmpl="$command_tmpl -c $CVMFS_UNITTESTS_CACHEPLUGINS"
  [ x"$CVMFS_UNITTESTS_DUCC" = x"true" ] && command_tmpl="$command_tmpl -d"
  [ x"$CVMFS_UNITTESTS_GATEWAY" = x"true" ] && command_tmpl="$command_tmpl -G"
  command_tmpl="$command_tmpl -g $CVMFS_SOURCE_LOCATION/cvmfs/webapi"
  [ -x "$(dirname $CVMFS_UNITTESTS_BINARY)/cvmfs_test_publish" ] && command_tmpl="$command_tmpl -p"  # publish unittests
  command_tmpl="$command_tmpl ${CVMFS_UNITTESTS_BINARY} ${CVMFS_UNITTESTS_RESULT_LOCATION}"
  echo "++ $command_tmpl"

  # run the build script
  $command_tmpl
else
  echo "Unit tests are disabled... skipping"
fi
