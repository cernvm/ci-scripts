FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         ubuntu2004_x86_64.tar.gz /
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
                                              golang            \
                                              libattr1-dev      \
                                              libcap-dev        \
                                              libffi-dev        \
                                              libfuse-dev       \
                                              libssl-dev        \
                                              pkg-config        \
                                              ruby              \
                                              ruby-dev          \
                                              rubygems          \
                                              unzip             \
                                              uuid-dev          \
                                              valgrind

RUN sed -i /etc/apt/sources.list -e 's/main$/main universe/'

RUN apt-get -y update && apt-get -y install \
  autoconf \
  bison \
  doxygen \
  graphviz \
  gsfonts \
  dh-systemd \
  flex \
  libhesiod-dev \
  libkrb5-dev \
  libldap2-dev \
  libsasl2-dev \
  libxml2-dev \
  python-dev-is-python2 \
  python-setuptools \
  sssd-common


# Erlang part below

RUN curl -o /tmp/esl-erlang.deb \
    http://ecsft.cern.ch/dist/cvmfs/builddeps/otp/esl-erlang_23.0-1~ubuntu~focal_amd64.deb && \
    apt-get -y install libsctp1 libwxbase3.0-0v5 libwxgtk3.0-gtk3-0v5 && \
    dpkg -i /tmp/esl-erlang.deb

RUN curl -o /usr/local/bin/rebar3 https://s3.amazonaws.com/rebar3/rebar3 && chmod +x /usr/local/bin/rebar3 && /usr/local/bin/rebar3 local install

# End of Erlang part

RUN GOPATH=/usr/local go get github.com/jstemmer/go-junit-report

RUN gem install --no-ri --no-rdoc fpm
