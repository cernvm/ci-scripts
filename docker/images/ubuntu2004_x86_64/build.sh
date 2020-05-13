#!/bin/bash

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../common.sh

SYSTEM_NAME="ubuntu2004"
BASE_ARCH="x86_64"
REPO_BASE_URL="http://archive.ubuntu.com/ubuntu/"
UBUNTU_RELEASE="focal"

. ${SCRIPT_LOCATION}/../ubuntu_common/build.sh
