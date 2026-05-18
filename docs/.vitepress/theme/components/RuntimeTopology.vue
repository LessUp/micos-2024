<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

const { isDark } = useData()

// 主题感知颜色计算
const colors = computed(() => {
  if (isDark.value) {
    return {
      bg: '#161a2e',
      cardBg: '#1e2238',
      cardBorder: '#3a4268',
      titleText: '#f0f4ff',
      subtitleText: '#8b95b8',
      bodyText: '#a8b0d0',
      accent: '#6b8afd',
      accentLabel: '#8ba4ff',
      arrow: '#6b8afd',
    }
  } else {
    return {
      bg: '#f8faff',
      cardBg: '#ffffff',
      cardBorder: '#d0d8f0',
      titleText: '#1a1f36',
      subtitleText: '#4a5580',
      bodyText: '#6b7598',
      accent: '#4f6ef7',
      accentLabel: '#4f6ef7',
      arrow: '#4f6ef7',
    }
  }
})

const nodes = [
  {
    x: 56, y: 118, width: 232, height: 120,
    eyebrow: 'ENTRY LAYER',
    title: 'micos CLI',
    desc1: 'Click-based commands,',
    desc2: 'validation and dry-run.',
  },
  {
    x: 344, y: 118, width: 232, height: 120,
    eyebrow: 'ORCHESTRATION',
    title: 'Python modules',
    desc1: 'Full pipeline, quality control,',
    desc2: 'taxonomy, diversity, reporting.',
  },
  {
    x: 632, y: 118, width: 232, height: 120,
    eyebrow: 'WORKFLOW ASSETS',
    title: 'steps/ + containers/',
    desc1: 'WDL stages, Singularity defs,',
    desc2: 'Docker Compose services.',
  },
  {
    x: 140, y: 298, width: 232, height: 116,
    eyebrow: 'CONFIG SURFACE',
    title: 'config/*.template',
    desc1: 'Project, database, and sample',
    desc2: 'metadata templates.',
  },
  {
    x: 548, y: 298, width: 232, height: 116,
    eyebrow: 'POWER USER SURFACE',
    title: 'scripts/',
    desc1: 'Thin wrappers plus experimental',
    desc2: 'analyses outside the CLI core.',
  },
]
</script>

<template>
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 920 480" class="runtime-topology-svg">
    <!-- 裁剪路径：每个卡片内容区 -->
    <defs>
      <clipPath v-for="(node, index) in nodes" :key="'clip-' + index" :id="'topo-clip-' + index">
        <rect :x="node.x + 12" :y="node.y + 12" :width="node.width - 24" :height="node.height - 16" rx="0"/>
      </clipPath>
    </defs>

    <!-- 背景 -->
    <rect width="920" height="480" rx="28" :fill="colors.bg"/>

    <!-- 标题区域 -->
    <g font-family="Inter, Arial, sans-serif">
      <text x="56" y="58" font-size="18" font-weight="700" :fill="colors.titleText">Runtime topology</text>
      <text x="56" y="82" font-size="13" :fill="colors.subtitleText">The repository blends Python orchestration, shell wrappers, WDL stages, and container assets.</text>
    </g>

    <!-- 节点卡片 -->
    <g v-for="(node, index) in nodes" :key="index">
      <rect
        :x="node.x"
        :y="node.y"
        :width="node.width"
        :height="node.height"
        rx="20"
        :fill="colors.cardBg"
        :stroke="colors.cardBorder"
        class="topology-node"
      />
      <g :clip-path="`url(#topo-clip-${index})`">
        <text
          :x="node.x + 28"
          :y="node.y + 36"
          font-family="Inter, Arial, sans-serif"
          font-size="13"
          letter-spacing=".12em"
          :fill="colors.accentLabel"
        >{{ node.eyebrow }}</text>
        <text
          :x="node.x + 28"
          :y="node.y + 68"
          font-family="Inter, Arial, sans-serif"
          font-size="24"
          font-weight="700"
          :fill="colors.titleText"
        >{{ node.title }}</text>
        <text
          :x="node.x + 28"
          :y="node.y + 96"
          font-family="Inter, Arial, sans-serif"
          font-size="13"
          :fill="colors.bodyText"
        >{{ node.desc1 }}</text>
        <text
          :x="node.x + 28"
          :y="node.y + 113"
          font-family="Inter, Arial, sans-serif"
          font-size="13"
          :fill="colors.bodyText"
        >{{ node.desc2 }}</text>
      </g>
    </g>

    <!-- 连接线 -->
    <g fill="none" :stroke="colors.arrow" stroke-linecap="round" stroke-width="4">
      <path d="M288 178h56"/>
      <path d="M576 178h56"/>
      <path d="M460 238v48"/>
      <path d="M256 298v-48h204"/>
      <path d="M664 298v-48H460"/>
    </g>

    <!-- 箭头 -->
    <g :fill="colors.arrow">
      <path d="M336 169l16 9-16 9z"/>
      <path d="M624 169l16 9-16 9z"/>
      <path d="M451 278l9 16 9-16z"/>
    </g>
  </svg>
</template>

<style scoped>
.runtime-topology-svg {
  width: 100%;
  height: auto;
}

.topology-node {
  transition: all 0.3s ease;
}

.runtime-topology-svg:hover .topology-node {
  filter: brightness(1.02);
}
</style>
