---
title: Deployment Modes
---

# Deployment Modes

MICOS-2024 can be deployed in several ways, but they are not equivalent. This page explains what each mode is trying to optimize.

## Mode 1, direct Python execution

Best for:

- local development,
- debugging,
- repositories where the Python environment is already controlled.

Strengths:

- shortest feedback loop,
- easiest way to inspect CLI behavior,
- direct alignment with `micos/cli.py`.

## Mode 2, shell-wrapper execution

Best for:

- backwards-compatible automation,
- teams migrating from older script-first workflows.

Important detail:

The wrapper scripts are now thin delegators, not independent pipeline engines. This is good. It reduces logic drift.

## Mode 3, workflow-driven execution

Best for:

- larger execution ecosystems,
- workflow-engine integration,
- explicit step-level orchestration.

Relevant assets:

- `steps/01_quality_control/fastqc.wdl`
- `steps/02_read_cleaning/kneaddata.wdl`
- `steps/03_taxonomic_profiling_kraken/kraken2.wdl`
- `steps/04_taxonomic_conversion_biom/kraken-biom.wdl`
- `steps/05_taxonomic_visualization_krona/krona.wdl`
- `steps/06_qiime2_analysis/*.wdl`

## Mode 4, container-backed execution

Best for:

- reproducible dependency stacks,
- collaborator handoff,
- isolating environment drift.

Relevant assets:

- `deploy/docker-compose.example.yml`
- `containers/singularity/*.def`

## Deployment matrix

| Need | Preferred mode |
| --- | --- |
| Fastest local iteration | Direct Python CLI |
| Compatibility with legacy shell workflows | Shell wrappers |
| Portable step graph | WDL assets |
| Reproducible environment package | Containers |

## Practical recommendation

For most contributors:

1. operate the stable CLI first,
2. use workflow assets when integrating with orchestration systems,
3. use containers to freeze environments,
4. use wrappers only when you need the legacy ergonomics.
