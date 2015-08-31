#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# This script works as well for aufs kernel binaries
if [ "x${AUFS_BUILD_LOCATION}" != "x" ]; then
  CVMFS_BUILD_LOCATION="$AUFS_BUILD_LOCATION"
fi

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION ] || die "CVMFS_BUILD_LOCATION missing"

# discover what to do for the platform
package_type="$(get_package_type)"
rpm_signing_server="https://cvm-sign01.cern.ch/cgi-bin/rpm/sign-rpm"
deb_signing_server="https://cvm-sign01.cern.ch/cgi-bin/deb/sign-deb"


sign_rpm() {
  local rpm_directory="${CVMFS_BUILD_LOCATION}/RPMS"
  local source_rpm_directory="${CVMFS_BUILD_LOCATION}/SRPMS"

  [ -d $rpm_directory ] || return 1
  echo "looking for RPMs in ${rpm_directory} and ${source_rpm_directory}..."

  for rpm in $(find "$rpm_directory" "$source_rpm_directory" -type f | \
               grep -e '.*\.rpm$'); do
    local unsigned_rpm="$(echo "$rpm" | sed -e 's/^\(.*\)\.rpm$/\1.nosig.rpm/')"

    echo "renaming ${rpm} to ${unsigned_rpm}..."
    mv $rpm $unsigned_rpm || return 2

    echo "signing ${unsigned_rpm} saving into ${rpm}..."
    curl --data-binary @$unsigned_rpm                          \
         --cacert      /etc/pki/tls/certs/cern-ca-bundle.crt   \
         --cert        /etc/pki/tls/certs/$(hostname -s).crt   \
         --key         /etc/pki/tls/private/$(hostname -s).key \
         --silent                                              \
         "$rpm_signing_server" > $rpm || return 3

    echo "validating ${rpm}..."
    rpm -K $rpm || return 4

    echo "removing ${unsigned_rpm}..."
    rm -f $unsigned_rpm || return 5
  done
}


sign_deb() {
  [ -d "${CVMFS_BUILD_LOCATION}" ] || return 1
  echo "looking for DEBs in ${CVMFS_BUILD_LOCATION}..."

  for deb in $(find "${CVMFS_BUILD_LOCATION}" -type f | \
               grep -e '.*\.deb$'); do
    local unsigned_deb="$(echo "$deb" | sed -e 's/^\(.*\)\.deb$/\1.nosig.deb/')"

    echo "renaming ${deb} to ${unsigned_deb}..."
    mv $deb $unsigned_deb || return 2

    echo "signing ${unsigned_deb} saving into ${deb}..."
    curl --data-binary @$unsigned_deb                          \
         --cacert      /etc/pki/tls/certs/cern-ca-bundle.crt   \
         --cert        /etc/pki/tls/certs/$(hostname -s).crt   \
         --key         /etc/pki/tls/private/$(hostname -s).key \
         --silent                                              \
         "$deb_signing_server" > $deb || return 3

    echo "validating ${deb}..."
    dpkg-sig -c $deb | grep -q GOODSIG || return 4

    echo "removing ${unsigned_deb}..."
    rm -f $unsigned_deb || return 5
  done
}

if [ ! -f /etc/pki/tls/certs/$(hostname -s).crt ]; then
  echo "WARNING: NO HOST CERTIFICATE FOUND!"
  echo "  Expected /etc/pki/tls/certs/$(hostname -s).crt"
  echo "  Not signing packages!"
  exit 0
fi

case "$package_type" in
  rpm)
    sign_rpm || die "fail (error code: $?)"
    ;;
  deb)
    sign_deb || die "fail (error code: $?)"
    ;;
  *)
    echo "signing is not supported for $package_type"
    ;;
esac
