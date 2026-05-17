---
layout: home
hero:
  name: MICOS-2024
  text: ' '
  actions:
    - theme: brand
      text: 简体中文
      link: /zh/
    - theme: alt
      text: English
      link: /en/
---

<script setup>
import { onMounted } from 'vue'
import { useRouter, withBase } from 'vitepress'

onMounted(() => {
  const router = useRouter()
  const savedLang = localStorage.getItem('micos-lang-preference')

  if (savedLang === 'zh' || savedLang === 'en') {
    router.go(withBase(`/${savedLang}/`))
    return
  }

  const browserLang = navigator.language || navigator.userLanguage || 'en-US'
  const nextLocale = browserLang.startsWith('zh') ? 'zh' : 'en'
  router.go(withBase(`/${nextLocale}/`))
})
</script>
