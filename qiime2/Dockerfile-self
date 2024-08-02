# 使用官方的 Ubuntu 作为基础镜像
FROM ubuntu:20.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的依赖
RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    curl \
    git \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    sudo \
    locales \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置 locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# 安装 Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh

# 添加 conda 到 PATH
ENV PATH /opt/conda/bin:$PATH

# 创建并激活 QIIME2 环境
RUN wget https://data.qiime2.org/distro/core/qiime2-2023.8-py38-linux-conda.yml -O /tmp/qiime2.yml && \
    conda env create -n qiime2-2023.8 --file /tmp/qiime2.yml && \
    rm /tmp/qiime2.yml

# 激活环境
SHELL ["conda", "run", "-n", "qiime2-2023.8", "/bin/bash", "-c"]

# 设置工作目录
WORKDIR /data

# 入口命令
CMD ["qiime"]