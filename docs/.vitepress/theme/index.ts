import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import { watch } from 'vue'
import { useData } from 'vitepress'
import { saveLangPreference } from '../utils/lang'

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

    const { lang } = useData()

    // 只负责持久化语言偏好
    watch(
      lang,
      (newLang) => {
        if (newLang === 'zh-CN') {
          saveLangPreference('zh')
        } else if (newLang === 'en-US') {
          saveLangPreference('en')
        }
      },
      { immediate: true },
    )
  },
}

export default theme
