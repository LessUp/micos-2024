<script setup lang="ts">
defineProps<{
  eyebrow?: string
  title: string
  lede?: string
}>()
</script>

<template>
  <section class="micos-section">
    <header class="micos-section__header">
      <p v-if="eyebrow" class="micos-section__eyebrow">{{ eyebrow }}</p>
      <h2 class="micos-section__title">{{ title }}</h2>
      <p v-if="lede" class="micos-section__lede">{{ lede }}</p>
    </header>
    <slot />
  </section>
</template>
