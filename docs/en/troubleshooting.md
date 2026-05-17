---
title: Troubleshooting
---

# Troubleshooting

## `validate-config` fails immediately

Most often this means one of the following:

- template placeholders were not replaced,
- `config/databases.yaml` points to nonexistent paths,
- `config/analysis.yaml` and database config disagree.

Run:

```bash
python -m micos.cli validate-config --config config/analysis.yaml
```

## `full-run` complains about missing database paths

The current stable CLI expects explicit database resolution for:

- KneadData
- Kraken2

Provide them through config defaults or direct flags:

```bash
python -m micos.cli full-run \
  --kneaddata-db /db/kneaddata/human_genome \
  --kraken2-db /db/kraken2/standard
```

## Wrapper script behavior differs from what I expected

Re-check the wrapper intent. The wrapper scripts are thin compatibility layers now. If something looks surprising, inspect the CLI command they delegate to before debugging the shell script itself.

## Container setup looks healthy, but the run still fails

That usually means environment readiness and pipeline correctness are being conflated. The Compose example helps prepare services and mounts, but it does not replace configuration validation or command-level verification.

## The docs mention advanced analyses I cannot find in the main CLI

Those capabilities may live in `scripts/` instead of the stable CLI surface. Use the **Project Structure** and **CLI Reference** pages together to determine which layer a feature belongs to.
