FROM        scratch
MAINTAINER  Rene Meusel <rene.meusel@cern.ch>

ADD         slc6_x86_64.tar.gz /
RUN         yum -y update && yum -y install                         \
                                        cmake                       \
                                        curl-devel                  \
                                        fuse-devel                  \
                                        fuse3-devel                 \
                                        gcc                         \
                                        gcc-c++                     \
                                        git                         \
                                        globus-common-devel         \
                                        globus-gsi-callback-devel   \
                                        globus-gsi-cert-utils-devel \
                                        globus-gsi-credential-devel \
                                        globus-gsi-sysconfig-devel  \
                                        golang                      \
                                        gridsite                    \
                                        hardlink                    \
                                        libattr-devel               \
                                        libcap-devel                \
                                        libuuid-devel               \
                                        libyaml-devel               \
                                        make                        \
                                        openssl-devel               \
                                        policycoreutils-python      \
                                        python-devel                \
                                        python-setuptools           \
                                        rpm-build                   \
                                        ruby-devel                  \
                                        selinux-policy-devel        \
                                        selinux-policy-targeted     \
                                        sysvinit-tools              \
                                        valgrind-devel              \
                                        voms-devel                  \
                                        which                       \
                                        zlib-devel                  \
                                        python-pip                  \
                                        python-argparse


RUN         useradd sftnight

RUN go get github.com/jstemmer/go-junit-report

USER        sftnight
WORKDIR     /home/sftnight
