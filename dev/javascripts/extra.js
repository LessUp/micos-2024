/**
 * =============================================================================
 * MICOS-2024 自定义 JavaScript - 最强交互体验
 * =============================================================================
 */

(function() {
  'use strict';

  // ==================== 平滑滚动到锚点 ====================
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
        target.classList.add('highlight-anchor');
        setTimeout(() => {
          target.classList.remove('highlight-anchor');
        }, 2000);
      }
    });
  });

  // ==================== 滚动进度条 ====================
  function createProgressBar() {
    const progressBar = document.createElement('div');
    progressBar.id = 'scroll-progress';
    progressBar.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 0%;
      height: 3px;
      background: linear-gradient(90deg, var(--md-primary-fg-color), var(--md-accent-fg-color));
      z-index: 10000;
      transition: width 0.1s;
    `;
    document.body.appendChild(progressBar);
    
    window.addEventListener('scroll', function() {
      const winScroll = document.body.scrollTop || document.documentElement.scrollTop;
      const height = document.documentElement.scrollHeight - document.documentElement.clientHeight;
      const scrolled = (winScroll / height) * 100;
      progressBar.style.width = scrolled + '%';
    });
  }
  createProgressBar();

  // ==================== 图片点击放大 ====================
  document.querySelectorAll('.md-typeset img').forEach(img => {
    img.style.cursor = 'zoom-in';
    img.addEventListener('click', function() {
      const overlay = document.createElement('div');
      overlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0,0,0,0.9);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 10000;
        cursor: zoom-out;
        animation: fadeIn 0.3s;
      `;
      
      const enlarged = document.createElement('img');
      enlarged.src = this.src;
      enlarged.style.cssText = `
        max-width: 90%;
        max-height: 90%;
        object-fit: contain;
        border-radius: 8px;
      `;
      
      overlay.appendChild(enlarged);
      document.body.appendChild(overlay);
      
      overlay.addEventListener('click', () => overlay.remove());
    });
  });

  // ==================== 外部链接在新窗口打开 ====================
  document.querySelectorAll('.md-typeset a').forEach(link => {
    if (link.hostname && link.hostname !== location.hostname) {
      link.setAttribute('target', '_blank');
      link.setAttribute('rel', 'noopener noreferrer');
    }
  });

  // ==================== 键盘快捷键 ====================
  document.addEventListener('keydown', function(e) {
    // Ctrl/Cmd + K 聚焦搜索
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      const searchInput = document.querySelector('.md-search__input');
      if (searchInput) searchInput.focus();
    }
  });

  // ==================== 动画关键帧 ====================
  const style = document.createElement('style');
  style.textContent = `
    @keyframes fadeIn {
      from { opacity: 0; }
      to { opacity: 1; }
    }
    .highlight-anchor {
      animation: highlight 2s ease;
    }
    @keyframes highlight {
      0%, 100% { background: transparent; }
      50% { background: rgba(255, 64, 129, 0.2); }
    }
  `;
  document.head.appendChild(style);

  console.log('%c MICOS-2024 ', 'background: linear-gradient(135deg, #3f51b5, #ff4081); color: white; font-size: 20px; font-weight: bold; padding: 8px 16px; border-radius: 8px;');
  console.log('%c 专业宏基因组分析平台 ', 'color: #3f51b5; font-size: 14px;');
})();
