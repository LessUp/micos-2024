# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelogs.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2025-04-16

### 🎉 Highlights

- **Professional Documentation**: Complete bilingual (English/Chinese) documentation overhaul
- **Enhanced User Experience**: Restructured docs with task-oriented organization
- **Comprehensive Guides**: New installation, configuration, and troubleshooting guides

### 🚀 New Features

#### Documentation
- Added bilingual documentation structure (`docs/en/` and `docs/zh/`)
- Created comprehensive installation guides for Docker and Conda
- Added detailed configuration reference with parameter explanations
- New diversity analysis documentation module
- Added API reference for CLI commands
- Created FAQ section with common questions and answers

#### Configuration
- Improved configuration validation with detailed error messages
- Added configuration templates with inline documentation
- Enhanced database path management with variable substitution

### 🔧 Improvements

#### Documentation Quality
- Restructured all documentation for better navigation
- Added cross-references between related documents
- Improved code examples with real-world parameters
- Added performance benchmarks and recommendations

#### User Experience
- Clearer installation instructions with platform-specific notes
- Better troubleshooting guides with diagnostic flowcharts
- Added quick start guides for common use cases

### 📚 Documentation

#### New Documents
- `docs/en/index.md` - English documentation portal
- `docs/zh/index.md` - Chinese documentation portal
- `docs/en/installation.md` - Detailed installation guide
- `docs/zh/installation.md` - 详细安装指南
- `docs/en/configuration.md` - Configuration reference
- `docs/zh/configuration.md` - 配置参考
- `docs/en/taxonomic-profiling.md` - Taxonomic profiling guide
- `docs/en/functional-profiling.md` - Functional profiling guide
- `docs/en/diversity-analysis.md` - Diversity analysis guide (new)
- `docs/en/troubleshooting.md` - Comprehensive troubleshooting
- `docs/zh/troubleshooting.md` - 综合故障排除
- `docs/en/faq.md` - Frequently asked questions
- `docs/zh/faq.md` - 常见问题
- `docs/en/api-reference.md` - CLI API reference

### 🙏 Contributors

- MICOS-2024 Team

---

## [1.0.0] - 2024-10-24

### 🎉 Highlights

- **First Stable Release**: Production-ready metagenomic analysis platform
- **Complete Pipeline**: End-to-end analysis from raw reads to reports
- **Competition Ready**: Optimized for Mammoth Cup 2024

### 🚀 New Features

#### Core Pipeline
- Quality control module (FastQC + KneadData)
- Taxonomic profiling (Kraken2 + Bracken + Krona)
- Diversity analysis (QIIME2 integration)
- Functional annotation (HUMAnN 3.x)
- HTML report generation

#### Infrastructure
- Docker containerization
- WDL workflow support (Cromwell)
- Singularity container definitions
- CLI interface with modular commands

#### Analysis Features
- Multi-threading support
- Configurable parameters
- Automatic result summarization
- Support for paired-end and single-end data

### 🔧 Technical Details

#### Dependencies
- Python 3.9+
- Kraken2 2.1.3
- QIIME2 2024.5
- HUMAnN 3.x
- KneadData 0.12.0

#### Supported Platforms
- Linux (Ubuntu 18.04+)
- macOS (11+)
- Docker/Singularity containers

### 📚 Documentation

- Initial README with basic usage
- User manual with installation instructions
- Configuration guide
- Module-specific documentation

---

## [0.9.0] - 2024-10-20

### 🎉 Highlights

- **Open Source Preparation**: Code cleanup and documentation
- **Repository Restructure**: Improved project organization
- **CI/CD Setup**: Automated testing and workflows

### 🔧 Improvements

#### Project Structure
- Restructured deployment configurations into `deploy/`
- Moved legacy scripts to `legacy/` directory
- Created `changelog/` directory for version tracking
- Reorganized container definitions

#### Documentation
- Added SECURITY.md
- Created configuration README
- Added contribution guidelines
- Initial troubleshooting guide

#### Development
- Set up GitHub Actions CI/CD
- Added pre-commit hooks
- Configured code coverage reporting

### ⚠️ Breaking Changes

- Moved `docker-compose.yml` to `deploy/docker-compose.example.yml`
- Removed deprecated `install.sh` script
- Restructured `steps/` directory (removed build directories)

### 🗑️ Removed

- Root-level `docker-compose.yml` (moved to `deploy/`)
- `install.sh` script (use Conda instead)
- `.augment-guidelines` file
- Build directories in `steps/02_read_cleaning/`

---

## Version History Summary

| Version | Date | Milestone |
|:---|:---|:---|
| 1.1.0 | 2025-04-16 | Professional Documentation Release |
| 1.0.0 | 2024-10-24 | First Stable Release |
| 0.9.0 | 2024-10-20 | Open Source Preparation |
| 0.1.0 | 2024-05-15 | Project Inception |

---

## [Unreleased]

### Planned Features

- [ ] Enhanced QC module with multiqc integration
- [ ] Additional visualization options
- [ ] Cloud deployment guides (AWS, GCP, Azure)
- [ ] Automated database updates
- [ ] Performance benchmarks for different hardware

### Known Issues

- None currently tracked

---

## Release Notes Template

When creating a new release:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### 🎉 Highlights
- Major feature or improvement

### 🚀 New Features
- New functionality added

### 🔧 Improvements
- Enhancements to existing features

### 🐛 Bug Fixes
- Fixed issues

### ⚠️ Breaking Changes
- Changes requiring user action

### 📚 Documentation
- Documentation updates

### 🙏 Contributors
- List of contributors
```

---

[1.1.0]: https://github.com/BGI-MICOS/MICOS-2024/releases/tag/v1.1.0
[1.0.0]: https://github.com/BGI-MICOS/MICOS-2024/releases/tag/v1.0.0
[0.9.0]: https://github.com/BGI-MICOS/MICOS-2024/releases/tag/v0.9.0
