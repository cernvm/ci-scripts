FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

# 2019-02-05 11:36  - dummy comment to trigger installation of latest golang compiler
ADD         cc7_x86_64.tar.gz /
RUN         yum -y update
RUN         yum -y install filesystem
RUN         yum -y install epel-release
RUN         yum -y install                     \
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
                       libffi-devel            \
                       libuuid-devel           \
                       make                    \
                       openssl-devel           \
                       policycoreutils-python  \
                       python-devel            \
                       python-setuptools       \
                       rpm-build               \
                       ruby-devel              \
                       selinux-policy-devel    \
                       selinux-policy-targeted \
                       sysvinit-tools          \
                       which                   \
                       valgrind-devel          \
                       voms-devel              \
                       zlib-devel

RUN         useradd sftnight

# Relieve a bit the version requirement of selinux-policy
RUN yum -y downgrade \
  http://ftp.scientificlinux.org/linux/scientific/7.3/x86_64/os/Packages/selinux-policy-targeted-3.13.1-102.el7.noarch.rpm \
  http://ftp.scientificlinux.org/linux/scientific/7.3/x86_64/os/Packages/selinux-policy-devel-3.13.1-102.el7.noarch.rpm \
  http://ftp.scientificlinux.org/linux/scientific/7.3/x86_64/os/Packages/selinux-policy-3.13.1-102.el7.noarch.rpm

# Erlang part below

RUN yum -y install http://ecsft.cern.ch/dist/cvmfs/builddeps/otp/esl-erlang_21.2.5-1~centos~7_amd64.rpm

RUN curl -o /usr/local/bin/rebar3 https://s3.amazonaws.com/rebar3/rebar3 && chmod +x /usr/local/bin/rebar3 && /usr/local/bin/rebar3 local install

RUN yum -y install http://ecsft.cern.ch/dist/cvmfs/builddeps/togo-2.5-1.noarch.rpm

RUN mkdir -p /home/sftnight/.togo && chown sftnight /home/sftnight/.togo && chmod ugo+rwx /home/sftnight/.togo
RUN touch /home/sftnight/.rpmmacros && chown sftnight /home/sftnight/.rpmmacros && chmod ugo+rw /home/sftnight/.rpmmacros

# End of Erlang part

RUN go get github.com/jstemmer/go-junit-report

ENV PATH=$PATH:/root/go/bin

USER        sftnight

WORKDIR     /home/sftnight
