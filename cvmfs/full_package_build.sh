#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION  ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION ] || die "CVMFS_SOURCE_LOCATION missing"

# setup a fresh build workspace on first execution or on request
mkdir -p "$CVMFS_BUILD_LOCATION"

# run the build
echo "switching to $CVMFS_BUILD_LOCATION and invoking build script..."
cd "$CVMFS_BUILD_LOCATION"

build_script=""
case $(get_package_type) in
  rpm)
    build_script="build_rpm.sh"
    ;;
  deb)
    build_script="build_deb.sh"
    ;;
  pkg)
    build_script="build_pkg.sh"
    ;;
  *)
    die "unknown package type '$(get_package_type)"
    ;;
esac

echo "using build script: '$build_script'"
build_script="${CVMFS_SOURCE_LOCATION}/ci/$build_script"

$build_script "$CVMFS_SOURCE_LOCATION" \
              "$(get_number_of_cpu_cores)"
