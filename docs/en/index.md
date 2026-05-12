---
layout: home
---

<div class="home-header">
  <div class="home-header-left">
    <div class="home-logo">MC</div>
    <div>
      <span class="home-title">MICOS-2024</span>
      <span class="home-subtitle">Metagenomic Intelligence Suite</span>
    </div>
  </div>
  <div class="home-nav">
    <a href="./guides/getting-started">Guides</a>
    <a href="https://github.com/LessUp/micos-2024">GitHub</a>
    <a href="../zh/">中文</a>
  </div>
</div>

<div class="home-intro-row">
  <div class="home-intro">
    MICOS-2024 is a comprehensive metagenomic analysis platform that integrates taxonomic profiling, functional annotation, and diversity analysis into a unified workflow. Containerized and reproducible.
  </div>
  <div class="home-stats">
    <span><strong>6+</strong> modules</span>
    <span><strong>10+</strong> tools</span>
    <span><strong>100%</strong> reproducible</span>
  </div>
</div>

## Core Modules

<div class="feature-map">
  <div class="feature-card">
    <div class="feature-card-title">🧬 Taxonomic Profiling</div>
    <div class="feature-card-desc">
      Species-level classification using Kraken2, Bracken, and MetaPhlAn with confidence scoring.
    </div>
    <div class="feature-tags">
      <a href="./analysis/taxonomic-profiling" class="feature-tag">Kraken2</a>
      <a href="./analysis/taxonomic-profiling" class="feature-tag">Bracken</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">🔬 Functional Annotation</div>
    <div class="feature-card-desc">
      Gene prediction, pathway analysis, and antimicrobial resistance gene detection.
    </div>
    <div class="feature-tags">
      <a href="./analysis/functional-profiling" class="feature-tag">HUMAnN</a>
      <a href="./analysis/functional-profiling" class="feature-tag">eggNOG</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">📊 Diversity Analysis</div>
    <div class="feature-card-desc">
      Alpha and beta diversity metrics, ordination plots, and statistical comparisons.
    </div>
    <div class="feature-tags">
      <a href="./analysis/diversity-analysis" class="feature-tag">Alpha</a>
      <a href="./analysis/diversity-analysis" class="feature-tag">Beta</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">✅ Quality Control</div>
    <div class="feature-card-desc">
      Read trimming, host removal, and quality filtering with FastP and Bowtie2.
    </div>
    <div class="feature-tags">
      <a href="./guides/getting-started" class="feature-tag">FastP</a>
      <a href="./guides/getting-started" class="feature-tag">Bowtie2</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">⚙️ WDL Workflows</div>
    <div class="feature-card-desc">
      Portable workflow definitions compatible with Cromwell, miniWDL, and Terra.
    </div>
    <div class="feature-tags">
      <a href="./configuration" class="feature-tag">WDL</a>
      <a href="./configuration" class="feature-tag">Cromwell</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">🐳 Containerized</div>
    <div class="feature-card-desc">
      Docker and Singularity support for fully reproducible analysis environments.
    </div>
    <div class="feature-tags">
      <a href="./guides/getting-started" class="feature-tag">Docker</a>
      <a href="./guides/getting-started" class="feature-tag">Singularity</a>
    </div>
  </div>
</div>

<div class="quick-start">
  <div class="quick-start-title">Quick Start</div>
  <div class="quick-start-content">
    <div class="command-block">
      <code>python -m micos.cli full-run --input-dir data/raw_input --results-dir results --threads 16</code>
    </div>
    See <a href="./guides/getting-started">Getting Started</a> for installation and detailed usage.
  </div>
</div>

## Analysis Pipeline

```mermaid
graph LR
    A[Raw FASTQ] --> B[QC & Trimming]
    B --> C[Host Removal]
    C --> D[Taxonomic Profiling]
    C --> E[Functional Profiling]
    D --> F[Diversity Analysis]
    E --> F
    F --> G[Reports]
```

## Performance Benchmarks

| Dataset Size | Reads | Threads | Time | Peak Memory |
|:---:|:---:|:---:|:---:|:---:|
| Small | 1M | 8 | ~15 min | 4 GB |
| Medium | 10M | 16 | ~1 hour | 16 GB |
| Large | 100M | 32 | ~6 hours | 64 GB |

---

MIT License - [LessUp](https://github.com/LessUp)
