#!/bin/sh

REPO_BASE_URL=http://download.opensuse.org/distribution/13.2/repo/oss/
DESTINATION=/chroot

echo "setting up base system..."
zypper --non-interactive      \
       --gpg-auto-import-keys \
       --root ${DESTINATION}  \
       addrepo $REPO_BASE_URL repo-oss

echo "putting /dev/zero in place..."
mkdir ${DESTINATION}/dev
cp -a /dev/zero ${DESTINATION}/dev/

echo "refreshing metadata cache..."
zypper --non-interactive      \
       --gpg-auto-import-keys \
       --root ${DESTINATION}  \
       refresh

echo "installing package manager..."
zypper --non-interactive     \
       --root ${DESTINATION} \
       install openSUSE-release zypper

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


echo "cleaning zypper caches..."
zypper --non-interactive     \
       --root ${DESTINATION} \
       clean
