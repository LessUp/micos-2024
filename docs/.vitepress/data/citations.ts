// 学术引用数据
export interface Citation {
  id: string
  authors: string
  title: string
  venue: string
  year: number
  doi?: string
  url?: string
}

// 核心工具引用
export const coreCitations: Citation[] = [
  {
    id: 'kraken2',
    authors: 'Wood DE, Lu J, Langmead B',
    title: 'Improved metagenomic analysis with Kraken 2',
    venue: 'Genome Biology',
    year: 2019,
    doi: '10.1186/s13059-019-1891-0',
  },
  {
    id: 'qiime2',
    authors: 'Bolyen E, Rideout JR, Dillon MR, et al.',
    title: 'Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2',
    venue: 'Nature Biotechnology',
    year: 2019,
    doi: '10.1038/s41587-019-0209-9',
  },
  {
    id: 'phyloseq',
    authors: 'McMurdie PJ, Holmes S',
    title: 'phyloseq: an R package for reproducible interactive analysis and graphics of microbiome census data',
    venue: 'PLoS ONE',
    year: 2013,
    doi: '10.1371/journal.pone.0061217',
  },
  {
    id: 'kneaddata',
    authors: 'McIver LJ, Abu-Ali G, Franzosa EA, et al.',
    title: 'bioBakery: a meta-omic analysis environment',
    venue: 'Bioinformatics',
    year: 2018,
    doi: '10.1093/bioinformatics/btx261',
  },
  {
    id: 'humann3',
    authors: 'Beghini F, McIver LJ, Blanco-Míguez A, et al.',
    title: 'Integrating taxonomic, functional, and strain-level profiling of diverse microbial communities with bioBakery 3',
    venue: 'eLife',
    year: 2021,
    doi: '10.7554/eLife.65088',
  },
  {
    id: 'krona',
    authors: 'Ondov BD, Bergman CM, Phillippy AM',
    title: 'Interactive metagenomic visualization in a Web browser',
    venue: 'BMC Bioinformatics',
    year: 2011,
    doi: '10.1186/1471-2105-12-385',
  },
]

// 算法引用
export const algorithmCitations: Citation[] = [
  {
    id: 'shannon',
    authors: 'Shannon CE',
    title: 'A mathematical theory of communication',
    venue: 'Bell System Technical Journal',
    year: 1948,
    doi: '10.1002/j.1538-7305.1948.tb01338.x',
  },
  {
    id: 'kmer',
    authors: 'Marçais G, Kingsford C',
    title: 'A fast, lock-free approach for parallelizing exact k-mer counting',
    venue: 'Bioinformatics',
    year: 2015,
    doi: '10.1093/bioinformatics/btu310',
  },
  {
    id: 'alpha-diversity',
    authors: 'Hill MO',
    title: 'Diversity and evenness: a unifying notation and its consequences',
    venue: 'Ecology',
    year: 1973,
    doi: '10.2307/1934352',
  },
  {
    id: 'beta-diversity',
    authors: 'Lozupone C, Knight R',
    title: 'UniFrac: a new phylogenetic method for comparing microbial communities',
    venue: 'Applied and Environmental Microbiology',
    year: 2005,
    doi: '10.1128/AEM.71.12.8228-8235.2005',
  },
]

// 性能基准数据
export interface BenchmarkData {
  scale: string
  samples: number
  timeHours: number
  memoryGB: number
  threads: number
}

export const benchmarkData: BenchmarkData[] = [
  { scale: 'Small', samples: 10, timeHours: 2, memoryGB: 16, threads: 16 },
  { scale: 'Medium', samples: 50, timeHours: 8, memoryGB: 32, threads: 32 },
  { scale: 'Large', samples: 100, timeHours: 15, memoryGB: 64, threads: 64 },
  { scale: 'XLarge', samples: 500, timeHours: 72, memoryGB: 128, threads: 128 },
]

// 竞品对比数据
export interface ComparisonData {
  feature: string
  micos: boolean | string
  qiime2: boolean | string
  metaphlan: boolean | string
  humann: boolean | string
}

export const comparisonData: ComparisonData[] = [
  { feature: 'End-to-end integration', micos: true, qiime2: 'partial', metaphlan: false, humann: false },
  { feature: 'Reproducibility (WDL/containers)', micos: true, qiime2: 'partial', metaphlan: false, humann: false },
  { feature: 'Test coverage >80%', micos: true, qiime2: 'partial', metaphlan: false, humann: false },
  { feature: 'Workflow support (WDL/CWL)', micos: true, qiime2: false, metaphlan: false, humann: false },
  { feature: 'Containerization (Docker+Singularity)', micos: true, qiime2: 'partial', metaphlan: false, humann: false },
  { feature: 'Multi-omics support', micos: true, qiime2: 'partial', metaphlan: false, humann: false },
  { feature: 'CLI-first design', micos: true, qiime2: true, metaphlan: true, humann: true },
  { feature: 'Active development', micos: true, qiime2: true, metaphlan: true, humann: true },
]
