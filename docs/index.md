# MICOS-2024

<!-- 这个文件是主页入口，Material 主题会应用 main.html 中的英雄区域 -->

<div class="micos-lang-select" style="text-align: center; margin: 2rem 0;">

  <h2>🌐 选择语言 / Select Language</h2>

  <div class="micos-lang-cards" style="display: flex; justify-content: center; gap: 2rem; flex-wrap: wrap; margin: 2rem 0;">

  <a href="en/" class="micos-lang-card" style="
      display: block;
      width: 280px;
      padding: 2rem;
      border-radius: 12px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      text-decoration: none;
      transition: transform 0.3s, box-shadow 0.3s;
      box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
    ">
      <div style="font-size: 3rem; margin-bottom: 1rem;">🇺🇸</div>
      <h3 style="margin: 0 0 0.5rem; color: white;">English</h3>
      <p style="margin: 0; opacity: 0.9; font-size: 0.9rem;">
        Professional metagenomic analysis platform with comprehensive documentation
      </p>
      <div style="margin-top: 1rem; font-size: 0.85rem; opacity: 0.8;">
        → Get Started
      </div>
    </a>

  <a href="zh/" class="micos-lang-card" style="
      display: block;
      width: 280px;
      padding: 2rem;
      border-radius: 12px;
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
      color: white;
      text-decoration: none;
      transition: transform 0.3s, box-shadow 0.3s;
      box-shadow: 0 10px 25px rgba(245, 87, 108, 0.3);
    ">
      <div style="font-size: 3rem; margin-bottom: 1rem;">🇨🇳</div>
      <h3 style="margin: 0 0 0.5rem; color: white;">中文</h3>
      <p style="margin: 0; opacity: 0.9; font-size: 0.9rem;">
        专业宏基因组分析平台，提供完整的中文文档支持
      </p>
      <div style="margin-top: 1rem; font-size: 0.85rem; opacity: 0.8;">
        → 开始使用
      </div>
    </a>

  </div>

</div>

<style>
.micos-lang-card:hover {
  transform: translateY(-5px) !important;
  box-shadow: 0 20px 40px rgba(0,0,0,0.2) !important;
}
</style>

---

## 🚀 快速导航 / Quick Navigation

| 📚 Documentation | 🛠️ Installation | 🔬 Analysis | 💡 Support |
|:---:|:---:|:---:|:---:|
| [English Docs](en/) | [Install Guide](en/installation.md) | [Taxonomic](en/taxonomic-profiling.md) | [FAQ](en/faq.md) |
| [中文文档](zh/) | [安装指南](zh/installation.md) | [功能注释](zh/) | [常见问题](zh/faq.md) |

---

## ✨ 核心特性 / Key Features

<div class="micos-features" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin: 2rem 0;">

<div class="feature-card" style="padding: 1.5rem; border-radius: 8px; background: var(--md-code-bg-color); border: 1px solid var(--md-default-fg-color--lightest);">
  <h4>🧬 端到端分析 / End-to-End</h4>
  <p>从原始数据到可视化报告的完整流程</p>
</div>

<div class="feature-card" style="padding: 1.5rem; border-radius: 8px; background: var(--md-code-bg-color); border: 1px solid var(--md-default-fg-color--lightest);">
  <h4>🐳 容器化部署 / Containerized</h4>
  <p>Docker & Singularity 支持，确保可重现性</p>
</div>

<div class="feature-card" style="padding: 1.5rem; border-radius: 8px; background: var(--md-code-bg-color); border: 1px solid var(--md-default-fg-color--lightest);">
  <h4>⚡ 高性能 / High Performance</h4>
  <p>多线程加速，优化处理大规模数据</p>
</div>

<div class="feature-card" style="padding: 1.5rem; border-radius: 8px; background: var(--md-code-bg-color); border: 1px solid var(--md-default-fg-color--lightest);">
  <h4>📊 丰富可视化 / Rich Visualization</h4>
  <p>交互式报告，Krona 图表，多样性分析</p>
</div>

</div>

---

<p align="center">
  <a href="https://github.com/BGI-MICOS/MICOS-2024" class="md-button">
    <span class="twemoji">{% include ".icons/fontawesome/brands/github.svg" %}</span>
    GitHub 仓库
  </a>
  <a href="https://github.com/BGI-MICOS/MICOS-2024/issues" class="md-button md-button--secondary">
    <span class="twemoji">{% include ".icons/octicons/bug-16.svg" %}</span>
    问题反馈
  </a>
</p>
