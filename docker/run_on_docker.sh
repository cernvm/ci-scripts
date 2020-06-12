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
CVMFS_DOCKER_IMAGE="$2"
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

check_and_build_image() {
  # check if the docker container specification exists in ci/docker
  image_name="cvmfs/${CVMFS_DOCKER_IMAGE}"
  container_dir="${SCRIPT_LOCATION}/images/${CVMFS_DOCKER_IMAGE}"
  [ -d $container_dir ] || die "container $CVMFS_DOCKER_IMAGE not found"

  # bootstrap the docker container if non-existent or recreate if outdated
  if ! sudo docker images $image_name | grep -q "$image_name"; then
    bootstrap_image "$image_name" "$container_dir"
  elif [ $(image_creation $image_name) -lt $(image_recipe $container_dir) ]; then
    echo -n "removing outdated docker image '$image_name'... "
    sudo docker rmi -f "$image_name" > /dev/null || die "fail"
    echo "done"
    bootstrap_image "$image_name" "$container_dir"
  fi
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
  sudo docker build \
          --build-arg SFTNIGHT_UID=$(id sftnight -u) \
          --build-arg SFTNIGHT_GID=$(id sftnight -g) \
          --tag=$image_name .
  [ $? -eq 0 ] || die "Failed to build docker image '$image_name'"
  cd $old_wordir
  rm -fR $build_workdir
}

# check if docker is installed
which docker > /dev/null 2>&1 || die "docker is not installed"
which git    > /dev/null 2>&1 || die "git is not installed"

case ${CVMFS_DOCKER_IMAGE} in
  "ubuntu2004_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/ubuntu_x86_64:20.04"
    sudo docker pull $image_name
    ;;
  "ubuntu1804_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/ubuntu_x86_64:18.04"
    sudo docker pull $image_name
    ;;
  "ubuntu1804_i386")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/ubuntu_i386:18.04"
    sudo docker pull $image_name
    ;;
  "ubuntu1604_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/ubuntu_x86_64:16.04"
    sudo docker pull $image_name
    ;;
  "ubuntu1604_i386")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/ubuntu_i386:16.04"
    sudo docker pull $image_name
    ;;
  "ubuntu1404_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/ubuntu_x86_64:14.04"
    sudo docker pull $image_name
    ;;
  "ubuntu1404_i386")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/ubuntu_i386:14.04"
    sudo docker pull $image_name
    ;;
  "sles11_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/sles_x86_64:11"
    sudo docker pull $image_name
    ;;
  "sles12_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/sles_x86_64:12"
    sudo docker pull $image_name
    ;;
  "fedora32_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/fedora_x86_64:32"
    sudo docker pull $image_name
    ;;
  "fedora31_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/fedora_x86_64:31"
    sudo docker pull $image_name
    ;;
  "fedora30_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/fedora_x86_64:30"
    sudo docker pull $image_name
    ;;
  "fedora30_i386")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/fedora_i386:30"
    sudo docker pull $image_name
    ;;
  "debian10_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/debian_x86_64:10"
    sudo docker pull $image_name
    ;;
  "debian9_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/debian_x86_64:9"
    sudo docker pull $image_name
    ;;
  "debian8_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/debian_x86_64:8"
    sudo docker pull $image_name
    ;;
  "cc8_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/centos_x86_64:8"
    sudo docker pull $image_name
    ;;
  "cc7_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/centos_x86_64:7"
    sudo docker pull $image_name
    ;;
  "slc6_x86_64")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/slc_x86_64:6"
    sudo docker pull $image_name
    ;;
  "slc6_i386")
    image_name="gitlab-registry.cern.ch/cernvm/build-images/slc_i386:6"
    sudo docker pull $image_name
    ;;
  *)
    die "Unknow platform"
    ;;
esac

echo "image used: $image_name"

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
args="--env GOCACHE=$WORKSPACE/.gocache $args"

uid=$(id -u)
gid=$(id -g)
echo "++ $@"

mkdir -p $WORKSPACE
docker run \
                --volume="$WORKSPACE":"$WORKSPACE"           \
                --user=${uid}:${gid}                         \
                --rm=true                                    \
                --privileged=true                            \
                $args $image_name                            \
                "$@"
