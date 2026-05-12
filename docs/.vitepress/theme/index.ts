import DefaultTheme from 'vitepress/theme'
import { watch } from 'vue'
import { useData } from 'vitepress'
import './style.css'

export default {
  ...DefaultTheme,
  setup() {
    if (DefaultTheme.setup) {
      DefaultTheme.setup()
    }

    // 监听语言变化并保存用户偏好
    const { lang } = useData()
    watch(lang, (newLang) => {
      if (newLang === 'zh-CN') {
        localStorage.setItem('micos-lang-preference', 'zh')
      } else if (newLang === 'en-US') {
        localStorage.setItem('micos-lang-preference', 'en')
      }
    })
  }
}
