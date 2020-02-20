## See README.md, build.sh and ../build_on_docker.sh

FROM       scratch
MAINTAINER Jakob Blomer <jblomer@cern.ch>

ADD        sles12_x86_64.tar.gz /
RUN        zypper -n update && zypper -n install    \
                                  cmake             \
                                  fuse-devel        \
                                  gcc               \
                                  gcc-c++           \
                                  gdb               \
                                  git               \
                                  libattr-devel     \
                                  libcap-devel      \
                                  libcurl-devel     \
                                  libopenssl-devel  \
                                  libuuid-devel     \
                                  make              \
                                  patch             \
                                  pkgconfig         \
                                  python-devel      \
                                  python-pytest     \
                                  python-setuptools \
                                  rpmbuild          \
                                  tar               \
                                  unzip             \
                                  valgrind-devel    \
                                  zlib-devel

RUN        ln -s /usr/bin/ld.bfd /etc/alternatives/ld
RUN        ln -s /usr/bin/unzip-plain /etc/alternatives/unzip

RUN        useradd sftnight
USER       sftnight
WORKDIR    /home/sftnight
