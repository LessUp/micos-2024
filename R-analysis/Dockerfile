# Dockerfile for Combined Diversity, Differential Abundance Analysis and Report Generation
FROM rocker/r-ver:4.1.0

# Install necessary system libraries
RUN apt-get update && apt-get install -y \
    libxt6 \
    libxt-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('vegan', 'ggplot2', 'DESeq2', 'edgeR', 'rmarkdown', 'knitr'), repos='http://cran.rstudio.com/')"

# Copy analysis scripts
COPY scripts/diversity_analysis.R scripts/diversity_analysis.R
COPY scripts/differential_abundance_analysis.R scripts/differential_abundance_analysis.R
COPY scripts/generate_report.R scripts/generate_report.R

# Set the entrypoint (will be overridden in WDL)
ENTRYPOINT ["Rscript"]