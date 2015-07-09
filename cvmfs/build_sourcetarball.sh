#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_SOURCETARBALL_LOCATION ] || die "CVMFS_SOURCETARBALL_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION   ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_BUILD_SCRIPT_BASE ] || die "CVMFS_BUILD_SCRIPT_BASE missing"
[ ! -z $CVMFS_CI_PLATFORM_LABEL ] || die "CVMFS_CI_PLATFORM_LABEL missing"

# setup a fresh build workspace
if [ -d $CVMFS_SOURCE_TARBALL ]; then
  echo "removing previous source tarball location..."
  rm -fR $CVMFS_SOURCETARBALL_LOCATION
fi
echo "creating a fresh source tarball location in ${CVMFS_SOURCETARBALL_LOCATION}..."
mkdir -p "$CVMFS_SOURCETARBALL_LOCATION"

# run the build
echo "looking for build script to invoke..."
build_script_location="${CVMFS_SOURCE_LOCATION}/ci"
build_script_name="${CVMFS_BUILD_SCRIPT_BASE}_${sourcetarball}.sh"
build_script="${build_script_location}/${build_script_name}"

# check if the script exists and is executable
[ -f $build_script ] || die "Build script '${build_script}' not found"
[ -x $build_script ] || die "Build script '${build_script}' not executable"

echo "invoking source tarball maker..."
# parse the command line arguments (keep quotation marks)
args=""
while [ $# -gt 0 ]; do
  if echo "$1" | grep -q "[[:space:]]"; then
    args="$args \"$1\""
  else
    args="$args $1"
  fi
  shift 1
done

# build the invocation string and print it for debugging reasons
command_tmpl="$build_script ${CVMFS_SOURCE_LOCATION} ${CVMFS_BUILD_LOCATION} $args"
echo "++ $command_tmpl"

# run the build script
$command_tmpl
