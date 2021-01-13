#!/bin/sh

# This script spawns a virtual machine of a specific platform type on ibex and
# runs the associated test cases on this machine

# Configuration for cloud access
# Example:
# EC2_ACCESS_KEY="..."
# EC2_SECRET_KEY="..."
# EC2_ENDPOINT="..."
# EC2_KEY="..."
# EC2_INSTANCE_TYPE="..."
# EC2_KEY_LOCATION="/home/.../ibex_key.pem"

# internal script configuration
script_location=$(cd "$(dirname "$0")"; pwd)
. ${script_location}/common.sh

config_package_base_url="https://ecsft.cern.ch/dist/cvmfs/cvmfs-config"

# static information (check also remote_cov_setup.sh and remote_cov_run.sh)
cvmfs_workspace="/tmp/cvmfs-test-gcov-workspace"
cvmfs_source_directory="${cvmfs_workspace}/cvmfs-source"
cvmfs_log_directory="${cvmfs_workspace}/logs"

# global variables for external script parameters
platform=""
platform_run_script=""
platform_setup_script=""
ec2_config=""
ami_name=""
log_destination="."
username="root"
userdata=""
cvmfs_git_repository="https://github.com/cvmfs/cvmfs.git"
cvmfs_git_branch="devel"

# global variables (get filled by spawn_virtual_machine)
ip_address=""
instance_id=""


#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#



usage() {
  local msg="$1"

  echo "Error: $msg"
  echo
  echo "Mandatory options:"
  echo " -p <platform name>         name of the platform to be tested"
  echo " -x <setup script>          platform specific setup script (inside the tarball)"
  echo " -r <run script>            platform specific test script (inside the tarball)"
  echo " -a <AMI name>              the virtual machine image to spawn"
  echo
  echo "Optional parameters:"
  echo " -e <EC2 config file>       local location of the ec2_config.sh file"
  echo " -d <results destination>   Directory to store final test session logs"
  echo " -m <ssh user name>         User name to be used for VM login (default: root)"
  echo " -c <cloud init userdata>   User data string to be passed to the new instance"
  echo " -s <git repository>        CernVM-FS git repository to be checked out"
  echo " -b <git branch name>       branch name to be tested"

  exit 1
}


spawn_my_virtual_machine() {
  local ami=$1
  local userdata="$2"

  local retcode

  echo -n "spawning virtual machine from $ami... "
  local spawn_results
  spawn_results="$(spawn_virtual_machine $ami "$userdata")"
  retcode=$?
  instance_id=$(echo $spawn_results | awk '{print $1}')
  ip_address=$(echo $spawn_results | awk '{print $2}')

  check_retcode $retcode
}


get_test_results() {
  local ip=$1
  local username=$2
  local retval=0
  echo -n "retrieving test results... "
  retrieve_file_from_virtual_machine \
      $ip                            \
      $username                      \
      "${cvmfs_log_directory}/*"     \
      $log_destination
  check_retcode $?
}


handle_test_failure() {
  local ip=$1
  local username=$2

  get_test_results $ip $username

  echo -n "something went wrong - destroying VM ($ip)... "
  # tear_down_virtual_machine $instance_id || die "fail!"
  echo "done"
}


setup_virtual_machine() {
  local ip=$1
  local username=$2

  local remote_setup_script
  remote_setup_script="${script_location}/remote_gcov_setup.sh"

  echo -n "setting up VM ($ip) for CernVM-FS integration test coverage... "
  run_script_on_virtual_machine $ip $username $remote_setup_script \
      -r $platform_setup_script
  check_retcode $?
  if [ $? -ne 0 ]; then
    handle_test_failure $ip $username
    return 1
  fi

  echo -n "giving the dust time to settle... "
  sleep 15
  echo "done"
}


run_test_cases() {
  local ip=$1
  local username=$2

  local retcode
  local log_files
  local remote_run_script
  remote_run_script="${script_location}/remote_gcov_run.sh"

  echo -n "running test cases on VM ($ip)... "
  run_script_on_virtual_machine $ip $username $remote_run_script \
      -r $platform_run_script
  check_retcode $?

  if [ $? -ne 0 ]; then
    handle_test_failure $ip $username
    return 1
  fi
}


#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#


while getopts "p:x:r:a:e:d:m:c:s:b:" option; do
  case $option in
    p)
      platform=$OPTARG
      ;;
    x)
      platform_setup_script=$OPTARG
      ;;
    r)
      platform_run_script=$OPTARG
      ;;
    a)
      ami_name=$OPTARG
      ;;
    e)
      ec2_config=$OPTARG
      ;;
    d)
      log_destination=$OPTARG
      ;;
    m)
      username=$OPTARG
      ;;
    c)
      userdata="$OPTARG"
      ;;
    s)
      cvmfs_git_repository="$OPTARG"
      ;;
    b)
      cvmfs_git_branch=$OPTARG
      ;;
    ?)
      shift $(($OPTIND-2))
      usage "Unrecognized option: $1"
      ;;
  esac
done

# check if we have all bits and pieces
if [ x$platform_run_script   = "x" ] ||
   [ x$platform_setup_script = "x" ] ||
   [ x$platform              = "x" ] ||
   [ x$ami_name              = "x" ]; then
  usage "Missing parameter(s)"
fi

# load EC2 configuration
. $ec2_config

# spawn the virtual machine image, run the platform specific setup script
# on it, wait for the spawning and setup to be complete and run the actual
# test suite on the VM.
spawn_my_virtual_machine  $ami_name   "$userdata" || die "Aborting..."
wait_for_virtual_machine  $ip_address  $username  || die "Aborting..."
setup_virtual_machine     $ip_address  $username  || die "Aborting..."
wait_for_virtual_machine  $ip_address  $username  || die "Aborting..."
run_test_cases            $ip_address  $username  || die "Aborting..."
get_test_results          $ip_address  $username  || die "Aborting..."
tear_down_virtual_machine $instance_id            || die "Aborting..."

echo "all done"
