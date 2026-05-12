---
layout: home
---

<div class="home-header">
  <div class="home-header-left">
    <div class="home-logo">MC</div>
    <div>
      <span class="home-title">MICOS-2024</span>
      <span class="home-subtitle">宏基因组综合分析平台</span>
    </div>
  </div>
  <div class="home-nav">
    <a href="./guides/getting-started">指南</a>
    <a href="https://github.com/LessUp/micos-2024">GitHub</a>
    <a href="../en/">English</a>
  </div>
</div>

<div class="home-intro-row">
  <div class="home-intro">
    MICOS-2024 是一个综合宏基因组分析平台，将物种分类、功能注释和多样性分析整合到统一的工作流程中。支持容器化部署，确保分析结果完全可重现。
  </div>
  <div class="home-stats">
    <span><strong>6+</strong> 个模块</span>
    <span><strong>10+</strong> 个工具</span>
    <span><strong>100%</strong> 可重现</span>
  </div>
</div>

## 核心模块

<div class="feature-map">
  <div class="feature-card">
    <div class="feature-card-title">🧬 物种分类分析</div>
    <div class="feature-card-desc">
      基于 Kraken2、Bracken 和 MetaPhlAn 的物种级分类，支持置信度评分。
    </div>
    <div class="feature-tags">
      <a href="./analysis/taxonomic-profiling" class="feature-tag">Kraken2</a>
      <a href="./analysis/taxonomic-profiling" class="feature-tag">Bracken</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">🔬 功能注释分析</div>
    <div class="feature-card-desc">
      基因预测、通路分析和抗性基因检测。
    </div>
    <div class="feature-tags">
      <a href="./analysis/functional-profiling" class="feature-tag">HUMAnN</a>
      <a href="./analysis/functional-profiling" class="feature-tag">eggNOG</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">📊 多样性分析</div>
    <div class="feature-card-desc">
      Alpha 和 Beta 多样性指标、排序图和统计比较。
    </div>
    <div class="feature-tags">
      <a href="./analysis/diversity-analysis" class="feature-tag">Alpha</a>
      <a href="./analysis/diversity-analysis" class="feature-tag">Beta</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">✅ 质量控制</div>
    <div class="feature-card-desc">
      使用 FastP 和 Bowtie2 进行读段修剪、宿主去除和质量过滤。
    </div>
    <div class="feature-tags">
      <a href="./guides/getting-started" class="feature-tag">FastP</a>
      <a href="./guides/getting-started" class="feature-tag">Bowtie2</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">⚙️ WDL 工作流</div>
    <div class="feature-card-desc">
      可移植的工作流定义，兼容 Cromwell、miniWDL 和 Terra。
    </div>
    <div class="feature-tags">
      <a href="./configuration" class="feature-tag">WDL</a>
      <a href="./configuration" class="feature-tag">Cromwell</a>
    </div>
  </div>

  <div class="feature-card">
    <div class="feature-card-title">🐳 容器化部署</div>
    <div class="feature-card-desc">
      支持 Docker 和 Singularity，确保分析环境完全可重现。
    </div>
    <div class="feature-tags">
      <a href="./guides/getting-started" class="feature-tag">Docker</a>
      <a href="./guides/getting-started" class="feature-tag">Singularity</a>
    </div>
  </div>
</div>

<div class="quick-start">
  <div class="quick-start-title">快速开始</div>
  <div class="quick-start-content">
    <div class="command-block">
      <code>python -m micos.cli full-run --input-dir data/raw_input --results-dir results --threads 16</code>
    </div>
    详见 <a href="./guides/getting-started">快速开始</a> 了解安装和详细用法。
  </div>
</div>

## 分析流程

```mermaid
graph LR
    A[原始 FASTQ] --> B[质控与修剪]
    B --> C[宿主去除]
    C --> D[物种分类分析]
    C --> E[功能注释分析]
    D --> F[多样性分析]
    E --> F
    F --> G[报告生成]
```

## 性能基准

| 数据规模 | Reads 数量 | 线程数 | 耗时 | 峰值内存 |
|:---:|:---:|:---:|:---:|:---:|
| 小型 | 1M | 8 | ~15 分钟 | 4 GB |
| 中型 | 10M | 16 | ~1 小时 | 16 GB |
| 大型 | 100M | 32 | ~6 小时 | 64 GB |

---

MIT 许可证 - [LessUp](https://github.com/LessUp)
