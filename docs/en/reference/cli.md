---
title: CLI Reference
---

# CLI Reference

This reference is aligned to the **actual Click commands implemented in `micos/cli.py`**.

## Invocation pattern

```bash
python -m micos.cli [GLOBAL_OPTIONS] <COMMAND> [COMMAND_OPTIONS]
```

If installed via `pyproject.toml`, the entrypoint is also available as:

```bash
micos [GLOBAL_OPTIONS] <COMMAND> [COMMAND_OPTIONS]
```

## Global options

| Option | Description |
| --- | --- |
| `--config` | path to the analysis configuration file |
| `--log-file` | optional log output file |
| `--verbose` | enable debug logging |
| `--dry-run` | print planned work without executing it |
| `--version` | print version information |

## Stable commands

### `validate-config`

Validate the effective configuration before a run.

```bash
python -m micos.cli validate-config --config config/analysis.yaml
```

### `full-run`

Run the end-to-end stable pipeline surface.

```bash
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /db/kneaddata/human_genome \
  --kraken2-db /db/kraken2/standard
```

Key flags:

- `--skip-qc`
- `--skip-taxonomy`
- `--skip-functional`
- `--skip-diversity`

### `run quality-control`

```bash
python -m micos.cli run quality-control \
  --input-dir data/raw_input \
  --output-dir results/quality_control \
  --threads 8 \
  --kneaddata-db /db/kneaddata/human_genome
```

### `run taxonomic-profiling`

```bash
python -m micos.cli run taxonomic-profiling \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/taxonomic_profiling \
  --threads 16 \
  --kraken2-db /db/kraken2/standard \
  --confidence 0.1
```

### `run diversity-analysis`

```bash
python -m micos.cli run diversity-analysis \
  --input-biom results/taxonomic_profiling/feature-table.biom \
  --output-dir results/diversity_analysis
```

### `run functional-annotation`

```bash
python -m micos.cli run functional-annotation \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/functional_annotation \
  --threads 8
```

### `run summarize-results`

```bash
python -m micos.cli run summarize-results \
  --results-dir results \
  --output-file results/micos_summary_report.html
```

## Wrapper scripts

Two shell wrappers matter operationally:

| Wrapper | Role |
| --- | --- |
| `scripts/run_full_analysis.sh` | thin compatibility layer around `micos full-run` |
| `scripts/run_module.sh` | module wrapper that delegates to stable CLI commands |

The important architectural point is that these wrappers **delegate**. They are not documented here as separate pipeline implementations.

## Return codes

The CLI defines explicit exit codes in `micos/cli.py`:

| Code | Meaning |
| --- | --- |
| `0` | success |
| `1` | general error |
| `2` | invalid arguments |
| `3` | configuration error |
| `4` | missing dependencies |
| `5` | database error |
| `6` | I/O error |
| `130` | interrupted |

## Practical note

If you see older examples that imply additional global flags or broader command coverage, prefer this page. It is aligned to the current implemented surface, not to earlier documentation drift.
