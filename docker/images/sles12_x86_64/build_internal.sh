#!/bin/sh

set -e

REPO_BASE_URL=http://cvm-storage00.cern.ch/yum/sles12/
REPO_BASE_URL_SDK=http://cvm-storage00.cern.ch/yum/sles12-sdk/
DESTINATION=/chroot
BASE_PACKAGES="sles-release which zypper"

echo "registering cleanup handler..."
cleanup() {
  echo "cleaning up the chroot environment..."
  umount ${DESTINATION}/proc || true
  umount ${DESTINATION}/sys  || true
  umount ${DESTINATION}/dev  || true
}
trap cleanup EXIT HUP INT TERM

echo "setting up base system..."
zypper --non-interactive      \
       --gpg-auto-import-keys \
       --root ${DESTINATION}  \
       addrepo $REPO_BASE_URL repo-suse

zypper --non-interactive      \
       --gpg-auto-import-keys \
       --root ${DESTINATION}  \
       addrepo $REPO_BASE_URL_SDK repo-suse-sdk

echo "mounting /proc, /sys and /dev file systems..."
mkdir -p ${DESTINATION}/proc ${DESTINATION}/sys ${DESTINATION}/dev
mount -t proc proc ${DESTINATION}/proc/
mount -t sysfs sys ${DESTINATION}/sys/
mount -o bind /dev ${DESTINATION}/dev/

echo "refreshing metadata cache..."
zypper --non-interactive      \
       --gpg-auto-import-keys \
       --root ${DESTINATION}  \
       refresh

echo "downloading necessary RPMs..."
# Workaround: Some versions of zypper report an error even if the download-only
#             job finished successfully. We ignore this and hope for follow-up
#             errors in case something _actually_ went wrong.
#   Bugzilla: https://bugzilla.opensuse.org/show_bug.cgi?id=956480
zypper --non-interactive       \
       --root ${DESTINATION}   \
       install --download-only \
       ${BASE_PACKAGES} || true

echo "copying zypper cache for later re-build..."
zypper_cache="${DESTINATION}/var/cache/zypp/packages"
mkdir -p ${DESTINATION}/tmp
cp -r $zypper_cache ${DESTINATION}/tmp

echo "installing base system and package manager..."
zypper --non-interactive     \
       --root ${DESTINATION} \
       install ${BASE_PACKAGES}

echo "checking for expected public key..."
expected_pubkey1="gpg-pubkey-3dbdc284-53674dd4"
expected_pubkey2="gpg-pubkey-307e3d54-4be01a65"
expected_pubkey3="gpg-pubkey-39db7c82-510a966b"
expected_pubkey4="gpg-pubkey-307e3d54-5aaa90a5"
expected_pubkey5="gpg-pubkey-39db7c82-5847eb1f"
echo "*** Public Keys ***"
rpm -qa | grep gpg-pubkey
[ $(rpm -qa | grep gpg-pubkey | wc -l) -le 3 ] || { echo "more than three keys found"; exit 1; }
if [ $(rpm -qa | grep gpg-pubkey | wc -l) -eq 2 ]; then
  rpm -qa | grep $expected_pubkey1               || { echo "public key doesn't match ($expected_pubkey1)"; exit 1; }
  rpm -qa | grep $expected_pubkey2               || { echo "public key doesn't match ($expected_pubkey2)"; exit 1; }
elif [ $(rpm -qa | grep gpg-pubkey | wc -l) -eq 3 ]; then
  rpm -qa | grep $expected_pubkey1               || { echo "public key doesn't match ($expected_pubkey1)"; exit 1; }
  rpm -qa | grep $expected_pubkey4               || { echo "public key doesn't match ($expected_pubkey4)"; exit 1; }
  rpm -qa | grep $expected_pubkey5               || { echo "public key doesn't match ($expected_pubkey5)"; exit 1; }
else
  rpm -qa | grep $expected_pubkey3               || { echo "public key doesn't match ($expected_pubkey3)"; exit 1; }
fi

echo "rebuilding rpm database..."
rpm_db="${DESTINATION}/var/lib/rpm"
rm -fR $rpm_db
mkdir -p $rpm_db
chroot $DESTINATION rpm --initdb
chroot $DESTINATION rpm -ivh --justdb '/tmp/packages/repo-suse/suse/*/*.rpm'

echo "cleaning up zypper cache copy..."
rm -fR ${DESTINATION}/tmp/packages

echo "cleaning zypper caches..."
zypper --non-interactive     \
       --root ${DESTINATION} \
       clean
