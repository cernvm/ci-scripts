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
  echo "-s <server package>   CernVM-FS server package to be tested"
  echo "-c <client package>   CernVM-FS client package to be tested"
  echo "-d <devel package>    CernVM-FS devel package to be tested"
  echo "-g <repository_gateway_url> CernVM-FS gateway build ULR"
  echo "-k <config package>   CernVM-FS configuration package to be used"
  echo
  echo "Optional parameters:"
  echo "-p <platform path>    custom search path for platform specific script"
  echo "-u <user name>        user name to use for test run"

  exit 1
}

canonicalize_path() {
  local path_name=$1
  local system_name=`uname -s`
  if [ "x$system_name" = "xLinux" ]; then
    echo $(readlink -f $(basename $path_name))
  elif [ "x$system_name" = "xDarwin" ]; then
    echo $(/usr/local/bin/greadlink -f $(basename $path_name))
  fi
}

export LC_ALL=C

# static information (check also remote_setup.sh and run.sh)
cvmfs_workspace="/tmp/cvmfs-test-workspace"
cvmfs_source_directory="${cvmfs_workspace}/cvmfs-source"
cvmfs_log_directory="${cvmfs_workspace}/logs"

# parameterized variables
platform_script=""
platform_script_path=""
test_username="sftnight"
server_package=""
client_package=""
devel_package=""
config_package=""
repository_gateway_url=""

# from now on everything is logged to the logfile
# Note: the only output of this script is the absolute path to the generated
#       log files
RUN_LOGFILE="${cvmfs_log_directory}/run.log"
sudo touch                               $RUN_LOGFILE
sudo chmod a+w                           $RUN_LOGFILE
sudo chown $test_username                $RUN_LOGFILE
exec &>                                  $RUN_LOGFILE

# switch to working directory
cd $cvmfs_workspace

# read parameters
while getopts "r:s:c:d:g:k:p:u:" option; do
  case $option in
    r)
      platform_script=$OPTARG
      ;;
    s)
      server_package=$(canonicalize_path $OPTARG)
      ;;
    c)
      client_package=$(canonicalize_path $OPTARG)
      ;;
    d)
      devel_package=$(canonicalize_path $OPTARG)
      ;;
    g)
      repository_gateway_url=$OPTARG
      ;;
    k)
      config_package=$(canonicalize_path $OPTARG)
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

if [ "x$(uname -s)" != "xDarwin" ]; then
# check if we have all bits and pieces
  if [ x"$platform_script"  = "x" ] ||
    [ x"$client_package"   = "x" ] ||
    [ x"$devel_package"    = "x" ] ||
    [ x"$server_package"   = "x" ] ||
    [ x"$config_package"  = "x" ]; then
    usage "Missing parameter(s)"
  fi
  # check if the needed packages are downloaded
  if [ ! -f $server_package ] ||
    [ ! -f $client_package ] ||
    [ ! -f $devel_package  ]; then
    usage "Missing package(s)"
  fi
  if [ ! -f $config_package ] ; then
    usage "Missing config package '$config_package'"
  fi
else
# check if we have all bits and pieces
  if [ x"$platform_script"  = "x" ] ||
    [ x"$client_package"   = "x" ]; then
    usage "Missing parameter(s)"
  fi
# check if the needed packages are downloaded
  if [ ! -f $client_package ]; then
    usage "Missing package(s)"
  fi
fi

# export the location of the client, server and config packages
export CVMFS_CLIENT_PACKAGE=$client_package
export CVMFS_DEVEL_PACKAGE=$devel_package
export CVMFS_SERVER_PACKAGE=$server_package
export CVMFS_CONFIG_PACKAGES="$config_package"
export CVMFS_GATEWAY_URL=$repository_gateway_url

# change working directory to test workspace
cd $cvmfs_workspace

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
args="-t $cvmfs_source_directory \
      -l $cvmfs_log_directory    \
      -c $client_package"
if [ "x$(uname -s)" != "xDarwin" ]; then
  args="$args -s $server_package -d $devel_package"
fi
sudo -H -E -u $test_username bash $platform_script_abs $args
