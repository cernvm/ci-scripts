#!/bin/sh

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../jenkins/common.sh
. ${SCRIPT_LOCATION}/common.sh

PLATFORMS="${SCRIPT_LOCATION}/cloud_testing/platforms.json"

# sanity checks
[ ! -z $CVMFS_PLATFORM ]        || die "CVMFS_PLATFORM missing"
[ ! -z $CVMFS_PLATFORM_CONFIG ] || die "CVMFS_PLATFORM_CONFIG missing"
[ ! -z $CVMFS_TESTEE_URL ]      || die "CVMFS_TESTEE_URL missing"
which jq > /dev/null 2>&1       || die "jq utility missing"

vm_desc="$(get_platform_description $CVMFS_PLATFORM $CVMFS_PLATFORM_CONFIG)"
[ ! -z "$vm_desc" ] || die "test platform not specified in $PLATFORMS"

echo "Running cloud tests for $CVMFS_PLATFORM / $CVMFS_PLATFORM_CONFIG ..."
echo "$vm_desc"


