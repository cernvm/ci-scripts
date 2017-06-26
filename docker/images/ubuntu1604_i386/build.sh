#!/bin/bash

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../common.sh

SYSTEM_NAME="ubuntu1604"
BASE_ARCH="i386"
REPO_BASE_URL="http://archive.ubuntu.com/ubuntu/"
UBUNTU_RELEASE="xenial"

. ${SCRIPT_LOCATION}/../ubuntu_common/build.sh
