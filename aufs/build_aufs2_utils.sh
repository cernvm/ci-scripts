#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $AUFS_UTIL_BUILD_LOCATION     ]                    || die "AUFS_UTIL_BUILD_LOCATION missing"
[ ! -z $AUFS_UTIL_SOURCE_LOCATION    ]                    || die "AUFS_UTIL_SOURCE_LOCATION missing"
[ "$(echo $AUFS_UTIL_SOURCE_LOCATION | head -c1)" = "/" ] || die "AUFS_UTIL_SOURCE_LOCATION must be absolute"

echo "cleaning out previous build location..."
rm -fR $AUFS_UTIL_BUILD_LOCATION

echo "setting up fresh RPM build location..."
mkdir ${AUFS_UTIL_BUILD_LOCATION}
mkdir ${AUFS_UTIL_BUILD_LOCATION}/BUILD
mkdir ${AUFS_UTIL_BUILD_LOCATION}/BUILDROOT
mkdir ${AUFS_UTIL_BUILD_LOCATION}/RPMS
mkdir ${AUFS_UTIL_BUILD_LOCATION}/SOURCES
mkdir ${AUFS_UTIL_BUILD_LOCATION}/SPECS
mkdir ${AUFS_UTIL_BUILD_LOCATION}/SRPMS
mkdir ${AUFS_UTIL_BUILD_LOCATION}/TMP

echo "creating source tarball..."
tarball_name="aufs2-util-2.1.tar.gz"
spec_name="aufs2-util.spec"

mv      ${AUFS_UTIL_SOURCE_LOCATION}/$spec_name ${AUFS_UTIL_BUILD_LOCATION}/SPECS
tar cfz $tarball_name                           ${AUFS_UTIL_SOURCE_LOCATION}
mv      $tarball_name                           ${AUFS_UTIL_BUILD_LOCATION}/SOURCES

# Build
echo "running the RPM build..."
cd ${AUFS_UTIL_BUILD_LOCATION}/SPECS
rpmbuild --define "%_topdir ${AUFS_UTIL_BUILD_LOCATION}"      \
         --define "%_tmppath ${AUFS_UTIL_BUILD_LOCATION}/TMP" \
         -ba $spec_name
