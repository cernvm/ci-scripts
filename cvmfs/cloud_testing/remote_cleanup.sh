#!/bin/bash

#
# This script cleans up the test machine after a successful integration run.
# It is intended to be used on a macOS machine.
#

export LC_ALL=C

cvmfs_workspace="/tmp/cvmfs-test-workspace"
cvmfs_source_directory="${cvmfs_workspace}/cvmfs-source"
cvmfs_log_directory="${cvmfs_workspace}/logs"

touch ${cvmfs_log_directory}/cleanup.log
exec &> ${cvmfs_log_directory}/cleanup.log

echo "Cleaning up test machine..."

echo " - unmounting all the CVMFS repositories"
for repo in $(mount | grep cvmfs2 | awk '{print $3}') ; do
    echo "   - unmounting $repo"
    sudo umount -f $repo
done

echo " - removing CVMFS configuration directory (/etc/cvmfs)"
sudo rm -rf /etc/cvmfs

echo " - removing CVMFS files (/var/lib/cvmfs)"
sudo rm -rf /var/lib/cvmfs

exit 0