FROM mgor/docker-ubuntu-pkg-builder:yakkety

MAINTAINER Mikael Göransson <github@mgor.se>

ENV DEBIAN_FRONTEND noninteractive
ENV BUILD_DIRECTORY /usr/local/src
ENV BUILD_SCRIPT /usr/local/bin/build.sh

# Using apt-get due to warning with apt:
# WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
RUN apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y \
        sudo \
        libxi-dev \
        libmicrohttpd-dev \
        zlib1g-dev \
        libgcrypt20-dev \
        qtbase5-dev \
        qttools5-dev \
        qttools5-dev-tools \
        cmake \
        libxtst-dev \
        libqt5x11extras5-dev && \
    # Clean up!
    rm -rf /var/lib/apt/lists/*

COPY build.sh ${BUILD_SCRIPT}

RUN chmod 755 ${BUILD_SCRIPT}

WORKDIR ${BUILD_DIRECTORY}

CMD ${BUILD_SCRIPT}
