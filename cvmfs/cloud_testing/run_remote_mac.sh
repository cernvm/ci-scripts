#!/bin/bash

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
set -x
echo "Printing environment " && env

original_directory=$(pwd)

# Download and decompress the sources and install the client
wget $source_tarball_url && tar xvf $source_name && mv cvmfs* cvmfs || usage "Couldn't download and decompress the sources in the mac VM"
wget $client_package_url && cd / && sudo /usr/sbin/installer -pkg /Users/vagrant/$package_name -target / && cd $original_directory || usage "Couldn't download and install the CVMFS package"

# Run the setup script
cvmfs/test/cloud_testing/platforms/$setup_script $osx_name || usage "Couldn't execute the setup_script"

# Run the test script
cvmfs/test/cloud_testing/platforms/$run_script $osx_name || usage "Couldn't execute the run_script"
