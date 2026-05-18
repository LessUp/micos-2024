<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

export interface Citation {
  id: string
  authors: string
  title: string
  venue: string
  year: number
  doi?: string
  url?: string
}

const props = defineProps<{
  citation: Citation
  showBibtex?: boolean
}>()

const { isDark } = useData()

const colors = computed(() => isDark.value
  ? {
      bg: '#1e2238',
      border: '#3a4268',
      accent: '#6b8afd',
      text: '#f0f4ff',
      subtext: '#8b95b8',
    }
  : {
      bg: '#ffffff',
      border: '#d0d8f0',
      accent: '#4f6ef7',
      text: '#1a1f36',
      subtext: '#6b7598',
    }
)

const bibtex = computed(() => {
  const c = props.citation
  const authorList = c.authors.split(', ').map(a => a.split(' ').reverse().join(', ')).join(' and ')
  return `@article{${c.id},
  author = {${authorList}},
  title = {${c.title}},
  journal = {${c.venue}},
  year = {${c.year}}${c.doi ? `,
  doi = {${c.doi}}` : ''}
}`
})

const copied = ref(false)

function copyBibtex() {
  navigator.clipboard.writeText(bibtex.value)
  copied.value = true
  setTimeout(() => { copied.value = false }, 2000)
}
</script>

<template>
  <div class="citation-block" :style="{ background: colors.bg, borderColor: colors.border }">
    <div class="citation-number" :style="{ background: colors.accent }">{{ citation.id }}</div>
    <div class="citation-content">
      <p class="citation-authors" :style="{ color: colors.subtext }">{{ citation.authors }}</p>
      <p class="citation-title" :style="{ color: colors.text }">{{ citation.title }}</p>
      <p class="citation-venue" :style="{ color: colors.subtext }">
        <em>{{ citation.venue }}</em>, {{ citation.year }}
      </p>
      <div class="citation-links">
        <a v-if="citation.doi" :href="`https://doi.org/${citation.doi}`" class="citation-link" :style="{ color: colors.accent }">
          DOI: {{ citation.doi }}
        </a>
        <a v-if="citation.url" :href="citation.url" class="citation-link" :style="{ color: colors.accent }">
          Link
        </a>
      </div>
      <div v-if="showBibtex" class="bibtex-section">
        <button @click="copyBibtex" class="copy-btn" :style="{ color: colors.accent, borderColor: colors.accent }">
          {{ copied ? '✓ Copied' : 'Copy BibTeX' }}
        </button>
        <pre class="bibtex-code" :style="{ background: isDark ? '#161a2e' : '#f8faff' }">{{ bibtex }}</pre>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { ref } from 'vue'
export default { name: 'CitationBlock' }
</script>

<style scoped>
.citation-block {
  display: flex;
  gap: 1rem;
  border: 1px solid;
  border-radius: 12px;
  padding: 1rem;
  margin: 1rem 0;
}

.citation-number {
  flex-shrink: 0;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 600;
  color: white;
}

.citation-content {
  flex: 1;
}

.citation-authors,
.citation-title,
.citation-venue {
  margin: 0 0 0.5rem;
}

.citation-title {
  font-weight: 600;
}

.citation-links {
  display: flex;
  gap: 1rem;
  margin-top: 0.5rem;
}

.citation-link {
  font-size: 0.85rem;
  text-decoration: none;
}

.citation-link:hover {
  text-decoration: underline;
}

.bibtex-section {
  margin-top: 1rem;
}

.copy-btn {
  padding: 0.4rem 0.8rem;
  border: 1px solid;
  border-radius: 6px;
  background: transparent;
  cursor: pointer;
  font-size: 0.8rem;
  font-weight: 500;
}

.bibtex-code {
  margin-top: 0.5rem;
  padding: 0.75rem;
  border-radius: 8px;
  font-size: 0.75rem;
  overflow-x: auto;
}
</style>
