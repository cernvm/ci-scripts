#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $AUFS_UTIL_BUILD_LOCATION     ]                    || die "AUFS_UTIL_BUILD_LOCATION missing"
[ ! -z $AUFS_UTIL_SOURCE_LOCATION    ]                    || die "AUFS_UTIL_SOURCE_LOCATION missing"
[ "$(echo $AUFS_UTIL_SOURCE_LOCATION | head -c1)" = "/" ] || die "AUFS_UTIL_SOURCE_LOCATION must be absolute"


echo "define tarball and spec file specifics..."
tarball_name="aufs2-util-2.1.tar.gz"
tarball_prefix="$(basename $tarball_name .tar.gz)"
tarball_path_prefix="$(echo "$AUFS_UTIL_SOURCE_LOCATION" | sed -e 's/^\/\(.*\)/\1/' | sed -e 's/\//\\\//g')"
spec_name="aufs2-util.spec"

echo "creating source tarball ($tarball_name | $tarball_path_prefix)..."
tar --transform="s/$tarball_path_prefix/$tarball_prefix/" -cvzf \
    $tarball_name                                               \
    ${AUFS_UTIL_SOURCE_LOCATION}

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
mv ${AUFS_UTIL_SOURCE_LOCATION}/$spec_name ${AUFS_UTIL_BUILD_LOCATION}/SPECS
mv $tarball_name                           ${AUFS_UTIL_BUILD_LOCATION}/SOURCES

# Build
echo "running the RPM build..."
cd ${AUFS_UTIL_BUILD_LOCATION}/SPECS
rpmbuild --define "%_topdir ${AUFS_UTIL_BUILD_LOCATION}"      \
         --define "%_tmppath ${AUFS_UTIL_BUILD_LOCATION}/TMP" \
         -ba $spec_name
