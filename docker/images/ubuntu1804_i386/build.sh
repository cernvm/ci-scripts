#!/bin/bash

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../common.sh

SYSTEM_NAME="ubuntu1804"
BASE_ARCH="i386"
REPO_BASE_URL="http://archive.ubuntu.com/ubuntu/"
UBUNTU_RELEASE="bionic"

. ${SCRIPT_LOCATION}/../ubuntu_common/build.sh
