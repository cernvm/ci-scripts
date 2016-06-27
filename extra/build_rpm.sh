#!/bin/sh

set -e

usage() {
  echo "Usage: $0 <workspace> <git sources>"
}

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh

WORKSPACE="$1"
GIT_SOURCES="$2"

# sanity checks
[ ! -z $WORKSPACE   ] || die "WORKSPACE missing"
[ ! -z $GIT_SOURCES ] || die "GIT_SOURCES missing"

RPMBUILD_LOCATION="${WORKSPACE}/rpmbuild"
PACKAGE="$(basename $GIT_SOURCES)"
SPEC_FILE="${GIT_SOURCES}/${PACKAGE}.spec"

[ -d $GIT_SOURCES ] || die "source directory $GIT_SOURCES missing"
[ -f $SPEC_FILE ] || die "spec file $SPEC_FILE missing"

VERSION="$(grep ^Version: $SPEC_FILE | awk '{print $2}')"
echo "Building ${PACKAGE}-${VERSION}"

# setup a fresh build workspace
if [ -d "$RPMBUILD_LOCATION" ]; then
  echo "removing previous build location..."
  rm -fR "$RPMBUILD_LOCATION"
fi
echo "creating a fresh rpmbuild location in $RPMBUILD_LOCATION..."
mkdir -p "${RPMBUILD_LOCATION}/SOURCES"

echo "creating source tarball ${PACKAGE}-${VERSION}.tar.gz"
cd $GIT_SOURCES
git archive \
  --prefix="${PACKAGE}-${VERSION}/" \
  --format=tar \
  $(git describe --contains --all HEAD) | \
  gzip > "${RPMBUILD_LOCATION}/SOURCES/${PACKAGE}-${VERSION}.tar.gz"
cd $OLDPWD

echo "building RPM ${PACKAGE}"
rpmbuild -ba "${GIT_SOURCES}/${PACKAGE}.spec" \
  --define "%_topdir ${RPMBUILD_LOCATION}"
