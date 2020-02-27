FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         fedora29_x86_64.tar.gz /
RUN         dnf -y update && dnf -y install                     \
                                        cmake                   \
                                        curl-devel              \
                                        fuse-devel              \
                                        fuse3-devel             \
					gcc                     \
                                        gcc-c++                 \
                                        gdb                     \
                                        git                     \
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

RUN curl https://dl.google.com/go/go1.14.linux-amd64.tar.gz --output go.tar.gz && \
        tar -C /usr/local -xzf go.tar.gz 
ENV PATH $PATH:/usr/local/go/bin

RUN GOPATH=/usr/local go get github.com/jstemmer/go-junit-report

RUN         useradd sftnight
USER        sftnight
WORKDIR     /home/sftnight

