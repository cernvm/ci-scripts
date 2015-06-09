#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_SOURCE_LOCATION ]                  || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_RUN_UNITTESTS ]                    || die "CVMFS_RUN_UNITTESTS missing"
[ ! -z $CVMFS_RUN_PYTHON_UNITTESTS ]             || die "CVMFS_RUN_PYTHON_UNITTESTS missing"
[ ! -z $CVMFS_UNITTESTS_BINARY ]                 || die "CVMFS_UNITTESTS_BINARY missing"
[ ! -z $CVMFS_UNITTESTS_RESULT_LOCATION ]        || die "CVMFS_UNITTESTS_RESULT_LOCATION missing"
[ ! -z $CVMFS_UNITTESTS_PYTHON_RESULT_LOCATION ] || die "CVMFS_UNITTESTS_PYTHON_RESULT_LOCATION missing"

# check if there is already a result file and clean it up
if [ -f $CVMFS_UNITTESTS_RESULT_LOCATION ]; then
  echo "cleaning up old unittest results..."
  rm -f $CVMFS_UNITTESTS_RESULT_LOCATION
fi
if [ -d $CVMFS_UNITTESTS_PYTHON_RESULT_LOCATION ]; then
  echo "cleaning up old python unittest results..."
  rm -fR $CVMFS_UNITTESTS_PYTHON_RESULT_LOCATION
fi

# check if unittests actually should be run
if [ x"$CVMFS_RUN_UNITTESTS" = x"true" ]; then
  echo "running googletest unittests..."

  # build the invocation string and print it for debugging reasons
  command_tmpl="${CVMFS_SOURCE_LOCATION}/ci/run_unittests.sh"
  [ ! -z "$CVMFS_LIBRARY_PATH" ]          && command_tmpl="$command_tmpl -l $CVMFS_LIBRARY_PATH"
  [ x"$CVMFS_UNITTESTS_QUICK" = x"true" ] && command_tmpl="$command_tmpl -q"
  command_tmpl="$command_tmpl ${CVMFS_UNITTESTS_BINARY} ${CVMFS_UNITTESTS_RESULT_LOCATION}"
  echo "++ $command_tmpl"

  # run the build script
  $command_tmpl
else
  echo "Unit tests are disabled... skipping"
fi

# check if the python unittests should be run
if [ x"$CVMFS_RUN_PYTHON_UNITTESTS" = x"true" ]; then
  echo "running python unittests..."

  # build the invocation string and print it for debugging reasons
  command_tmpl="${CVMFS_SOURCE_LOCATION}/ci/run_python_unittests.sh"
  command_tmpl="$command_tmpl ${CVMFS_UNITTESTS_PYTHON_RESULT_LOCATION}"
  echo "++ $command_tmpl"

  # run the build script
  $command_tmpl
else
  echo "Python unit tests are disabled... skipping"
fi
