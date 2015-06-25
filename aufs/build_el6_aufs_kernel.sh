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
download_kernel_sources $source_location $AUFS_KERNEL_VERSION

echo "applying patches to build configuration..."
apply_patch $source_location 1 ${AUFS_SOURCE_LOCATION}/rhel6.3-config-generic.patch

echo "decompressing kernel sources..."
decompress_kernel_sources_tarbz2 $source_location
kernel_source_location="${source_location}/${kernel_id}"

echo "patching kernel sources..."
apply_patch $kernel_source_location 1 ${AUFS_SOURCE_LOCATION}/aufs2-base.patch
apply_patch $kernel_source_location 1 ${AUFS_SOURCE_LOCATION}/aufs2-kbuild.patch
apply_patch $kernel_source_location 0 ${AUFS_SOURCE_LOCATION}/rhel6.5-vfs-update.patch

echo "adding additional AUFS files..."
cp -r ${AUFS_SOURCE_LOCATION}/fs/aufs                   ${kernel_source_location}/fs/
cp ${AUFS_SOURCE_LOCATION}/Documentation/ABI/testing/*  ${kernel_source_location}/Documentation/ABI/testing/
cp ${AUFS_SOURCE_LOCATION}/include/linux/aufs_type.h    ${kernel_source_location}/include/linux/

echo "patching AUFS kernel sources..."
apply_patch $kernel_source_location 0 ${AUFS_SOURCE_LOCATION}/cvmfs-fix-deadlock.patch

echo "compressing kernel sources..."
compress_kernel_sources_tarbz2 $source_location

echo "patching the kernel spec file..."
sed -i -e '1 i %define buildid .aufs21' ${source_location}/kernel.spec

echo "switching to the build directory and build the kernel..."
cd $source_location
rpmbuild --define "%_topdir ${rpmbuild_location}"      \
         --define "%_tmppath ${rpmbuild_location}/TMP" \
         --with firmware                               \
         -ba kernel.spec

echo "cleaning up..."
rm -fR ${rpmbuild_location}/BUILD/kernel-${AUFS_KERNEL_VERSION}

aufs_kernel_version_tag="${AUFS_KERNEL_VERSION}.aufs21.x86_64"
echo "successfully built AUFS enabled kernel ${aufs_kernel_version_tag}"

echo "downloading OpenAFS, ZFS kernel module sources..."
download_kmod_sources $source_location \
                      kernel-module-openafs-${AUFS_KERNEL_VERSION}
download_kmod_sources $source_location spl-kmod
download_kmod_sources $source_location zfs-kmod

echo "installing just created kernel RPMs..."
install_kernel_devel_rpm "$rpmbuild_location" "$aufs_kernel_version_tag"

echo "building the OpenAFS kernel module..."
rpmbuild --define "%_topdir ${rpmbuild_location}"      \
         --define "%_tmppath ${rpmbuild_location}/TMP" \
         --define "build_modules 1"                    \
         --define "build_userspace 1"                  \
         --define "kernvers $aufs_kernel_version_tag"  \
         --rebuild openafs-*.rpm

echo "building SPL kernel modules..."
rpmbuild --define "%_topdir ${rpmbuild_location}"      \
         --define "%_tmppath ${rpmbuild_location}/TMP" \
         --define "%kernels $aufs_kernel_version_tag"  \
         --rebuild spl-kmod*.rpm
echo "  installing SPL modules..."
install_module_rpm "$rpmbuild_location" "$aufs_kernel_version_tag" kmod-spl
install_module_rpm "$rpmbuild_location" "$aufs_kernel_version_tag" kmod-spl-devel
echo "building ZFS kernel modules..."
rpmbuild --define "%_topdir ${rpmbuild_location}"      \
         --define "%_tmppath ${rpmbuild_location}/TMP" \
         --define "%kernels $aufs_kernel_version_tag"  \
         --rebuild zfs-kmod*.rpm

