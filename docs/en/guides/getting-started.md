---
title: Getting Started
---

# Getting Started

This guide is intentionally biased toward the **current stable operational path** of the repository. It does not pretend every script or template is equally mature.

## Choose an execution posture

| Posture | Best for | What you use |
| --- | --- | --- |
| Python CLI | local development, controlled environments | `micos` or `python -m micos.cli` |
| Shell wrappers | compatibility with earlier habits | `scripts/run_full_analysis.sh`, `scripts/run_module.sh` |
| Workflow and containers | reproducible environments, integration work | `steps/`, `deploy/`, `containers/` |

## Fastest credible path

### 1. Clone and install

```bash
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024
pip install -e ".[dev]"
```

If you prefer Conda or Mamba, the repository already provides `environment.yml`.

### 2. Prepare configuration

```bash
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv
```

Edit the copied files so that database paths point to real local resources.

### 3. Validate before running

```bash
python -m micos.cli validate-config --config config/analysis.yaml
```

This is the cheapest way to detect broken paths before a long run.

### 4. Run the stable full pipeline entrypoint

```bash
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_db
```

## If you want wrappers instead

The wrapper scripts are intentionally thin:

```bash
./scripts/run_full_analysis.sh \
  --config config/analysis.yaml \
  --input-dir data/raw_input \
  --results-dir results
```

Use wrappers when they fit existing automation, but prefer the CLI when documenting or debugging behavior.

## If you want containers instead

The repository includes a Docker Compose example:

```bash
docker compose -f deploy/docker-compose.example.yml config
docker compose -f deploy/docker-compose.example.yml up -d
```

Important nuance: this compose file is an environment example and readiness scaffold, not a magical all-in-one replacement for understanding the pipeline.

## First-run checklist

1. config files copied from templates
2. database paths resolved
3. `validate-config` succeeds
4. input directory exists
5. output directory is writable

## What to inspect after the first run

- `results/quality_control/`
- `results/taxonomic_profiling/`
- `results/diversity_analysis/`
- `results/functional_annotation/`

If those folders make sense, the rest of the platform becomes much easier to trust.

## Where to go next

- Read **Configuration System** to understand template structure and precedence.
- Read **Runtime Topology** if you need to integrate MICOS into a larger platform.
