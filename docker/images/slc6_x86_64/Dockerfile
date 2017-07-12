FROM        scratch
MAINTAINER  Rene Meusel <rene.meusel@cern.ch>

ADD         slc6_x86_64.tar.gz /
RUN         yum -y update && yum -y install                     \
                                        cmake                   \
                                        curl-devel              \
                                        fuse-devel              \
                                        gcc                     \
                                        gcc-c++                 \
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
                                        libuuid-devel           \
                                        make                    \
                                        openssl-devel           \
                                        policycoreutils-python  \
                                        python-devel            \
                                        rpm-build               \
                                        selinux-policy-devel    \
                                        selinux-policy-targeted \
                                        sysvinit-tools          \
                                        valgrind-devel          \
                                        voms-devel              \
                                        which                   \
                                        zlib-devel              \
                                        python-pip              \
            && pip install --upgrade pip gcovr

RUN         useradd sftnight

RUN curl -o /tmp/esl-erlang.rpm \
    http://ecsft.cern.ch/dist/cvmfs/builddeps/otp/esl-erlang_20.0-1~centos~6_amd64.rpm && \
    yum -y install /tmp/esl-erlang.rpm

RUN curl -o /usr/local/bin/rebar3 https://s3.amazonaws.com/rebar3/rebar3 && chmod +x /usr/local/bin/rebar3

USER        sftnight
WORKDIR     /home/sftnight
