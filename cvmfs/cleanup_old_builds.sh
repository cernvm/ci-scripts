#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_FULL_BUILD_WORKSPACE ]                       || die "CVMFS_FULL_BUILD_WORKSPACE missing"
[ ! -z $CVMFS_CLEANUP_GRACE_PERIOD ]                       || die "CVMFS_CLEANUP_GRACE_PERIOD missing"
[ "$(echo $CVMFS_FULL_BUILD_WORKSPACE | head -c1)" = "/" ] || die "CVMFS_FULL_BUILD_WORKSPACE must be absolute"

get_candidates() {
  local dir="$1"
  ls -tr "$dir"
}

echo "checking if directories need to be removed in ${CVMFS_FULL_BUILD_WORKSPACE}..."
number_of_builds=$(get_candidates $CVMFS_FULL_BUILD_WORKSPACE | wc -l)
echo "found $number_of_builds build dirs"

if [ $number_of_builds -le $CVMFS_CLEANUP_GRACE_PERIOD ]; then
  echo "nothing to be cleaned up"
  exit 0
fi

builds_to_delete=$(( $number_of_builds - $CVMFS_CLEANUP_GRACE_PERIOD ))
echo "removing $builds_to_delete build directories..."
for d in $(get_candidates $CVMFS_FULL_BUILD_WORKSPACE | head -n $builds_to_delete); do
  to_be_removed="${CVMFS_FULL_BUILD_WORKSPACE}/$d"
  # sanity check (only delete directories)
  if [ ! -d $to_be_removed ]; then
    echo "'$d' is not a directory and therefore not deleted"
    continue
  fi

  # sanity check (only remove number style directories)
  if echo "$d" | grep -v -q -e '^[0-9]*$'; then
    echo "directory '$d' doesn't look like a build number and is not deleted"
    continue
  fi

  echo "deleting '$to_be_removed'"
  rm -fR $to_be_removed
done
