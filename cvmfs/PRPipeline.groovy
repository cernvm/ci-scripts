import org.jenkinsci.plugins.ghprb.GhprbTrigger

void postComment(String comment, String prId) {
    def triggerJob = manager.hudson.getJob('jpriessn-PipelinePRBuilder')
    def prbTrigger = triggerJob.getTriggers().get(GhprbTrigger.getDscp())
    prbTrigger.getRepository().addComment(Integer.valueOf(prId), comment)
}

def cloudTestingBuildCombinations = [
                                    //  'CVMFS_BUILD_ARCH=docker-i386,CVMFS_BUILD_PLATFORM=slc6',
                                    //  'CVMFS_BUILD_ARCH=docker-i386,CVMFS_BUILD_PLATFORM=ubuntu1604',
                                    //  'CVMFS_BUILD_ARCH=docker-i386,CVMFS_BUILD_PLATFORM=ubuntu1804',
                                    //  'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=slc6',
                                     'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=cc7'
                                    //  'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=fedora28',
                                    //  'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=fedora29',
                                    //  'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=ubuntu1404',
                                    //  'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=ubuntu1604',
                                    //  'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=ubuntu1804',
                                    //  'CVMFS_BUILD_ARCH=osx10-x86_64,CVMFS_BUILD_PLATFORM=mac'
                                     ]

if (env.ghprbCommentBody == "ok to test") {
    postComment("nothing to run for testing yet", env.ghprbPullId)
} else if (env.ghprbCommentBody == "ok to cloudtest") {
    postComment("building CVMFS for cloudtesting", env.ghprbPullId)

    def buildResult = build job: 'CvmfsFullBuildDocker',
        parameters: [
            string(name: 'CVMFS_GIT_REVISION', value: env.sha1),
            [$class: 'MatrixCombinationsParameterValue', name: 'CVMFS_BUILD_PLATFORMS', combinations: cloudTestingBuildCombinations, description: null]],
        propagate: false

    postComment("building finished: " + buildResult.getResult() + " " + buildResult.getAbsoluteUrl(), env.ghprbPullId)
    if (buildResult.getResult() != 'SUCCESS') {
        currentBuild.result = buildResult.getResult()
        error 'CvmfsFullBuildDocker did not succeed'
    }

    postComment("running cloudtests", env.ghprbPullId)

    def testResult = build job: 'CvmfsCloudTesting',
        parameters: [
            string(name: 'CVMFS_TESTEE_URL', value: 'http://ecsft.cern.ch/dist/cvmfs/nightlies/cvmfs-git-' + buildResult.getId()),
            booleanParam(name: 'CVMFS_QUICK_TESTS', value: true),
            [$class: 'MatrixCombinationsParameterValue', name: 'CVMFS_TEST_PLATFORMS', combinations: ['CVMFS_PLATFORM=el7,CVMFS_PLATFORM_CONFIG=x86_64,label=trampoline'], description: null]]
        propagate: false
    
    postComment("cloudtesting finished: " + testResult.getResult() + " " + testResult.getAbsoluteUrl(), env.ghprbPullId)
    if (testResult.getResult() != 'SUCCESS') {
        currentBuild.result = testResult.getResult()
        error 'CvmfsCloudTesting did not succeed'
    }

} else if (env.ghprbCommentBody == "ok to fullbuild"){
    postComment("building CVMFS",  env.ghprbPullId)
    def result = build job: 'CvmfsFullBuildDocker', parameters: [
        string(name: 'CVMFS_GIT_REVISION', value: env.sha1)]
        // [$class: 'MatrixCombinationsParameterValue', name: 'CVMFS_BUILD_PLATFORMS', combinations: ['CVMFS_BUILD_ARCH=docker-x86_664,CVMFS_BUILD_PLATFORM=cc7'], description: null]]
    postComment("building finished: " + result.getResult() + " " + buildResult.getAbsoluteUrl(), env.ghprbPullId)

} else {
    // def r = build job: 'jpriessn-CvmfsFullBuildDocker', parameters: [
    //     string(name: 'CVMFS_GIT_REVISION', value: env.sha1),
    //     [$class: 'MatrixCombinationsParameterValue', name: 'CVMFS_BUILD_PLATFORMS', combinations: cloudTestingBuildCombinations, description: null]],
    //     // wait: false,
    //     propagate: false
    // echo r.class.
    // echo r.getAbsoluteUrl()
    // echo r.getCurrentResult()
    // echo r.getResult()
}
