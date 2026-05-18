---
layout: home
---

<script setup>
const heroActions = [
  { text: '进入学院', link: './academy/pipeline-foundations', theme: 'brand' },
  { text: '查看架构', link: './architecture/system-overview', theme: 'alt' },
  { text: '查看 GitHub 源码', link: 'https://github.com/LessUp/micos-2024', theme: 'ghost', external: true },
]

const heroPills = [
  'Python 包 + Click CLI',
  'WDL 工作流资产',
  '容器化执行能力',
  '中英双语技术白皮书',
]

const metrics = [
  {
    label: '主运行面',
    value: 'CLI 优先编排',
    detail: '稳定入口集中在 Click CLI，Shell 脚本保留为兼容包装层，而不是第二套事实标准。',
  },
  {
    label: '工作流姿态',
    value: 'WDL + 容器',
    detail: '仓库同时持有步骤级 WDL、Singularity 定义和 Docker Compose 示例，强调可重现环境。',
  },
  {
    label: '阅读目标',
    value: '面试官级可解释性',
    detail: '本页不是功能海报，而是让评审快速判断项目边界、工程组织和科研依据的入口。',
  },
]

const stages = [
  {
    eyebrow: '阶段 01',
    title: '质量控制与宿主去除',
    summary: 'FastQC 与 KneadData 构成入口守门链路，为后续分析提供更干净的读段。',
    bullets: ['原始 FASTQ 摄取', '过滤与修剪', '宿主读段清除'],
  },
  {
    eyebrow: '阶段 02',
    title: '物种分类证据生成',
    summary: 'Kraken2、kraken-biom 与 Krona 将清洗后的读段转换为可追溯的分类学证据。',
    href: './analysis/taxonomic-profiling',
    bullets: ['Kraken2 报告', 'BIOM 转换', 'Krona 交互视图'],
  },
  {
    eyebrow: '阶段 03',
    title: '多样性解释',
    summary: 'QIIME2 与元数据联动把丰度表转化为生态学层面的样本差异与群落结构解释。',
    href: './analysis/diversity-analysis',
    bullets: ['Alpha 多样性', 'Beta 多样性', '排序分析输出'],
  },
  {
    eyebrow: '阶段 04',
    title: '功能读出与结果汇总',
    summary: '功能注释与汇总模块将通路、功能表和最终报告串成可交付结果。',
    href: './analysis/functional-profiling',
    bullets: ['功能矩阵', '辅助脚本', 'HTML 面向汇总'],
  },
]

const references = [
  {
    authors: 'Wood DE, Lu J, Langmead B',
    title: 'Improved metagenomic analysis with Kraken 2',
    venue: 'Genome Biology',
    year: '2019',
    link: 'https://doi.org/10.1186/s13059-019-1891-0',
  },
  {
    authors: 'Bolyen E, Rideout JR, Dillon MR, et al.',
    title: 'Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2',
    venue: 'Nature Biotechnology',
    year: '2019',
    link: 'https://doi.org/10.1038/s41587-019-0209-9',
  },
  {
    authors: 'McMurdie PJ, Holmes S',
    title: 'phyloseq: an R package for reproducible interactive analysis and graphics of microbiome census data',
    venue: 'PLoS ONE',
    year: '2013',
    link: 'https://doi.org/10.1371/journal.pone.0061217',
  },
]
</script>

<div class="micos-home">
  <SiteHero
    eyebrow="开源宏基因组技术白皮书"
    title="MICOS-2024"
    lede="这不是传统意义上的命令说明书，而是一份面向严苛读者的项目导读：解释仓库如何把原始测序输入转化为可重现、可审查、可讨论的微生物组分析结果。"
    caption="站点被重构为评审导向的技术白皮书，用来回答两个关键问题：项目究竟做了什么，以及它为什么值得被认真看待。"
    :pills="heroPills"
    :actions="heroActions"
  >
    <div class="micos-rail-card">
      <h3>本站强调什么</h3>
      <p>仓库真实能力、运行边界、架构意图，以及其背后的科研工具谱系。</p>
    </div>
    <div class="micos-rail-card">
      <h3>本站刻意呈现什么</h3>
      <p>稳定 CLI 主链路、扩展型工作流资产，以及“目标蓝图”与“当前实现面”之间的差异。</p>
    </div>
    <div class="micos-rail-card">
      <h3>推荐阅读路径</h3>
      <p>先读学院，再看架构，随后按你的角色进入指南或研究部分，最后再回到具体模块页。</p>
    </div>
  </SiteHero>

  <MetricGrid :items="metrics" />

  <SiteSection
    eyebrow="流程叙事"
    title="当执行链路被看见，项目才更值得信任。"
    lede="MICOS-2024 最适合被理解为一个四段式证据流程：输入清洁、分类学证据、多样性解释，以及面向报告的最终产物。"
  >
    <div class="micos-grid micos-grid--2">
      <figure class="micos-theme-asset">
        <PipelineOverview />
        <figcaption>使用 Vue SVG 组件实现零延迟主题切换，单一源维护。</figcaption>
      </figure>
      <div class="micos-stack">
        <div class="micos-callout success">
          <strong>阅读信号</strong><br>
          我们把流程写成“证据变换链”，而不是单纯罗列工具名字。
        </div>
        <div class="micos-callout">
          <strong>工程信号</strong><br>
          仓库同时存在稳定 CLI 入口与更宽泛的工作流资产，文档会明确区分，而不是混成一层。
        </div>
        <div class="micos-callout warning">
          <strong>运行信号</strong><br>
          多个高级分析仍位于 <code>scripts/</code> 中，属于专家扩展面，而非与主 CLI 相同稳定级别的接口承诺。
        </div>
      </div>
    </div>

    <FlowStageGrid :stages="stages" />
  </SiteSection>

  <SiteSection
    eyebrow="系统剖面"
    title="不是只有页面，更要能映射回仓库层次。"
    lede="一个成熟的文档站应该让读者顺着页面直接定位到代码：入口命令、Python 模块、工作流定义、配置模板、容器资产以及验证面。"
  >
    <div class="micos-grid micos-grid--2">
      <figure class="micos-theme-asset">
        <RuntimeTopology />
        <figcaption>项目的真实执行面分布在 CLI、Python 编排、工作流定义与扩展脚本之间。</figcaption>
      </figure>
      <div class="micos-panel-list">
        <div class="micos-panel">
          <h3>稳定核心</h3>
          <p><code>micos/cli.py</code> 提供 <code>full-run</code>、<code>validate-config</code> 以及质量控制、分类、多样性、功能注释、结果汇总等命令。</p>
        </div>
        <div class="micos-panel">
          <h3>工作流资产</h3>
          <p><code>steps/</code>、<code>deploy/</code> 与 <code>containers/</code> 把项目扩展到可重现执行环境和步骤级编排模式。</p>
        </div>
        <div class="micos-panel">
          <h3>研究姿态</h3>
          <p>MICOS-2024 的价值不在于重新发明底层算法，而在于把已有微生物组工具整合为一套更完整的分析体验，这一点在研究章节中被正面呈现。</p>
        </div>
      </div>
    </div>
  </SiteSection>

  <SiteSection
    eyebrow="执行链速记"
    title="一张图理解仓库的抽象分层"
    lede="项目跨越多个抽象层级，文档必须帮助读者判断每个职责究竟落在哪一层。"
  >

```mermaid
flowchart LR
    A[用户或自动化系统] --> B[micos CLI]
    B --> C[micos Python 模块]
    B --> D[scripts/run_full_analysis.sh]
    B --> E[scripts/run_module.sh]
    C --> F[results/]
    C --> G[config/*.template]
    H[steps/*.wdl] --> I[工作流执行环境]
    J[deploy/docker-compose.example.yml] --> I
    K[containers/singularity/*.def] --> I
```

  </SiteSection>

  <SiteSection
    eyebrow="研究基底"
    title="项目的可信度，部分来自它继承了什么。"
    lede="MICOS-2024 不是无中生有，它站在成熟微生物组工具之上进行系统整合。把这种谱系写清楚，本身就是专业度的一部分。"
  >
    <ReferenceList :items="references" />
  </SiteSection>
</div>
