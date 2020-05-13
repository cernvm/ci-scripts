#!/bin/bash

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../common.sh

SYSTEM_NAME="fedora32"
BASE_ARCH="x86_64"

yum_repo="$(get_yum_repo_mirror "https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-32&arch=$BASE_ARCH")"
REPO_BASE_URL="$yum_repo"
REPO_MIRRORLIST="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-32&arch=$BASE_ARCH"
GPG_KEY_PATHS="file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-32"
BASE_PACKAGES="fedora-release coreutils tar iputils dnf"
PACKAGE_MGR="dnf"

. ${SCRIPT_LOCATION}/../rhel_common/build.sh
