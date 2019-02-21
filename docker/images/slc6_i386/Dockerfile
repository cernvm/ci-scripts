FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         slc6_i386.tar.gz /
RUN         yum -y update && yum -y install                     \
                                        cmake                   \
                                        curl-devel              \
                                        fuse-devel              \
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

RUN         useradd sftnight
USER        sftnight
WORKDIR     /home
