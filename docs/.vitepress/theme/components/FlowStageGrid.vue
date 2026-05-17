<script setup lang="ts">
defineProps<{
  stages: Array<{
    eyebrow?: string
    title: string
    summary: string
    href?: string
    bullets?: string[]
  }>
}>()
</script>

<template>
  <div class="micos-stage-grid">
    <article v-for="stage in stages" :key="stage.title" class="micos-stage">
      <p v-if="stage.eyebrow" class="micos-stage__eyebrow">{{ stage.eyebrow }}</p>
      <h3>
        <a v-if="stage.href" :href="stage.href">{{ stage.title }}</a>
        <span v-else>{{ stage.title }}</span>
      </h3>
      <p class="micos-stage__summary">{{ stage.summary }}</p>
      <ul v-if="stage.bullets?.length">
        <li v-for="bullet in stage.bullets" :key="bullet">{{ bullet }}</li>
      </ul>
    </article>
  </div>
</template>
