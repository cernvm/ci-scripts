FROM        scratch
MAINTAINER  Rene Meusel <rene.meusel@cern.ch>

ADD         cc7_x86_64.tar.gz /
RUN         yum -y update && yum -y install epel-release
RUN         yum -y install                     \
                       cmake                   \
                       curl-devel              \
                       fuse-devel              \
                       gcc                     \
                       gcc-c++                 \
                       git                     \
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
                       which                   \
                       valgrind-devel          \
                       voms-devel              \
                       zlib-devel

RUN         useradd sftnight

RUN curl -o /tmp/esl-erlang.rpm \
    http://ecsft.cern.ch/dist/cvmfs/builddeps/otp/esl-erlang_20.0-1~centos~7_amd64.rpm && \
    yum -y install /tmp/esl-erlang.rpm

RUN curl -o /usr/local/bin/rebar3 https://s3.amazonaws.com/rebar3/rebar3 && chmod +x /usr/local/bin/rebar3 && /usr/local/bin/rebar3 local install

USER        sftnight
WORKDIR     /home/sftnight
