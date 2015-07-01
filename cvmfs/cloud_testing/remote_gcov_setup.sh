#!/bin/bash

#
# This script is designed to be as platform independent as possible. It executes
# a platform specific test initialization script found in the CernVM-FS repo
#

usage() {
  local error_msg=$1

  echo "$error_msg"
  echo
  echo "Mandatory options:"
  echo "-r <setup script>      platform specific script (inside the checkout)"
  echo
  echo "Optional parameters:"
  echo "-p <platform path>     custom search path for platform specific script"
  echo "-u <user name>             user name to use for test run"
  echo "-s <git repository>    CernVM-FS git repository to be checked out"
  echo "-b <git branch name>   branch name to be tested"

  exit 1
}

export LC_ALL=C

# static information (check also remote_cov_run.sh and run_cov.sh)
cvmfs_workspace="/tmp/cvmfs-test-gcov-workspace"
cvmfs_source_directory="${cvmfs_workspace}/cvmfs-source"
cvmfs_log_directory="${cvmfs_workspace}/logs"

# parameterized information
cvmfs_git_repository="https://github.com/cvmfs/cvmfs.git"
cvmfs_git_branch="devel"
platform_script=""
platform_script_path=""
test_username="sftnight"

# RHEL (SLC) requires a tty for sudo... work around that
sudo_fix="Defaults:root !requiretty"
if [ $(id -u) -eq 0 ]; then
  # if we are root, we can fix it right away
  if ! cat /etc/sudoers | grep -q "$sudo_fix"; then
    echo "$sudo_fix" | tee --append /etc/sudoers > /dev/null 2>&1
  fi
else
  # if not, we need to hope that the current user is allowed to `sudo`

  # first wait until sudo doesn't complain about unresolvable hostname
  # (probably waits until landb has been updated on Ubuntu)
  timeout=1800
  while sudo echo "f" 2>&1 | grep -q "unable to resol" && [ $timeout -gt 0 ]; do
    timeout=$(( $timeout - 1 ))
    sleep 1
  done
  [ $timeout -gt 0 ] || exit 2
  if ! sudo cat /etc/sudoers | grep -q "$sudo_fix"; then
    echo "$sudo_fix" | sudo tee --append /etc/sudoers > /dev/null 2>&1
  fi
fi

# create a workspace
sudo rm -fR $cvmfs_workspace > /dev/null 2>&1
mkdir -p $cvmfs_workspace
if [ $? -ne 0 ]; then
  echo "failed to create workspace $cvmfs_workspace"
  exit 3
fi
cd $cvmfs_workspace

# # create log file destination
mkdir -p $cvmfs_log_directory

# from now on everything is logged to the logfile
# Note: the only output of this script is the absolute path to the generated
#       log files
touch ${cvmfs_log_directory}/setup.log
exec &> ${cvmfs_log_directory}/setup.log

# read parameters
while getopts "r:s:b:p:u:" option; do
  case $option in
    r)
      platform_script=$OPTARG
      ;;
    s)
      cvmfs_git_repository=$OPTARG
      ;;
    b)
      cvmfs_git_branch=$OPTARG
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

# check that sudo works as expected
sudo echo "testing sudo..." || exit 2

# check if we have all bits and pieces
if [ "x$platform_script"      = "x" ] ||
   [ "x$cvmfs_git_repository" = "x" ] ||
   [ "x$cvmfs_git_branch"           = "x" ]; then
  usage "Missing parameter(s)"
fi

# create test user account if necessary
id $test_username > /dev/null 2>&1
if [ $? -ne 0 ]; then
  sudo /usr/sbin/useradd --create-home -s /bin/bash $test_username
  if [ $? -ne 0 ]; then
    echo "cannot create user account $test_username"
    exit 4
  fi
  echo "$test_username ALL = NOPASSWD: ALL"  | sudo tee --append /etc/sudoers
  echo "Defaults:$test_username !requiretty" | sudo tee --append /etc/sudoers
fi

# extract the source tarball
echo "installing git... "
if which yum > /dev/null 2>&1; then
  yum -y install git
elif which apt-get > /dev/null 2>&1; then
  apt-get -y install git || exit 5
fi

echo "checking out the CernVM-FS source from $cvmfs_git_repository ($cvmfs_git_branch)..."
[ ! -d $cvmfs_source_directory ] || rm -fR $cvmfs_source_directory
git clone $cvmfs_git_repository $cvmfs_source_directory || exit 6
cd $cvmfs_source_directory
git checkout $cvmfs_git_branch || exit 7
cd $cvmfs_workspace

# chown the source tree to allow $test_username to work with it
sudo chown -R $test_username:$test_username $cvmfs_workspace

# find the platform specific script
if [ x$platform_script_path = "x" ]; then
  platform_script_path=${cvmfs_source_directory}/test/cloud_testing/platforms
fi
platform_script_abs=${platform_script_path}/${platform_script}
if [ ! -f $platform_script_abs ]; then
  echo "platform specific script $platform_script not found here:"
  echo $platform_script_abs
  exit 7
fi

# run the platform specific script to perform platform specific test setups
echo "running platform specific script $platform_script... "
sudo -H -E -u $test_username sh $platform_script_abs -t $cvmfs_source_directory   \
                                                     -l $cvmfs_log_directory
