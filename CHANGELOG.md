# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelogs.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nothing yet

### Changed
- Nothing yet

### Fixed
- Nothing yet

---

## [1.0.0] - 2024-10-24

### Added
- Initial release for Mammoth Cup 2024 competition
- Complete metagenomic analysis pipeline
- Quality control module with KneadData and FastQC
- Taxonomic profiling with Kraken2 and Krona visualization
- Diversity analysis using QIIME2
- Functional annotation with HUMAnN
- WDL workflow support for reproducible analysis
- Docker containerization for easy deployment
- CLI interface with modular commands
- Comprehensive documentation

### Core Features
| Module | Tools | Description |
|:---|:---|:---|
| Quality Control | FastQC, KneadData | Host DNA removal and quality filtering |
| Taxonomic Profiling | Kraken2, Krona | Fast taxonomic classification and visualization |
| Diversity Analysis | QIIME2 | Alpha/Beta diversity metrics |
| Functional Annotation | HUMAnN | Gene family and pathway analysis |

---

## [0.9.0] - 2024-10-20

### Added
- Open source refactoring and cleanup
- New directory structure: `deploy/`, `containers/singularity/`
- Docker Compose example deployment configuration
- Security policy document (`SECURITY.md`)
- Configuration README for unified setup instructions

### Changed
- Migrated legacy scripts to `legacy/` directory
- Restructured container definitions
- Updated CI/CD workflows
- Improved code coverage configuration

### Removed
- Root level `docker-compose.yml` (moved to `deploy/`)
- Deprecated `install.sh` script
- Legacy build directories in `steps/`

---

## Version History Summary

| Version | Date | Milestone |
|:---|:---|:---|
| 1.0.0 | 2024-10-24 | Mammoth Cup 2024 Final Release |
| 0.9.0 | 2024-10-20 | Open Source Preparation |
| 0.1.0 | 2024-05-15 | Project Inception |

---

[Unreleased]: https://github.com/BGI-MICOS/MICOS-2024/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/BGI-MICOS/MICOS-2024/releases/tag/v1.0.0
[0.9.0]: https://github.com/BGI-MICOS/MICOS-2024/compare/v0.1.0...v0.9.0
