<script setup lang="ts">
defineProps<{
  items: Array<{
    authors: string
    title: string
    venue: string
    year: string
    link?: string
    note?: string
  }>
}>()
</script>

<template>
  <ol class="micos-references">
    <li v-for="item in items" :key="`${item.title}-${item.year}`" class="micos-reference">
      <p class="micos-reference__authors">{{ item.authors }}</p>
      <p class="micos-reference__title">{{ item.title }}</p>
      <p class="micos-reference__meta">{{ item.venue }} · {{ item.year }}</p>
      <p v-if="item.note" class="micos-reference__note">{{ item.note }}</p>
      <a
        v-if="item.link"
        class="micos-reference__link"
        :href="item.link"
        target="_blank"
        rel="noreferrer"
      >
        Open source / paper link
      </a>
    </li>
  </ol>
</template>
