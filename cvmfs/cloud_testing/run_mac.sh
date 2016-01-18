#!/bin/bash

# in this script we will sum up all the different steps to run the tests
# on a mac VM from a mac host
# All the variables are defined in ../run_cloudtests.sh


SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
cd "$SCRIPT_LOCATION"
. ${SCRIPT_LOCATION}/common.sh

log_destination="."
osx_name="$ami_name"
package_name=$(read_package_map   ${testee_url}/pkgmap "$platform" 'client')
client_package_url="$testee_url/$package_name"
source_tarball_url="$testee_url/$source_tarball"

# Step 0: check the things are there
which vagrant                           || echo "Vagrant is not installed!"
vagrant plugin list | grep vagrant-scp  || echo "Vagrant scp plugin not installed!"

# Step 1: boot the VM
vagrant up $osx_name || echo "Cannot execute vagrant up $osx_name"

# Step 2: run the script
vagrant ssh -c "
export testee_url=$testee_url
export package_name=$package_name
export source_name=$source_tarball
export osx_name=$osx_name
export setup_script=$platform_setup_script
export run_script=$platform_run_script
export client_package_url=$client_package_url
export source_tarball_url=$source_tarball_url

export cvmfs_workspace=$cvmfs_workspace
export cvmfs_log_directory=$cvmfs_workspace/logs

bash -s" < run_remote_mac.sh $osx_name

retval=$?

# Step 3: Collect the results
vagrant scp "$osx_name:$cvmfs_log_directory/*" "$log_destination"

# Step 4: destroy the VM if everything was correct
if [ $retval -eq 0 ]; then
  vagrant destroy -f $osx_name
else
  echo "VM not destroyed because the tests failed. Access to the VM by running 'vagrant ssh $osx_name' from the host machine"
fi
