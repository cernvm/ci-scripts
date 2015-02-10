#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_UNITTESTS_BINARY ] || die "CVMFS_UNITTESTS_BINARY missing"

# run the unit tests
$CVMFS_UNITTESTS_BINARY --gtest_shuffle
