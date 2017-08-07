#!/bin/bash

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../common.sh

SYSTEM_NAME="debian9"
BASE_ARCH="x86_64"
REPO_BASE_URL="http://httpredir.debian.org/debian/"
UBUNTU_RELEASE="stretch"

. ${SCRIPT_LOCATION}/../ubuntu_common/build.sh
