# 2024-10-20 开源重构与清理

> 本次重构为 MICOS-2024 参赛作品的开源发布做准备，优化项目结构，清理冗余文件。

## 变更概览

| 类别 | 变更数量 |
|:---|:---:|
| 目录调整 | 5 |
| 新增文件 | 4 |
| 删除文件 | 7 |
| 配置更新 | 3 |

---

## 目录结构变更

### 新增目录

| 目录 | 说明 |
|:---|:---|
| `deploy/` | 部署配置文件 |
| `legacy/` | 历史脚本归档 |
| `changelog/` | 更新日志目录 |
| `containers/singularity/` | Singularity 容器定义（原 `containers/sif_build/`） |

### 目录重命名

| 原路径 | 新路径 |
|:---|:---|
| `containers/sif_build/` | `containers/singularity/` |
| `scripts/legacy_scripts/` | `legacy/` |

---

## 新增文件

### 部署配置

```
deploy/
└── docker-compose.example.yml    # Docker Compose 示例配置
```

**说明**：提供核心分析服务的容器编排示例，包含 FastQC、KneadData、Kraken2、Krona、QIIME2 等服务。

### 文档与策略

| 文件 | 说明 |
|:---|:---|
| `SECURITY.md` | 安全策略文档 |
| `config/README.md` | 配置文件统一说明 |

### CI 配置更新

| 文件 | 变更 |
|:---|:---|
| `.github/workflows/ci.yml` | 优化 CI 流程 |

---

## 删除文件

### 根目录清理

| 文件 | 原因 |
|:---|:---|
| `docker-compose.yml` | 移至 `deploy/` 目录 |
| `install.sh` | 使用 Conda/environment.yml 替代 |
| `config.yaml.example` | 使用 `config/` 目录模板替代 |
| `.augment-guidelines` | 不再需要 |

### 步骤目录清理

| 路径 | 原因 |
|:---|:---|
| `steps/02_read_cleaning/build-1/` | 冗余构建目录 |
| `steps/02_read_cleaning/build-2/` | 冗余构建目录 |
| `steps/02_read_cleaning/build-3/` | 冗余构建目录 |

---

## 配置更新

### Coverage 配置

```yaml
# pyproject.toml
[tool.coverage.run]
source = ["micos"]  # 指向核心包
```

### CI 流程

- 移除 Sphinx 文档构建步骤
- Docker 任务改为仅校验示例 Compose 配置

---

## 影响范围

### 用户影响

- **安装方式**：推荐使用 `environment.yml` 或 Docker
- **配置方式**：使用 `config/` 目录下的模板文件

### 开发者影响

- **脚本位置**：历史脚本移至 `legacy/`
- **容器定义**：Singularity 定义移至 `containers/singularity/`

---

## 迁移指南

### 从旧版本迁移

```bash
# 1. 更新代码
git pull origin main

# 2. 更新配置文件位置
cp deploy/docker-compose.example.yml docker-compose.yml  # 如需本地 Compose

# 3. 使用新的配置模板
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
```

---

## 后续计划

- [ ] 完善单元测试覆盖率
- [ ] 添加更多使用示例
- [ ] 优化文档结构
- [ ] 添加性能基准测试

---

*变更时间：2024-10-20*
*变更人员：MICOS-2024 Team*
