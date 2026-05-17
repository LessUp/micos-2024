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
import { withBase } from 'vitepress'
import { getTargetLang } from './.vitepress/utils/lang'

// 立即执行跳转（同步代码，减少闪烁）
if (typeof window !== 'undefined') {
  const targetLang = getTargetLang()
  // 使用 replace 避免污染历史记录
  window.location.replace(withBase(`/${targetLang}/`))
}
</script>

<template>
  <div class="lang-redirect-splash">
    <div class="spinner"></div>
    <p>Detecting language...</p>
  </div>
</template>

<style>
.lang-redirect-splash {
  position: fixed;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  background: var(--vp-c-bg);
  color: var(--vp-c-text-2);
  font-size: 14px;
  z-index: 99999;
}

.spinner {
  width: 24px;
  height: 24px;
  border: 2px solid var(--vp-c-divider);
  border-top-color: var(--vp-c-brand-1);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
