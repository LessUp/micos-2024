# 容器化部署策略

## 概述

MICOS-2024 采用 Docker/Singularity 双轨容器策略，确保分析环境的可移植性和可复现性。

## 容器镜像清单

| 分析步骤 | Docker 镜像 | 基础镜像 |
|----------|-------------|----------|
| FastQC | `biocontainers/fastqc:v0.11.9_cv8` | Debian |
| KneadData | `biobakery/kneaddata:latest` | Ubuntu |
| Kraken2 | 自建 `kraken2:2.1.3` | Ubuntu 24.04 |
| Kraken-BIOM | `amancevice/pandas:1.1.5` | Python |
| Krona | 自建 `krona:2.8.1` | Ubuntu |
| QIIME2 | `quay.io/qiime2/metagenome:2024.5` | conda |
| Phyloseq | `rocker/r-ver:latest` | R |

## Dockerfile 规范

### 结构模板

```dockerfile
# 语法版本
# syntax=docker/dockerfile:1

# 基础镜像
FROM ubuntu:24.04

# 元数据
LABEL maintainer="BGI-MICOS <support@micos.org>"
LABEL version="1.0.0"
LABEL description="MICOS-2024 分析模块"

# 系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Python 环境
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# 应用代码
COPY . /app
WORKDIR /app

# 入口点
ENTRYPOINT ["python", "-m", "micos.cli"]
```

### 最佳实践

1. **多阶段构建**: 减小镜像体积
2. **层缓存优化**: 依赖层在前，代码层在后
3. **安全扫描**: 使用 `hadolint` 检查 Dockerfile
4. **版本锁定**: 明确指定镜像版本标签

## Singularity 支持

### 定义文件 (.def)

```def
Bootstrap: docker
From: biocontainers/fastqc:v0.11.9_cv8

%post
    apt-get update
    apt-get install -y wget

%environment
    export PATH=/usr/local/bin:$PATH

%runscript
    exec fastqc "$@"
```

### 构建命令

```bash
sudo singularity build fastqc.sif fastqc.def
```

## 容器编排

### docker-compose.yaml

```yaml
version: "3.9"
services:
  fastqc:
    image: biocontainers/fastqc:v0.11.9_cv8
    volumes:
      - ./data:/data
      - ./results:/results
    command: fastqc /data/*.fastq.gz -o /results/qc/
```

## CI/CD 集成

1. **镜像构建**: GitHub Actions 自动构建
2. **镜像推送**: Docker Hub + GHCR 双推送
3. **标签策略**: 
   - `latest`: 最新稳定版
   - `vX.Y.Z`: 版本标签
   - `dev`: 开发版

## 资源限制

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 16G
    reservations:
      cpus: '2'
      memory: 8G
```
