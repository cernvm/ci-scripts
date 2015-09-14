#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $AUFS_BUILD_LOCATION  ] || die "AUFS_BUILD_LOCATION missing"
[ ! -z $AUFS_SOURCE_LOCATION ] || die "AUFS_SOURCE_LOCATION missing"
[ ! -z $AUFS_KERNEL_VERSION  ] || die "AUFS_KERNEL_VERSION missing"

kernel_id="$(get_kernel_package_name $AUFS_KERNEL_VERSION)"

echo "preparing the build environment for ${kernel_id}..."
prepare_kernel_build_environment $AUFS_BUILD_LOCATION

echo "downloading the kernel sources..."
rpmbuild_location="${AUFS_BUILD_LOCATION}/rpmbuild"
source_location="${rpmbuild_location}/SOURCES"
download_kernel_sources $source_location $AUFS_KERNEL_VERSION updates-source

echo "decompressing kernel sources..."
decompress_kernel_sources_tarxz $source_location
kernel_source_location="${source_location}/${kernel_id}"

echo "applying AUFS patches..."
apply_patch $kernel_source_location 1 ${AUFS_SOURCE_LOCATION}/aufs3-kbuild.patch
apply_patch $kernel_source_location 1 ${AUFS_SOURCE_LOCATION}/aufs3-base.patch
apply_patch $kernel_source_location 1 ${AUFS_SOURCE_LOCATION}/aufs3-mmap.patch
apply_patch $kernel_source_location 0 ${AUFS_SOURCE_LOCATION}/aufs3-mmap-fremap.patch

echo "adding additional files to kernel source tree..."
cp -r ${AUFS_SOURCE_LOCATION}/fs/aufs                         ${kernel_source_location}/fs/
cp    ${AUFS_SOURCE_LOCATION}/Documentation/ABI/testing/*     ${kernel_source_location}/Documentation/ABI/testing/
cp    ${AUFS_SOURCE_LOCATION}/include/uapi/linux/aufs_type.h  ${kernel_source_location}/include/uapi/linux/

echo "compressing kernel sources..."
compress_kernel_sources_tarxz $source_location

echo "writing kernel build configuration files..."
echo '
CONFIG_AUFS_FS=y
CONFIG_AUFS_BRANCH_MAX_127=y
CONFIG_AUFS_SBILIST=y
CONFIG_AUFS_SHWH=y
CONFIG_AUFS_BR_RAMFS=n
CONFIG_AUFS_BR_FUSE=y
CONFIG_AUFS_POLL=y
CONFIG_AUFS_BDEV_LOOP=y
CONFIG_AUFS_XATTR=y
CONFIG_CGROUP_PERF=n' >> ${source_location}/kernel-3.10.0-x86_64.config

echo '
CONFIG_AUFS_FS=y
CONFIG_AUFS_BRANCH_MAX_127=y
CONFIG_AUFS_SBILIST=y
CONFIG_AUFS_SHWH=y
CONFIG_AUFS_BR_RAMFS=n
CONFIG_AUFS_BR_FUSE=y
CONFIG_AUFS_POLL=y
CONFIG_AUFS_BDEV_LOOP=y
CONFIG_AUFS_XATTR=y
CONFIG_CGROUP_PERF=n
CONFIG_AUFS_DEBUG=y' >> ${source_location}/kernel-3.10.0-x86_64-debug.config

echo "patching the kernel spec file..."
sed -i -e '1 i %define buildid .aufs3'                                              ${source_location}/kernel.spec
sed -i -e 's/^%define listnewconfig_fail 1/%define listnewconfig_fail 0/'           ${source_location}/kernel.spec
sed -i -e 's/"${patch:0:8}" != "patch-3."/"${patch:0:8}" != "patch-3." -a 0 -eq 1/' ${source_location}/kernel.spec  # HACK, broken upstream?

echo "switching to the build directory and build the kernel..."
cd ${source_location}
rpmbuild --define "%_topdir ${rpmbuild_location}"      \
         --define "%_tmppath ${rpmbuild_location}/TMP" \
         --with firmware                               \
         --without kabichk                             \
         -ba kernel.spec

echo "cleaning up..."
rm -fR ${rpmbuild_location}/BUILD/${kernel_id}

aufs_kernel_version_tag="${AUFS_KERNEL_VERSION}.aufs3.x86_64"
echo "successfully built AUFS enabled kernel ${aufs_kernel_version_tag}"

# this is currently disabled because of reasons...
#
# TODO: Installing openafs-1.6.9-2.el7.cern.src.rpm
#       warning: openafs-1.6.9-2.el7.cern.src.rpm: Header V4 DSA/SHA1 Signature, key ID 1d1e034b: NOKEY
#       error: Failed build dependencies:
#         kernel-devel-x86_64 = 3.10.0-123.20.1.el7.aufs3.x86_64 is needed by openafs-1.6.9-2.el7.centos.x86_64
#       [centos@cvm-build18 test_build]$ yum list installed | grep kernel-devel
#       kernel-devel.x86_64                   3.10.0-123.20.1.el7.aufs3        installed
#
#       The build dependency is kernel-devel-x86_64 while the package is called
#                               kernel-devel.x86_64 (- vs. .)

# echo "downloading OpenAFS kernel module sources..."
# download_kmod_sources $source_location kmod-openafs

# echo "installing just created kernel RPMs..."
# install_kernel_devel_rpm "$rpmbuild_location" "$aufs_kernel_version_tag"

# echo "building the OpenAFS kernel module..."
# rpmbuild --define "%_topdir ${rpmbuild_location}"      \
#          --define "%_tmppath ${rpmbuild_location}/TMP" \
#          --define "build_modules 1"                    \
#          --define "build_userspace 1"                  \
#          --define "kernvers $aufs_kernel_version_tag"  \
#          --rebuild openafs-*.rpm
