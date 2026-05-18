<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

const { isDark } = useData()

// 主题感知颜色计算
const colors = computed(() => {
  if (isDark.value) {
    return {
      // 深色模式 - 沉浸极客
      bg: '#161a2e',
      cardBg: '#1e2238',
      cardBorder: '#3a4268',
      titleText: '#f0f4ff',
      subtitleText: '#8b95b8',
      bodyText: '#a8b0d0',
      accent: '#6b8afd',
      accentLabel: '#8ba4ff',
      gridLine: '#2a3050',
      arrow: '#6b8afd',
    }
  } else {
    return {
      // 浅色模式 - 冷静专业
      bg: '#f8faff',
      cardBg: '#ffffff',
      cardBorder: '#d0d8f0',
      titleText: '#1a1f36',
      subtitleText: '#4a5580',
      bodyText: '#6b7598',
      accent: '#4f6ef7',
      accentLabel: '#4f6ef7',
      gridLine: '#e0e8ff',
      arrow: '#4f6ef7',
    }
  }
})

const stages = [
  {
    eyebrow: 'STAGE 01',
    title: 'QC',
    desc1: 'FastQC, KneadData,',
    desc2: 'trimming, host depletion.',
    output: 'clean reads',
  },
  {
    eyebrow: 'STAGE 02',
    title: 'Taxonomy',
    desc1: 'Kraken2, kraken-biom,',
    desc2: 'Krona summaries.',
    output: 'reports, biom, krona',
  },
  {
    eyebrow: 'STAGE 03',
    title: 'Diversity',
    desc1: 'QIIME2 metrics, alpha',
    desc2: 'and beta views.',
    output: 'ordination and tables',
  },
  {
    eyebrow: 'STAGE 04',
    title: 'Report',
    desc1: 'Functional outputs and',
    desc2: 'final summary views.',
    output: '',
  },
]
</script>

<template>
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 920 480" class="pipeline-overview-svg">
    <!-- 背景 -->
    <rect width="920" height="480" rx="28" :fill="colors.bg"/>

    <!-- 网格线 -->
    <g :stroke="colors.gridLine" stroke-width="1" opacity="0.5">
      <path d="M60 96h800M60 200h800M60 304h800M60 408h800"/>
      <path d="M164 40v400M344 40v400M524 40v400M704 40v400"/>
    </g>

    <!-- 标题区域 -->
    <g font-family="Inter, Arial, sans-serif">
      <text x="60" y="56" font-size="18" font-weight="700" :fill="colors.titleText">MICOS pipeline overview</text>
      <text x="60" y="82" font-size="13" :fill="colors.subtitleText">From raw FASTQ to interpretable microbiome outputs</text>
    </g>

    <!-- 阶段卡片 -->
    <g v-for="(stage, index) in stages" :key="index">
      <rect
        :x="60 + index * 220"
        y="120"
        :width="index === 3 ? 140 : 180"
        height="220"
        rx="20"
        :fill="colors.cardBg"
        :stroke="colors.cardBorder"
        class="stage-card"
      />
      <text
        :x="84 + index * 220"
        y="160"
        font-family="Inter, Arial, sans-serif"
        font-size="13"
        letter-spacing=".12em"
        :fill="colors.accentLabel"
      >{{ stage.eyebrow }}</text>
      <text
        :x="84 + index * 220"
        y="192"
        font-family="Inter, Arial, sans-serif"
        font-size="26"
        font-weight="700"
        :fill="colors.titleText"
      >{{ stage.title }}</text>
      <text
        :x="84 + index * 220"
        y="220"
        font-family="Inter, Arial, sans-serif"
        font-size="13"
        :fill="colors.bodyText"
      >{{ stage.desc1 }}</text>
      <text
        :x="84 + index * 220"
        y="237"
        font-family="Inter, Arial, sans-serif"
        font-size="13"
        :fill="colors.bodyText"
      >{{ stage.desc2 }}</text>
      <text
        v-if="stage.output"
        :x="84 + index * 220"
        y="288"
        font-family="Inter, Arial, sans-serif"
        font-size="13"
        :fill="colors.accentLabel"
      >Output</text>
      <text
        v-if="stage.output"
        :x="84 + index * 220"
        y="312"
        font-family="Inter, Arial, sans-serif"
        font-size="14"
        :fill="colors.subtitleText"
      >{{ stage.output }}</text>
    </g>

    <!-- 连接箭头 -->
    <g v-for="i in 3" :key="'arrow-' + i">
      <path
        :d="`M${220 + (i-1) * 220} 230h40`"
        fill="none"
        :stroke="colors.arrow"
        stroke-width="4"
        stroke-linecap="round"
      />
      <path
        :d="`M${254 + (i-1) * 220} 221l16 9-16 9z`"
        :fill="colors.arrow"
      />
    </g>
  </svg>
</template>

<style scoped>
.pipeline-overview-svg {
  width: 100%;
  height: auto;
}

.stage-card {
  transition: all 0.3s ease;
}

.pipeline-overview-svg:hover .stage-card {
  filter: brightness(1.02);
}
</style>
