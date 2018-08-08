FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         debian8_x86_64.tar.gz /
RUN         apt-get -y update && apt-get -y upgrade
RUN         apt-get -y update && apt-get -y install             \
                                              autotools-dev     \
                                              cmake             \
                                              cpio              \
                                              debhelper         \
                                              devscripts        \
                                              gdb               \
                                              git               \
                                              libattr1-dev      \
                                              libcap-dev        \
                                              libfuse-dev       \
                                              libssl-dev        \
                                              pbuilder          \
                                              pkg-config        \
                                              python-dev        \
                                              python-setuptools \
                                              unzip             \
                                              uuid-dev          \
                                              valgrind

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

