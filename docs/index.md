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

  // 优先检查用户保存的语言偏好
  const savedLang = localStorage.getItem('micos-lang-preference')
  if (savedLang) {
    router.go(withBase(`/${savedLang}/`))
    return
  }

  // 否则检测浏览器语言
  const browserLang = navigator.language || navigator.userLanguage
  const lang = browserLang.startsWith('zh') ? 'zh' : 'en'
  router.go(withBase(`/${lang}/`))
})
</script>
