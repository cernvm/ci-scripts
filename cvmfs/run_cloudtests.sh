#!/bin/sh

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../jenkins/common.sh
. ${SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_ARCH ]       || die "CVMFS_ARCH missing"
[ ! -z $CVMFS_PLATFORM ]   || die "CVMFS_PLATFORM missing"
[ ! -z $CVMFS_TESTEE_URL ] || die "CVMFS_TESTEE_URL missing"

echo "Running cloud tests for $CVMFS_PLATFORM / $CVMFS_ARCH ..."
