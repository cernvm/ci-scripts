FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

# 2019-02-05 11:36  - dummy comment to trigger installation of latest golang compiler
ADD         cc7_x86_64.tar.gz /
RUN         yum -y update
RUN         yum -y install filesystem
RUN         yum -y install epel-release
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
                       libffi-devel            \
                       libuuid-devel           \
                       make                    \
                       openssl-devel           \
                       policycoreutils-python  \
                       python-devel            \
                       python-setuptools       \
                       rpm-build               \
                       ruby-devel              \
                       selinux-policy-devel    \
                       selinux-policy-targeted \
                       sysvinit-tools          \
                       which                   \
                       valgrind-devel          \
                       voms-devel              \
                       zlib-devel

RUN         useradd sftnight

# Fix yum issues with Docker OverlayFS by installing this plugin
RUN yum -y install yum-plugin-ovl

RUN GOPATH=/usr/local go get github.com/jstemmer/go-junit-report

USER        sftnight

WORKDIR     /home/sftnight
