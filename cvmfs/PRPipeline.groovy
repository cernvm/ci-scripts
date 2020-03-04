#!groovy

// @Library('cvmfs-pipelines')

import org.jenkinsci.plugins.ghprb.GhprbTrigger
import org.kohsuke.github.GHCommitState
import jenkins.model.Jenkins

void postComment(String comment) {
    def triggerJob = manager.hudson.getJob(currentBuild.projectName)
    def prbTrigger = triggerJob.getTriggers().get(GhprbTrigger.getDscp())
    prbTrigger.getRepository().addComment(Integer.valueOf(env.ghprbPullId), comment)
}

void setCommitStatus(context, status, text, url) {
    def triggerJob = manager.hudson.getJob(currentBuild.projectName)
    def prbTrigger = triggerJob.getTriggers().get(GhprbTrigger.getDscp())
    prbTrigger.getGitHub().getRepository(env.ghprbGhRepository).createCommitStatus(env.ghprbActualCommit, status, url, text, context)

}

void getNextBuildUrl(String job) {
    def item = Jenkins.instance.getItem(job)
    def url = item.getAbsoluteUrl() + item.getNextBuildNumber().toString()
    return url
}

cloudTestingBuildCombinations = [
                                'CVMFS_BUILD_ARCH=docker-i386,CVMFS_BUILD_PLATFORM=slc6',
                                'CVMFS_BUILD_ARCH=docker-i386,CVMFS_BUILD_PLATFORM=ubuntu1604',
                                'CVMFS_BUILD_ARCH=docker-i386,CVMFS_BUILD_PLATFORM=ubuntu1804',
                                'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=slc6',
                                'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=cc7',
                                'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=fedora28',
                                'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=fedora29',
                                'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=ubuntu1404',
                                'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=ubuntu1604',
                                'CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=ubuntu1804',
                                'CVMFS_BUILD_ARCH=osx10-x86_64,CVMFS_BUILD_PLATFORM=mac'
                                ]

cloudTestingcc7TestCombinations = [
                                  'CVMFS_PLATFORM=el7,CVMFS_PLATFORM_CONFIG=x86_64,label=trampoline',
                                  'CVMFS_PLATFORM=el7,CVMFS_PLATFORM_CONFIG=x86_64_s3,label=trampoline',
                                  'CVMFS_PLATFORM=el7,CVMFS_PLATFORM_CONFIG=x86_64_nfs,label=trampoline',
                                  'CVMFS_PLATFORM=el7,CVMFS_PLATFORM_CONFIG=x86_64_ramcache,label=trampoline',
                                  'CVMFS_PLATFORM=el7,CVMFS_PLATFORM_CONFIG=x86_64_fuse3,label=trampoline',
                                  'CVMFS_PLATFORM=el7,CVMFS_PLATFORM_CONFIG=x86_64_yubikey,label=trampoline'
                                  ]


mention = "@cernvm-bot"
helpString = "Syntax: " + mention + " subcommand + [args]\n" +
             "Available commands:\n" +
             "help\n" +
             "cpplint\n" +
             "unittest + [full] + [ducc] + [linux] + [mac]\n" +
             "cloudtest + [full] + [nodestroy] + [cc7]\n" +
             "all\n"

void helpCommand() {
    postComment(helpString)
}

void cpplintCommand(args) {
    setCommitStatus("cpplint", GHCommitState.PENDING, "", getNextBuildUrl('CvmfsCpplint'))    
    def lintResult = build job: 'CvmfsCpplint',
        parameters: [
            string(name: 'CVMFS_GIT_REVISION', value: env.sha1)],
        propagate: false
    def status = lintResult.getResult() == 'SUCCESS' ? GHCommitState.SUCCESS : GHCommitState.FAILURE
    setCommitStatus("cpplint", status, "", lintResult.getAbsoluteUrl())

    def s = new Scanner(lintResult.rawBuild.getArtifactManager().root().child("cpplint.error").open()).useDelimiter("\\A");
    def errors = s.hasNext() ? s.next() : "";
    if (errors != "") {
        postComment("linter finished with errors:\n" + errors)
        currentBuild.result = lintResult.getResult()
    }
}

void unittestCommand(args) {
    def params = [string(name: 'CVMFS_GIT_REVISION', value: env.sha1)]
    def combs = []
    args.each {
        switch(it) {
            case "full":
            params.add(booleanParam(name: 'CVMFS_UNITTESTS_QUICK', value: false))
            break
            case "ducc":
            params.add(booleanParam(name: 'CVMFS_UNITTESTS_DUCC', value: true))
            break
            case "linux":
            combs.add('CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=cc7')
            break
            case "mac":
            combs.add('CVMFS_BUILD_ARCH=osx10-x86_64,CVMFS_BUILD_PLATFORM=mac')
            break
        }
    }
    if (!combs.isEmpty()) {
        params.add([$class: 'MatrixCombinationsParameterValue', name: 'CVMFS_BUILD_PLATFORMS', combinations: combs, description: null])
    }
    setCommitStatus("unittest", GHCommitState.PENDING, "", getNextBuildUrl('CvmfsUnittest'))    
    def testResult = build job: 'CvmfsUnittest',
        parameters: params,
        propagate: false
    // postComment("unittests finished: " + testResult.getResult() + " " + testResult.getAbsoluteUrl())
    def status = testResult.getResult() == 'SUCCESS' ? GHCommitState.SUCCESS : GHCommitState.FAILURE
    setCommitStatus("unittest", status, "", testResult.getAbsoluteUrl())
    if (testResult.getResult() != 'SUCCESS') {
        currentBuild.result = testResult.getResult()
        error 'CvmfsCloudTesting did not succeed'
    }
}

void cloudtestCommand(args) {
    def testParams = []
    def quickSuite = true
    def destroy = true
    def buildCombs = cloudTestingBuildCombinations
    args.each {
        switch(it) {
            case "full":
            quickSuite = false;
            break
            case "nodestroy":
            destroy = false;
            break
            case "cc7":
            testParams.add([$class: 'MatrixCombinationsParameterValue', name: 'CVMFS_TEST_PLATFORMS', combinations: cloudTestingcc7TestCombinations, description: null])
            buildCombs = ['CVMFS_BUILD_ARCH=docker-x86_64,CVMFS_BUILD_PLATFORM=cc7']
            break
        }
    }
    testParams.add(booleanParam(name: 'CVMFS_QUICK_TESTS', value: quickSuite))
    testParams.add(booleanParam(name: 'CVMFS_DESTROY_FAILED_VMS', value: destroy));

    setCommitStatus("cloudtest", GHCommitState.PENDING, "", getNextBuildUrl('CvmfsFullBuildDocker'))    

    def buildResult = build job: 'CvmfsFullBuildDocker',
        parameters: [
            string(name: 'CVMFS_GIT_REVISION', value: env.sha1),
            [$class: 'MatrixCombinationsParameterValue', name: 'CVMFS_BUILD_PLATFORMS', combinations: buildCombs, description: null],
            string(name: 'CVMFS_TARGET_DIR', value: "pr/pr" + env.ghprbPullId)],
        propagate: false

    postComment("building for cloudtests finished: " + buildResult.getResult() + " " + buildResult.getAbsoluteUrl())
    if (buildResult.getResult() != 'SUCCESS') {
        setCommitStatus("cloudtest", GHCommitState.FAILURE, "", buildResult.getAbsoluteUrl())
        currentBuild.result = buildResult.getResult()
        error 'CvmfsFullBuildDocker did not succeed'
    }
    setCommitStatus("cloudtest", GHCommitState.PENDING, "", getNextBuildUrl('CvmfsCloudTesting'))

    testParams.add(string(name: 'CVMFS_TESTEE_URL', value: 'http://ecsft.cern.ch/dist/cvmfs/pr/pr' + env.ghprbPullId + '-' + buildResult.getId()))

    def testResult = build job: 'CvmfsCloudTesting',
        parameters: testParams,
        propagate: false

    postComment("cloudtests finished: " + testResult.getResult() + " " + testResult.getAbsoluteUrl())
    def status = testResult.getResult() == 'SUCCESS' ? GHCommitState.SUCCESS : GHCommitState.FAILURE
    setCommitStatus("cloudtest", status, "", testResult.getAbsoluteUrl())
    if (testResult.getResult() != 'SUCCESS') {
        currentBuild.result = testResult.getResult()
        error 'CvmfsCloudTesting did not succeed'
    }
}

void allCommand(args) {
    parallel(
        'Cpplint': {
            cpplintCommand([])
        },
        'Unittest': {
            unittestCommand([])
        },
        'Cloudtest': {
            cloudtestCommand([])
        }
    )
}

void commentHandler() {
    def words = env.ghprbCommentBody.split().toList()
    if (words[0] != mention) return;
    words.addAll(["", ""]) // so words.size() >= 3

    def command = words[1];
    if (command == "cpplint") cpplintCommand(words[2..-1]);
    else if (command == "unittest") unittestCommand(words[2..-1]);
    else if (command == "cloudtest") cloudtestCommand(words[2..-1]);
    else if (command == "all") allCommand(words[2..-1]);
    else helpCommand();
}

void commitHandler() {
    parallel(
        'Cpplint': {
            cpplintCommand([])
        },
        'Unittest': {
            unittestCommand([])
        }
    )
}

// someone pushed new commit or opened PR 
if (env.ghprbActualCommitAuthor != "") {
    commitHandler()
} else {
    commentHandler()
}
