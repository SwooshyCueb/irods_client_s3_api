FROM ubuntu:22.04

SHELL [ "/bin/bash", "-c" ]

ENV DEBIAN_FRONTEND=noninteractive

# Make sure we're starting with an up-to-date image
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*
# To mark all installed packages as manually installed:
#apt-mark showauto | xargs -r apt-mark manual

RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        ccache \
        g++-10 \
        gcc \
        gcc-10 \
        git \
        gnupg \
        help2man \
        libbz2-dev \
        libcurl4-gnutls-dev \
        libfuse-dev \
        libjson-perl \
        libkrb5-dev \
        libpam0g-dev \
        libssl-dev \
        libxml2-dev \
        lsb-release \
        lsof \
        make \
        ninja-build \
        odbc-postgresql \
        postgresql \
        python3 \
        python3-dev \
        python3-pip \
        python3-distro \
        python3-jsonschema \
        python3-packaging \
        python3-psutil \
        python3-pyodbc \
        python3-requests \
        sudo \
        super \
        unixodbc-dev \
        wget \
        zlib1g-dev \
    && \
    pip3 --no-cache-dir install lief && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list && \
    wget -qO - https://core-dev.irods.org/irods-core-dev-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://core-dev.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods-core-dev.list

ARG irods_version=4.3.1-0~jammy
RUN apt-get update && \
    apt-get install -y \
        irods-externals-clang13.0.0-0 \
        irods-externals-cmake3.21.4-0 \
        irods-externals-fmt8.1.1-0 \
        irods-externals-json3.10.4-0 \
        irods-externals-nanodbc2.13.0-1 \
        irods-externals-spdlog1.9.2-1 \
        irods-dev=${irods_version} \
        irods-runtime=${irods_version} \
        irods-icommands=${irods_version} \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN update-alternatives --install /usr/local/bin/gcc gcc /usr/bin/gcc-10 1 && \
    update-alternatives --install /usr/local/bin/g++ g++ /usr/bin/g++-10 1 && \
    hash -r

ARG cmake_path="/opt/irods-externals/cmake3.21.4-0/bin"
ENV PATH=${cmake_path}:$PATH

# This is where the dockerfile deviates from the one used by the development environment's docker
# file

COPY scripts scripts

RUN mkdir irods_s3_api

COPY . irods_s3_api

RUN bash scripts/build_bridge.sh

RUN ls -l /irods_s3_api/build && dpkg -i /irods_s3_api/build/irods-experimental-client-s3-api_0.1.0-0~jammy_amd64.deb

RUN chmod +x scripts/run_bridge.sh && \
    mkdir -p /root/.irods

ENTRYPOINT [ "scripts/run_bridge.sh" ]
