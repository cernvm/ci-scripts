FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         ubuntu1604_x86_64.tar.gz /
RUN         apt-get -y update && apt-get -y upgrade
RUN         apt-get -y update && apt-get -y install             \
                                              autotools-dev     \
                                              build-essential   \
                                              cmake             \
                                              cpio              \
                                              debhelper         \
                                              devscripts        \
                                              gdb               \
                                              gcc               \
                                              git               \
                                              libattr1-dev      \
                                              libcap-dev        \
                                              libffi-dev        \
                                              libfuse-dev       \
                                              libssl-dev        \
                                              pkg-config        \
                                              python-dev        \
                                              python-setuptools \
                                              ruby              \
                                              ruby-dev          \
                                              rubygems          \
                                              unzip             \
                                              uuid-dev          \
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

# Erlang part below

RUN curl -o /tmp/esl-erlang.deb \
    http://ecsft.cern.ch/dist/cvmfs/builddeps/otp/esl-erlang_21.2.5-1~ubuntu~xenial_amd64.deb && \
    apt-get -y install libsctp1 libwxbase3.0-0v5 libwxgtk3.0-0v5 && \
    dpkg -i /tmp/esl-erlang.deb

RUN curl -o /usr/local/bin/rebar3 https://s3.amazonaws.com/rebar3/rebar3 && chmod +x /usr/local/bin/rebar3 && /usr/local/bin/rebar3 local install
# End of Erlang part

# Golang >= 11.5 is needed for cvmfs-gateway
RUN curl -o /tmp/go.tar.gz https://dl.google.com/go/go1.12.4.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

RUN gem install --no-ri --no-rdoc fpm
