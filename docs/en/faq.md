---
title: FAQ
---

# FAQ

## Is MICOS-2024 a workflow engine?

No. It is better described as a metagenomics platform shell with:

- a stable Python CLI,
- workflow assets under `steps/`,
- environment assets under `deploy/` and `containers/`.

## Is every script in `scripts/` part of the stable public interface?

No. Several scripts are specialist tools or expansion surfaces. The CLI reference documents the narrower stable command contract.

## Should I use the shell wrappers or the Python CLI?

Prefer the Python CLI for new automation and documentation. Use the wrappers when maintaining compatibility with existing shell-first workflows.

## Why are the configuration templates broader than the CLI surface?

Because the repository ambition is broader than the currently unified runtime surface. The templates capture that broader platform direction.

## Does the Docker Compose file run the full analysis pipeline?

It provides a reproducible environment scaffold and service example. It should not be read as a guarantee that every pipeline concern is fully automated through Compose alone.

## Where should a reviewer start?

Start with the homepage, then:

1. `Academy / Pipeline Foundations`
2. `Architecture / System Overview`
3. `Reference / CLI Reference`

That path gives the clearest signal about maturity and boundaries.
