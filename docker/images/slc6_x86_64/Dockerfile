FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         slc6_x86_64.tar.gz /
RUN         yum -y update && yum -y install                         \
                                        cmake                       \
                                        curl-devel                  \
                                        fuse-devel                  \
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

RUN         useradd sftnight

RUN yum -y install http://ecsft.cern.ch/dist/cvmfs/builddeps/otp/esl-erlang_20.3.8.6-1~centos~6_amd64.rpm

RUN curl -o /usr/local/bin/rebar3 https://s3.amazonaws.com/rebar3/rebar3 && chmod +x /usr/local/bin/rebar3 && /usr/local/bin/rebar3 local install

RUN curl -o /tmp/togo-2.5-1.noarch.rpm http://ecsft.cern.ch/dist/cvmfs/builddeps/togo-2.5-1.noarch.rpm && rpm -i --nodeps /tmp/togo-2.5-1.noarch.rpm

RUN mkdir -p /home/sftnight/.togo && chown sftnight /home/sftnight/.togo && chmod ugo+rwx /home/sftnight/.togo
RUN touch /home/sftnight/.rpmmacros && chown sftnight /home/sftnight/.rpmmacros && chmod ugo+rw /home/sftnight/.rpmmacros

RUN         useradd sftnight
RUN         rm -rf /home/sftnight

USER        sftnight
WORKDIR     /home
