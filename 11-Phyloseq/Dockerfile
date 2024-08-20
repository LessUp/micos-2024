FROM rocker/r-ver:latest

# 更新和安装必要的系统包
RUN set -e \
    && apt-get -y update \
    && apt-get -y dist-upgrade \
    && apt-get -y install --no-install-recommends --no-install-suggests zlib1g-dev libxml2 libglpk40 \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 R 包
RUN Rscript -e "install.packages(c('BiocManager', 'dplyr', 'grid', 'gridExtra', 'xfun', 'pvclust', 'dendextend'))" \
    && Rscript -e "BiocManager::install('phyloseq')"

# 设置工作目录
WORKDIR /data/

# 复制 R 脚本到工作目录
COPY Phyloseq_pimba.R /data/