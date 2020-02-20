FROM        scratch
MAINTAINER  Simone Mosciatti <simone.mosciatti@cern.ch>

# This two args should not be necessary, but the bug fixed by
# https://github.com/opencontainers/runc/pull/2086
# makes them necessary in our environment
ARG SFTNIGHT_UID=500
ARG SFTNIGHT_GID=500

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
                       python2-pytest          \
                       python3-devel           \
                       rpm-build               \
                       ruby-devel              \
                       selinux-policy-devel    \
                       selinux-policy-targeted \
                       which                   \
                       valgrind-devel          \
                       voms-devel              \
                       zlib-devel

# Similarly to the node above.
# `adduser sftnight` should be sufficient, but the bug above requires
# this workaround
RUN  groupadd --gid $SFTNIGHT_GID sftnight && \
        adduser --uid $SFTNIGHT_UID --gid $SFTNIGHT_GID sftnight

USER        sftnight

WORKDIR     /home/sftnight
