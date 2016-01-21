#!/bin/sh

# This script spawns a virtual machine of a specific platform type on ibex and
# runs the associated test cases on this machine.
# Some variables have been sourced in ../run_cloudtests.sh

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
cvmfs_source_directory="${CT_CVMFS_WORKSPACE}/cvmfs-source"

# global variables (get filled by spawn_virtual_machine)
ip_address=""
instance_id=""
log_destination="."


#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#



usage() {
  local msg="$1"

  echo "Error: $msg"
  echo
  echo "Mandatory options:"
  echo " -u <testee URL>            URL to the nightly build directory to be tested"
  echo " -p <platform name>         name of the platform to be tested"
  echo " -b <setup script>          platform specific setup script (inside the tarball)"
  echo " -r <run script>            platform specific test script (inside the tarball)"
  echo " -a <AMI name>              the virtual machine image to spawn"
  echo
  echo "Optional parameters:"
  echo " -e <EC2 config file>       local location of the ec2_config.sh file"
  echo " -d <results destination>   Directory to store final test session logs"
  echo " -m <ssh user name>         User name to be used for VM login (default: root)"
  echo " -c <cloud init userdata>   User data string to be passed to the new instance"
  echo
  echo " -l <custom client URL>     URL to a nightly build for a custom CVMFS client"

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


setup_virtual_machine() {
  local ip=$1
  local username=$2

  local remote_setup_script
  remote_setup_script="${script_location}/remote_setup.sh"

  echo -n "setting up VM ($ip) for CernVM-FS test suite... "
  run_script_on_virtual_machine $ip $CT_USERNAME $remote_setup_script \
      -s $server_package                                              \
      -c $client_package                                              \
      -d $devel_package                                               \
      -t $source_tarball                                              \
      -g $unittest_package                                            \
      -k "$config_packages"                                           \
      -r $CT_PLATFORM_setup_script
  check_retcode $?
  if [ $? -ne 0 ]; then
    handle_test_failure $ip $CT_USERNAME
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
  remote_run_script="${script_location}/remote_run.sh"

  echo -n "running test cases on VM ($ip)... "
  run_script_on_virtual_machine $ip $CT_USERNAME $remote_run_script \
      -s $server_package                                         \
      -c $client_package                                         \
      -d $devel_package                                          \
      -k "$config_packages"                                      \
      -r $CT_PLATFORM_run_script
  check_retcode $?

  if [ $? -ne 0 ]; then
    handle_test_failure $ip $CT_USERNAME
  fi
}


handle_test_failure() {
  local ip=$1
  local username=$2

  get_test_results $ip $CT_USERNAME

  echo "at least one test case failed... skipping destructions of VM!"
  exit 100
}


get_test_results() {
  local ip=$1
  local username=$2
  local retval=0

  echo -n "retrieving test results... "
  retrieve_file_from_virtual_machine \
      $ip                            \
      $username                      \
      "${CT_CVMFS_LOG_DIRECTORY}/*"  \
      $log_destination
  check_retcode $?
}


#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#

# check if we have all bits and pieces
if [ x$CT_PLATFORM_RUN_SCRIPT   = "x" ] ||
   [ x$CT_PLATFORM_SETUP_SCRIPT = "x" ] ||
   [ x$CT_PLATFORM              = "x" ] ||
   [ x$CT_TESTEE_URL            = "x" ] ||
   [ x$CT_AMI_NAME              = "x" ]; then
  usage "Missing parameter(s)"
fi

# check if we have a custom client testee URL
if [ ! -z "$CT_CLIENT_TESTEE_URL" ]; then
  echo "using custom client from here: $client_testee_url"
else
  client_testee_url="$testee_url"
fi

# figure out which packages need to be downloaded
ctu="$CT_CLIENT_TESTEE_URL"
otu="$CT_TESTEE_URL"
client_package=$(read_package_map   ${ctu}/pkgmap "$CT_PLATFORM" 'client'   )
server_package=$(read_package_map   ${otu}/pkgmap "$CT_PLATFORM" 'server'   )
devel_package=$(read_package_map    ${ctu}/pkgmap "$CT_PLATFORM" 'devel'    )
unittest_package=$(read_package_map ${otu}/pkgmap "$CT_PLATFORM" 'unittests')
config_packages="$(read_package_map ${otu}/pkgmap "$CT_PLATFORM" 'config'   )"

# check if all necessary packages were found
if [ x"$server_package"        = "x" ] ||
   [ x"$client_package"        = "x" ] ||
   [ x"$devel_package"         = "x" ] ||
   [ x"$config_packages"       = "x" ] ||
   [ x"$unittest_package"      = "x" ]; then
  usage "Incomplete pkgmap file"
fi

# construct the full package URLs
client_package="${ctu}/${client_package}"
server_package="${otu}/${server_package}"
devel_package="${ctu}/${devel_package}"
unittest_package="${otu}/${unittest_package}"
source_tarball="${otu}/${CT_SOURCE_TARBALL}"
config_package_urls=""
for config_package in $config_packages; do
  config_package_urls="${config_package_base_url}/${config_package} $config_package_urls"
done
config_packages="$config_package_urls"

# load EC2 configuration
. $ec2_config

# spawn the virtual machine image, run the platform specific setup script
# on it, wait for the spawning and setup to be complete and run the actual
# test suite on the VM.
spawn_my_virtual_machine  $CT_AMI_NAME "$CT_USERDATA"   || die "Aborting..."
wait_for_virtual_machine  $ip_address   $CT_USERNAME    || die "Aborting..."
setup_virtual_machine     $ip_address   $CT_USERNAME    || die "Aborting..."
wait_for_virtual_machine  $ip_address   $CT_USERNAME    || die "Aborting..."
run_test_cases            $ip_address   $CT_USERNAME    || die "Aborting..."
get_test_results          $ip_address   $CT_USERNAME    || die "Aborting..."
tear_down_virtual_machine $instance_id                  || die "Aborting..."

echo "all done"
