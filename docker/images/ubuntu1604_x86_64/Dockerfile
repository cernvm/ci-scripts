FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         ubuntu1604_x86_64.tar.gz /
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
                                              pkg-config    \
                                              python-dev    \
                                              unzip         \
                                              uuid-dev      \
                                              valgrind

RUN apt-get -y update && apt-get -y install \
  doxygen \
  graphviz \
  gsfonts

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

RUN curl -o /tmp/esl-erlang.deb \
    http://ecsft.cern.ch/dist/cvmfs/builddeps/otp/esl-erlang_20.0-1~ubuntu~xenial_amd64.deb && \
    apt-get -y install libsctp1 libwxbase3.0-0v5 libwxgtk3.0-0v5 && \
    dpkg -i /tmp/esl-erlang.deb

RUN curl -o /usr/local/bin/rebar3 https://s3.amazonaws.com/rebar3/rebar3 && chmod +x /usr/local/bin/rebar3
