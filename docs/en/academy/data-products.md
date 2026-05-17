---
title: Data Products and Interpretation
---

# Data Products and Interpretation

MICOS-2024 produces more than files. It produces analysis claims in different maturity bands. This page explains how to read the output directories as evidence products rather than opaque folders.

## Output families

| Output family | Typical location | What it represents | How to read it |
| --- | --- | --- | --- |
| Cleaned reads | `results/quality_control/` | Post-filter sequencing input | Trust boundary for all downstream analysis |
| Classification reports | `results/taxonomic_profiling/` | Per-sample taxonomic assignment summaries | Good for composition review and abundance ranking |
| BIOM tables | `results/taxonomic_profiling/feature-table.biom` | Structured abundance matrix | Feedstock for diversity workflows |
| Diversity artifacts | `results/diversity_analysis/` | Ecological comparisons | Good for cohort separation and richness summaries |
| Functional tables | `results/functional_annotation/` | Pathway or feature abundance views | Useful for pathway-level hypotheses |
| Summary reports | final HTML outputs | Review-friendly synthesis | Best entry point for stakeholders outside the codebase |

## Reading the results directory

```text
results/
├── quality_control/
├── taxonomic_profiling/
├── diversity_analysis/
├── functional_annotation/
└── micos_summary_report.html
```

This layout matters because it mirrors the pipeline itself. A reviewer can infer provenance: later directories depend on earlier ones.

## What counts as strong evidence

### Strongest current signals

- explicit CLI commands in `micos/cli.py`,
- result folder contracts documented by the CLI reference,
- shell wrapper tests under `tests/test_shell_wrappers.py`,
- configuration templates that align with those runtime surfaces.

### Weaker but still important signals

- advanced helper scripts in `scripts/`,
- broader template configuration for analyses that are not yet fully unified in the stable CLI,
- container and WDL assets that describe intended execution ecosystems.

## Interpreting with caution

Three mistakes are common in metagenomics documentation:

1. treating classification output as if it were contamination-proof,
2. treating diversity plots as self-explanatory,
3. treating every script in the repository as equally stable.

MICOS-2024 is more credible when those distinctions are explicit.

## Suggested review path for evaluators

If you are evaluating technical maturity:

1. inspect `taxonomic_profiling/` outputs first,
2. verify how they feed `feature-table.biom`,
3. then assess whether diversity and functional outputs are explained with enough provenance.

## Suggested review path for users

If you are operating the platform:

1. confirm QC outputs look reasonable,
2. check taxonomy reports for expected sample signal,
3. only then invest time in diversity or functional interpretation.
