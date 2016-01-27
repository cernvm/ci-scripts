#!/bin/sh

set -e
set -x

# sanity checks
[ ! -z $CVMFS_BUILD_LOCATION    ] || exit 1
[ ! -z $CVMFS_SOURCE_LOCATION   ] || exit 2
[ ! -z $COV_TMP                 ] || exit 3
[ -f $COV_BUILD                 ] || exit 4


# building the dependencies only
mkdir -p ${CVMFS_BUILD_LOCATION}
rm -rf ${CVMFS_BUILD_LOCATION}/*
cd ${CVMFS_BUILD_LOCATION}
cmake -DBUILD_UNITTESTS=yes -DBUILD_PRELOADER=yes ${CVMFS_SOURCE_LOCATION}

make libcares
make libcurl
make zlib
make libleveldb
make sqlite3
make sparsehash
make libvjson
make libtbb
make libpacparser
make googletest
make libgeoip
make python-geoip
make libsha2
make libsha3

# create the temporary directory for coverity
mkdir -p "$COV_TMP"

# go for the actual build
$COV_BUILD --dir "$COV_TMP" make
