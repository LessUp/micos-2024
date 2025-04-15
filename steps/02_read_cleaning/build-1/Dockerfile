# 使用轻量级的Miniconda3镜像作为基础
FROM continuumio/miniconda3:latest

# 设置工作目录
WORKDIR /app

# 设置环境变量以使用Conda
ENV PATH /opt/conda/bin:$PATH

# 更新Conda并安装Mamba加速包管理
RUN conda update -n base -c defaults conda && \
    conda install -y -c conda-forge mamba

# 使用Mamba安装KneadData及其所有依赖项
RUN mamba install -y -c bioconda -c conda-forge \
    kneaddata=0.12.0 \
    bowtie2 \
    trimmomatic \
    openjdk \
    trf && \
    mamba clean -afy

# 验证安装
RUN kneaddata --version && \
    bowtie2 --version && \
    trimmomatic -version && \
    java -version && \
    trf 2>/dev/null

# 设置入口点
ENTRYPOINT ["kneaddata"]

# 设置默认命令
CMD ["--help"]