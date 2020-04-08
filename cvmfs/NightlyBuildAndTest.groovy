#!groovy

// This is a pipeline script for CvmfsNightlyBuildAndTest Jenkins job.
// IT IS NOT SYNCHRONIZED AUTOMATICALLY.
// When updating the script, push the new revision into the upstream AND
// copy-paste the whole updated script directly into the CvmfsNightlyBuildAndTest
// job definition. Apart from the copy-paste, also add a comment with
// git hash of the latest commit.

def testParams = []

def buildResult = build job: 'CvmfsFullBuildDocker'

def buildDir = "nightlies/cvmfs-git-" + buildResult.getId()

testParams.add(string(name: 'CVMFS_TESTEE_URL', value: 'http://ecsft.cern.ch/dist/cvmfs/' + buildDir))
testParams.add(booleanParam(name: 'CVMFS_QUICK_TESTS', value: false))
testParams.add(booleanParam(name: 'CVMFS_DESTROY_FAILED_VMS', value: true));

def testResult = build job: 'CvmfsCloudTesting',
    parameters: testParams
