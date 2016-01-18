#!/bin/bash

# in this script we will sum up all the different steps to run the tests
# on a mac VM from a mac host


SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
cd "$SCRIPT_LOCATION"
set -x
testee_url=$1
package_name=$2
source_name=$3
osx_name=$4  # might be yosemite, el_capitan, etc.
setup_script=$5
run_script=$6
client_package_url="$testee_url/$package_name"
source_tarball_url="$testee_url/$source_name"

# Step 0: check the things are there
which vagrant                           || echo "Vagrant is not installed!"
vagrant plugin list | grep vagrant-scp  || echo "Vagrant scp plugin not installed!"

# Step 1: boot the VM
vagrant up $osx_name || echo "Cannot execute vagrant up $osx_name"

# Step 2: run the script
vagrant ssh -c "
export testee_url=$1
export package_name=$2
export source_name=$3
export osx_name=$4  # might be yosemite, el_capitan, etc.
export setup_script=$5
export run_script=$6
export client_package_url="$testee_url/$package_name"
export source_tarball_url="$testee_url/$source_name"
bash -s" < run_remote_mac.sh $osx_name

# Step 3: destroy the VM
if [ $? -eq 0 ]; then
  vagrant destroy -f $osx_name
else
  echo "VM not destroyed because the tests failed. Access to the VM by running 'vagrant ssh $osx_name' from the host machine"
fi
