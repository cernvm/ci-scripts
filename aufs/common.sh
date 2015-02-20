#!/bin/sh

prepare_kernel_build_environment() {
  local build_location="$1"

  if [ -d $build_location ]; then
    echo "removing previous build location..."
    rm -fR $build_location
  fi
  echo "creating a fresh build location in ${build_location}..."
  mkdir -p "$build_location"

  for d in BUILD BUILDROOT RPMS SOURCES SPECS SRPMS TMP; do
    mkdir -p ${build_location}/rpmbuild/${d}
  done
}

get_kernel_package_name() {
  local kernel_version="$1"
  echo "linux-${kernel_version}"
}

download_kernel_sources() {
  local source_location="$1"
  local kernel_version="$2"
  local previous_workdir="$(pwd)"

  cd $source_location

  yum clean all
  yumdownloader --source kernel-${kernel_version}
  rpm2cpio kernel-${kernel_version}.src.rpm | cpio -i
  rm -f kernel-${kernel_version}.src.rpm

  cd $previous_workdir
}

decompress_kernel_sources() {
  local source_location="$1"
  local previous_workdir="$(pwd)"

  cd $source_location

  local kernel_tarball="$(ls *.tar.xz)"
  [ $(echo "$kernel_tarball" | wc -l) -eq 1 ] || return 1

  tar xfJ $kernel_tarball
  rm $kernel_tarball

  cd $previous_workdir
}

compress_kernel_sources() {
  local source_location="$1"
  local previous_workdir="$(pwd)"

  cd $source_location

  local kernel_id="$(find * -mindepth 0 -maxdepth 0 -type d)"
  [ $(echo "$kernel_id" | wc -l) -eq 1 ] || return 1

  tar cfJ ${kernel_id}.tar.xz ${kernel_id}
  rm -fR ${kernel_id}

  cd $previous_workdir
}

apply_patch() {
  local source_location="$1"
  local strip_num="$2"
  local patch_file="$3"
  local previous_workdir="$(pwd)"

  cd $source_location

  patch -p$strip_num < $patch_file

  cd $previous_workdir
}

echo "print environment variables..."
env
