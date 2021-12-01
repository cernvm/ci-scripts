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

# static information (check also remote_setup.sh and remote_run.sh)
cvmfs_workspace="/tmp/cvmfs-test-workspace"
cvmfs_source_directory="${cvmfs_workspace}/cvmfs-source"
cvmfs_log_directory="${cvmfs_workspace}/logs"

# yubikey test node specific information
YUBIKEY_SSH_PORT=2222
YUBIKEY_VM_STARTUP_SCRIPT='/root/centos7-cloudtesting_start.sh'
YUBIKEY_VM_TEARDOWN_SCRIPT='/root/centos7-cloudtesting_teardown.sh'

# global variables for external script parameters
testee_url=""
client_testee_url=""
platform=""
platform_run_script=""
platform_setup_script=""
ec2_config=""
ami_name=""
log_destination="."
username="root"
userdata=""
destroy_failed=""

# package download locations
server_package=""
client_package=""
devel_package=""
config_packages=""  # might be more than one... BEWARE OF SPACES!!
unittest_package=""
source_tarball="source.tar.gz" # will be prepended by ${testee_url} later

suites=""
geoip_key=""

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
  echo " -u <testee URL>              URL to the nightly build directory to be tested"
  echo " -p <platform name>           name of the platform to be tested"
  echo " -b <setup script>            platform specific setup script (inside the tarball)"
  echo " -r <run script>              platform specific test script (inside the tarball)"
  echo " -a <AMI name>                the virtual machine image to spawn"
  echo
  echo "Optional parameters:"
  echo " -e <EC2 config file>         local location of the ec2_config.sh file"
  echo " -d <results destination>     Directory to store final test session logs"
  echo " -m <ssh user name>           User name to be used for VM login (default: root)"
  echo " -c <cloud init userdata>     User data string to be passed to the new instance"
  echo
  echo " -l <custom client URL>       URL to a nightly build for a custom CVMFS client"
  echo " -s <test suite labels>       Restrict tests to given suite names"
  echo " -G <geoip key>               Download key for GeoIP database"
  echo " -F <destroy failed VMs>      Destroy VMs with failed tests"


  exit 1
}


spawn_my_virtual_machine() {
  local ami=$1
  local userdata="$2"

  local retcode

  # special case for macos and yubikey testing node
  if [ x"$platform" = "xosx_x86_64" ] || [ x"$ami" = "xcvm-yubikey01" ] || [ x"$platform" = x"cc8_aarch64" ]; then
    ip_address=$(getent ahostsv4 $ami | head -n1 | awk '{ print $1}')
    retcode=$?
    [ $retcode -eq 0 ] || return $retcode

    # need to set up the VM on yubikey testing node
    # run a script prepared by Ansible in root home directory
    if [ x"$ami" = "xcvm-yubikey01" ]; then
      start_yubikey_vm $ip_address || retcode=$?
    fi

    return $retcode
  fi

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

  local remote_setup_script="${script_location}/remote_setup.sh"

  echo -n "setting up VM ($ip) for CernVM-FS test suite... "

  local args="$ip $username $remote_setup_script \
              -t $source_tarball -r $platform_setup_script"
  if [ "x$server_package" != "x" ]; then
    args="$args -s $server_package"
  fi
  if [ "x$client_package" != "x" ]; then
    args="$args -c $client_package"
  fi
  if [ "x$fuse3_package" != "x" ]; then
    args="$args -f $fuse3_package"
  fi
  if [ "x$devel_package" != "x" ]; then
    args="$args -d $devel_package"
  fi
  if [ "x$unittest_package" != "x" ]; then
    args="$args -g $unittest_package"
  fi
  if [ "x$shrinkwrap_package" != "x" ]; then
    args="$args -e $shrinkwrap_package"
  fi
  if [ "x$config_packages" != "x" ]; then
    args="$args -k $config_packages"
  fi
  if [ "x$service_container" != "x" ]; then
    args="$args -C $service_container"
  fi
  if [ "x$gateway_package" != "x" ]; then
    args="$args -w $gateway_package"
  fi
  if [ "x$ducc_package" != "x" ]; then
    args="$args -D $ducc_package"
  fi
  run_script_on_virtual_machine $args

  check_retcode $?
  if [ $? -ne 0 ]; then
    handle_test_failure $ip $username
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

  local args="$ip $username $remote_run_script \
              -r $platform_run_script"
  if [ "x$server_package" != "x" ]; then
    args="$args -s $server_package"
  fi
  if [ "x$client_package" != "x" ]; then
    args="$args -c $client_package"
  fi
  if [ "x$devel_package" != "x" ]; then
    args="$args -d $devel_package"
  fi
  if [ "x$config_packages" != "x" ]; then
    args="$args -k $config_packages"
  fi
  if [ "x$suites" != "x" ]; then
    args="$args -S $suites"
  fi
  if [ "x$geoip_key" != "x" ]; then
    args="$args -G $geoip_key"
  fi

  run_script_on_virtual_machine $args

  check_retcode $?

  if [ $? -ne 0 ]; then
    handle_test_failure $ip $username
  fi
}


cleanup_test_machine() {
  local ip=$1
  local username=$2

  local retcode
  local log_files
  local remote_script="${script_location}/remote_cleanup.sh"

  echo -n "cleaning up test machine ($ip)... "

  local args="$ip $username $remote_script"
  run_script_on_virtual_machine $args

  check_retcode $?

  if [ $? -ne 0 ]; then
    handle_test_failure $ip $username
  fi
}

start_yubikey_vm() {
  local ip_address=$1
  echo -n "Setting up VM on cvm-yubikey01 node... "
  ssh -i $EC2_KEY_LOCATION -o StrictHostKeyChecking=no     \
                           -o UserKnownHostsFile=/dev/null \
                           -o LogLevel=ERROR               \
                           -o BatchMode=yes                \
      root@${ip_address} $YUBIKEY_VM_STARTUP_SCRIPT > /dev/null 2>&1
  retcode=$?
  check_retcode $retcode || return $retcode
}

tear_down_yubikey_vm() {
  local ip_address=$1
  echo -n "Tearing down VM on cvm-yubikey01 node... "
  ssh -i $EC2_KEY_LOCATION -o StrictHostKeyChecking=no     \
                           -o UserKnownHostsFile=/dev/null \
                           -o LogLevel=ERROR               \
                           -o BatchMode=yes                \
      root@${ip_address} $YUBIKEY_VM_TEARDOWN_SCRIPT > /dev/null 2>&1
  retcode=$?
  check_retcode $retcode || return $retcode
}

tear_down() {
  if [ "x$platform" = "xosx_x86_64" ] || [ x"$platform" = x"cc8_aarch64" ]; then
    cleanup_test_machine $ip_address $username        || die "Cleanup of test machine failed!"
  elif [ x"$ami_name" = "xcvm-yubikey01" ]; then
    tear_down_yubikey_vm $ip_address                  || die "Teardown of Yubikey VM failed!"
  else
    tear_down_virtual_machine $instance_id            || die "Teardown of VM failed!"
  fi
}

handle_test_failure() {
  local ip=$1
  local username=$2

  get_test_results $ip $username

  echo -n "at least one test case failed..."
  if [ "x$destroy_failed" = "xyes" ]; then
    echo "destroying VM!"
    tear_down
  else
    echo "skipping destructions of VM!"
  fi
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
      "${cvmfs_log_directory}/*"     \
      $log_destination
  check_retcode $?
}


#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#


while getopts "r:b:u:p:e:a:d:m:c:l:s:D:G:F" option; do
  case $option in
    r)
      platform_run_script=$OPTARG
      ;;
    b)
      platform_setup_script=$OPTARG
      ;;
    u)
      testee_url=$OPTARG
      ;;
    p)
      platform=$OPTARG
      ;;
    e)
      ec2_config=$OPTARG
      ;;
    a)
      ami_name=$OPTARG
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
    l)
      client_testee_url=$OPTARG
      ;;
    s)
      suites="$OPTARG"
      ;;
    G)
      geoip_key="$OPTARG"
      ;;
    F)
      destroy_failed="yes"
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
   [ x$testee_url            = "x" ] ||
   [ x$ami_name              = "x" ]; then
  usage "Missing parameter(s)"
fi

# check if we have a custom client testee URL
if [ ! -z "$client_testee_url" ]; then
  echo "using custom client from here: $client_testee_url"
else
  client_testee_url="$testee_url"
fi

# figure out which packages need to be downloaded
ctu="$client_testee_url"
otu="$testee_url"
client_package=$(read_package_map     ${ctu}/pkgmap "$platform" 'client'    )
fuse3_package=$(read_package_map      ${ctu}/pkgmap "$platform" 'fuse3'     )
server_package=$(read_package_map     ${otu}/pkgmap "$platform" 'server'    )
devel_package=$(read_package_map      ${ctu}/pkgmap "$platform" 'devel'     )
unittest_package=$(read_package_map   ${otu}/pkgmap "$platform" 'unittests' )
shrinkwrap_package=$(read_package_map ${otu}/pkgmap "$platform" 'shrinkwrap')
gateway_package=$(read_package_map    ${otu}/pkgmap "$platform" 'gateway'   )
ducc_package=$(read_package_map       ${otu}/pkgmap "$platform" 'ducc'      )
config_packages="$(read_package_map   ${otu}/pkgmap "$platform" 'config'    )"
service_container="$(read_package_map ${ctu}/pkgmap "container_x86_64" 'client')"

if [ x"$platform" != "xosx_x86_64" ]; then
  # check if all necessary packages were found
  if [ x"$server_package"        = "x" ] ||
    [ x"$client_package"        = "x" ] ||
    [ x"$devel_package"         = "x" ] ||
    [ x"$config_packages"       = "x" ] ||
    [ x"$unittest_package"      = "x" ] ||
    [ x"$shrinkwrap_package"    = "x" ]; then
    usage "Incomplete pkgmap file"
  fi

  if [ "x$fuse3_package" != "x" ]; then
    fuse3_package="${ctu}/${fuse3_package}"
  fi

  if [ "x$gateway_package" != "x" ]; then
    gateway_package="${otu}/${gateway_package}"
  fi

  if [ "x$ducc_package" != "x" ]; then
    ducc_package="${otu}/${ducc_package}"
  fi

  server_package="${otu}/${server_package}"
  devel_package="${ctu}/${devel_package}"
  unittest_package="${otu}/${unittest_package}"
  shrinkwrap_package="${otu}/${shrinkwrap_package}"
  config_package_urls=""
  for config_package in $config_packages; do
    config_package_urls="${config_package_base_url}/${config_package} $config_package_urls"
  done
  config_packages="$config_package_urls"
  if [ "x$service_container" != "x" ]; then
    service_container="${ctu}/${service_container}"
  fi
else
  if [ x"$client_package" = "x" ]; then
    usage "Incomplete pkgmap file"
  fi
  # Don't try to download the service container on macOS
  service_container=
fi

# special case: yubikey testing node runs a VM accesible by port 2222
if [ x"$ami_name" = "xcvm-yubikey01" ]; then
  export CLOUD_TESTING_SSH_PORT=$YUBIKEY_SSH_PORT
  echo "Setting custom port for ssh $CLOUD_TESTING_SSH_PORT"
fi

# load EC2 configuration
. $ec2_config

# construct the full package URLs
client_package="${ctu}/${client_package}"
source_tarball="${otu}/${source_tarball}"


# spawn the virtual machine image, run the platform specific setup script
# on it, wait for the spawning and setup to be complete and run the actual
# test suite on the VM.
spawn_my_virtual_machine  $ami_name   "$userdata"   || die "Aborting..."
wait_for_virtual_machine  $ip_address  $username    || die "Aborting..."
setup_virtual_machine     $ip_address  $username    || die "Aborting..."
wait_for_virtual_machine  $ip_address  $username    || die "Aborting..."
run_test_cases            $ip_address  $username    || die "Aborting..."
get_test_results          $ip_address  $username    || die "Aborting..."
tear_down

echo "all done"
