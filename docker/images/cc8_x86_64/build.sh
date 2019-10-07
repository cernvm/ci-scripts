#!/bin/bash

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../common.sh

SYSTEM_NAME="cc8"
BASE_ARCH="x86_64"
REPO_BASE_URL="http://mirror.centos.org/centos/8/BaseOS/$BASE_ARCH/os"
#REPO_BASE_URL="http://linuxsoft.cern.ch/cern/centos/8.0/os/$BASE_ARCH/"
GPG_KEY_PATHS="http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official"
BASE_PACKAGES="centos-release.x86_64 coreutils.x86_64 tar.x86_64 iputils.x86_64 rpm.x86_64 yum"

. ${SCRIPT_LOCATION}/../rhel_common/build.sh
