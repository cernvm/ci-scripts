FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         fedora30_i386.tar.gz /
RUN         dnf -y update && dnf -y install                     \
                                        cmake                   \
                                        curl-devel              \
                                        fuse-devel              \
                                        fuse3-devel             \
					gcc                     \
                                        gcc-c++                 \
                                        gdb                     \
                                        git                     \
                                        golang                  \
                                        gridsite                \
                                        hardlink                \
                                        libattr-devel           \
                                        libcap-devel            \
                                        libuuid-devel           \
                                        make                    \
                                        nfs-utils               \
                                        openssl-devel           \
                                        perl-IO-Interface       \
                                        policycoreutils-python  \
                                        python-devel            \
                                        python-setuptools       \
                                        rpm-build               \
                                        selinux-policy-devel    \
                                        selinux-policy-targeted \
                                        sudo                    \
                                        tree                    \
                                        voms-devel              \
                                        which                   \
                                        valgrind-devel          \
                                        zlib-devel


RUN GOPATH=/usr/local go get github.com/jstemmer/go-junit-report

RUN         useradd sftnight
USER        sftnight
WORKDIR     /home/sftnight
