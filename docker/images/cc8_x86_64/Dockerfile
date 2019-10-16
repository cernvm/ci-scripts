FROM        scratch
MAINTAINER  Simone Mosciatti <simone.mosciatti@cern.ch>

# 2019-02-05 11:36  - dummy comment to trigger installation of latest golang compiler
ADD         cc8_x86_64.tar.gz /
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
                       gdb                     \
                       git                     \
                       golang                  \
                       hardlink                \
                       libattr-devel           \
                       libcap-devel            \
                       libffi-devel            \
                       libuuid-devel           \
                       make                    \
                       openssl-devel           \
                       python2                 \
                       python2-devel           \
                       python3-devel           \
                       rpm-build               \
                       ruby-devel              \
                       selinux-policy-devel    \
                       selinux-policy-targeted \
                       which                   \
                       valgrind-devel          \
                       voms-devel              \
                       zlib-devel

RUN         useradd sftnight

USER        sftnight

WORKDIR     /home/sftnight
