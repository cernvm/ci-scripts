#!/bin/sh

#
# This script runs build scripts from the ci directory inside a specified docker
# container in the ci/docker directory.
#

set -e

SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
. ${SCRIPT_LOCATION}/../jenkins/common.sh

if [ $# -lt 2 ]; then
  echo "Usage: $0 <workspace> <docker image>"
  echo
  echo "This script imports and publishes the given image tarball."
  echo "Image name, tag, and user are derived from the tarball name."
  echo "E.g., cvmfs-shrinkwrap-2.6.0-1.tar.gz becomes cvmfs/shrinkwrap:2.6.0-1"
  exit 1
fi

WORKSPACE="$1"
IMAGE_LOCATION="$2"

# check if docker is installed
which docker > /dev/null 2>&1 || die "docker is not installed"
which git    > /dev/null 2>&1 || die "git is not installed"

get_docker_library() {
  local image_name=$1
  echo $image_name | cut -d\- -f1
}


get_docker_tag() {
  local image_name=$1
  local release=$(echo $image_name | rev | cut -d\- -f1 | rev | cut -d. -f1)
  local version=$(echo $image_name | rev | cut -d\- -f2 | rev)
  echo "$version-$release"
}

get_docker_name() {
  local image_name=$1
  echo $image_name | cut -d\- -f2
}

cleanup_images() {
  docker rmi --force $DOCKER_NAME || true
  docker rmi --force $DOCKER_NAME_LATEST || true
}

IMAGE_NAME="$(basename "$IMAGE_LOCATION")"
DOCKER_NAME="$(get_docker_library $IMAGE_NAME)/$(get_docker_name $IMAGE_NAME):$(get_docker_tag $IMAGE_NAME)"
DOCKER_NAME_LATEST="$(get_docker_library $IMAGE_NAME)/$(get_docker_name $IMAGE_NAME):latest"

echo "*** Importing $IMAGE_LOCATION as $DOCKER_NAME"
echo

trap cleanup_images EXIT HUP INT TERM

curl -f --connect-timeout 20 $IMAGE_LOCATION | zcat | docker import - $DOCKER_NAME
docker tag $DOCKER_NAME $DOCKER_NAME_LATEST
docker images

docker push $DOCKER_NAME
docker push $DOCKER_NAME_LATEST

