#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_SOURCE_LOCATION ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_BUILD_LOCATION  ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $BUILD_NUMBER          ] || die "BUILD_NUMBER missing"

# make sure that the build location is there
[ -d $CVMFS_BUILD_LOCATION ] || mkdir -p $CVMFS_BUILD_LOCATION

# run the build
echo "looking for build script to invoke..."
build_script="${CVMFS_SOURCE_LOCATION}/ci/build_cvmfs_sourcetarball.sh"

# check if the script exists and is executable
[ -f $build_script ] || die "Build script '${build_script}' not found"
[ -x $build_script ] || die "Build script '${build_script}' not executable"

# figure out if we are building a nightly
nightly_number=
if [ x"$CVMFS_NIGHTLY_BUILD" = x"true" ]; then
  nightly_number=${BUILD_NUMBER}
fi

echo "invoking source tarball maker..."
# build the invocation string and print it for debugging reasons
command_tmpl="$build_script ${CVMFS_SOURCE_LOCATION} ${CVMFS_BUILD_LOCATION} $nightly_number"
echo "++ $command_tmpl"

# run the build script
$command_tmpl
