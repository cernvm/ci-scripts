#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_UNITTESTS_BINARY ]          || die "CVMFS_UNITTESTS_BINARY missing"
[ ! -z $CVMFS_UNITTESTS_RESULT_LOCATION ] || die "CVMFS_UNITTESTS_RESULT_LOCATION missing"

# configure manual library path if needed
if [ ! -z $CVMFS_LIBRARY_PATH ]; then
  echo "using custom library path: '$CVMFS_LIBRARY_PATH'"
  if is_linux; then
    export LD_LIBRARY_PATH="$CVMFS_LIBRARY_PATH"
  elif is_macos; then
    export DYLD_LIBRARY_PATH="$CVMFS_LIBRARY_PATH"
  else
    die "who am i on? $(uname -a)"
  fi
fi

# run the unit tests
echo "running unit tests..."
$CVMFS_UNITTESTS_BINARY --gtest_shuffle \
                        --gtest_output=xml:$CVMFS_UNITTESTS_RESULT_LOCATION
