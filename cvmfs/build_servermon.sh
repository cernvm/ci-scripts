#!/bin/bash

set -e
set -x

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

[ ! -z $CVMFS_SERVERMON_SOURCE_LOCATION   ] || die "CVMFS_SERVERMON_SOURCE_LOCATION missing"
[ ! -z $CVMFS_WORKSPACE   ]                 || die "CVMFS_WORKSPACE missing"

CVMFS_SERVERMON_RESULT_LOCATION="${CVMFS_WORKSPACE}/rpmbuild"
mkdir     ${CVMFS_SERVERMON_RESULT_LOCATION}              \
          ${CVMFS_SERVERMON_RESULT_LOCATION}/TMP          \
          ${CVMFS_SERVERMON_RESULT_LOCATION}/RPMS         \
          ${CVMFS_SERVERMON_RESULT_LOCATION}/SRPMS        \
          ${CVMFS_SERVERMON_RESULT_LOCATION}/BUILD        \
          ${CVMFS_SERVERMON_RESULT_LOCATION}/BUILDROOT    \
          ${CVMFS_SERVERMON_RESULT_LOCATION}/SPECS        \
          ${CVMFS_SERVERMON_RESULT_LOCATION}/SOURCES

cp ${CVMFS_SERVERMON_SOURCE_LOCATION}/packaging/rpm/cvmfs-servermon.spec ${CVMFS_SERVERMON_RESULT_LOCATION}
CVMFS_SERVERMON_VERSION=$(cat ${CVMFS_SERVERMON_RESULT_LOCATION}/cvmfs-servermon.spec | grep -e "^Version:" | awk '{print $2}')

source_name="cvmfs-servermon-${CVMFS_SERVERMON_VERSION}"
source_path=${CVMFS_SERVERMON_RESULT_LOCATION}/SOURCES/$source_name
mkdir $source_path

# copy the sources
cp -R ${CVMFS_SERVERMON_SOURCE_LOCATION}/webapi        \
      ${CVMFS_SERVERMON_SOURCE_LOCATION}/LICENSE       \
      ${CVMFS_SERVERMON_SOURCE_LOCATION}/README.md     \
      ${CVMFS_SERVERMON_SOURCE_LOCATION}/misc          \
      ${CVMFS_SERVERMON_SOURCE_LOCATION}/compat        \
      ${CVMFS_SERVERMON_SOURCE_LOCATION}/etc           \
      $source_path

targz_path=${source_path}.tar.gz
cd ${CVMFS_SERVERMON_RESULT_LOCATION}/SOURCES
tar czf $targz_path $source_name
rm -rf "$source_path"

cd $CVMFS_SERVERMON_RESULT_LOCATION
rpmbuild --define "%_topdir  ${CVMFS_SERVERMON_RESULT_LOCATION}"       \
         --define "%_tmppath ${CVMFS_SERVERMON_RESULT_LOCATION}/TMP"   \
         -ba cvmfs-servermon.spec
