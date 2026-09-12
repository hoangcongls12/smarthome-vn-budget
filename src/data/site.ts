// src/data/site.ts
export const SITE_CONFIG = {
  name: 'Smart Home VN Budget',
  shortName: 'SHVN Budget',
  description: 'Xây dựng Smart Home giá rẻ cho người Việt - Review thiết bị, Hướng dẫn cài đặt Home Assistant, Automation tiết kiệm điện',
  tagline: 'Smart Home không đắt - Chỉ cần biết cách',
  url: 'https://smarthomevn.pages.dev',
  ogImage: '/og-default.jpg',
  favicon: '/favicon.ico',
  author: {
    name: 'Smart Home VN Budget Team',
    email: 'contact@smarthomevn.pages.dev',
    twitter: '@smarthomevn',
    github: 'https://github.com/smarthomevn',
  },
  navigation: [
    { label: 'Trang chủ', href: '/' },
    { label: 'Review', href: '/review' },
    { label: 'Hướng dẫn', href: '/huong-dan' },
    { label: 'Automation', href: '/automation' },
    { label: 'So sánh', href: '/so-sanh' },
    { label: 'Budget Build', href: '/budget-build' },
  ],
  categories: [
    { slug: 'thiet-bi-khoi-dau', name: 'Thiết bị khởi đầu', description: 'Bulb, Plug, Sensor - Budget <500k', icon: '💡' },
    { slug: 'hub-protocol', name: 'Hub & Protocol', description: 'Zigbee, Matter, Home Assistant, DIY', icon: '🔧' },
    { slug: 'automation', name: 'Automation & Scene', description: 'Tiết kiệm điện, An ninh, Tiện nghi', icon: '⚡' },
    { slug: 'review-so-sanh', name: 'Review & So sánh', description: 'Device A vs B, Brand X review', icon: '⚖️' },
    { slug: 'cai-dat', name: 'Hướng dẫn cài đặt', description: 'Flash Tasmota, ESPHome, HA addon', icon: '📋' },
  ],
  social: {
    github: 'https://github.com/smarthomevn',
    twitter: 'https://twitter.com/smarthomevn',
    facebook: 'https://facebook.com/smarthomevn',
    youtube: 'https://youtube.com/@smarthomevn',
    tiktok: 'https://tiktok.com/@smarthomevn',
  },
  affiliate: {
    disclaimer: 'Một số liên kết trong bài viết là liên kết affiliate. Nếu bạn mua qua các liên kết này, chúng tôi có thể nhận được hoa hồng nhỏ без chi phí thêm cho bạn. Điều này giúp duy trì hoạt động của trang web.',
    networks: ['shopee', 'lazada', 'amazon', 'gearvn', 'aliexpress'],
  },
  analytics: {
    ga4: 'G-XXXXXXXXXX', // Thay bằng GA4 Measurement ID thực
    umami: 'https://analytics.smarthomevn.pages.dev/script.js',
  },
  pagination: {
    postsPerPage: 10,
  },
  comments: {
    enabled: false,
    giscus: {
      repo: 'smarthomevn/smarthome-vn-budget',
      repoId: '',
      category: 'Announcements',
      categoryId: '',
    },
  },
} as const;

export type SiteConfig = typeof SITE_CONFIG;