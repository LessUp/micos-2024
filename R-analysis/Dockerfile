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

# 安装 DESeq2 所需的所有依赖包
RUN R -e "BiocManager::install(c('S4Vectors', 'IRanges', 'GenomeInfoDb', 'GenomicRanges', 'SummarizedExperiment', 'DelayedArray', 'BiocGenerics', 'matrixStats', 'Biobase', 'AnnotationDbi', 'GenomicAlignments', 'BiocParallel', 'edgeR', 'vegan', 'ggplot2', 'rmarkdown', 'knitr', 'hdf5r', 'Rhtslib', 'GenomicFiles', 'Rsamtools', 'apeglm', 'ashr', 'vsn', 'pheatmap', 'genefilter', 'ReportingTools', 'DESeq2'), ask=FALSE, update=FALSE, Ncpus=4, verbose=TRUE)"

# 安装常用 R 包
RUN R -e "install.packages(c('BH', 'futile.logger', 'cpp11', 'httr', 'glue', 'Rcpp', 'RcppArmadillo', 'locfit'), repos='https://cloud.r-project.org/', Ncpus=4)"

# 验证 DESeq2 安装
RUN R -e "if (!requireNamespace('DESeq2', quietly = TRUE)) { stop('DESeq2 not installed') } else { cat('DESeq2 installed successfully\n') }"

# 复制分析脚本
COPY scripts/diversity_analysis.R /scripts/diversity_analysis.R
COPY scripts/differential_abundance_analysis.R /scripts/differential_abundance_analysis.R
COPY scripts/generate_report.R /scripts/generate_report.R

# 设置入口点（将在 WDL 中被覆盖）
ENTRYPOINT ["Rscript"]
