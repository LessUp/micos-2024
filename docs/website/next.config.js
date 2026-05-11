const withNextra = require('nextra').default({
  theme: 'nextra-theme-docs',
  themeConfig: './theme.config.tsx',
  defaultShowCopyCode: true,
  staticImage: true,
})

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  distDir: '../.site',
  basePath: '/micos-2024',
  assetPrefix: '/micos-2024',
  images: {
    unoptimized: true,
  },
}

module.exports = withNextra(nextConfig)
