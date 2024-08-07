# 使用 Ubuntu 20.04 作为基础镜像
FROM ubuntu:20.04

# 设置非交互式前端和时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# 设置 APT 源为阿里云镜像，加速下载（如果你在中国大陆）
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/' /etc/apt/sources.list

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    wget \
    unzip \
    bowtie2 \
    trimmomatic \
    fastqc \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置 pip 源为阿里云镜像，加速下载（如果你在中国大陆）
RUN pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/

# 安装 KneadData
RUN pip3 install --no-cache-dir kneaddata==0.12.0

# 设置工作目录
WORKDIR /data

# 设置默认命令
ENTRYPOINT ["kneaddata"]
CMD ["--help"]