<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

const props = defineProps<{
  title: string
  description: string
  complexity?: string
  codeSnippet?: string
  language?: string
}>()

const { isDark } = useData()

const colors = computed(() => isDark.value
  ? {
      bg: '#1e2238',
      border: '#3a4268',
      accent: '#6b8afd',
      text: '#f0f4ff',
      subtext: '#8b95b8',
      codeBg: '#161a2e',
    }
  : {
      bg: '#ffffff',
      border: '#d0d8f0',
      accent: '#4f6ef7',
      text: '#1a1f36',
      subtext: '#6b7598',
      codeBg: '#f8faff',
    }
)
</script>

<template>
  <div class="algorithm-card" :style="{ background: colors.bg, borderColor: colors.border }">
    <div class="algo-header">
      <h3 class="algo-title" :style="{ color: colors.text }">{{ title }}</h3>
      <span v-if="complexity" class="algo-complexity" :style="{ background: colors.accent }">
        {{ complexity }}
      </span>
    </div>
    <p class="algo-description" :style="{ color: colors.subtext }">{{ description }}</p>
    <div v-if="codeSnippet" class="algo-code" :style="{ background: colors.codeBg }">
      <code :class="['code-block', language && `language-${language}`]">{{ codeSnippet }}</code>
    </div>
    <slot />
  </div>
</template>

<style scoped>
.algorithm-card {
  border: 1px solid;
  border-radius: 16px;
  padding: 1.25rem;
  transition: all 0.2s ease;
}

.algorithm-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 32px rgba(79, 110, 247, 0.1);
}

.algo-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 0.75rem;
}

.algo-title {
  margin: 0;
  font-size: 1.1rem;
  font-weight: 600;
}

.algo-complexity {
  padding: 0.25rem 0.6rem;
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 600;
  color: white;
  font-family: 'JetBrains Mono', monospace;
}

.algo-description {
  margin: 0 0 1rem;
  line-height: 1.6;
}

.algo-code {
  border-radius: 10px;
  padding: 1rem;
  overflow-x: auto;
}

.code-block {
  font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 0.85rem;
  line-height: 1.5;
  white-space: pre;
}
</style>
