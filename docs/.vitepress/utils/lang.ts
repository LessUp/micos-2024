/**
 * 语言检测和存储工具函数
 * SSR 安全，兼容隐私模式
 */

const LANG_KEY = 'micos-lang-preference'

/**
 * 安全获取 localStorage
 */
function getStorage(): Storage | null {
  if (typeof window === 'undefined') return null
  try {
    return window.localStorage
  } catch {
    // 隐私模式下可能抛出异常
    return null
  }
}

/**
 * 获取保存的语言偏好
 */
export function getSavedLangPreference(): 'zh' | 'en' | null {
  const storage = getStorage()
  if (!storage) return null

  const saved = storage.getItem(LANG_KEY)
  if (saved === 'zh' || saved === 'en') {
    return saved
  }
  return null
}

/**
 * 保存语言偏好
 */
export function saveLangPreference(lang: 'zh' | 'en'): void {
  const storage = getStorage()
  if (storage) {
    storage.setItem(LANG_KEY, lang)
  }
}

/**
 * 检测浏览器语言
 */
export function detectBrowserLang(): 'zh' | 'en' {
  if (typeof navigator === 'undefined') return 'en'

  const browserLang = (
    navigator.language ||
    (navigator as any).userLanguage ||
    'en'
  ).toLowerCase()

  return browserLang.startsWith('zh') ? 'zh' : 'en'
}

/**
 * 获取目标语言（综合判断）
 * 优先级：保存的偏好 > 浏览器语言
 */
export function getTargetLang(): 'zh' | 'en' {
  return getSavedLangPreference() ?? detectBrowserLang()
}
