#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION  ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_NIGHTLY_NUMBER  ] || die "CVMFS_NIGHTLY_NUMBER missing"
[ ! -z $CVMFS_NIGHTLY_BUILD   ] || die "CVMFS_NIGHTLY_BUILD missing"

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

nightly_number=
if [ x"$CVMFS_NIGHTLY_BUILD" = x"true" ]; then
  nightly_number=$CVMFS_NIGHTLY_NUMBER
  echo "building a nightly release with number '$nightly_number'"
fi

$build_script "$CVMFS_SOURCE_LOCATION" \
              "$CVMFS_BUILD_LOCATION"  \
              $nightly_number
