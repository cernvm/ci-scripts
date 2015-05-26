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
  local oldwd="$(pwd)"

  cd $CVMFS_BUILD_LOCATION
  for rpm in $(find . -type f | grep -e '.*\.rpm$'); do
    local unsigned_rpm="$(echo "$rpm" | sed -e 's/^\(.*\)\.rpm$/\1.nosig.rpm/')"
    local unsigned_rpm_path="$(dirname $rpm)/${unsigned_rpm}"

    echo "renaming ${rpm} to ${unsigned_rpm_path}..."
    mv $rpm $unsigned_rpm_path || return 1

    echo "signing ${unsigned_rpm_path} saving into ${rpm}..."
    curl --data-binary @$unsigned_rpm_path                     \
         --cacert      /etc/pki/tls/certs/cern-ca-bundle.crt   \
         --cert        /etc/pki/tls/certs/$(hostname -s).crt   \
         --key         /etc/pki/tls/private/$(hostname -s).key \
         "$rpm_signing_server" > $rpm || return 2

    echo "validating ${rpm}..."
    rpm -K $rpm || return 3

    echo "removing ${unsigned_rpm_path}..."
    rm -f $unsigned_rpm_path || return 4
  done

  cd $oldwd
}

case "$package_type" in
  rpm)
    echo "signing RPM"
    ;;
  *)
    echo "signing is not supported for $package_type"
    ;;
esac
