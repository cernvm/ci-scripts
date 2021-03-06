#!/bin/bash

# This is a unified script supposed to bootstrap RHEL-based chroot tarballs. It
# should _not_ be invoked by itself but instead sourced by platform dependent
# build scripts definding _all_ of the following variables:
#

#   SYSTEM_NAME    generic name of the OS to be built (i.e. slc5)
#   BASE_ARCH      CPU architecture to be built for (i386 or x86_64)
#   REPO_BASE_URL  URL to the base apt repository to be used for bootstrapping
#   UBUNTU_RELEASE The name of the ubuntu release to bootstrap (e.g. 'trusty')

set -e

[ ! -z "$SYSTEM_NAME"    ] || die "SYSTEM_NAME is not defined"
[ ! -z "$BASE_ARCH"      ] || die "BASE_ARCH is not defined"
[ ! -z "$REPO_BASE_URL"  ] || die "REPO_BASE_URL is not defined"
[ ! -z "$UBUNTU_RELEASE" ] || die "GPG_KEY_PATHS is not defined"

TARBALL_NAME="${SYSTEM_NAME}_${BASE_ARCH}.tar.gz"
DESTINATION="$(mktemp -d)"

which debootstrap || die "debootstrap is not installed"

if [ x"$BASE_ARCH" = x"x86_64" ]; then
  echo "using 'amd64' in lieu of x86_64..."
  BASE_ARCH="amd64"
fi

echo "installing cleanup handler..."
cleanup() {
  echo "cleaning up the build environment..."
  umount ${DESTINATION}/dev  || true
  umount ${DESTINATION}/proc || true
  rm -fR $DESTINATION        || true
}
trap cleanup EXIT HUP INT TERM

echo "creating chroot dir..."
[ ! -d $DESTINATION ] || rm -fR $DESTINATION
mkdir -p $DESTINATION

# the include="perl" line fixes deboostrap for buster; if it works without it in the future, remove the line
echo "bootstrapping a build environment..."
debootstrap --variant=buildd  \
            --include="perl"  \
            --arch=$BASE_ARCH \
	          --force-check-gpg \
            $UBUNTU_RELEASE   \
            $DESTINATION      \
            $REPO_BASE_URL

if [ x"$UBUNTU_RELEASE" != x"bionic" ] && [ x"$UBUNTU_RELEASE" != x"buster" ] ; then
  echo "installing stretch and artful source repositories for autofs backport..."
  echo "deb-src http://ftp.debian.org/debian stretch main" > $DESTINATION/etc/apt/sources.list.d/stretch-src.list
  echo "deb-src http://old-releases.ubuntu.com/ubuntu/ artful main" > $DESTINATION/etc/apt/sources.list.d/artful-src.list
  keysfile_stretch="$(dirname $0)/../ubuntu_common/stretch-keys.asc"
  keysfile_artful="$(dirname $0)/../ubuntu_common/artful-keys.asc"
  cp $keysfile_stretch $DESTINATION/etc/apt/trusted.gpg.d/stretch-keys.asc
  cp $keysfile_artful $DESTINATION/etc/apt/trusted.gpg.d/artful-keys.asc
  gpg --dearmor $DESTINATION/etc/apt/trusted.gpg.d/stretch-keys.asc
  gpg --dearmor $DESTINATION/etc/apt/trusted.gpg.d/artful-keys.asc
fi

echo "packaging up the image..."
tar -czf $TARBALL_NAME -C $DESTINATION .

echo "created $TARBALL_NAME ($(stat --format='%s' $TARBALL_NAME) bytes)"
