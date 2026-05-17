---
title: 参考文献
---

# 参考文献

MICOS-2024 的可信度，一部分来自它建立在成熟宏基因组和微生物组工具之上。本页把这条谱系显式写出来。

<script setup>
const references = [
  {
    authors: 'Wood DE, Lu J, Langmead B',
    title: 'Improved metagenomic analysis with Kraken 2',
    venue: 'Genome Biology',
    year: '2019',
    link: 'https://doi.org/10.1186/s13059-019-1891-0',
    note: '当前仓库分类分支的重要方法学基线。',
  },
  {
    authors: 'Bolyen E, Rideout JR, Dillon MR, et al.',
    title: 'Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2',
    venue: 'Nature Biotechnology',
    year: '2019',
    link: 'https://doi.org/10.1038/s41587-019-0209-9',
    note: '多样性分析和微生物组解释的重要支柱。',
  },
  {
    authors: 'McIver LJ, Abu-Ali G, Franzosa EA, et al.',
    title: "bioBakery: a meta'omic analysis environment",
    venue: 'Bioinformatics',
    year: '2018',
    link: 'https://doi.org/10.1093/bioinformatics/btx754',
    note: 'KneadData 及更广微生物组处理惯例的重要背景。',
  },
  {
    authors: 'Franzosa EA, McIver LJ, Rahnavard G, et al.',
    title: 'Species-level functional profiling of metagenomes and metatranscriptomes',
    venue: 'Nature Methods',
    year: '2018',
    link: 'https://doi.org/10.1038/s41592-018-0176-y',
    note: 'HUMAnN 功能分析谱系中的关键参考。',
  },
  {
    authors: 'McMurdie PJ, Holmes S',
    title: 'phyloseq: an R package for reproducible interactive analysis and graphics of microbiome census data',
    venue: 'PLoS ONE',
    year: '2013',
    link: 'https://doi.org/10.1371/journal.pone.0061217',
    note: 'R 侧微生物组解释与图形分析的重要基础。',
  },
]
</script>

## 如何引用 MICOS-2024

项目自身的引用方式请参考仓库中的 `CITATION.md`。如果你使用了某一分析分支，也应同时引用相应工具论文。

<ReferenceList :items="references" />

## 为什么这里要单列一页

对于开源平台来说，引用卫生本身就是架构诚实的一部分。它说明哪些东西是在这里发明的，哪些东西是被认真整合进来的。
