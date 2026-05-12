import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'
import llmstxt from 'vitepress-plugin-llms'

const rawBase = process.env.VITEPRESS_BASE
const base = rawBase
  ? rawBase.startsWith('/')
    ? rawBase.endsWith('/') ? rawBase : `${rawBase}/`
    : `/${rawBase}/`
  : '/'

export default withMermaid(defineConfig({
  base,
  title: 'MICOS-2024',
  description: 'Metagenomic Intelligence and Comprehensive Omics Suite',

  locales: {
    zh: {
      label: '简体中文',
      lang: 'zh-CN',
      link: '/zh/',
      title: 'MICOS-2024 文档',
      description: '宏基因组综合分析平台',
      themeConfig: {
        nav: [
          { text: '指南', link: '/zh/guides/getting-started', activeMatch: '/zh/guides/' },
          { text: '分析模块', link: '/zh/analysis/taxonomic-profiling', activeMatch: '/zh/analysis/' },
          { text: '配置', link: '/zh/configuration', activeMatch: '/zh/configuration' },
          { text: '参考手册', link: '/zh/reference/cli', activeMatch: '/zh/reference/' },
          { text: '常见问题', link: '/zh/faq' },
          { text: '故障排除', link: '/zh/troubleshooting' },
        ],
        sidebar: {
          '/zh/guides/': [
            {
              text: '指南',
              items: [
                { text: '快速开始', link: '/zh/guides/getting-started' },
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
          '/zh/configuration': [
            {
              text: '配置',
              items: [
                { text: '配置指南', link: '/zh/configuration' },
              ],
            },
          ],
          '/zh/reference/': [
            {
              text: '参考手册',
              items: [
                { text: 'CLI 参考', link: '/zh/reference/cli' },
              ],
            },
          ],
        },
      },
    },
    en: {
      label: 'English',
      lang: 'en-US',
      link: '/en/',
      title: 'MICOS-2024 Docs',
      description: 'Metagenomic Intelligence and Comprehensive Omics Suite',
      themeConfig: {
        nav: [
          { text: 'Guides', link: '/en/guides/getting-started', activeMatch: '/en/guides/' },
          { text: 'Analysis', link: '/en/analysis/taxonomic-profiling', activeMatch: '/en/analysis/' },
          { text: 'Configuration', link: '/en/configuration', activeMatch: '/en/configuration' },
          { text: 'Reference', link: '/en/reference/cli', activeMatch: '/en/reference/' },
          { text: 'FAQ', link: '/en/faq' },
          { text: 'Troubleshooting', link: '/en/troubleshooting' },
        ],
        sidebar: {
          '/en/guides/': [
            {
              text: 'Guides',
              items: [
                { text: 'Getting Started', link: '/en/guides/getting-started' },
              ],
            },
          ],
          '/en/analysis/': [
            {
              text: 'Analysis',
              items: [
                { text: 'Taxonomic Profiling', link: '/en/analysis/taxonomic-profiling' },
                { text: 'Functional Profiling', link: '/en/analysis/functional-profiling' },
                { text: 'Diversity Analysis', link: '/en/analysis/diversity-analysis' },
              ],
            },
          ],
          '/en/configuration': [
            {
              text: 'Configuration',
              items: [
                { text: 'Configuration Guide', link: '/en/configuration' },
              ],
            },
          ],
          '/en/reference/': [
            {
              text: 'Reference',
              items: [
                { text: 'CLI Reference', link: '/en/reference/cli' },
              ],
            },
          ],
        },
      },
    },
  },

  themeConfig: {
    outline: [2, 3],
    search: { provider: 'local' },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/LessUp/micos-2024' },
    ],
  },

  vite: {
    plugins: [llmstxt()],
  },
}))
