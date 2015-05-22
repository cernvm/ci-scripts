#!/bin/sh

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../jenkins/common.sh
. ${SCRIPT_LOCATION}/common.sh

LINT_SCRIPT="ci/run_cpplint.sh"

# sanity checks
[ ! -z $CVMFS_SOURCE_LOCATION ]                || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_CPPLINT_RESULT_LOCATION ]        || die "CVMFS_CPPLINT_RESULT_LOCATION missing"
[ -f ${CVMFS_SOURCE_LOCATION}/${LINT_SCRIPT} ] || die "$LINT_SCRIPT missing"

# check if there is already a result file and clean it up
if [ -f $CVMFS_CPPLINT_RESULT_LOCATION ]; then
  echo "cleaning up old cpplint results..."
  rm -f $CVMFS_CPPLINT_RESULT_LOCATION
fi

echo "running CppLint and sending output to $CVMFS_CPPLINT_RESULT_LOCATION ..."
${CVMFS_SOURCE_LOCATION}/${LINT_SCRIPT} > $CVMFS_CPPLINT_RESULT_LOCATION 2>&1
