#!/bin/bash

#
# This script is designed to be as platform independent as possible. It does
# final preparations to run the platform specific test cases of CernVM-FS and
# invokes a platform dependent script to steer the actual test session
#

usage() {
  local error_msg=$1

  echo "$error_msg"
  echo
  echo "Mandatory options:"
  echo "-r <test script>      platform specific script (inside the cvmfs sources)"
  echo
  echo "Optional parameters:"
  echo "-p <platform path>    custom search path for platform specific script"
  echo "-u <user name>        user name to use for test run"

  exit 1
}

export LC_ALL=C

# static information (check also remote_setup.sh and run.sh)
cvmfs_workspace="/tmp/cvmfs-test-gcov-workspace"
cvmfs_source_directory="${cvmfs_workspace}/cvmfs-source"
cvmfs_log_directory="${cvmfs_workspace}/logs"

# parameterized variables
platform_script=""
platform_script_path=""
test_username="sftnight"

# from now on everything is logged to the logfile
# Note: the only output of this script is the absolute path to the generated
#       log files
RUN_LOGFILE="${cvmfs_log_directory}/run.log"
sudo touch                               $RUN_LOGFILE
sudo chmod a+w                           $RUN_LOGFILE
sudo chown $test_username:$test_username $RUN_LOGFILE
exec &>                                  $RUN_LOGFILE

# switch to working directory
cd $cvmfs_workspace

# read parameters
while getopts "r:p:u:" option; do
  case $option in
    r)
      platform_script=$OPTARG
      ;;
    p)
      platform_script_path=$OPTARG
      ;;
    u)
      test_username=$OPTARG
      ;;
    ?)
      shift $(($OPTIND-2))
      usage "Unrecognized option: $1"
      ;;
  esac
done

# check if we have all bits and pieces
if [ x"$platform_script"  = "x" ]; then
  usage "Missing parameter(s)"
fi

# find the platform specific script
if [ x$platform_script_path = "x" ]; then
  platform_script_path=${cvmfs_source_directory}/test/cloud_testing/platforms
fi
platform_script_abs=${platform_script_path}/${platform_script}
if [ ! -f $platform_script_abs ]; then
  echo "platform specific script $platform_script not found here:"
  echo $platform_script_abs
  exit 2
fi

# run the platform specific script to perform CernVM-FS tests
echo "running platform specific script $platform_script ..."
sudo -H -E -u $test_username sh $platform_script_abs -t $cvmfs_source_directory\
                                                     -l $cvmfs_log_directory

