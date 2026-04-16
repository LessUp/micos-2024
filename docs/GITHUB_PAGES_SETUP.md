# GitHub Pages 设置指南

本文档说明如何启用和配置 MICOS-2024 的强大 GitHub Pages 站点。

---

## 🚀 快速启用步骤

### 1. 启用 GitHub Pages

1. 进入仓库 **Settings** → **Pages**
2. **Source** 选择 `Deploy from a branch`
3. **Branch** 选择 `gh-pages` → `/ (root)`
4. 点击 **Save**

### 2. 配置工作流权限

1. 进入 **Settings** → **Actions** → **General**
2. **Workflow permissions** 选择 `Read and write permissions`
3. 勾选 `Allow GitHub Actions to create and approve pull requests`

---

## 📁 文件结构

```
.
├── mkdocs.yml                    # MkDocs 主配置
├── requirements-docs.txt          # 文档依赖
├── .github/workflows/
│   ├── pages.yml                 # 主部署工作流
│   ├── deploy-version.yml        # 版本部署
│   └── gh-pages-cleanup.yml      # 定期清理
└── docs/
    ├── index.md                  # 多语言入口
    ├── overrides/                # 主题覆盖
    │   ├── main.html             # 主模板
    │   ├── home.html             # 着陆页
    │   ├── 404.html              # 错误页面
    │   ├── stylesheets/extra.css # 自定义样式
    │   └── javascripts/extra.js  # 自定义脚本
    └── includes/
        └── abbreviations.md      # 缩写定义
```

---

## 🔧 本地预览

```bash
# 1. 安装依赖
pip install -r requirements-docs.txt

# 2. 启动开发服务器
mkdocs serve

# 3. 访问 http://127.0.0.1:8000
```

---

## 🏷️ 版本管理

使用 `mike` 管理文档版本：

```bash
# 部署新版本
mike deploy 1.1.0

# 部署并添加别名
mike deploy 1.1.0 stable

# 设置默认版本
mike set-default stable

# 删除旧版本
mike delete 1.0.0

# 列出所有版本
mike list
```

---

## 🎨 自定义配置

### 修改颜色主题

编辑 `mkdocs.yml`：

```yaml
palette:
  - media: "(prefers-color-scheme: light)"
    scheme: default
    primary: indigo    # 修改主色
    accent: pink       # 修改强调色
```

可用颜色：`red`, `pink`, `purple`, `deep-purple`, `indigo`, `blue`, `light-blue`, `cyan`, `teal`, `green`, `light-green`, `lime`, `yellow`, `amber`, `orange`, `deep-orange`, `brown`, `grey`, `blue-grey`, `white`, `black`

### 添加新页面

```yaml
nav:
  - New Section:
    - Page Title: path/to/file.md
```

### 修改社交链接

```yaml
extra:
  social:
    - icon: fontawesome/brands/twitter
      link: https://twitter.com/your_account
```

---

## 📊 特性列表

| 特性 | 状态 | 说明 |
|:---|:---:|:---|
| 即时导航 | ✅ | 无刷新页面切换 |
| 深色/浅色模式 | ✅ | 自动跟随系统 |
| 搜索 | ✅ | 全文搜索 + 建议 |
| 版本管理 | ✅ | mike 支持多版本 |
| 多语言 | ✅ | 中英文双语支持 |
| 社交卡片 | ✅ | 自动生成 Open Graph |
| 代码复制 | ✅ | 一键复制代码块 |
| 图片放大 | ✅ | 点击查看大图 |
| 打印优化 | ✅ | 打印友好样式 |
| 响应式设计 | ✅ | 移动端适配 |

---

## 🔗 相关链接

- [MkDocs 官方文档](https://www.mkdocs.org/)
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- [Mike 版本管理](https://github.com/jimporter/mike)

---

## 💡 故障排除

### 部署失败

检查 Actions 日志，常见问题：
- 工作流权限不足 → 按上面步骤 2 配置
- 依赖安装失败 → 检查 `requirements-docs.txt`

### 页面不更新

```bash
# 清除 gh-pages 缓存
mike delete --all
# 重新部署
mike deploy 1.1.0 stable --push
```

### 本地预览图片不显示

这是正常现象，部署到 GitHub Pages 后会正常显示。
