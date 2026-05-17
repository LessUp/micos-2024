---
layout: home
---

<script setup>
const heroActions = [
  { text: 'Start reading', link: './academy/pipeline-foundations', theme: 'brand' },
  { text: 'Inspect architecture', link: './architecture/system-overview', theme: 'alt' },
  { text: 'View source on GitHub', link: 'https://github.com/LessUp/micos-2024', theme: 'ghost', external: true },
]

const heroPills = [
  'Python package + Click CLI',
  'WDL workflow assets',
  'Container-aware execution',
  'Bilingual technical whitepaper',
]

const metrics = [
  {
    label: 'Primary runtime',
    value: 'CLI-first orchestration',
    detail: 'The stable surface is a Click CLI backed by Python modules, with shell wrappers kept as compatibility layers.',
  },
  {
    label: 'Workflow posture',
    value: 'WDL + containers',
    detail: 'The repository carries step-level WDL assets, Singularity definitions, and a Docker Compose example for reproducible environments.',
  },
  {
    label: 'Reader outcome',
    value: 'Interview-grade clarity',
    detail: 'This site is organized to let a reviewer understand scientific scope, software boundaries, and operational trade-offs quickly.',
  },
]

const stages = [
  {
    eyebrow: 'Stage 01',
    title: 'Quality control and host depletion',
    summary: 'FastQC and KneadData frame the entry gate, producing cleaner reads before downstream interpretation begins.',
    bullets: ['Raw FASTQ intake', 'Filtering and trimming', 'Host read removal'],
  },
  {
    eyebrow: 'Stage 02',
    title: 'Taxonomic profiling',
    summary: 'Kraken2, kraken-biom, and Krona turn cleaned reads into ranked taxonomic evidence and navigable summaries.',
    href: './analysis/taxonomic-profiling',
    bullets: ['Kraken2 reports', 'BIOM conversion', 'Interactive Krona views'],
  },
  {
    eyebrow: 'Stage 03',
    title: 'Diversity interpretation',
    summary: 'QIIME2 and associated metadata joins convert abundance tables into ecological signals and cohort comparisons.',
    href: './analysis/diversity-analysis',
    bullets: ['Alpha diversity', 'Beta diversity', 'Ordination-ready outputs'],
  },
  {
    eyebrow: 'Stage 04',
    title: 'Functional readout and reporting',
    summary: 'Functional profiling and summarization consolidate pathways, annotations, and report-facing deliverables.',
    href: './analysis/functional-profiling',
    bullets: ['Functional tables', 'Auxiliary scripts', 'HTML-oriented summaries'],
  },
]

const references = [
  {
    authors: 'Wood DE, Lu J, Langmead B',
    title: 'Improved metagenomic analysis with Kraken 2',
    venue: 'Genome Biology',
    year: '2019',
    link: 'https://doi.org/10.1186/s13059-019-1891-0',
  },
  {
    authors: 'Bolyen E, Rideout JR, Dillon MR, et al.',
    title: 'Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2',
    venue: 'Nature Biotechnology',
    year: '2019',
    link: 'https://doi.org/10.1038/s41587-019-0209-9',
  },
  {
    authors: 'McMurdie PJ, Holmes S',
    title: 'phyloseq: an R package for reproducible interactive analysis and graphics of microbiome census data',
    venue: 'PLoS ONE',
    year: '2013',
    link: 'https://doi.org/10.1371/journal.pone.0061217',
  },
]
</script>

<div class="micos-home">
  <SiteHero
    eyebrow="Open-source metagenomics whitepaper"
    title="MICOS-2024"
    lede="A documentation experience rebuilt as a technical brief: not a checklist of commands, but a guided map of how this repository turns raw sequencing input into reproducible, reviewable microbiome analysis outputs."
    caption="The site is optimized for demanding readers: interviewers, maintainers, and senior open-source engineers evaluating whether the project is coherent beyond its README."
    :pills="heroPills"
    :actions="heroActions"
  >
    <div class="micos-rail-card">
      <h3>What this site emphasizes</h3>
      <p>Repository truth, execution boundaries, architecture intent, and research lineage.</p>
    </div>
    <div class="micos-rail-card">
      <h3>What is deliberately surfaced</h3>
      <p>The current stable CLI core, the broader workflow assets, and the gap between ambition and implemented runtime surface.</p>
    </div>
    <div class="micos-rail-card">
      <h3>How to read it</h3>
      <p>Start in Academy, then move into Architecture, then drop into Guides or Research depending on whether you are operating or auditing.</p>
    </div>
  </SiteHero>

  <MetricGrid :items="metrics" />

  <SiteSection
    eyebrow="Pipeline narrative"
    title="The platform is easier to trust when the execution chain is visible."
    lede="MICOS-2024 is best understood as an analysis story with four checkpoints: input hygiene, taxonomic evidence, ecological interpretation, and report-facing outputs."
  >
    <div class="micos-grid micos-grid--2">
      <ThemeAsset
        light="/illustrations/pipeline-overview-light.svg"
        dark="/illustrations/pipeline-overview-dark.svg"
        alt="Pipeline overview illustration"
        caption="Theme-aware illustration for the full data path, designed to stay readable in both light and dark modes."
      />
      <div class="micos-stack">
        <div class="micos-callout success">
          <strong>Reader signal</strong><br>
          The pipeline is presented as a sequence of evidence transformations, not just a list of tools.
        </div>
        <div class="micos-callout">
          <strong>Engineering signal</strong><br>
          The repository carries both stable CLI entrypoints and broader workflow assets. This site distinguishes them instead of flattening everything into one surface.
        </div>
        <div class="micos-callout warning">
          <strong>Operational signal</strong><br>
          Several advanced analyses live under <code>scripts/</code> as specialist tools. They matter, but they are not described as part of the same stability contract as the CLI core.
        </div>
      </div>
    </div>

    <FlowStageGrid :stages="stages" />
  </SiteSection>

  <SiteSection
    eyebrow="System anatomy"
    title="Repository layers, not just pages"
    lede="A reviewer should be able to map the docs to the codebase: entry commands, Python modules, workflow definitions, configuration templates, containers, and validation surfaces."
  >
    <div class="micos-grid micos-grid--2">
      <ThemeAsset
        light="/illustrations/runtime-topology-light.svg"
        dark="/illustrations/runtime-topology-dark.svg"
        alt="Runtime topology illustration"
        caption="The project operates across a CLI layer, Python orchestration modules, workflow assets, and power-user scripts."
      />
      <div class="micos-panel-list">
        <div class="micos-panel">
          <h3>Stable core</h3>
          <p><code>micos/cli.py</code> exposes <code>full-run</code>, <code>validate-config</code>, and module-level commands for quality control, taxonomy, diversity, functional annotation, and summarization.</p>
        </div>
        <div class="micos-panel">
          <h3>Workflow assets</h3>
          <p><code>steps/</code>, <code>deploy/</code>, and <code>containers/</code> extend the platform into reproducible environments and step-level orchestration patterns.</p>
        </div>
        <div class="micos-panel">
          <h3>Research posture</h3>
          <p>The project benefits from established microbiome tooling, then attempts to wrap it into a more coherent end-to-end suite. That lineage is explicit in the Research section.</p>
        </div>
      </div>
    </div>
  </SiteSection>

  <SiteSection
    eyebrow="Execution chain"
    title="A quick mental model"
    lede="The runtime stack spans more than one abstraction level. This diagram makes the split explicit so contributors and reviewers can reason about where each concern lives."
  >

```mermaid
flowchart LR
    A[User or automation] --> B[micos CLI]
    B --> C[micos Python modules]
    B --> D[scripts/run_full_analysis.sh]
    B --> E[scripts/run_module.sh]
    C --> F[results/]
    C --> G[config/*.template]
    H[steps/*.wdl] --> I[Workflow execution environments]
    J[deploy/docker-compose.example.yml] --> I
    K[containers/singularity/*.def] --> I
```

  </SiteSection>

  <SiteSection
    eyebrow="Research grounding"
    title="The project inherits credibility from the ecosystem it assembles."
    lede="MICOS-2024 is not a blank-slate invention. It is an integration effort sitting on top of well-cited microbiome tooling. That is a strength, and this site treats it as one."
  >
    <ReferenceList :items="references" />
  </SiteSection>
</div>
