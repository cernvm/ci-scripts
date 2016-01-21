#!/bin/sh

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../jenkins/common.sh
. ${SCRIPT_LOCATION}/common.sh

PLATFORMS="${SCRIPT_LOCATION}/cloud_testing/platforms.json"
EC2_CONFIG="/etc/cvmfs-testing/ec2_config.sh"

# sanity checks
[ ! -z $CVMFS_PLATFORM ]        || die "CVMFS_PLATFORM missing"
[ ! -z $CVMFS_PLATFORM_CONFIG ] || die "CVMFS_PLATFORM_CONFIG missing"
[ ! -z $CVMFS_TESTEE_URL ]      || die "CVMFS_TESTEE_URL missing"
which jq > /dev/null 2>&1       || die "jq utility missing"

vm_desc="$(get_platform_description $CVMFS_PLATFORM $CVMFS_PLATFORM_CONFIG)"
[ ! -z "$vm_desc" ] || die "test platform not specified in $PLATFORMS"

# sanity checks for the platform description
has_platform_parameter 'label' "$vm_desc" || die "VM parameter .label missing"
has_platform_parameter 'setup' "$vm_desc" || die "VM parameter .setup missing"
has_platform_parameter 'test'  "$vm_desc" || die "VM parameter .test missing"
has_platform_parameter 'ami'   "$vm_desc" || die "VM parameter .ami missing"
has_platform_parameter 'user'  "$vm_desc" || die "VM parameter .user missing"

# exports for scripts in mac and linux
export CT_TESTEE_URL="$CVMFS_TESTEE_URL"
export CT_CLIENT_TESTEE_URL="$CVMFS_CLIENT_TESTEE_URL"
export CT_PLATFORM=$(get_platform_parameter 'label'   "$vm_desc")
export CT_PLATFORM_SETUP_SCRIPT=$(get_platform_parameter 'setup'   "$vm_desc")
export CT_PLATFORM_RUN_SCRIPT=$(get_platform_parameter 'test'    "$vm_desc")
export CT_EC2_CONFIG="$EC2_CONFIG"
export CT_AMI_NAME=$(get_platform_parameter 'ami'     "$vm_desc")
export CT_USERNAME=$(get_platform_parameter 'user'    "$vm_desc")
export CT_USERDATA=$(get_platform_parameter 'context' "$vm_desc")
export CT_SOURCE_TARBALL="source.tar.gz"

# static information (check also remote_setup.sh and remote_run.sh)
export CT_CVMFS_WORKSPACE="/tmp/cvmfs-test-workspace"
export CT_CVMFS_LOG_DIRECTORY="${CT_CVMFS_WORKSPACE}/logs"


echo "Running cloud tests for $CT_CVMFS_PLATFORM / $CVMFS_PLATFORM_CONFIG ..."

# if we are on mac then we have to run an special script
if [ ! $(is_linux_vm $CT_AMI_NAME) ]; then
  ${SCRIPT_LOCATION}/cloud_testing/run_mac.sh
else
  ${SCRIPT_LOCATION}/cloud_testing/run.sh
fi
