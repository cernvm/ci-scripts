#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh

# signing server endpoints
rpm_signing_server="https://cvm-sign02.cern.ch/cgi-bin/rpm/sign-rpm"
deb_signing_server="https://cvm-sign02.cern.ch/cgi-bin/deb/sign-deb"

# This script works as well for aufs packages
if [ "x${AUFS_BUILD_LOCATION}" != "x" ]; then
  CVMFS_BUILD_LOCATION="${AUFS_BUILD_LOCATION}/rpmbuild"
elif [ "x${AUFS_UTIL_BUILD_LOCATION}" != "x" ]; then
  CVMFS_BUILD_LOCATION="${AUFS_UTIL_BUILD_LOCATION}/rpmbuild"
fi

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION    ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_CI_PLATFORM_LABEL ] || die "CVMFS_CI_PLATFORM_LABEL missing"

# discover what to do for the platform
package_type="unknown"
if [ x"$CVMFS_CI_PLATFORM_LABEL" = x"docker" ]; then
  # on a docker host we need to guess which package type to sign since it might
  # not be the package type of the host system
  rpms="$(find $CVMFS_BUILD_LOCATION -name '*.rpm' | wc -l)"
  debs="$(find $CVMFS_BUILD_LOCATION -name '*.deb' | wc -l)"
  containers="$(find $CVMFS_BUILD_LOCATION -name '*.docker.tar.gz' | wc -l)"
  snapshotters="$(find $CVMFS_BUILD_LOCATION -name 'cvmfs_snapshotter.*.x86_64' | wc -l)"
  [ $rpms -gt 0 ] || [ $debs -gt 0 ] || [ $containers -gt 0 ] || [ $snapshotters -gt 0 ] || \
    die "Neither RPMs nor DEBs nor containers nor snapshotters found"

  if [ $snapshotters -gt 0 ]; then
    package_type="snapshotter"
  elif [ $containers -gt 0 ]; then
    package_type="container"
  elif [ $rpms -gt $debs ]; then
    package_type="rpm"
  else
    package_type="deb"
  fi
else
  # on a bare metal build machine we just assume the package type to be the
  # system's default package type
  package_type="$(get_package_type)"
fi


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
    curl --data-binary @$unsigned_rpm  \
         --cacert      $CACERT         \
         --cert        $CERT           \
         --key         $KEY            \
         --silent                      \
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
    curl --data-binary @$unsigned_deb      \
         --cacert      $CACERT             \
         --cert        $CERT               \
         --key         $KEY                \
         --silent                          \
         "$deb_signing_server" > $deb || return 3

    echo "validating ${deb}..."
    dpkg-sig -c $deb | grep -q GOODSIG || return 4

    echo "removing ${unsigned_deb}..."
    rm -f $unsigned_deb || return 5
  done
}

CERT=/etc/pki/tls/certs/$(hostname -s).crt
KEY=/etc/pki/tls/private/$(hostname -s).key
CACERT=/etc/pki/tls/certs/cern-ca-bundle.crt
if [ -f $HOME/cernvm/$(hostname -s).crt ]; then
  CERT="$HOME/cernvm/$(hostname -s).crt"
  KEY="$HOME/cernvm/$(hostname -s).key"
  CACERT="$HOME/cernvm/cern-ca-bundle.crt"
  echo "Using foreign certificate $CERT"
fi

if [ ! -f $CERT ]; then
  echo "WARNING: NO HOST CERTIFICATE FOUND!"
  echo "  Expected $CERT"
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
  container)
    echo "TODO: sign docker container"
    ;;
  *)
    echo "signing is not supported for $package_type"
    ;;
esac
