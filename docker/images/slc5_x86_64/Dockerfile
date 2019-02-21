FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         slc5_x86_64.tar.gz /
RUN         yum -y update && yumdownloader -y --resolve  \
                                        buildsys-macros         \
                                        cmake                   \
                                        curl-devel              \
                                        fuse-devel              \
                                        gcc                     \
                                        gcc-c++                 \
                                        gdb                     \
                                        git                     \
                                        globus-common-devel     \
                                        globus-gsi-callback-devel \
                                        globus-gsi-cert-utils-devel \
                                        globus-gsi-credential-devel \
                                        globus-gsi-sysconfig-devel \
                                        gridsite                \
                                        hardlink                \
                                        libattr-devel           \
                                        libcap-devel            \
                                        make                    \
                                        openssl-devel           \
                                        python-devel            \
                                        python-setuptools       \
                                        rpm-build               \
                                        selinux-policy-devel    \
					selinux-policy-targeted \
					SysVinit                \
                                        which                   \
                                        voms-devel              \
                                        valgrind-devel          \
                                        zlib-devel
RUN         rpm --rebuilddb && rpm -vhU --replacepkgs --nocontexts *.rpm

RUN         useradd sftnight
USER        sftnight
WORKDIR     /home
