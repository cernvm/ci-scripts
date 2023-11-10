#!/bin/sh

script_location=$(cd "$(dirname "$0")"; pwd)

reachability_timeout=1800  # (  30 minutes )
accessibility_timeout=7200 # ( 120 minutes )


die() {
  local msg=$1
  echo $msg
  exit 103
}


check_retcode() {
  local retcode=$1
  local additional_msg="$2"

  if [ $retcode -ne 0 ]; then
    echo -n "fail"
  else
    echo -n "okay"
  fi
  if [ x"$additional_msg" != x"" ]; then
    echo " ($additional_msg)"
  else
    echo ""
  fi

  return $retcode
}


check_timeout() {
  local timeout_state=$1
  local timeout_start=$2
  local waiting_time=$(( ( $timeout_start - $timeout_state ) / 60 ))

  [ $timeout_state -ne 0 ]
  check_retcode $? "waited $waiting_time minutes"
}


# Reads the package map produced by the nightly build process to map supported
# platforms to their associated packages.
# pkgmap-format (ini-style):
#     [<platform name>]
#     client=<url to client package>
#     server=<url to server package>
#     ...=...
#     [<next platform name>]
#     ...=...
#
# @param base_pkgmap_url  base URL where to find the package map files
# @param platform         the platform name to be searched for
# @param package          the package to be retrieved from the pkgmap
# @return                 0 on success (queried package URL through stdout)
read_package_map() {
  local base_pkgmap_url=$1
  local platform=$2
  local package=$3

  local platform_found=0
  local package_url=""
  local old_ifs="$IFS"

  local pkgmap_url="${base_pkgmap_url}/pkgmap.${platform}"

  IFS='
'
  for line in $(wget --no-check-certificate --quiet --output-document=- $pkgmap_url); do
    # search the desired platform
    if [ $platform_found -eq 0 ] && [ x"$line" = x"[$platform]" ]; then
      platform_found=1
      continue
    fi

    # when the platform was found, look for the desired package name
    if [ $platform_found -eq 1 ]; then
      # if the next platform starts, we didn't find the desired package
      if echo "$line" | grep -q -e '^\[.*\]$'; then
        break
      fi

      # check for desired package name and possibly return successfully
      if [ x"$(echo "$line" | cut -d= -f1)" = x"$package" ]; then
        package_url="$(echo "$line" | cut -d= -f2)"
        break
      fi
    fi
  done

  IFS="$old_ifs"

  # check if the desired package URL was found
  if [ x"$package_url" != x"" ]; then
    echo "$package_url"
    return 0
  else
    return 2
  fi
}


spawn_virtual_machine() {
  local l_image_id="$1"
  local userdata="$2"

  local spawn_results
  ${script_location}/instance_handler.py spawn  --image  $l_image_id
  check_retcode $?
}


wait_for_virtual_machine() {
  local ip=$1
  local username=$2
  local port=${CLOUD_TESTING_SSH_PORT:-22}

  # wait for the virtual machine to respond to pings
  echo -n "waiting for IP ($ip) to become reachable... "
  local timeout=$reachability_timeout
  while [ $timeout -gt 0 ] && ! ping -c 1 $ip > /dev/null 2>&1; do
    sleep 10
    timeout=$(( $timeout - 10 ))
  done
  if ! check_timeout $timeout $reachability_timeout; then return 1; fi

  # wait for the virtual machine to become accessible via ssh
  echo -n "waiting for VM ($ip) to become accessible... "
  timeout=$accessibility_timeout
  while [ $timeout -gt 0 ] &&                                      \
        ! ssh -i $OPENSTACK_KEY_LOCATION -o StrictHostKeyChecking=no     \
                                   -o UserKnownHostsFile=/dev/null \
                                   -o LogLevel=ERROR               \
                                   -o BatchMode=yes                \
              ${username}@${ip} -p $port 'echo hallo' > /dev/null 2>&1; do
    sleep 10
    timeout=$(( $timeout - 10 ))
  done
  if ! check_timeout $timeout $accessibility_timeout; then return 1; fi
}


tear_down_virtual_machine() {
  local instance=$1

  echo -n "tearing down virtual machine instance $instance... "
  local teardown_results
  teardown_results=$(${script_location}/instance_handler.py terminate          \
                                         --instance-id      $instance)
  check_retcode $?
}


run_script_on_virtual_machine() {
  local ip=$1
  local username=$2
  local script_path=$3
  shift 3

  local port=${CLOUD_TESTING_SSH_PORT:-22}

  args=""
  while [ $# -gt 0 ]; do
    if echo "$1" | grep -q "[[:space:]]"; then
      args="$args \"$1\""
    else
      args="$args $1"
    fi
    shift 1
  done

  ssh -i $OPENSTACK_KEY_LOCATION -o StrictHostKeyChecking=no     \
                           -o UserKnownHostsFile=/dev/null \
                           -o LogLevel=ERROR               \
                           -o BatchMode=yes                \
      $username@$ip -p $port 'cat | bash /dev/stdin' $args < $script_path
}


retrieve_file_from_virtual_machine() {
  local ip=$1
  local username=$2
  local file_path=$3
  local dest_path=$4
  local port=${CLOUD_TESTING_SSH_PORT:-22}

  scp -i $OPENSTACK_KEY_LOCATION -o StrictHostKeyChecking=no -P $port\
      $username@${ip}:${file_path} ${dest_path} > /dev/null 2>&1
}
