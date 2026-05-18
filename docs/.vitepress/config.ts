import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'
import llmstxt from 'vitepress-plugin-llms'

const rawBase = process.env.VITEPRESS_BASE
const base = rawBase
  ? rawBase.startsWith('/')
    ? rawBase.endsWith('/') ? rawBase : `${rawBase}/`
    : `/${rawBase}/`
  : '/'

const sharedThemeConfig = {
  logo: {
    light: '/brand/logo-light.svg',
    dark: '/brand/logo-dark.svg',
    alt: 'MICOS-2024',
  },
  outline: [2, 3] as [number, number],
  search: { provider: 'local' as const },
  socialLinks: [
    { icon: 'github', link: 'https://github.com/LessUp/micos-2024' },
  ],
}

export default withMermaid(defineConfig({
  base,
  title: 'MICOS-2024',
  description: 'A bilingual technical whitepaper for the MICOS-2024 metagenomic analysis platform.',
  cleanUrls: true,
  lastUpdated: true,

  // Mermaid 主题适配配置
  mermaid: {
    theme: 'base',
    themeVariables: {
      primaryColor: '#4f6ef7',
      primaryTextColor: '#1a1a2e',
      primaryBorderColor: '#4f6ef7',
      lineColor: '#5a6c7d',
      secondaryColor: '#f0f4ff',
      tertiaryColor: '#e8f0fe',
      noteBkgColor: '#fff9e6',
      noteTextColor: '#1a1a2e',
      noteBorderColor: '#ffc107',
      sequenceNumberColor: '#4f6ef7',
      actorBkg: '#f0f4ff',
      actorBorder: '#4f6ef7',
      actorTextColor: '#1a1a2e',
      actorLineColor: '#5a6c7d',
    },
  },

  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: `${base}brand/favicon.svg` }],
    ['meta', { name: 'theme-color', content: '#0f766e' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'MICOS-2024 Whitepaper' }],
    ['meta', { property: 'og:description', content: 'An architecture-focused documentation site for a metagenomic analysis platform.' }],
    ['meta', { property: 'og:site_name', content: 'MICOS-2024' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
  ],

  locales: {
    zh: {
      label: '简体中文',
      lang: 'zh-CN',
      link: '/zh/',
      title: 'MICOS-2024',
      description: '面向高级开发者与评审者的宏基因组分析平台技术白皮书',
      themeConfig: {
        ...sharedThemeConfig,
        nav: [
          { text: '导读', link: '/zh/' },
          { text: '学院', link: '/zh/academy/pipeline-foundations', activeMatch: '/zh/academy/' },
          { text: '架构', link: '/zh/architecture/system-overview', activeMatch: '/zh/architecture/' },
          { text: '算法', link: '/zh/algorithms/quality-control', activeMatch: '/zh/algorithms/' },
          { text: '指南', link: '/zh/guides/getting-started', activeMatch: '/zh/guides/|/zh/configuration|/zh/faq|/zh/troubleshooting' },
          { text: '参考', link: '/zh/reference/cli', activeMatch: '/zh/reference/' },
          { text: '研究', link: '/zh/research/citations', activeMatch: '/zh/research/' },
        ],
        sidebar: {
          '/zh/academy/': [
            {
              text: '学院',
              items: [
                { text: '流程基础', link: '/zh/academy/pipeline-foundations' },
                { text: '数据产物与解释', link: '/zh/academy/data-products' },
                { text: '算法深潜', link: '/zh/academy/algorithm-deep-dive' },
              ],
            },
            {
              text: '模块深潜',
              items: [
                { text: '物种分类分析', link: '/zh/analysis/taxonomic-profiling' },
                { text: '功能注释分析', link: '/zh/analysis/functional-profiling' },
                { text: '多样性分析', link: '/zh/analysis/diversity-analysis' },
              ],
            },
          ],
          '/zh/architecture/': [
            {
              text: '架构',
              items: [
                { text: '系统总览', link: '/zh/architecture/system-overview' },
                { text: '运行时拓扑', link: '/zh/architecture/runtime-topology' },
                { text: '模块设计原理', link: '/zh/architecture/module-design' },
                { text: '测试策略', link: '/zh/architecture/testing-strategy' },
              ],
            },
          ],
          '/zh/algorithms/': [
            {
              text: '算法',
              items: [
                { text: '质量控制算法', link: '/zh/algorithms/quality-control' },
                { text: '物种分类算法', link: '/zh/algorithms/taxonomic-classification' },
                { text: '多样性度量', link: '/zh/algorithms/diversity-metrics' },
                { text: '性能基准测试', link: '/zh/algorithms/performance-benchmarks' },
              ],
            },
          ],
          '/zh/guides/': [
            {
              text: '指南',
              items: [
                { text: '快速开始', link: '/zh/guides/getting-started' },
                { text: '部署模式', link: '/zh/guides/deployment' },
                { text: '配置系统', link: '/zh/configuration' },
                { text: '常见问题', link: '/zh/faq' },
                { text: '故障排除', link: '/zh/troubleshooting' },
              ],
            },
          ],
          '/zh/reference/': [
            {
              text: '参考',
              items: [
                { text: 'CLI 参考', link: '/zh/reference/cli' },
                { text: '项目结构', link: '/zh/reference/project-structure' },
              ],
            },
          ],
          '/zh/research/': [
            {
              text: '研究',
              items: [
                { text: '参考文献', link: '/zh/research/citations' },
                { text: '相关开源项目探究', link: '/zh/research/related-projects' },
                { text: '演进思考', link: '/zh/research/evolution-notes' },
              ],
            },
          ],
          '/zh/analysis/': [
            {
              text: '分析模块',
              items: [
                { text: '物种分类分析', link: '/zh/analysis/taxonomic-profiling' },
                { text: '功能注释分析', link: '/zh/analysis/functional-profiling' },
                { text: '多样性分析', link: '/zh/analysis/diversity-analysis' },
              ],
            },
          ],
        },
        outlineTitle: '本页内容',
        darkModeSwitchLabel: '主题',
        sidebarMenuLabel: '菜单',
        returnToTopLabel: '返回顶部',
        docFooter: { prev: '上一页', next: '下一页' },
        footer: {
          message: 'MICOS-2024 技术白皮书，面向可重现宏基因组分析。',
          copyright: 'MIT License · LessUp / MICOS-2024',
        },
      },
    },
    en: {
      label: 'English',
      lang: 'en-US',
      link: '/en/',
      title: 'MICOS-2024',
      description: 'A technical whitepaper and architecture guide for the MICOS-2024 metagenomics platform',
      themeConfig: {
        ...sharedThemeConfig,
        nav: [
          { text: 'Overview', link: '/en/' },
          { text: 'Academy', link: '/en/academy/pipeline-foundations', activeMatch: '/en/academy/' },
          { text: 'Architecture', link: '/en/architecture/system-overview', activeMatch: '/en/architecture/' },
          { text: 'Algorithms', link: '/en/algorithms/quality-control', activeMatch: '/en/algorithms/' },
          { text: 'Guides', link: '/en/guides/getting-started', activeMatch: '/en/guides/|/en/configuration|/en/faq|/en/troubleshooting' },
          { text: 'Reference', link: '/en/reference/cli', activeMatch: '/en/reference/' },
          { text: 'Research', link: '/en/research/citations', activeMatch: '/en/research/' },
        ],
        sidebar: {
          '/en/academy/': [
            {
              text: 'Academy',
              items: [
                { text: 'Pipeline Foundations', link: '/en/academy/pipeline-foundations' },
                { text: 'Data Products and Interpretation', link: '/en/academy/data-products' },
              ],
            },
            {
              text: 'Module Deep Dives',
              items: [
                { text: 'Taxonomic Profiling', link: '/en/analysis/taxonomic-profiling' },
                { text: 'Functional Profiling', link: '/en/analysis/functional-profiling' },
                { text: 'Diversity Analysis', link: '/en/analysis/diversity-analysis' },
              ],
            },
          ],
          '/en/architecture/': [
            {
              text: 'Architecture',
              items: [
                { text: 'System Overview', link: '/en/architecture/system-overview' },
                { text: 'Runtime Topology', link: '/en/architecture/runtime-topology' },
              ],
            },
          ],
          '/en/algorithms/': [
            {
              text: 'Algorithms',
              items: [
                { text: 'Quality Control', link: '/en/algorithms/quality-control' },
                { text: 'Taxonomic Classification', link: '/en/algorithms/taxonomic-classification' },
                { text: 'Diversity Metrics', link: '/en/algorithms/diversity-metrics' },
                { text: 'Performance Benchmarks', link: '/en/algorithms/performance-benchmarks' },
              ],
            },
          ],
          '/en/guides/': [
            {
              text: 'Guides',
              items: [
                { text: 'Getting Started', link: '/en/guides/getting-started' },
                { text: 'Deployment Modes', link: '/en/guides/deployment' },
                { text: 'Configuration System', link: '/en/configuration' },
                { text: 'FAQ', link: '/en/faq' },
                { text: 'Troubleshooting', link: '/en/troubleshooting' },
              ],
            },
          ],
          '/en/reference/': [
            {
              text: 'Reference',
              items: [
                { text: 'CLI Reference', link: '/en/reference/cli' },
                { text: 'Project Structure', link: '/en/reference/project-structure' },
              ],
            },
          ],
          '/en/research/': [
            {
              text: 'Research',
              items: [
                { text: 'Citations', link: '/en/research/citations' },
                { text: 'Related Open Source Projects', link: '/en/research/related-projects' },
                { text: 'Evolution Notes', link: '/en/research/evolution-notes' },
              ],
            },
          ],
          '/en/analysis/': [
            {
              text: 'Analysis Modules',
              items: [
                { text: 'Taxonomic Profiling', link: '/en/analysis/taxonomic-profiling' },
                { text: 'Functional Profiling', link: '/en/analysis/functional-profiling' },
                { text: 'Diversity Analysis', link: '/en/analysis/diversity-analysis' },
              ],
            },
          ],
        },
        outlineTitle: 'On this page',
        darkModeSwitchLabel: 'Appearance',
        sidebarMenuLabel: 'Menu',
        returnToTopLabel: 'Return to top',
        docFooter: { prev: 'Previous page', next: 'Next page' },
        footer: {
          message: 'MICOS-2024 whitepaper for reproducible metagenomics engineering.',
          copyright: 'MIT License · LessUp / MICOS-2024',
        },
      },
    },
  },

  vite: {
    plugins: [llmstxt()],
  },
}))
