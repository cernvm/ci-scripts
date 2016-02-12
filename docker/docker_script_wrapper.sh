#!/bin/sh

#
# Workaround: Producing a lot of output on stdout/stderr produces hiccups inside
#             the docker deamon. Apparently docker is aware of it, but it still
#             seems to happen [1].
#
#   [1] https://github.com/docker/docker/issues/14460
#
# This wrapper script is working around this issue by piping stdout and stderr
# through files inside a mounted docker volume.
#

die() {
  echo "$1" >&2
  exit 1
}

if [ $# -lt 3 ]; then
  echo "Usage: $0 <stdout file> <stderr file> <command>"
  exit 1
fi

fstdout="$1"
fstderr="$2"
shift 2

[ -f $fstdout ] || touch $fstdout || die "cannot find or create $fstdout"
[ -f $fstderr ] || touch $fstderr || die "cannot find or create $fstderr"

"$@" >> $fstdout 2>>$fstderr
