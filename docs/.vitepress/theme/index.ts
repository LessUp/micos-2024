import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import { watch } from 'vue'
import { useData } from 'vitepress'

import FlowStageGrid from './components/FlowStageGrid.vue'
import MetricGrid from './components/MetricGrid.vue'
import ReferenceList from './components/ReferenceList.vue'
import SiteHero from './components/SiteHero.vue'
import SiteSection from './components/SiteSection.vue'
import ThemeAsset from './components/ThemeAsset.vue'
import './style.css'

const theme: Theme = {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('FlowStageGrid', FlowStageGrid)
    app.component('MetricGrid', MetricGrid)
    app.component('ReferenceList', ReferenceList)
    app.component('SiteHero', SiteHero)
    app.component('SiteSection', SiteSection)
    app.component('ThemeAsset', ThemeAsset)
  },
  setup() {
    DefaultTheme.setup?.()

    if (typeof window === 'undefined') {
      return
    }

    const { lang } = useData()

    watch(
      lang,
      (newLang) => {
        if (newLang === 'zh-CN') {
          localStorage.setItem('micos-lang-preference', 'zh')
        } else if (newLang === 'en-US') {
          localStorage.setItem('micos-lang-preference', 'en')
        }
      },
      { immediate: true },
    )
  },
}

export default theme
