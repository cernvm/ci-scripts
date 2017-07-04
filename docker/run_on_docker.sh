#!/bin/sh

#
# This script runs build scripts from the ci directory inside a specified docker
# container in the ci/docker directory.
#

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../jenkins/common.sh

if [ $# -lt 3 ]; then
  echo "Usage: $0 <workspace>" "<docker image name>"
  echo "<build script invocation>"
  echo
  echo "This script runs a build script inside a docker container. The docker "
  echo "image is generated on demand - i.e. look into ci-scripts/cvmfs/docker "
  echo "for available docker image blueprints."
  exit 1
fi

WORKSPACE="$1"

# NOTE (nhardi): Docker image name consists of platform and arch part.
# Experimental Jenkins build node and test job have suffix -test for
# architecture but such configurations (Dockerbuild files) don't really exist.
# The solution is to remove the "-test" suffix if there is one.
# This doesn't # have any effect in normal runs.
CVMFS_DOCKER_IMAGE="$(echo $2 | sed 's/-test$//')"
shift 2

# retrieves the image creation time of a docker image in epoch
# @param image_name  the full name of the docker image
# @return            creation time in Unix epoch
image_creation() {
  local image_name="$1"
  date +%s --date "$(sudo docker inspect --format='{{.Created}}' $image_name)"
}

_time_from_git() {
  local relative_path="$1"
  date +%s --date "$(git log -1 --format=%ai -- $relative_path)"
}

_max() {
  local lhs="$1"
  local rhs="$2"
  [ $lhs -gt $rhs ] && echo $lhs || echo $rhs
}

_max_time_from_git() {
  local directory_path="$1"
  local max_epoch=0
  for f in $(find $directory_path -mindepth 1); do
    max_epoch="$(_max $max_epoch $(_time_from_git $f))"
  done
  echo $max_epoch
}

# retrieves the last-changed timestamp for a specific docker image recipe
# @param recipe_dir  the directory of the docker image recipe to check
# @return            last modified timestamp in Unix epoch
image_recipe() {
  local recipe_dir="$1"
  local owd="$(pwd)"
  cd ${recipe_dir}
  local recipe_epoch="$(_max_time_from_git .)"
  cd ..
  for d in $(find . -maxdepth 1 -mindepth 1 -type d -name '*_common'); do
    recipe_epoch="$(_max $recipe_epoch $(_max_time_from_git $d))"
  done
  cd $owd
  echo $recipe_epoch
}

bootstrap_image() {
  local image_name="$1"
  local container_dir="$2"

  echo "bootstrapping docker image for ${image_name}..."
  build_workdir=$(mktemp -d)
  old_wordir=$(pwd)
  cd $build_workdir
  cp ${container_dir}/* .
  [ -x ${container_dir}/build.sh ] || die "./build.sh not available or not executable"
  sudo ${container_dir}/build.sh   || die "Failed to build chroot tarball"
  sudo docker build --tag=$image_name .
  [ $? -eq 0 ] || die "Failed to build docker image '$image_name'"
  cd $old_wordir
  rm -fR $build_workdir
}

push_image() {
    local image_name="$1"
    local error_msg="Failed to push Docker image $image_name."

    if ! docker push $image_name; then
        if [ x"$FORCE_DOCKER_IMAGE_PUSH" = x"false" ]; then
            echo "WARNING: $error_msg"
        else
            die "$error_msg"
        fi
    fi
}

# check if docker is installed
which docker > /dev/null 2>&1 || die "docker is not installed"
which git    > /dev/null 2>&1 || die "git is not installed"

# check if the docker container specification exists in ci/docker
image_name="cvmfs-dockerhub03.cern.ch/${CVMFS_DOCKER_IMAGE}"
container_dir="${SCRIPT_LOCATION}/images/${CVMFS_DOCKER_IMAGE}"
[ -d $container_dir ] || die "container $CVMFS_DOCKER_IMAGE not found"

# bootstrap the docker container if non-existent or recreate if outdated
if ! sudo docker images $image_name | grep -q "$image_name"; then
  if ! docker pull $image_name; then
    bootstrap_image "$image_name" "$container_dir"
    push_image "$image_name"
  fi
fi

if [ $(image_creation $image_name) -lt $(image_recipe $container_dir) ]; then
  echo -n "removing outdated docker image '$image_name'... "
  sudo docker rmi -f "$image_name" > /dev/null || die "fail"
  echo "done"
  bootstrap_image "$image_name" "$container_dir"
  push_image "$image_name"
fi

# Workaround: set up a stdout/stderr redirection to circumvent docker's broken
#             forwarding. Apparently this is a known issue of Docker and might
#             become fixed at some point.
#             (See docker_script_wrapper.sh for more details)
OUTPUT_POOL_DIR=
OUTPUT_POOL_STDOUT_READER=
OUTPUT_POOL_STDERR_READER=
cleanup_output_pool() {
  echo "running cleanup function..."
  [ -z $OUTPUT_POOL_STDOUT_READER ] || kill $OUTPUT_POOL_STDOUT_READER
  [ -z $OUTPUT_POOL_STDERR_READER ] || kill $OUTPUT_POOL_STDERR_READER
  [ -z $OUTPUT_POOL_DIR           ] || rm -fR $OUTPUT_POOL_DIR
}

trap cleanup_output_pool EXIT HUP INT TERM

OUTPUT_POOL_DIR=$(mktemp -d)
[ -d $OUTPUT_POOL_DIR ] || die "cannot create output redirection pool"
fstdout="${OUTPUT_POOL_DIR}/stdout"
fstderr="${OUTPUT_POOL_DIR}/stderr"
touch $fstdout $fstderr || die "cannot create output redirection files"
cp ${SCRIPT_LOCATION}/docker_script_wrapper.sh $OUTPUT_POOL_DIR || \
  die "cannot put docker_script_wrapper.sh in place"

tail -f $fstdout &
OUTPUT_POOL_STDOUT_READER=$!
tail -f $fstderr >&2 &
OUTPUT_POOL_STDERR_READER=$!

[ ! -z $OUTPUT_POOL_STDOUT_READER ] && [ ! -z $OUTPUT_POOL_STDERR_READER ] && \
kill -0 $OUTPUT_POOL_STDOUT_READER  && kill -0 $OUTPUT_POOL_STDERR_READER  || \
  die "cannot setup output redirection readers"

# Jenkins provides the CVMFS_CI_PLATFORM_LABEL as a platform specifier. For
# docker this needs to be re-set to the actual label rather than 'docker'
if [ x"$CVMFS_CI_PLATFORM_LABEL" = x"docker" ]; then
  CVMFS_CI_PLATFORM_LABEL="$CVMFS_DOCKER_IMAGE"
fi

# collect the environment variables belonging to the CVMFS and CERNVM workspaces
# TODO(rmeusel): figure out how to properly escape environment variables that
#                contain whitespace
for var in $(env | grep -ohe "^\(CVMFS\|CERNVM\)_[^=]*"); do
  if eval "echo \$$var" | grep -qe "[[:space:]]"; then
    echo "WARNING: skipped forwarding of environment variable \$$var"
    continue
  fi
  args="--env $var=$(eval "echo \$$var") $args"
done

# run provided script inside the docker container
# Note: Workaround for stdout/stderr redirection in conjunction with
#       docker_script_wrapper.sh
uid=$(id -u)
gid=$(id -g)
echo "++ $@"
sudo docker run --volume="$WORKSPACE":"$WORKSPACE"           \
                --volume=/etc/passwd:/etc/passwd             \
                --volume=/etc/group:/etc/group               \
                --volume="$OUTPUT_POOL_DIR:$OUTPUT_POOL_DIR" \
                --user=${uid}:${gid}                         \
                --rm=true                                    \
                --privileged=true                            \
                $args $image_name                            \
                ${OUTPUT_POOL_DIR}/docker_script_wrapper.sh  \
                $fstdout $fstderr "$@"
