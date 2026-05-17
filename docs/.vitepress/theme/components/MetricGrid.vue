<script setup lang="ts">
defineProps<{
  items: Array<{
    label: string
    value: string
    detail: string
  }>
}>()
</script>

<template>
  <div class="micos-metric-grid">
    <article v-for="item in items" :key="item.label" class="micos-metric">
      <p class="micos-metric__label">{{ item.label }}</p>
      <h3 class="micos-metric__value">{{ item.value }}</h3>
      <p class="micos-metric__detail">{{ item.detail }}</p>
    </article>
  </div>
</template>
