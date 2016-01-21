#!/bin/bash

error() {
  local msg="$1"
  echo "Error: $msg"
  exit 1
}

original_directory=$(pwd)

# Create the workspace and the log directories
mkdir -p "$CT_CVMFS_WORKSPACE" "$cvmfs_log_directory"

# Download and decompress the sources and install the client
wget $source_tarball_url && tar xvf $CT_SOURCE_TARBALL && mv cvmfs* cvmfs || error "Couldn't download and decompress the sources in the mac VM"
wget $client_package_url && cd / && sudo /usr/sbin/installer -pkg /Users/vagrant/$package_name -target / && cd $original_directory || error "Couldn't download and install the CVMFS package"

# Run the setup script
cvmfs/test/cloud_testing/platforms/$CT_PLATFORM_SETUP_SCRIPT $osx_name || error "Couldn't execute the setup_script"

# Run the test script
cvmfs/test/cloud_testing/platforms/$CT_PLATFORM_RUN_SCRIPT $osx_name || error "Couldn't execute the run_script"
