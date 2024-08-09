# 使用轻量级的Miniconda3镜像作为基础
FROM continuumio/miniconda3:latest

# 设置工作目录
WORKDIR /data

# 设置环境变量以使用Conda
ENV PATH /opt/conda/bin:$PATH

# 更新Conda并安装Mamba加速包管理
RUN conda update -n base -c defaults conda && \
    conda install -y -c conda-forge mamba

# 创建一个新的Conda环境并安装KneadData
RUN mamba create -n kneaddata_env -y -c bioconda -c conda-forge \
    kneaddata=0.12.0 bowtie2 trimmomatic && \
    mamba clean -afy

RUN rm /opt/conda/bin/trimmomatic && \
    ln -s /opt/conda/share/trimmomatic-0.39-2/trimmomatic.jar /opt/conda/bin/trimmomatic

# 使用SHELL指令来激活环境
SHELL ["conda", "run", "-n", "kneaddata_env", "/bin/bash", "-c"]

# 验证安装
RUN kneaddata --version && \
    bowtie2 --version && \
    trimmomatic -version

# 设置入口点
# ENTRYPOINT ["conda", "run", "-n", "kneaddata_env", "--"]

# 设置默认命令
CMD ["/bin/bash"]