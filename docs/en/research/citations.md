---
title: Citations
---

# Citations

MICOS-2024 gains legitimacy by building on well-established metagenomics and microbiome tools. This page turns that dependency graph into an explicit scholarly trail.

<script setup>
const references = [
  {
    authors: 'Wood DE, Lu J, Langmead B',
    title: 'Improved metagenomic analysis with Kraken 2',
    venue: 'Genome Biology',
    year: '2019',
    link: 'https://doi.org/10.1186/s13059-019-1891-0',
    note: 'Core taxonomic classification reference for the repository taxonomy branch.',
  },
  {
    authors: 'Bolyen E, Rideout JR, Dillon MR, et al.',
    title: 'Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2',
    venue: 'Nature Biotechnology',
    year: '2019',
    link: 'https://doi.org/10.1038/s41587-019-0209-9',
    note: 'Diversity and microbiome interpretation backbone.',
  },
  {
    authors: 'McIver LJ, Abu-Ali G, Franzosa EA, et al.',
    title: "bioBakery: a meta'omic analysis environment",
    venue: 'Bioinformatics',
    year: '2018',
    link: 'https://doi.org/10.1093/bioinformatics/btx754',
    note: 'Upstream context for KneadData and broader microbiome processing conventions.',
  },
  {
    authors: 'Franzosa EA, McIver LJ, Rahnavard G, et al.',
    title: 'Species-level functional profiling of metagenomes and metatranscriptomes',
    venue: 'Nature Methods',
    year: '2018',
    link: 'https://doi.org/10.1038/s41592-018-0176-y',
    note: 'Functional profiling reference lineage around HUMAnN.',
  },
  {
    authors: 'McMurdie PJ, Holmes S',
    title: 'phyloseq: an R package for reproducible interactive analysis and graphics of microbiome census data',
    venue: 'PLoS ONE',
    year: '2013',
    link: 'https://doi.org/10.1371/journal.pone.0061217',
    note: 'Important for downstream interpretation and R-facing microbiome workflows.',
  },
]
</script>

## How to cite MICOS-2024 itself

Use the repository citation guidance in `CITATION.md`, then include tool-specific references when you rely on a given analytical branch.

<ReferenceList :items="references" />

## Why this page matters

For an open-source platform, citation hygiene is part of architectural honesty. It makes clear which pieces were invented here and which pieces were responsibly integrated.
