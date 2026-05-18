<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

export interface ComparisonRow {
  feature: string
  values: (string | boolean | { text: string; status: 'yes' | 'no' | 'partial' })[]
}

const props = defineProps<{
  headers: string[]
  rows: ComparisonRow[]
  title?: string
}>()

const { isDark } = useData()

const colors = computed(() => isDark.value
  ? {
      bg: '#1e2238',
      border: '#3a4268',
      accent: '#6b8afd',
      text: '#f0f4ff',
      subtext: '#8b95b8',
      headerBg: '#252b45',
      yes: '#4fd1c5',
      no: '#fc8181',
      partial: '#f6ad55',
    }
  : {
      bg: '#ffffff',
      border: '#d0d8f0',
      accent: '#4f6ef7',
      text: '#1a1f36',
      subtext: '#6b7598',
      headerBg: '#f0f4ff',
      yes: '#38b2ac',
      no: '#e53e3e',
      partial: '#dd6b20',
    }
)

function renderValue(value: string | boolean | { text: string; status: 'yes' | 'no' | 'partial' }) {
  if (typeof value === 'boolean') {
    return { text: value ? '✓' : '✗', status: value ? 'yes' : 'no' }
  }
  if (typeof value === 'string') {
    return { text: value, status: 'neutral' }
  }
  return value
}
</script>

<template>
  <div class="comparison-table">
    <h4 v-if="title" class="table-title" :style="{ color: colors.text }">{{ title }}</h4>
    <table class="comp-table" :style="{ background: colors.bg, borderColor: colors.border }">
      <thead>
        <tr :style="{ background: colors.headerBg }">
          <th :style="{ color: colors.text, borderColor: colors.border }">Feature</th>
          <th v-for="header in headers" :key="header" :style="{ color: colors.text, borderColor: colors.border }">
            {{ header }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(row, rowIndex) in rows" :key="rowIndex" :style="{ borderColor: colors.border }">
          <td class="feature-cell" :style="{ color: colors.text, borderColor: colors.border }">
            {{ row.feature }}
          </td>
          <td
            v-for="(value, colIndex) in row.values"
            :key="colIndex"
            :style="{ borderColor: colors.border }"
          >
            <span
              v-if="renderValue(value).status !== 'neutral'"
              class="status-badge"
              :class="`status-${renderValue(value).status}`"
              :style="{
                background: renderValue(value).status === 'yes' ? colors.yes :
                           renderValue(value).status === 'no' ? colors.no :
                           colors.partial
              }"
            >
              {{ renderValue(value).text }}
            </span>
            <span v-else :style="{ color: colors.subtext }">{{ renderValue(value).text }}</span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
.comparison-table {
  width: 100%;
  overflow-x: auto;
}

.table-title {
  margin: 0 0 1rem;
  font-size: 1rem;
}

.comp-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid;
  border-radius: 12px;
  overflow: hidden;
}

.comp-table th,
.comp-table td {
  padding: 0.75rem 1rem;
  text-align: left;
  border-bottom: 1px solid;
}

.comp-table th {
  font-weight: 600;
  font-size: 0.9rem;
}

.comp-table tr:last-child td {
  border-bottom: none;
}

.feature-cell {
  font-weight: 500;
}

.status-badge {
  display: inline-block;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 600;
  color: white;
}

.status-yes {
  /* 绿色 - 完全支持 */
}

.status-no {
  /* 红色 - 不支持 */
}

.status-partial {
  /* 橙色 - 部分支持 */
}
</style>
