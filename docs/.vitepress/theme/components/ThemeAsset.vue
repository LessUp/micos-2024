<script setup lang="ts">
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'

const props = defineProps<{
  light: string
  dark: string
  alt: string
  caption?: string
}>()

const { isDark } = useData()
const src = computed(() => withBase(isDark.value ? props.dark : props.light))
</script>

<template>
  <figure class="micos-theme-asset">
    <img :src="src" :alt="alt" loading="lazy">
    <figcaption v-if="caption">{{ caption }}</figcaption>
  </figure>
</template>
