FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         debian9_x86_64.tar.gz /
RUN         apt-get -y update && apt-get -y upgrade
RUN         apt-get -y update && apt-get -y install         \
                                              autotools-dev \
                                              cmake         \
                                              debhelper     \
                                              devscripts    \
                                              gdb           \
                                              git           \
                                              libattr1-dev  \
                                              libcap-dev    \
                                              libfuse-dev   \
                                              libssl-dev    \
                                              libz-dev      \
                                              pbuilder      \
                                              pkg-config    \
                                              python-dev    \
                                              unzip         \
                                              uuid-dev      \
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
