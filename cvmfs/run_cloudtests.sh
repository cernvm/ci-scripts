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

export testee_url="$CVMFS_TESTEE_URL"
export client_testee_url="$CVMFS_CLIENT_TESTEE_URL"
export platform=$(get_platform_parameter 'label'   "$vm_desc")
export platform_setup_script=$(get_platform_parameter 'setup'   "$vm_desc")
export platform_run_script=$(get_platform_parameter 'test'    "$vm_desc")
export ec2_config="$EC2_CONFIG"
export ami_name=$(get_platform_parameter 'ami'     "$vm_desc")
export username=$(get_platform_parameter 'user'    "$vm_desc")
export userdata=$(get_platform_parameter 'context' "$vm_desc")
export source_tarball="source.tar.gz"


echo "Running cloud tests for $CVMFS_PLATFORM / $CVMFS_PLATFORM_CONFIG ..."

# if we are on mac then we have to run an special script
if [ ! $(is_linux_vm $ami_name) ]; then
  ${SCRIPT_LOCATION}/cloud_testing/run_mac.sh
else
  ${SCRIPT_LOCATION}/cloud_testing/run.sh
fi
