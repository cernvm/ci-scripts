#!/bin/bash

# in this script we will sum up all the different steps to run the tests
# on a mac VM from a mac host
usage() {
  local msg="$1"

  echo "Error: $msg"
  echo "Usage: $0 <testee_url> <package_name> <source_name> <osx_name> <setup_script> <run_script>"
  echo
  echo " <testee_url>            URL to the nightly build directory to be tested"
  echo " <package_name>          Name of the mac package to install"
  echo " <source_name>           Name of the source file"
  echo " <osx_name>              Name of the OSX. Can be yosemite, el_capitan, etc."
  echo " <setup_script>          Name of the setup_script for mac"
  echo " <run_script>            Name of the run_script for mac"

  exit 1
}


SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
cd "$SCRIPT_LOCATION"

testee_url=$1
package_name=$2
source_name=$3
osx_name=$4  # might be yosemite, el_capitan, etc.
setup_script=$5
run_script=$6
client_package_url="$testee_url/$package_name"
source_tarball_url="$testee_url/$source_name"

# Step 0: check the things are there
which vagrant                           || usage "Vagrant is not installed!"
vagrant plugin list | grep vagrant-scp  || usage "Vagrant scp plugin not installed!"

# Step 1: boot the VM
vagrant up $osx_name || usage "Cannot execute vagrant up $osx_name"

# Step 2: download and decompress the sources and install the client
vagrant ssh -c "wget $source_tarball_url && tar xvf $source_name && mv cvmfs* cvmfs" $osx_name || usage "Couldn't download and decompress the sources in the mac VM"
vagrant ssh -c "wget $client_package_url && cd / && sudo /usr/sbin/installer -pkg /Users/vagrant/$package_name -target /" $osx_name || usage "Couldn't download and install the CVMFS package"

# Step 3: run the setup script
vagrant ssh -c "cvmfs/test/cloud_testing/platforms/$setup_script" $osx_name || usage "Couldn't execute the setup_script"

# Step 4: run the test script
vagrant ssh -c "cvmfs/test/cloud_testing/platforms/$run_script" $osx_name

# Step 5: destroy the VM
if [ $retval -eq 0 ]; then
  vagrant destroy -f $osx_name
else
  echo "VM not destroyed because the tests failed. Access to the VM by running 'vagrant ssh $osx_name' from the host machine"
fi
