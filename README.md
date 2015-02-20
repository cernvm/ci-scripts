# ci-scripts
Continuous integration for CernVM-FS and CernVM projects 

## Generals Remarks
This repository contains continuous integration scripts that are used by our Jenkins installation at CERN. They are meant to abstract the specifics of Jenkins like build environment detection, setup and cleanup. We call those Jenkins-dependent scripts *build wrappers*.

In general, we strive to have as much scripting logic outside of Jenkins and under version control. On the other hand Jenkins jobs are used to manage the build platform configuration and collect/analyse build results. The Jenkins-independent and platform-dependent build steering is done by scripts in the upstream CernVM-FS or CernVM repositories to allow them to evolve along with the code.

## Build Script Environment Discovery
Jenkins implements multiple-platform builds by so-called [Multi-configuration projects](https://wiki.jenkins-ci.org/display/JENKINS/Building+a+matrix+project). Using those, the same build steps are being run in parallel on multiple individual build machines. Therefore build scripts need to characterize the build environment they landed on themselves. Typically properties to be detected are the operating system (Linux, Mac), the package type to be built (RPM, DEB, PKG) and the number of usable CPU cores. Helper functions for these tasks reside in `jenkins/common.sh`.

## Platform Specific Build Scripts
Once the environment characterisation and setup is completed, *build wrappers* call a platform-dependent build script inside the projects's upstream repository. This upstream build script is performing the actual build of either CernVM-FS or CernVM and should not be dependent on Jenkins.

For CernVM-FS there are [multiple build scripts](https://github.com/cvmfs/cvmfs/tree/devel/ci) for various platforms and packages. They follow a naming and parameter convention to simplify their usage inside the *build wrappers*: `${package_identifier}_${package_type}.sh ${source_location} ${build_location} $@`.
