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
  echo "image is pulled from gitlab-registry.cern.ch/cernvm/build-images ."
  exit 1
fi

WORKSPACE="$1"
CVMFS_DOCKER_IMAGE="$2"
shift 2

# check if docker is installed
which docker > /dev/null 2>&1 || die "docker is not installed"

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
    die "Unknow platform: ${CVMFS_DOCKER_IMAGE}"
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
mkdir -p $WORKSPACE

set -x
docker run \
                --volume="$WORKSPACE":"$WORKSPACE"           \
                --user=${uid}:${gid}                         \
                --rm=true                                    \
                --privileged=true                            \
                $args $image_name                            \
                "$@"
set +x
