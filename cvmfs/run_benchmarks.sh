#!/bin/sh

set -e

BUILD_SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${BUILD_SCRIPT_LOCATION}/../jenkins/common.sh
. ${BUILD_SCRIPT_LOCATION}/common.sh

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION    ] || die "CVMFS_BUILD_LOCATION missing"
[ ! -z $CVMFS_SOURCE_LOCATION   ] || die "CVMFS_SOURCE_LOCATION missing"
[ ! -z $CVMFS_TEST_LOCATION     ] || die "CVMFS_TEST_LOCATION missing"
[ ! -z $CVMFS_PYTHON_LOCATION   ] || die "CVMFS_PYTHON_LOCATION missing"
[ ! -z $CVMFS_DATA_LOCATION     ] || die "CVMFS_DATA_LOCATION missing"
which python2.7 > /dev/null 2>&1  || die "python2.7 is not in the PATH or is not installed"


# running the benchmarks
cd ${CVMFS_BUILD_LOCATION}
sudo make install
cd ${CVMFS_TEST_LOCATION}
./run.sh ${CVMFS_DATA_LOCATION}/benchmark.log -o ${CVMFS_DATA_LOCATION}/benchmark.xml benchmarks/*
cp -r /tmp/cvmfs_benchmarks ${CVMFS_DATA_LOCATION}
python2.7 ${CVMFS_PYTHON_LOCATION}/statistics_collector.py ${CVMFS_DATA_LOCATION}/cvmfs_benchmarks/*/*.data
