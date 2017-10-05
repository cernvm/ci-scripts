#!/bin/sh

#
# common configuration and helpers for CernVM-FS Graphdriver scripts
#

echo
echo "CernVM-FS Docker Graphdriver Build Environment"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Build Script:               $CVMFS_BUILD_SCRIPT"
echo "Source Location:            $CVMFS_SOURCE_LOCATION"
echo "Build Location:             $CVMFS_BUILD_LOCATION"
echo "Clean Build:                $CVMFS_BUILD_CLEAN"
echo "Graph Driver Git Revision:  $CVMFS_GD_GIT_REVISION"
echo

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
