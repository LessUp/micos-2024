<script setup lang="ts">
type HeroAction = {
  text: string
  link: string
  theme?: 'brand' | 'alt' | 'ghost'
  external?: boolean
}

defineProps<{
  eyebrow: string
  title: string
  lede: string
  caption?: string
  pills?: string[]
  actions?: HeroAction[]
}>()

const isExternal = (action: HeroAction): boolean =>
  action.external ?? /^https?:\/\//.test(action.link)
</script>

<template>
  <section class="micos-hero">
    <div class="micos-hero__shell">
      <div class="micos-hero__copy">
        <p class="micos-hero__eyebrow">{{ eyebrow }}</p>
        <h1 class="micos-hero__title">{{ title }}</h1>
        <p class="micos-hero__lede">{{ lede }}</p>
        <p v-if="caption" class="micos-hero__caption">{{ caption }}</p>

        <ul v-if="pills?.length" class="micos-hero__pills">
          <li v-for="pill in pills" :key="pill">{{ pill }}</li>
        </ul>

        <div v-if="actions?.length" class="micos-hero__actions">
          <a
            v-for="action in actions"
            :key="`${action.text}-${action.link}`"
            :href="action.link"
            class="micos-button"
            :class="`is-${action.theme ?? 'ghost'}`"
            :target="isExternal(action) ? '_blank' : undefined"
            :rel="isExternal(action) ? 'noreferrer' : undefined"
          >
            {{ action.text }}
          </a>
        </div>
      </div>

      <div class="micos-hero__aside">
        <slot />
      </div>
    </div>
  </section>
</template>
