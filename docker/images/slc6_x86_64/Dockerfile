FROM        scratch
MAINTAINER  Rene Meusel <rene.meusel@cern.ch>

# This two args should not be necessary, but the bug fixed by
# https://github.com/opencontainers/runc/pull/2086
# makes them necessary in our environment
ARG SFTNIGHT_UID=500
ARG SFTNIGHT_GID=500

ADD         slc6_x86_64.tar.gz /
RUN         yum -y update
RUN         yum -y install yum-plugin-ovl
RUN         yum -y install                         \
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
                       openssl                     \
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

# Similarly to the node above.
# `adduser sftnight` should be sufficient, but the bug above requires
# this workaround
RUN  groupadd --gid $SFTNIGHT_GID sftnight && \
        adduser --uid $SFTNIGHT_UID --gid $SFTNIGHT_GID sftnight

RUN GOPATH=/usr/local go get github.com/jstemmer/go-junit-report

# Necessary for packing stuff
RUN yum -y install http://ecsft.cern.ch/dist/cvmfs/builddeps/python-sqlite2-2.3.5-2.el6.x86_64.rpm http://ecsft.cern.ch/dist/cvmfs/builddeps/togo-2.5-1.noarch.rpm && \
        mkdir -p /home/sftnight/.togo && chown sftnight /home/sftnight/.togo && chmod ugo+rwx /home/sftnight/.togo && \
        touch /home/sftnight/.rpmmacros && chown sftnight /home/sftnight/.rpmmacros && chmod ugo+rw /home/sftnight/.rpmmacros

USER        sftnight
WORKDIR     /home/sftnight
