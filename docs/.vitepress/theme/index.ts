import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import ThemeAsset from './components/ThemeAsset.vue'
import ReferenceList from './components/ReferenceList.vue'
import AlgorithmCard from './components/AlgorithmCard.vue'
import CitationBlock from './components/CitationBlock.vue'
import ArchitectureDiagram from './components/ArchitectureDiagram.vue'
import './style.css'

const theme: Theme = {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('ThemeAsset', ThemeAsset)
    app.component('ReferenceList', ReferenceList)
    app.component('AlgorithmCard', AlgorithmCard)
    app.component('CitationBlock', CitationBlock)
    app.component('ArchitectureDiagram', ArchitectureDiagram)
  },
  setup() {
    DefaultTheme.setup?.()
  },
}

export default theme
