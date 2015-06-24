#/bin/sh


#
# This script builds cvmfs_unittest_debug runs the gcov and reports the test coverage status.
# It stores the final result in $CVMFS_
#

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION  ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_BUILD_CLEAN     ] || die "CVMFS_BUILD_CLEAN missing"

# setup a fresh build workspace on first execution or on request
if [ ! -d "$CVMFS_BUILD_LOCATION" ] || [ x"$CVMFS_BUILD_CLEAN" = x"true" ]; then
  rm -fR "$CVMFS_BUILD_LOCATION"
  mkdir -p "$CVMFS_BUILD_LOCATION"
fi

# run the build
echo "switching to ${CVMFS_BUILD_LOCATION} and invoking build script..."
cd "${CVMFS_BUILD_LOCATION}"
cmake -DBUILD_DOCUMENTATION=yes ${CVMFS_SOURCE_LOCATION}
make doc
