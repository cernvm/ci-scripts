#!/bin/sh

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../jenkins/common.sh
. ${SCRIPT_LOCATION}/common.sh

LINT_SCRIPT="ci/run_cpplint.sh"

# sanity checks
[ ! -z $WORKSPACE ]                            || die "WORKSPACE missing"
[ ! -z $CVMFS_RUN_CPPLINT ]                    || die "CVMFS_RUN_CPPLINT missing"
[ ! -z $CVMFS_SOURCE_LOCATION ]                || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_CPPLINT_RESULT_LOCATION ]        || die "CVMFS_CPPLINT_RESULT_LOCATION missing"
[ -f ${CVMFS_SOURCE_LOCATION}/${LINT_SCRIPT} ] || die "$LINT_SCRIPT missing"

# check if there is already a result file and clean it up
if [ -f $CVMFS_CPPLINT_RESULT_LOCATION ]; then
  echo "cleaning up old cpplint results..."
  rm -f $CVMFS_CPPLINT_RESULT_LOCATION
fi

# check if cpplint actually should be run
if [ x"$CVMFS_RUN_CPPLINT" != x"true" ]; then
  echo "CppLint is disabled... skipping"
  exit 0
fi

command_tmpl=""
desired_architecture="$(extract_arch $CVMFS_BUILD_ARCH)"
if is_docker_host; then
  echo "running CppLint on docker for ${desired_architecture} and sending output to $CVMFS_CPPLINT_RESULT_LOCATION..."
  docker_image_name="${CVMFS_BUILD_PLATFORM}_${desired_architecture}"
  command_tmpl="${CVMFS_SOURCE_LOCATION}/ci/run_on_docker.sh \
    ${WORKSPACE} \
    ${docker_image_name} \
    ${CVMFS_SOURCE_LOCATION}/${LINT_SCRIPT} \
    $CVMFS_CPPLINT_RESULT_LOCATION"
else
  echo "running CppLint bare metal for ${desired_architecture}..."
  command_tmpl="${CVMFS_SOURCE_LOCATION}/${LINT_SCRIPT} ${CVMFS_CPPLINT_RESULT_LOCATION}"
fi

# run the build script
echo "++ $command_tmpl"
$command_tmpl

