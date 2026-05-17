---
title: Project Structure
---

# Project Structure

This page maps the repository into responsibilities rather than just directories.

## Top-level map

| Path | Responsibility |
| --- | --- |
| `micos/` | stable Python package and CLI-facing orchestration |
| `config/` | configuration templates and sample metadata |
| `steps/` | WDL workflow assets for stage-level execution |
| `scripts/` | wrappers and specialist analyses beyond the narrow CLI core |
| `deploy/` | Docker Compose deployment example |
| `containers/` | Singularity definitions and environment assets |
| `tests/` | regression coverage for Python utilities and wrapper behavior |
| `docs/` | bilingual whitepaper-style documentation site |

## Stable core

```text
micos/
├── cli.py
├── full_run.py
├── quality_control.py
├── taxonomic_profiling.py
├── diversity_analysis.py
├── functional_annotation.py
└── summarize_results.py
```

This is the most important subtree for maintainability because it carries the stable command surface.

## Broader platform surface

```text
scripts/
├── run_full_analysis.sh
├── run_module.sh
├── download_databases.sh
├── verify_installation.sh
├── network_analysis.py
├── phylogenetic_analysis.py
├── amplicon_analysis.py
└── metatranscriptome_analysis.py
```

This subtree mixes compatibility helpers and advanced analyses. Treat it as valuable, but do not assume everything here carries the same stability contract as the Python CLI.

## Workflow assets

The `steps/` directory is where the platform expresses its step graph explicitly. This matters for reproducibility, portability, and systems-level reasoning.

## Documentation posture

The documentation site mirrors this structure:

- Academy explains the analytical model,
- Architecture explains repository layers,
- Guides explain how to operate,
- Reference explains exact interfaces,
- Research explains intellectual lineage and direction.
