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

# Set environment variables
ENV PATH="/kraken2-${K2VER}:$PATH" \
    LC_ALL=C

# Install dependencies and Kraken2
RUN apt-get update && apt-get -y --no-install-recommends install \
        wget \
        ca-certificates \
        zlib1g-dev \
        make \
        g++ \
        rsync \
        cpanminus && \
    rm -rf /var/lib/apt/lists/* && apt-get autoclean && \
    cpanm Getopt::Std && \
    K2VER="2.1.3" && \
    wget https://github.com/DerrickWood/kraken2/archive/v${K2VER}.tar.gz && \
    tar -xzf v${K2VER}.tar.gz && \
    rm -rf v${K2VER}.tar.gz && \
    cd kraken2-${K2VER} && \
    ./install_kraken2.sh . && \
    mkdir /data /kraken2-db

# Set the default command to bash
CMD ["/bin/bash"]
