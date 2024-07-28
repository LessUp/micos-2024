# 使用 rocker/r-ver 基础镜像
FROM rocker/r-ver:4.4.1 

# 设置环境变量以加速构建
ENV R_REMOTES_NO_ERRORS_FROM_WARNINGS=true

# 安装必要的系统库
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxt6 \
    libxt-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    libhdf5-dev \
    libtiff5-dev \
    libfftw3-dev \
    libgmp-dev \
    libv8-dev \
    libgsl-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 BiocManager
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org/')"

# 安装 edgeR 及其依赖包
RUN R -e "BiocManager::install(c('edgeR', 'limma'), ask=FALSE, update=FALSE, Ncpus=4, verbose=TRUE)"

# 复制分析脚本
COPY scripts/diversity_analysis.R /scripts/diversity_analysis.R
COPY scripts/differential_abundance_analysis.R /scripts/differential_abundance_analysis.R
COPY scripts/generate_report.R /scripts/generate_report.R

# 设置入口点（将在 WDL 中被覆盖）
ENTRYPOINT ["Rscript"]
