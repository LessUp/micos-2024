import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import FlowStageGrid from './components/FlowStageGrid.vue'
import MetricGrid from './components/MetricGrid.vue'
import ReferenceList from './components/ReferenceList.vue'
import SiteHero from './components/SiteHero.vue'
import SiteSection from './components/SiteSection.vue'
import ThemeAsset from './components/ThemeAsset.vue'
import PipelineOverview from './components/PipelineOverview.vue'
import RuntimeTopology from './components/RuntimeTopology.vue'
import ArchitectureDiagram from './components/ArchitectureDiagram.vue'
import AlgorithmCard from './components/AlgorithmCard.vue'
import BenchmarkChart from './components/BenchmarkChart.vue'
import CitationBlock from './components/CitationBlock.vue'
import ComparisonTable from './components/ComparisonTable.vue'
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
    app.component('PipelineOverview', PipelineOverview)
    app.component('RuntimeTopology', RuntimeTopology)
    app.component('ArchitectureDiagram', ArchitectureDiagram)
    app.component('AlgorithmCard', AlgorithmCard)
    app.component('BenchmarkChart', BenchmarkChart)
    app.component('CitationBlock', CitationBlock)
    app.component('ComparisonTable', ComparisonTable)
  },
  setup() {
    DefaultTheme.setup?.()
  },
}

export default theme
