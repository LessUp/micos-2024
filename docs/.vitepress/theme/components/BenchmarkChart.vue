<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

const props = defineProps<{
  data: {
    label: string
    values: number[]
    unit?: string
  }[]
  labels: string[]
  title?: string
}>()

const { isDark } = useData()

const colors = computed(() => isDark.value
  ? {
      bg: '#1e2238',
      border: '#3a4268',
      accent: '#6b8afd',
      accent2: '#4fd1c5',
      accent3: '#f6ad55',
      text: '#f0f4ff',
      subtext: '#8b95b8',
      gridLine: '#2a3050',
    }
  : {
      bg: '#ffffff',
      border: '#d0d8f0',
      accent: '#4f6ef7',
      accent2: '#38b2ac',
      accent3: '#dd6b20',
      text: '#1a1f36',
      subtext: '#6b7598',
      gridLine: '#e0e8ff',
    }
)

const barColors = computed(() => [
  colors.value.accent,
  colors.value.accent2,
  colors.value.accent3,
])

// 计算最大值用于缩放
const maxValue = computed(() => {
  const allValues = props.data.flatMap(d => d.values)
  return Math.max(...allValues, 1)
})

const chartWidth = 600
const chartHeight = 300
const barWidth = 40
const barGap = 20
const groupWidth = computed(() => props.data.length * barWidth + (props.data.length - 1) * 8)
const totalWidth = computed(() => props.labels.length * groupWidth.value + (props.labels.length - 1) * barGap)
</script>

<template>
  <div class="benchmark-chart">
    <h4 v-if="title" class="chart-title" :style="{ color: colors.text }">{{ title }}</h4>
    <svg :viewBox="`0 0 ${Math.max(totalWidth, chartWidth)} ${chartHeight}`" class="chart-svg">
      <!-- 背景 -->
      <rect width="100%" height="100%" rx="12" :fill="colors.bg"/>

      <!-- 网格线 -->
      <g :stroke="colors.gridLine" stroke-width="1" opacity="0.5">
        <line x1="60" y1="40" :x2="Math.max(totalWidth, chartWidth) - 20" y2="40" />
        <line x1="60" y1="100" :x2="Math.max(totalWidth, chartWidth) - 20" y2="100" />
        <line x1="60" y1="160" :x2="Math.max(totalWidth, chartWidth) - 20" y2="160" />
        <line x1="60" y1="220" :x2="Math.max(totalWidth, chartWidth) - 20" y2="220" />
      </g>

      <!-- Y 轴标签 -->
      <g font-family="Inter, Arial, sans-serif" font-size="11" :fill="colors.subtext">
        <text x="50" y="44" text-anchor="end">{{ maxValue.toFixed(0) }}</text>
        <text x="50" y="104" text-anchor="end">{{ (maxValue * 0.75).toFixed(0) }}</text>
        <text x="50" y="164" text-anchor="end">{{ (maxValue * 0.5).toFixed(0) }}</text>
        <text x="50" y="224" text-anchor="end">{{ (maxValue * 0.25).toFixed(0) }}</text>
      </g>

      <!-- 柱状图组 -->
      <g v-for="(label, labelIndex) in labels" :key="labelIndex">
        <g v-for="(series, seriesIndex) in data" :key="series.label">
          <rect
            :x="80 + labelIndex * (groupWidth + barGap) + seriesIndex * (barWidth + 8)"
            :y="260 - (series.values[labelIndex] / maxValue) * 220"
            :width="barWidth"
            :height="(series.values[labelIndex] / maxValue) * 220"
            rx="4"
            :fill="barColors[seriesIndex % barColors.length]"
            class="chart-bar"
          />
        </g>
        <!-- X 轴标签 -->
        <text
          :x="80 + labelIndex * (groupWidth + barGap) + groupWidth / 2 - barWidth / 2"
          y="275"
          font-family="Inter, Arial, sans-serif"
          font-size="11"
          text-anchor="middle"
          :fill="colors.subtext"
        >{{ label }}</text>
      </g>
    </svg>

    <!-- 图例 -->
    <div class="chart-legend">
      <div v-for="(series, index) in data" :key="series.label" class="legend-item">
        <span class="legend-bar" :style="{ background: barColors[index % barColors.length] }"></span>
        <span :style="{ color: colors.subtext }">{{ series.label }}{{ series.unit ? ` (${series.unit})` : '' }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.benchmark-chart {
  width: 100%;
}

.chart-title {
  margin: 0 0 1rem;
  font-size: 1rem;
}

.chart-svg {
  width: 100%;
  height: auto;
}

.chart-bar {
  transition: all 0.2s ease;
}

.chart-bar:hover {
  filter: brightness(1.1);
}

.chart-legend {
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
}

.legend-bar {
  width: 16px;
  height: 10px;
  border-radius: 3px;
}
</style>
