---
title: Runtime Topology
---

# Runtime Topology

Runtime topology answers a practical question: **where does MICOS-2024 actually execute, and what hands work off to what?**

<ThemeAsset
  light="/illustrations/runtime-topology-light.svg"
  dark="/illustrations/runtime-topology-dark.svg"
  alt="Runtime topology illustration"
  caption="The project spans entry commands, orchestration modules, workflow assets, configuration templates, and extended analysis scripts."
/>

## Execution surfaces

### Stable CLI path

The cleanest operational path is:

```bash
micos full-run --input-dir data/raw_input --results-dir results
```

This route is backed directly by the Python package and is the most coherent entrypoint for new users and automation.

### Shell wrapper path

Two shell wrappers exist:

- `scripts/run_full_analysis.sh`
- `scripts/run_module.sh`

These scripts no longer own the pipeline logic. They delegate to the Python CLI, which is the right architectural direction because it reduces duplicated control flow.

### Workflow asset path

The `steps/` directory contains WDL stage files. These are not the same thing as the CLI, but they are important because they describe how the project can integrate with workflow engines and reproducible execution environments.

### Container path

`deploy/docker-compose.example.yml` and `containers/singularity/*.def` describe environment strategy. They matter because metagenomics pipelines often fail at the environment boundary rather than the algorithmic boundary.

## Topology by concern

| Concern | Main owner | Supporting owner |
| --- | --- | --- |
| Command UX | `micos/cli.py` | shell wrappers |
| Pipeline composition | `micos/full_run.py` | module files under `micos/` |
| Reproducible environments | `deploy/`, `containers/` | workflow assets |
| Config defaults and paths | `config/*.template` | CLI config loading |
| Extended analyses | `scripts/` | result directories |

## Failure modes worth understanding

### Configuration mismatch

A common failure mode in this kind of platform is mismatch between:

- analysis templates,
- database templates,
- command-line expectations.

MICOS-2024 already has a `validate-config` command, which is exactly the kind of boundary hardening a reviewer wants to see.

### Wrapper drift

When shell wrappers diverge from the Python core, user trust drops. The current repository trend is to shrink wrappers into thin delegators, which is healthier than letting them become an alternate implementation.

### Environment drift

When container, workflow, and direct CLI surfaces describe different realities, reproducibility suffers. The docs therefore keep these surfaces separate and call out where they are examples versus stable defaults.

## Recommended contributor posture

When adding new capability, decide first which topology tier it belongs to:

1. stable CLI contract,
2. environment/workflow support,
3. specialist script.

That decision should drive implementation and documentation together.
