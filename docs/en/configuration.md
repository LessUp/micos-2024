---
title: Configuration System
---

# Configuration System

MICOS-2024 ships with a broad template vocabulary. That is useful, but it also means configuration should be read in two layers:

1. **stable CLI-relevant configuration**, which directly feeds the current command surface,
2. **platform ambition configuration**, which captures a wider analytical vision represented across scripts and workflow assets.

## Configuration files

| File | Role | Notes |
| --- | --- | --- |
| `config/analysis.yaml.template` | project and analysis parameters | broadest template, includes advanced sections |
| `config/databases.yaml.template` | database locations | important for validation and runtime defaults |
| `config/samples.tsv.template` | sample metadata | used to standardize cohort input |

## Precedence model

From the current CLI implementation, the practical precedence is:

1. command-line flags,
2. `config/analysis.yaml`,
3. defaults carried by the code.

`validate-config` also inspects `config/databases.yaml` when present.

## Minimum viable configuration for the stable CLI

The current `full-run` command primarily needs:

- input directory,
- results directory,
- thread count,
- KneadData database path,
- Kraken2 database path.

Everything else is valuable context, but those fields are the real operational minimum for a working run.

## Recommended setup sequence

```bash
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv
python -m micos.cli validate-config --config config/analysis.yaml
```

## Example, minimal operational profile

```yaml
paths:
  input_dir: "data/raw_input"
  output_dir: "results"

resources:
  max_threads: 16

quality_control:
  kneaddata:
    threads: 8

taxonomic_profiling:
  kraken2:
    threads: 16
    confidence: 0.1
```

## Example, database template expectations

```yaml
quality_control:
  kneaddata:
    human_genome: "/db/kneaddata/human_genome"

taxonomy:
  kraken2:
    standard: "/db/kraken2/standard"
```

## Why the templates are broader than the CLI

The repository contains:

- stable CLI modules,
- workflow assets,
- specialist scripts for differential abundance, network analysis, phylogenetics, amplicon workflows, and metatranscriptomics.

The configuration templates reflect that wider platform horizon. The docs therefore explain them as a superset, not as proof that every section is equally stable in the main CLI path.

## Validation posture

Use validation early:

```bash
python -m micos.cli validate-config
```

This catches missing files, placeholder database paths, and structural issues before longer jobs begin.

## Configuration advice for contributors

If you add a new config field, decide which layer it belongs to:

- stable CLI contract,
- workflow asset support,
- specialist script support.

That decision should shape where it is documented and how prominently it appears.
