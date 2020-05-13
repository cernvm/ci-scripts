FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         ubuntu2004_i386.tar.gz /
RUN         apt-get -y update && apt-get -y upgrade
RUN         apt-get -y update && apt-get -y install             \
                                              autotools-dev     \
                                              cmake             \
                                              cpio              \
                                              debhelper         \
                                              devscripts        \
                                              gdb               \
                                              git               \
                                              golang            \
                                              libattr1-dev      \
                                              libcap-dev        \
                                              libfuse-dev       \
                                              libssl-dev        \
                                              pkg-config        \
                                              python-dev        \
                                              python-setuptools \
                                              unzip             \
                                              uuid-dev          \
                                              valgrind

RUN sed -i /etc/apt/sources.list -e 's/main$/main universe/'
RUN apt-get -y update && apt-get -y install \
  autoconf \
  bison \
  dh-systemd \
  flex \
  libhesiod-dev \
  libkrb5-dev \
  libldap2-dev \
  libsasl2-dev \
  libxml2-dev \
  sssd-common

RUN GOPATH=/usr/local go get github.com/jstemmer/go-junit-report
