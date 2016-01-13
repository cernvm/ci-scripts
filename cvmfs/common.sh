#!/bin/sh

#
# common configuration and helpers for CernVM-FS CI build scripts
#

echo
echo "CernVM-FS Build Environment"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Build Script:            $CVMFS_BUILD_SCRIPT"
echo "Source Location:         $CVMFS_SOURCE_LOCATION"
echo "Build Location:          $CVMFS_BUILD_LOCATION"
echo "Clean Build:             $CVMFS_BUILD_CLEAN"
echo "CernVM-FS Git Revision:  $CVMFS_GIT_REVISION"
echo

get_platform_description() {
  local dist="$1"
  local cfg="$2"
  jq --raw-output \
    ".[] | select(.config == \"$cfg\" and .dist == \"$dist\")" $PLATFORMS
}

has_platform_parameter() {
  local parameter="$1"
  local vm_description="$2"
  local result
  result=$(echo "$vm_description" | jq --raw-output "has(\"$parameter\")")
  [ x"$result" = x"true" ]
}

get_platform_parameter() {
  local parameter="$1"
  local vm_description="$2"
  if ! has_platform_parameter "$parameter" "$vm_description"; then
    echo ""
  else
    echo "$vm_description" | jq --raw-output ".$parameter"
  fi
}

# extracts an architecture string from a CI or build machine label such as:
#   docker-i386
#   bare-armv7hl
#   ...
# @param label  the full label including the prefix and separated by -
# @return       the desired architecture string
extract_arch() {
  local label="$1"
  echo "$label" | sed -e 's/^[^-]\+-\(.*\)$/\1/'
}
