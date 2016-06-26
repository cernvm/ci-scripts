#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh

# sanity checks
[ ! -z $WORKSPACE   ] || die "WORKSPACE missing"
[ ! -z $GIT_SOURCES ] || die "GIT_SOURCES missing"

RPMBUILD_LOCATION="${WORKSPACE}/rpmbuild"
PACKAGE="$(filename $GIT_SOURCES)"
SPEC_FILE="${GIT_SOURCES}/${PACKAGE}.spec"

[ -d $GIT_SOURCES ] || die "source directory $GIT_SOURCES missing"
[ -f $SPEC_FILE ] || die "spec file $SPEC_FILE missing"

VERSION="$(grep ^Version: $SPEC_FILE | awk '{print $2}')"
echo "Building ${PAKCAGE}-${VERSION}"

# setup a fresh build workspace
if [ -d "$RPMBUILD_LOCATION" ]; then
  echo "removing previous build location..."
  rm -fR "$RPMBUILD_LOCATION"
fi
echo "creating a fresh rpmbuild location in $RPMBUILD_LOCATION..."
mkdir -p "${RPMBUILD_LOCATION}/SOURCES"

echo "creating source tarball"
cd $GIT_SOURCES
git archive -o "${RPMBUILD_LOCATION}/SOURCES/${PACKAGE}-${VERSION}.tar.gz" \
  --prefix="${PACKAGE}-${VERSION}/" \
  $(git describe --contains --all HEAD)
cd $OLDPWD

echo "building RPM"
rpmbuild -ba "${GIT_SOURCES}/${PACKAGE}.spec" \
  --define "%_topdir ${RPMBUILD_LOCATION}"  
