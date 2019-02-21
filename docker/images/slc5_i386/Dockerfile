FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         slc5_i386.tar.gz /
RUN         yum -y update && yumdownloader -y --resolve         \
                                        buildsys-macros         \
                                        cmake                   \
                                        curl-devel              \
                                        fuse                    \
                                        fuse-devel              \
                                        gcc                     \
                                        gcc-c++                 \
                                        gdb                     \
                                        git                     \
                                        hardlink                \
                                        libattr-devel           \
                                        libcap-devel            \
                                        make                    \
                                        openssl-devel           \
                                        python-devel            \
                                        python-setuptools       \
                                        rpm-build               \
                                        SysVinit                \
                                        selinux-policy-devel    \
                                        selinux-policy-targeted \
                                        voms-devel              \
                                        which                   \
                                        valgrind-devel          \
                                        zlib-devel
RUN         rpm --rebuilddb && rpm -vhU --replacepkgs --nocontexts *.rpm

RUN         useradd sftnight
USER        sftnight
WORKDIR     /home
