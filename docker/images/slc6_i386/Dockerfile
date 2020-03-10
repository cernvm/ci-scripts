FROM        scratch
MAINTAINER  Rene Meusel <rene.meusel@cern.ch>

ARG SFTNIGHT_UID=500
ARG SFTNIGHT_GID=500

ADD         slc6_i386.tar.gz /
RUN         yum -y update
RUN         yum -y install yum-plugin-ovl
RUN         yum -y install                     \
                       cmake                   \
                       curl-devel              \
                       fuse-devel              \
                       fuse3-devel             \
                       gcc                     \
                       gcc-c++                 \
                       git                     \
                       golang                  \
                       hardlink                \
                       libattr-devel           \
                       libcap-devel            \
                       libuuid-devel           \
                       make                    \
                       openssl-devel           \
                       policycoreutils-python  \
                       python-devel            \
                       python-setuptools       \
                       rpm-build               \
                       selinux-policy-devel    \
                       selinux-policy-targeted \
                       sysvinit-tools          \
                       valgrind-devel          \
                       voms-devel              \
                       which                   \
                       zlib-devel

RUN go get github.com/jstemmer/go-junit-report

RUN  groupadd --gid $SFTNIGHT_GID sftnight && \
        adduser --uid $SFTNIGHT_UID --gid $SFTNIGHT_GID sftnight

USER        sftnight
WORKDIR     /home/sftnight
