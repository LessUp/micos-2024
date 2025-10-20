# 2025-10-20 开源重构与清理

- 目录重构：新增 `deploy/`、`legacy/`、`changelog/`，`containers/sif_build` 重命名为 `containers/singularity/`。
- 脚本归档：`scripts/legacy_scripts/` 迁移至根目录 `legacy/`。
- 部署示例：新增 `deploy/docker-compose.example.yml`，仅保留核心分析服务。
- 文档与策略：新增 `SECURITY.md`，在 `config/README.md` 统一配置说明。
- CI 与配置：修正 coverage 指向 `micos/`，移除 Sphinx 文档构建，Docker 任务改为仅校验示例 Compose。
- 已删除：根 `docker-compose.yml`、`install.sh`、`config.yaml.example`、`.augment-guidelines`，以及 `steps/02_read_cleaning/` 下的 `build-1/`、`build-2/`、`build-3/`。
