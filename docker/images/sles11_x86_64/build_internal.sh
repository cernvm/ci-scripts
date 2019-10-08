#!/bin/sh

set -e

REPO_BASE_URL=http://cvm-storage00.cern.ch/yum/sles11/
REPO_BASE_URL_SDK=http://cvm-storage00.cern.ch/yum/sles11-sdk/
DESTINATION=/chroot

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
       sles-release zypper || true

echo "copying zypper cache for later re-build..."
zypper_cache="${DESTINATION}/var/cache/zypp/packages"
mkdir -p ${DESTINATION}/tmp
cp -r $zypper_cache ${DESTINATION}/tmp

echo "installing base system and package manager..."
zypper --non-interactive     \
       --root ${DESTINATION} \
       install sles-release zypper

echo "found the following public keys: "
rpm -qa | grep gpg-pubkey
num_pubkeys=$(rpm -qa | grep gpg-pubkey | wc -l)
echo "checking for expected public keys..."
if [ $num_pubkeys -eq 3 ]; then
  echo "checking for expected public key..."
  expected_pubkey1="gpg-pubkey-3dbdc284-53674dd4"
  expected_pubkey2="gpg-pubkey-307e3d54-5aaa90a5"
  expected_pubkey3="gpg-pubkey-39db7c82-5847eb1f"
  rpm -qa | grep $expected_pubkey1               || { echo "public key doesn't match"; exit 1; }
  rpm -qa | grep $expected_pubkey2               || { echo "public key doesn't match"; exit 1; }
  rpm -qa | grep $expected_pubkey3               || { echo "public key doesn't match"; exit 1; }
elif [ $num_pubkeys -eq 2 ]; then
  expected_pubkey1="gpg-pubkey-307e3d54-4be01a65"
  expected_pubkey2="gpg-pubkey-3dbdc284-53674dd4"
  rpm -qa | grep $expected_pubkey1               || { echo "public key doesn't match"; exit 1; }
  rpm -qa | grep $expected_pubkey2               || { echo "public key doesn't match"; exit 1; }
else
  echo "Problem with the build container's public keys"
  exit 1
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
