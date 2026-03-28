#!groovy

// ── Image lists ──────────────────────────────────────────────────────────────
// Each entry is a full Docker image reference.  To add a new platform just
// append the image string – no other changes needed.
// Package type is auto-detected: images whose name contains "debian" or
// "ubuntu" produce .deb packages, everything else produces .rpm packages.

def DEFAULT_IMAGES_X86_64 = [
    'gitlab-registry.cern.ch/linuxsupport/alma8-base',
    'gitlab-registry.cern.ch/linuxsupport/alma9-base',
    'gitlab-registry.cern.ch/linuxsupport/alma10-base',
    'docker.io/amd64/debian:11',
    'docker.io/amd64/debian:12',
    'docker.io/amd64/debian:13',
    'docker.io/amd64/fedora:41',
    'docker.io/amd64/fedora:42',
    'docker.io/amd64/fedora:43',
    'docker.io/opensuse/leap:15.5',
    'docker.io/amd64/ubuntu:24.04',
    'docker.io/amd64/ubuntu:25.10',
].join('\n')

def DEFAULT_IMAGES_AARCH64 = [
    'docker.io/rockylinux:8',
    'docker.io/almalinux:9',
    'gitlab-registry.cern.ch/linuxsupport/alma10-base:20250617-1.aarch64',
    'docker.io/arm64v8/debian:11',
    'docker.io/arm64v8/debian:12',
    'docker.io/arm64v8/debian:13',
    'docker.io/arm64v8/fedora:41',
    'docker.io/arm64v8/fedora:42',
    'docker.io/arm64v8/fedora:43',
    'docker.io/opensuse/leap:15.5',
    'docker.io/arm64v8/ubuntu:24.04',
    'docker.io/arm64v8/ubuntu:25.10',
].join('\n')

properties([
    buildDiscarder(logRotator(numToKeepStr: '5')),
    parameters([
        string(
            name:         'CVMFS_GIT_REVISION',
            defaultValue: 'refs/heads/devel',
            description:  'Git branch or refspec of the cvmfs repository to build.',
        ),
        string(
            name:         'CERNVM_CI_SCRIPT_REVISION',
            defaultValue: 'master',
            description:  'Branch or tag of ci-scripts to check out on each build node.',
        ),
        booleanParam(
            name:         'CVMFS_NIGHTLY_BUILD',
            defaultValue: true,
            description:  'Produce nightly (build-number-stamped) packages instead of release packages.',
        ),
        booleanParam(
            name:         'CVMFS_CLEAN_BUILDDEPS',
            defaultValue: false,
            description:  'Remove builddeps Docker images after the build (frees disk but slows down subsequent builds).',
        ),
        string(
            name:         'CVMFS_TARGET_DIR',
            defaultValue: 'nightlies/cvmfs-git',
            description:  'Packages published at http://ecsft.cern.ch/dist/cvmfs/$CVMFS_TARGET_DIR-$BUILD_NUMBER',
        ),
        text(
            name:         'CVMFS_IMAGES_X86_64',
            defaultValue: DEFAULT_IMAGES_X86_64,
            description:  'Docker image references to build for x86_64 (one per line or space-separated).',
        ),
        text(
            name:         'CVMFS_IMAGES_AARCH64',
            defaultValue: DEFAULT_IMAGES_AARCH64,
            description:  'Docker image references to build for aarch64 (one per line or space-separated).',
        ),
    ]),
    pipelineTriggers([cron('H 2 * * *')]),
])

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Turn a Docker image reference into a safe tag string for use in paths and
 *  Docker image names, e.g. "docker.io/amd64/debian:11" → "docker-io-amd64-debian-11". */
def imageToTag(String image) {
    return image.replaceAll(/[\/:.]+/, '-').replaceAll(/-+/, '-').replaceAll(/^-|-$/, '')
}

/** Auto-detect package type from the image name. */
def detectPkgType(String image) {
    return (image =~ /(?i)(debian|ubuntu)/) ? 'deb' : 'rpm'
}

def makeBuildClosure(String baseImage, String arch, String ciScriptRevision,
                     String cvmfsRevision, String nightlyNum) {
    return {
        def tag            = imageToTag(baseImage)
        def pkgType        = detectPkgType(baseImage)
        node("docker-${arch}") {
            echo "Running on ${env.NODE_NAME} (${env.NODE_LABELS})"
            def ws             = env.WORKSPACE
            def ciDir          = "${ws}/ci-scripts"
            def cvmfsSrc       = "${ws}/cvmfs"
            def buildDir       = "${ws}/build/${tag}"
            def platformTag    = "${tag}-${env.BUILD_NUMBER}"
            def builddepsTag   = "${tag}-cvmfs-builddeps"
            def dockerPlatform = (arch == 'aarch64') ? 'linux/arm64' : 'linux/amd64'

            dir(ciDir) {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: ciScriptRevision]],
                    userRemoteConfigs: [[url: 'https://github.com/cernvm/ci-scripts.git']],
                ])
            }
            dir(cvmfsSrc) {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: cvmfsRevision]],
                    userRemoteConfigs: [[
                        url:    'https://github.com/cvmfs/cvmfs.git',
                        refspec: '+refs/heads/*:refs/remotes/origin/* +refs/pull/*:refs/remotes/origin/pr/*',
                    ]],
                    extensions: [[$class: 'CleanBeforeCheckout']],
                ])
            }

            sh "mkdir -p ${buildDir}"

            try {
                sh """
                    DOCKER_BUILDKIT=1 docker build \\
                        --platform ${dockerPlatform} \\
                        --build-arg BASE_IMAGE=${baseImage} \\
                        -t ${builddepsTag} \\
                        -f ${ciDir}/docker/Dockerfile-builddeps-${pkgType} \\
                        ${cvmfsSrc}
                """
                sh """
                    DOCKER_BUILDKIT=1 docker build \\
                        --platform ${dockerPlatform} \\
                        --build-arg BUILDDEPS_IMAGE=${builddepsTag} \\
                        --build-arg PLATFORM_TAG=${platformTag} \\
                        ${nightlyNum ? "--build-arg NIGHTLY_NUMBER=${nightlyNum}" : ''} \\
                        --output type=local,dest=${buildDir} \\
                        --target export \\
                        -f ${ciDir}/docker/Dockerfile-build \\
                        ${cvmfsSrc}
                """
            } finally {
                if (params.CVMFS_CLEAN_BUILDDEPS) {
                    sh "docker rmi ${builddepsTag} || true"
                }
            }

            stash(name: tag, includes: "build/${tag}/**")
        }
    }
}

// ── Main pipeline ─────────────────────────────────────────────────────────────

def nightlyNum      = params.CVMFS_NIGHTLY_BUILD ? env.BUILD_NUMBER : ''
// Use defaults only on the very first run when params are not yet defined (null).
// An empty string means "build nothing for this arch".
def imagesX86_64    = (params.CVMFS_IMAGES_X86_64  != null ? params.CVMFS_IMAGES_X86_64  : DEFAULT_IMAGES_X86_64).split(/\s+/).findAll { it }
def imagesAarch64   = (params.CVMFS_IMAGES_AARCH64 != null ? params.CVMFS_IMAGES_AARCH64 : DEFAULT_IMAGES_AARCH64).split(/\s+/).findAll { it }

stage('Build Packages') {
    def branches = [:]
    imagesX86_64.each { img ->
        def image = img as String
        def tag   = imageToTag(image)
        branches["x86_64/${tag}"] = makeBuildClosure(
            image, 'x86_64',
            params.CERNVM_CI_SCRIPT_REVISION, params.CVMFS_GIT_REVISION, nightlyNum,
        )
    }
    imagesAarch64.each { img ->
        def image = img as String
        def tag   = imageToTag(image)
        branches["aarch64/${tag}"] = makeBuildClosure(
            image, 'aarch64',
            params.CERNVM_CI_SCRIPT_REVISION, params.CVMFS_GIT_REVISION, nightlyNum,
        )
    }
    parallel branches
}

stage('Source Tarball') {
    node('docker-x86_64') {
        echo "Running on ${env.NODE_NAME} (${env.NODE_LABELS})"
        def ws         = env.WORKSPACE
        def ciDir      = "${ws}/ci-scripts"
        def cvmfsSrc   = "${ws}/cvmfs"
        def tarballDir = "${ws}/build/cvmfs_source_tarball"
        def srcTarTag  = "cvmfs-sourcetarball-${env.BUILD_NUMBER}"

        dir(ciDir) {
            checkout([
                $class: 'GitSCM',
                branches: [[name: params.CERNVM_CI_SCRIPT_REVISION]],
                userRemoteConfigs: [[url: 'https://github.com/cernvm/ci-scripts.git']],
            ])
        }
        dir(cvmfsSrc) {
            checkout([
                $class: 'GitSCM',
                branches: [[name: params.CVMFS_GIT_REVISION]],
                userRemoteConfigs: [[
                    url:    'https://github.com/cvmfs/cvmfs.git',
                    refspec: '+refs/heads/*:refs/remotes/origin/* +refs/pull/*:refs/remotes/origin/pr/*',
                ]],
                extensions: [[$class: 'CleanBeforeCheckout']],
            ])
        }

        sh "mkdir -p ${tarballDir}"
        sh """
            DOCKER_BUILDKIT=1 docker build \\
                -t ${srcTarTag} \\
                -f ${ciDir}/docker/Dockerfile-sourcetarball \\
                ${ciDir}/docker
        """
        try {
            sh """
                docker run --rm \\
                    -e GOTOOLCHAIN=auto \\
                    -e GOPROXY=http://cvm-gomod-proxy1.cern.ch:3000 \\
                    -v ${cvmfsSrc}:/cvmfs:ro \\
                    -v ${tarballDir}:/build \\
                    ${srcTarTag} \\
                    /cvmfs/ci/build_cvmfs_sourcetarball.sh /cvmfs /build ${nightlyNum}
            """
        } finally {
            sh "docker rmi ${srcTarTag} || true"
        }

        stash(name: 'source_tarball', includes: 'build/cvmfs_source_tarball/**')
    }
}

stage('Publish') {
    node('docker-x86_64') {
        echo "Running on ${env.NODE_NAME} (${env.NODE_LABELS})"
        def targetDir = "${params.CVMFS_TARGET_DIR}-${env.BUILD_NUMBER}"

        imagesX86_64.each  { img -> unstash imageToTag(img as String) }
        imagesAarch64.each { img -> unstash imageToTag(img as String) }
        unstash 'source_tarball'

        archiveArtifacts(
            artifacts:         '**/cvmfs*.rpm,**/cvmfs*.deb,**/cvmfs*.pkg,' +
                               '**/cvmfs*.docker.tar.gz,**/cvmfs*.oci.tar,' +
                               '**/source.tar.gz,**/cvmfs-*.tar.gz',
            allowEmptyArchive: false,
        )

        sshPublisher(publishers: [
            sshPublisherDesc(
                configName: 'CernVM Public',
                verbose:    false,
                transfers: [
                    sshTransfer(
                        sourceFiles:     '**/cvmfs*.rpm,**/cvmfs*.deb,**/cvmfs*.pkg,**/cvmfs*.docker.tar.gz,**/cvmfs*.oci.tar',
                        remoteDirectory: targetDir,
                        removePrefix:    'build',
                        flatten:         false,
                        cleanRemote:     false,
                    ),
                    sshTransfer(
                        sourceFiles:     '**/source.tar.gz,**/cvmfs-*.tar.gz',
                        remoteDirectory: targetDir,
                        removePrefix:    'build/cvmfs_source_tarball',
                        flatten:         false,
                        cleanRemote:     false,
                    ),
                ],
            ),
        ])
    }
}
