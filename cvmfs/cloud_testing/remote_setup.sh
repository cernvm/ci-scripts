#!/bin/bash

#
# This script is designed to be as platform independent as possible. It down-
# loads the CernVM-FS packages provided by the test supervisor (i.e. Electric
# Commander) and executes a platform specific test initialization script found
# in the CernVM-FS repository
#

usage() {
  local error_msg=$1

  echo "$error_msg"
  echo
  echo "Mandatory options:"
  echo "-s <cvmfs server package>  CernVM-FS server package to be tested (Linux only)"
  echo "-c <cvmfs client package>  CernVM-FS client package to be tested"
  echo "-d <cvmfs devel package>   CernVM-FS devel package to be tested (Linux only)"
  echo "-t <cvmfs source tarball>  CernVM-FS sources containing associated tests"
  echo "-g <cvmfs tests package>   CernVM-FS unit tests package (Linux only)"
  echo "-k <cvmfs config package>  CernVM-FS config package (Linux only)"
  echo "-r <setup script>          platform specific script (inside the tarball)"
  echo
  echo "Optional parameters:"
  echo "-p <platform path>         custom search path for platform specific script"
  echo "-u <user name>             user name to use for test run"
  echo
  echo "You must provide http addresses for all packages and tar balls. They will"
  echo "be downloaded and executed to test CVMFS on various platforms"

  exit 1
}


mini_which() {
  local executable="$1"
  local old_ifs=$IFS
  local found=0
  IFS=":"
  for p in $PATH; do
    if [ -x ${p}/${executable} ]; then
      found=1
      break
    fi
  done
  IFS=$old_ifs
  [ $found -eq 1 ]
}

download_if_used() {
  if [ "x$1" != "x" ]; then
    download $1
  fi
}

download() {
  local url=$1
  local download_output=

  local dl_bin=""
  local which_bin="which"

  if ! which -v > /dev/null 2>&1; then
    which_bin="mini_which"
  fi

  if $which_bin wget > /dev/null 2>&1; then
    dl_bin="wget --no-check-certificate"
  elif $which_bin curl > /dev/null 2>&1; then
    dl_bin="curl --insecure --silent --remote-name"
  else
    echo "didn't find wget or curl."
    exit 1
  fi

  echo -n "downloading $url ... "
  download_output=$($dl_bin $url 2>&1)

  if [ $? -ne 0 ]; then
    echo "fail"
    echo "downloader said:"
    echo $download_output
    exit 2
  else
    echo "done"
  fi
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

# static information (check also remote_run.sh and run.sh)
cvmfs_workspace="/tmp/cvmfs-test-workspace"
cvmfs_source_directory="${cvmfs_workspace}/cvmfs-source"
cvmfs_log_directory="${cvmfs_workspace}/logs"

# parameterized information
platform_script=""
platform_script_path=""
server_package=""
client_package=""
devel_package=""
config_package=""
source_tarball=""
unittest_package=""
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
  # CC7: wait until cloud init set no-tty default
  timeout=600
  while sudo echo "f" 2>&1 | grep -q "tty" && [ $timeout -gt 0 ]; do
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

# create log file destination
mkdir -p $cvmfs_log_directory

# from now on everything is logged to the logfile
# Note: the only output of this script is the absolute path to the generated
#       log files
touch ${cvmfs_log_directory}/setup.log
exec &> ${cvmfs_log_directory}/setup.log

# read parameters
while getopts "r:s:c:d:t:g:k:p:u:" option; do
  case $option in
    r)
      platform_script=$OPTARG
      ;;
    s)
      server_package=$OPTARG
      ;;
    c)
      client_package=$OPTARG
      ;;
    d)
      devel_package=$OPTARG
      ;;
    t)
      source_tarball=$OPTARG
      ;;
    g)
      unittest_package=$OPTARG
      ;;
    k)
      config_package="$OPTARG"
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
if [ "x$(uname -s)" != "xDarwin" ]; then
  if [ "x$platform_script"  = "x" ] ||
    [ "x$server_package"   = "x" ] ||
    [ "x$client_package"   = "x" ] ||
    [ "x$devel_package"    = "x" ] ||
    [ "x$config_package"  = "x" ] ||
    [ "x$source_tarball"   = "x" ] ||
    [ "x$unittest_package" = "x" ]; then
    usage "Missing parameter(s)"
  fi
else
  if [ "x$platform_script"  = "x" ] ||
    [ "x$client_package"   = "x" ] ||
    [ "x$source_tarball"   = "x" ]; then
    usage "Missing parameter(s)"
  fi
fi

# create test user account if necessary
id $test_username > /dev/null 2>&1
if [ $? -ne 0 ]; then
  sudo /usr/sbin/useradd --create-home -s /bin/bash $test_username
  if [ $? -ne 0 ]; then
    echo "cannot create user account $test_username"
    exit 4
  fi
  echo "$test_username ALL=(ALL:ALL) NOPASSWD: ALL"  | sudo tee --append /etc/sudoers
  echo "Defaults:$test_username !requiretty" | sudo tee --append /etc/sudoers
fi

# download the needed packages
echo "downloading packages..."
download_if_used $server_package
download_if_used $client_package
download_if_used $devel_package
download_if_used $source_tarball
download_if_used $unittest_package
download_if_used $config_package

# get local file path of downloaded files
if [ "x$server_package" != "x" ]; then
  server_package=$(canonicalize_path $server_package)
fi
if [ "x$client_package" != "x" ]; then
  client_package=$(canonicalize_path $client_package)
fi
if [ "x$devel_package" != "x" ]; then
  devel_package=$(canonicalize_path $devel_package)
fi
if [ "x$source_tarball" != "x" ]; then
  source_tarball=$(canonicalize_path $source_tarball)
fi
if [ "x$unittest_package" != "x" ]; then
  unittest_package=$(canonicalize_path $unittest_package)
fi
if [ "x$config_package" != "x" ]; then
  config_package=$(canonicalize_path $config_package)
fi

# extract the source tarball
extract_location=$(tar -tzf $source_tarball | head -n1)
echo -n "extracting the CernVM-FS source file into $extract_location... "
tar_output=$(tar -xzf $source_tarball)
if [ $? -ne 0 ] || [ ! -d $extract_location ]; then
  echo "fail"
  echo "tar said:"
  echo $tar_output
  exit 5
else
  echo "done"
fi
echo -n "renaming $extract_location to generic name $cvmfs_source_directory... "
mv $(canonicalize_path $extract_location) $cvmfs_source_directory > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "fail"
  exit 6
else
  echo "done"
fi

# chown the source tree to allow $test_username to work with it
sudo chown -R $test_username $cvmfs_workspace

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
args="-t $cvmfs_source_directory \
      -l $cvmfs_log_directory    \
      -c $client_package"
if [ "x$(uname -s)" != "xDarwin" ]; then
  args="$args -s $server_package -d $devel_package -g $unittest_package -k $config_package"
fi
sudo -H -E -u $test_username bash $platform_script_abs $args
