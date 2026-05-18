<script setup lang="ts">
import { ref, computed } from 'vue'
import { useData } from 'vitepress'

const { isDark } = useData()

// 定义模块节点
const nodes = [
  { id: 'cli', label: 'CLI', sublabel: 'micos/cli.py', layer: 'entry' },
  { id: 'qc', label: 'QC', sublabel: 'quality_control.py', layer: 'core' },
  { id: 'tax', label: 'Taxonomy', sublabel: 'taxonomic_profiling.py', layer: 'core' },
  { id: 'div', label: 'Diversity', sublabel: 'diversity_analysis.py', layer: 'core' },
  { id: 'func', label: 'Functional', sublabel: 'functional_annotation.py', layer: 'core' },
  { id: 'results', label: 'Results', sublabel: 'summarize_results.py', layer: 'output' },
  { id: 'wdl', label: 'WDL', sublabel: 'workflows/', layer: 'workflow' },
  { id: 'docker', label: 'Docker', sublabel: 'containers/', layer: 'infra' },
]

// 定义连接
const connections = [
  { from: 'cli', to: 'qc' },
  { from: 'cli', to: 'tax' },
  { from: 'cli', to: 'div' },
  { from: 'cli', to: 'func' },
  { from: 'qc', to: 'tax' },
  { from: 'tax', to: 'div' },
  { from: 'func', to: 'results' },
  { from: 'div', to: 'results' },
  { from: 'wdl', to: 'docker' },
]

const hoveredNode = ref<string | null>(null)

const colors = computed(() => isDark.value
  ? {
      bg: '#161a2e',
      cardBg: '#1e2238',
      cardBorder: '#3a4268',
      text: '#f0f4ff',
      subtext: '#8b95b8',
      accent: '#6b8afd',
      connection: '#4a5580',
    }
  : {
      bg: '#f8faff',
      cardBg: '#ffffff',
      cardBorder: '#d0d8f0',
      text: '#1a1f36',
      subtext: '#6b7598',
      accent: '#4f6ef7',
      connection: '#a0b0d0',
    }
)

const layerColors = computed(() => ({
  entry: isDark.value ? '#6b8afd' : '#4f6ef7',
  core: isDark.value ? '#4fd1c5' : '#38b2ac',
  output: isDark.value ? '#f6ad55' : '#dd6b20',
  workflow: isDark.value ? '#fc8181' : '#e53e3e',
  infra: isDark.value ? '#b794f4' : '#805ad5',
}))

function isNodeActive(id: string) {
  if (!hoveredNode.value) return false
  return hoveredNode.value === id ||
    connections.some(c => (c.from === hoveredNode.value && c.to === id) ||
                          (c.to === hoveredNode.value && c.from === id))
}
</script>

<template>
  <div class="architecture-diagram">
    <svg viewBox="0 0 800 400" class="arch-svg">
      <!-- 背景 -->
      <rect width="800" height="400" rx="16" :fill="colors.bg"/>

      <!-- 层级标签 -->
      <g font-family="Inter, Arial, sans-serif" font-size="11" font-weight="600" letter-spacing="0.1em">
        <text x="40" y="60" :fill="colors.subtext">ENTRY</text>
        <text x="40" y="140" :fill="colors.subtext">CORE</text>
        <text x="40" y="260" :fill="colors.subtext">OUTPUT</text>
        <text x="580" y="60" :fill="colors.subtext">WORKFLOW</text>
        <text x="580" y="140" :fill="colors.subtext">INFRA</text>
      </g>

      <!-- 连接线 -->
      <g :stroke="colors.connection" stroke-width="2" fill="none" opacity="0.6">
        <path d="M160 80 L160 130" />
        <path d="M160 80 L280 130" />
        <path d="M160 80 L400 130" />
        <path d="M160 80 L520 130" />
        <path d="M160 180 L280 180 L280 240" />
        <path d="M280 180 L280 240" />
        <path d="M400 180 L400 240" />
        <path d="M520 180 L400 240" />
        <path d="M640 80 L640 130" />
      </g>

      <!-- 节点 -->
      <g v-for="node in nodes" :key="node.id">
        <rect
          :x="node.id === 'cli' ? 100 : node.id === 'wdl' ? 580 : node.id === 'docker' ? 580 : node.id === 'results' ? 300 : (node.id === 'qc' ? 100 : node.id === 'tax' ? 220 : node.id === 'div' ? 340 : 460)"
          :y="node.layer === 'entry' ? 40 : node.layer === 'workflow' ? 40 : node.layer === 'infra' ? 120 : node.layer === 'output' ? 220 : 120"
          :width="node.id === 'results' ? 180 : 120"
          height="70"
          rx="12"
          :fill="colors.cardBg"
          :stroke="isNodeActive(node.id) ? layerColors[node.layer] : colors.cardBorder"
          :stroke-width="isNodeActive(node.id) ? 2 : 1"
          class="arch-node"
          @mouseenter="hoveredNode = node.id"
          @mouseleave="hoveredNode = null"
        />
        <circle
          :cx="(node.id === 'cli' ? 100 : node.id === 'wdl' ? 580 : node.id === 'docker' ? 580 : node.id === 'results' ? 300 : (node.id === 'qc' ? 100 : node.id === 'tax' ? 220 : node.id === 'div' ? 340 : 460)) + 10"
          :cy="(node.layer === 'entry' ? 40 : node.layer === 'workflow' ? 40 : node.layer === 'infra' ? 120 : node.layer === 'output' ? 220 : 120) + 10"
          r="4"
          :fill="layerColors[node.layer]"
        />
        <text
          :x="(node.id === 'cli' ? 100 : node.id === 'wdl' ? 580 : node.id === 'docker' ? 580 : node.id === 'results' ? 300 : (node.id === 'qc' ? 100 : node.id === 'tax' ? 220 : node.id === 'div' ? 340 : 460)) + 24"
          :y="(node.layer === 'entry' ? 40 : node.layer === 'workflow' ? 40 : node.layer === 'infra' ? 120 : node.layer === 'output' ? 220 : 120) + 28"
          font-family="Inter, Arial, sans-serif"
          font-size="14"
          font-weight="600"
          :fill="colors.text"
        >{{ node.label }}</text>
        <text
          :x="(node.id === 'cli' ? 100 : node.id === 'wdl' ? 580 : node.id === 'docker' ? 580 : node.id === 'results' ? 300 : (node.id === 'qc' ? 100 : node.id === 'tax' ? 220 : node.id === 'div' ? 340 : 460)) + 24"
          :y="(node.layer === 'entry' ? 40 : node.layer === 'workflow' ? 40 : node.layer === 'infra' ? 120 : node.layer === 'output' ? 220 : 120) + 50"
          font-family="JetBrains Mono, monospace"
          font-size="11"
          :fill="colors.subtext"
        >{{ node.sublabel }}</text>
      </g>
    </svg>

    <!-- 图例 -->
    <div class="arch-legend">
      <div v-for="(color, layer) in layerColors" :key="layer" class="legend-item">
        <span class="legend-dot" :style="{ background: color }"></span>
        <span>{{ layer }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.architecture-diagram {
  position: relative;
  width: 100%;
}

.arch-svg {
  width: 100%;
  height: auto;
}

.arch-node {
  cursor: pointer;
  transition: all 0.2s ease;
}

.arch-node:hover {
  filter: brightness(1.05);
}

.arch-legend {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  margin-top: 1rem;
  justify-content: center;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  font-size: 0.85rem;
  color: var(--vp-c-text-2);
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}
</style>
