#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION    ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION   ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_BUILD_PACKAGE     ] || die "CVMFS_BUILD_PACKAGE missing"
[ ! -z $CVMFS_CI_PLATFORM_LABEL ] || die "CVMFS_CI_PLATFORM_LABEL missing"

# setup a fresh build workspace
if [ -d $CVMFS_BUILD_LOCATION ]; then
  echo "removing previous build location..."
  rm -fR $CVMFS_BUILD_LOCATION
fi
echo "creating a fresh build location in ${CVMFS_BUILD_LOCATION}..."
mkdir -p "$CVMFS_BUILD_LOCATION"

# run the build
echo "looking for build script to invoke..."
build_script="${CVMFS_SOURCE_LOCATION}/ci/build_package.sh"

# check if the script exists and is executable
[ -f $build_script ] || die "Build script '${build_script}' not found"
[ -x $build_script ] || die "Build script '${build_script}' not executable"

echo "switching to $CVMFS_BUILD_LOCATION and invoking build script..."
cd "$CVMFS_BUILD_LOCATION"

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
command_tmpl="$build_script ${CVMFS_SOURCE_LOCATION} \
                            ${CVMFS_BUILD_LOCATION}  \
                            ${CVMFS_BUILD_PACKAGE}   \
                            $args"
echo "++ $command_tmpl"

# run the build script
$command_tmpl
