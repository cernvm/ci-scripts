FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ARG SFTNIGHT_UID=500
ARG SFTNIGHT_GID=500

ADD         debian9_x86_64.tar.gz /
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
                                              libz-dev          \
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

RUN apt-get -y update && apt-get -y install \
  fakechroot

RUN  groupadd --gid $SFTNIGHT_GID sftnight && \
        adduser --uid $SFTNIGHT_UID --gid $SFTNIGHT_GID sftnight

USER sftnight

WORKDIR /home/sftnight
