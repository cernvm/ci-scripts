# Instructions to launch the mac VM

## Requirements for the mac host
- Recommended Mac OSX 10.10 (yosemite).
- Vagrant installed with the vagrant-scp plugin (vagrant plugin install vagrant-scp).
- VirtualBox installed.
- jq utility (prefereably 1.4) to parse JSON files.
- If intended to be used with Jenkins create the user sftnight and grant him sudo without password.

## VM instructions
### Creation of the VM
1) Download the corresponding .dmg official image from the apple store. It should be free having an apple ID, but older images are pretty difficult to find.
2) Use the dmg file to spawn a mac VM inside a mac. You might need to enable EFI to access it.
3) Access to the newly created mac VM through the GUI and create the 'vagrant' user and grant him access through ssh. Grant him sudo as well. Enable the ssh service too. Install hombrew and any other tool you might need, like *Xcode*. However, **it is recommendable not to install any unnecessary software**. It is better to do it in the provision step, where the software is updated.
4) Exit the VM and pack it with vagrant. Follow the instructions in https://docs.vagrantup.com/v2/virtualbox/boxes.html.
5) This generated box file can be imported later to Vagrant using the 'vagrant box add' command.

### Usage of the .box file
- **There is already a Mac OSX 10.10 Yosemite vagrant box ready to use in the private storage**. To import it simply type 'vagrant box add \<path-to-yosemite-box-file\> --name yosemite'.
- After that you should be able to execute 'vagrant up yosemite && vagrant ssh yosemite' to enter in the recently booted machine. It is important to mention that it is necessary to be in the _ci-scripts/cvmfs/cloud_testing_ folder.
- Also, the creation process will include a **provision** step defined in the ci-scripts/cvmfs/cloud_testing/vagrant/provision_osx.sh script. It should update brew to get the most updated software, and install the basic utilities. For example: wget, jq, fuse, etc.
