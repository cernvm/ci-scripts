#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION    ] || die "CVMFS_BUILD_LOCATION missing"

# discover what to do for the platform
package_type="$(get_package_type)"
rpm_signing_server="https://cvm-sign01.cern.ch/cgi-bin/rpm/sign-rpm"

sign_rpm() {
  local rpm_directory="${CVMFS_BUILD_LOCATION}/RPMS"

  [ -d $rpm_directory ] || return 1
  echo "looking for RPMs to sign in ${rpm_directory}..."

  for rpm in $(find "$rpm_directory" -type f | grep -e '.*\.rpm$'); do
    local unsigned_rpm="$(echo "$rpm" | sed -e 's/^\(.*\)\.rpm$/\1.nosig.rpm/')"

    echo "renaming ${rpm} to ${unsigned_rpm}..."
    mv $rpm $unsigned_rpm || return 2

    echo "signing ${unsigned_rpm} saving into ${rpm}..."
    curl --data-binary @$unsigned_rpm                          \
         --cacert      /etc/pki/tls/certs/cern-ca-bundle.crt   \
         --cert        /etc/pki/tls/certs/$(hostname -s).crt   \
         --key         /etc/pki/tls/private/$(hostname -s).key \
         "$rpm_signing_server" > $rpm || return 3

    echo "validating ${rpm}..."
    rpm -K $rpm || return 4

    echo "removing ${unsigned_rpm}..."
    rm -f $unsigned_rpm || return 5
  done
}

case "$package_type" in
  rpm)
    sign_rpm || die "fail (error code: $?)"
    ;;
  *)
    echo "signing is not supported for $package_type"
    ;;
esac
