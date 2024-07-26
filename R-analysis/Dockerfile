# Dockerfile for Combined Diversity, Differential Abundance Analysis and Report Generation
# lastest 4.4.1, last version 4.3.3
FROM rocker/r-ver:4.4.1 

# Install necessary system libraries
RUN apt-get update && apt-get install -y \
    libxt6 \
    libxt-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Bioconductor and necessary R packages
RUN R -e "install.packages('BiocManager', repos='http://cran.rstudio.com/')"
RUN R -e "BiocManager::install(c('edgeR', 'vegan', 'ggplot2', 'rmarkdown', 'knitr'))"

# Install DESeq2 dependencies
RUN R -e "BiocManager::install(c('XVector', 'SparseArray', 'GenomicRanges', 'DelayedArray', 'SummarizedExperiment'))"

# Install DESeq2 with detailed output and log to a file
RUN R -e "BiocManager::install('DESeq2', ask=FALSE, update=FALSE, verbose=TRUE)" > /tmp/deseq2_install.log 2>&1

# Check if DESeq2 is installed and print the log file
RUN R -e "if (!requireNamespace('DESeq2', quietly = TRUE)) { cat('DESeq2 not installed\n'); system('cat /tmp/deseq2_install.log'); stop('DESeq2 not installed') } else { cat('DESeq2 installed successfully\n') }"

# Copy analysis scripts
COPY scripts/diversity_analysis.R scripts/diversity_analysis.R
COPY scripts/differential_abundance_analysis.R scripts/differential_abundance_analysis.R
COPY scripts/generate_report.R scripts/generate_report.R

# Set the entrypoint (will be overridden in WDL)
ENTRYPOINT ["Rscript"]