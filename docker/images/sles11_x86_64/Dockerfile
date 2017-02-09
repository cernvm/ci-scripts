## See README.md, build.sh and ../build_on_docker.sh

FROM       scratch
MAINTAINER Rene Meusel <rene.meusel@cern.ch>

ADD        sles11_x86_64.tar.gz /
RUN        zypper -n update && zypper -n install   \
                                  fuse-devel       \
                                  gcc              \
                                  gcc-c++          \
                                  gdb              \
                                  git              \
                                  libattr-devel    \
                                  libcap-devel     \
                                  libcurl-devel    \
                                  libopenssl-devel \
                                  libuuid-devel    \
                                  make             \
                                  patch            \
                                  pkgconfig        \
                                  python-devel     \
                                  tar              \
                                  unzip            \
                                  valgrind-devel   \
                                  zlib-devel

ADD        https://cmake.org/files/v3.7/cmake-3.7.2-Linux-x86_64.tar.gz /tmp
RUN        cd /tmp && tar xzf cmake-3.7.2-Linux-x86_64.tar.gz && cp -rv cmake-3.7.2-Linux-x86_64/* /usr/

RUN        useradd sftnight
USER       sftnight
WORKDIR    /home/sftnight
