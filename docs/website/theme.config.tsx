import { useRouter } from 'next/router'

const config = {
  logo: (
    <span className="font-bold text-xl flex items-center gap-2">
      <svg
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="text-primary-600 dark:text-primary-400"
      >
        <path
          d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 20C7.59 20 4 16.41 4 12C4 7.59 7.59 4 12 4C16.41 4 20 7.59 20 12C20 16.41 16.41 20 12 20Z"
          fill="currentColor"
        />
        <path
          d="M8 12C8 9.79 9.79 8 12 8C14.21 8 16 9.79 16 12"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        />
        <circle cx="12" cy="12" r="2" fill="currentColor" />
      </svg>
      MICOS-2024
    </span>
  ),
  project: {
    link: 'https://github.com/LessUp/micos-2024',
  },
  docsRepositoryBase: 'https://github.com/LessUp/micos-2024/tree/master/docs/website',
  useNextSeoProps() {
    const { asPath } = useRouter()
    const title = asPath === '/'
      ? 'MICOS-2024 - Metagenomic Intelligence and Comprehensive Omics Suite'
      : '%s – MICOS-2024'
    return {
      titleTemplate: title,
      description: 'End-to-end metagenomic analysis platform integrating Kraken2, QIIME2, HUMAnN',
      openGraph: {
        type: 'website',
        locale: 'en_US',
        url: 'https://lessup.github.io/micos-2024',
        siteName: 'MICOS-2024',
      },
      twitter: {
        cardType: 'summary_large_image',
      },
    }
  },
  head: (
    <>
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta name="description" content="End-to-end metagenomic analysis platform integrating Kraken2, QIIME2, HUMAnN" />
      <meta property="og:title" content="MICOS-2024" />
      <meta property="og:description" content="Metagenomic Intelligence and Comprehensive Omics Suite" />
      <link rel="icon" type="image/svg+xml" href="/micos-2024/favicon.svg" />
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet" />
    </>
  ),
  search: {
    placeholder: 'Search documentation...',
  },
  toc: {
    title: 'On This Page',
  },
  editLink: {
    text: 'Edit this page on GitHub →',
  },
  feedback: {
    content: 'Question? Give us feedback →',
    labels: 'documentation',
  },
  footer: {
    text: (
      <div className="flex flex-col gap-2">
        <span>
          MIT {new Date().getFullYear()} ©{' '}
          <a href="https://github.com/LessUp" target="_blank" rel="noreferrer" className="hover:text-primary-600 transition-colors">
            LessUp
          </a>
        </span>
        <span className="text-xs text-gray-500 dark:text-gray-400">
          Built with Nextra
        </span>
      </div>
    ),
  },
  darkMode: true,
  nextThemes: {
    defaultTheme: 'system',
    storageKey: 'micos-theme',
  },
  sidebar: {
    defaultMenuCollapseLevel: 1,
    toggleButton: true,
  },
  navigation: {
    prev: true,
    next: true,
  },
  i18n: [
    { locale: 'en', text: 'English' },
    { locale: 'zh', text: '中文' },
  ],
}

export default config
