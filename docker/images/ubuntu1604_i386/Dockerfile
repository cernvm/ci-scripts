FROM        scratch
MAINTAINER  Jakob Blomer <jblomer@cern.ch>

ADD         ubuntu1604_i386.tar.gz /
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
                                              valgrind      \
                                              voms-dev

