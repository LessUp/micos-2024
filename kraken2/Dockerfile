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

# Set the K2VER environment variable
ENV K2VER="2.1.3"

# Now use K2VER in the PATH environment variable
ENV PATH="/kraken2-${K2VER}:$PATH" \
    LC_ALL=C

# Use Aliyun mirror and install dependencies and Kraken2
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update --fix-missing && apt-get -y --no-install-recommends install \
        wget \
        ca-certificates \
        zlib1g-dev \
        make \
        g++ \
        rsync \
        cpanminus && \
    rm -rf /var/lib/apt/lists/* && apt-get autoclean && \
    cpanm Getopt::Std && \
    wget https://github.com/DerrickWood/kraken2/archive/v${K2VER}.tar.gz && \
    tar -xzf v${K2VER}.tar.gz && \
    rm -rf v${K2VER}.tar.gz && \
    cd kraken2-${K2VER} && \
    ./install_kraken2.sh . && \
    mkdir /data /kraken2-db

# Set the default command to kraken2
# ENTRYPOINT ["kraken2"]

# Set default parameters for ENTRYPOINT
CMD ["/bin/bash"]