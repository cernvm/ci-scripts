#!/bin/bash

# in this script we will sum up all the different steps to run the tests
# on a mac VM from a mac host
# All CT_* global variables are defined in ../run_cloudtests.sh


SCRIPT_LOCATION=$(cd "$(dirname "$0")"; pwd)
cd "$SCRIPT_LOCATION"
. ${SCRIPT_LOCATION}/common.sh

log_destination="."
osx_name="$CT_AMI_NAME"
package_name=$(read_package_map   ${CT_TESTEE_URL}/pkgmap "$CT_PLATFORM" 'client')
client_package_url="$CT_TESTEE_URL/$package_name"
source_tarball_url="$CT_TESTEE_URL/$CT_SOURCE_TARBALL"

# Step 0: check the things are there
which vagrant                           || echo "Vagrant is not installed!"
vagrant plugin list | grep vagrant-scp  || echo "Vagrant scp plugin not installed!"

# Step 1: boot the VM
vagrant destroy -f $osx_name || echo "There are no Vagrant VMs. Creating one"  # just in case it's still there
vagrant up $osx_name || echo "Cannot execute vagrant up $osx_name"

cvmfs_log_directory="$CT_CVMFS_WORKSPACE/logs"

# Step 2: run the script
vagrant ssh -c "
export CT_TESTEE_URL=$CT_TESTEE_URL
export package_name=$package_name
export CT_SOURCE_TARBALL=$CT_SOURCE_TARBALL
export osx_name=$osx_name
export CT_PLATFORM_SETUP_SCRIPT=$CT_PLATFORM_SETUP_SCRIPT
export CT_PLATFORM_RUN_SCRIPT=$CT_PLATFORM_RUN_SCRIPT
export client_package_url=$client_package_url
export source_tarball_url=$source_tarball_url

export CT_CVMFS_WORKSPACE=$CT_CVMFS_WORKSPACE
export cvmfs_log_directory=$cvmfs_log_directory

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

exit $retval
