# Use the Ubuntu 24.04 base image
FROM ubuntu:24.04

# Labels
LABEL base.image="ubuntu:24.04" \
    dockerfile.version="1" \
    software="Kraken2" \
    software.version="2.1.3" \
    description="Taxonomic sequence classifier" \
    website="https://github.com/DerrickWood/kraken2" \
    license="https://github.com/DerrickWood/kraken2/blob/master/LICENSE" \
    maintainer="Curtis Kapsak" \
    maintainer.email="kapsakcj@gmail.com"

# ARG and ENV
ARG K2VER="2.1.3"
ENV PATH="/kraken2-${K2VER}:$PATH" \
    LC_ALL=C \
    PIP_DEFAULT_TIMEOUT=100

# Replace the default Ubuntu repository with a mirror
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources && \
    cat /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update --fix-missing && apt-get -y --no-install-recommends install \
    wget \
    ca-certificates \
    zlib1g-dev \
    make \
    g++ \
    python3-pip \
    python3-venv \
    git \
    rsync \
    cpanminus && \
    rm -rf /var/lib/apt/lists/* && apt-get autoclean

# Install Perl module
RUN cpanm Getopt::Std

# Install Kraken2
RUN wget https://github.com/DerrickWood/kraken2/archive/v${K2VER}.tar.gz && \
    tar -xzf v${K2VER}.tar.gz && \
    rm -rf v${K2VER}.tar.gz && \
    cd kraken2-${K2VER} && \
    ./install_kraken2.sh . && \
    mkdir /data /kraken2-db

# Create a virtual environment and install kraken-biom
RUN python3 -m venv /venv && \
    /venv/bin/pip install --upgrade pip setuptools && \
    /venv/bin/pip install -i https://pypi.tuna.tsinghua.edu.cn/simple kraken-biom

# Set the default command to kraken2
# ENTRYPOINT ["kraken2"]