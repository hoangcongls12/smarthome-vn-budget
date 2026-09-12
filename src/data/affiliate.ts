// src/data/affiliate.ts
export interface AffiliateLink {
  id: string;
  program: string;
  productName: string;
  productUrl: string;
  affiliateUrl: string;
  image?: string;
  price?: number;
  originalPrice?: number;
  rating?: number;
  reviewCount?: number;
  badge?: 'Best Seller' | 'Budget Pick' | 'Premium' | 'New';
  description?: string;
}

export const AFFILIATE_PROGRAMS = {
  shopee: {
    name: 'Shopee Affiliate',
    baseUrl: 'https://shopee.vn',
    commission: '2-8%',
    cookieDays: 30,
    trackingParam: 'af_id',
  },
  lazada: {
    name: 'Lazada Affiliate',
    baseUrl: 'https://www.lazada.vn',
    commission: '1-7%',
    cookieDays: 30,
    trackingParam: 'affiliate_id',
  },
  amazon: {
    name: 'Amazon Associates',
    baseUrl: 'https://www.amazon.com',
    commission: '1-4%',
    cookieDays: 24, // 24h for US, 30 days for some regions
    trackingParam: 'tag',
  },
  gearvn: {
    name: 'GearVN Direct',
    baseUrl: 'https://gearvn.com',
    commission: '5-10%',
    cookieDays: 30,
    trackingParam: 'ref',
  },
  anphuoc: {
    name: 'An Phước Direct',
    baseUrl: 'https://anphuoc.com',
    commission: '5-10%',
    cookieDays: 30,
    trackingParam: 'ref',
  },
  aliexpress: {
    name: 'AliExpress EPN',
    baseUrl: 'https://www.aliexpress.com',
    commission: '3-9%',
    cookieDays: 30,
    trackingParam: 'aff_fid',
  },
} as const;

export function createAffiliateLink(
  program: keyof typeof AFFILIATE_PROGRAMS,
  productPath: string,
  customParams?: Record<string, string>
): string {
  const config = AFFILIATE_PROGRAMS[program];
  const url = new URL(config.baseUrl + productPath);
  
  const defaultParams = {
    utm_source: 'smarthomevn',
    utm_medium: 'affiliate',
    utm_campaign: 'content',
    [config.trackingParam]: 'smarthomevn',
  };

  Object.entries({ ...defaultParams, ...customParams }).forEach(([key, value]) => {
    url.searchParams.set(key, value);
  });

  return url.toString();
}

export function createCloakedLink(slug: string): string {
  return `/go/${slug}`;
}

export const SAMPLE_AFFILIATE_LINKS: AffiliateLink[] = [
  {
    id: 'sonoff-zbdongle-e',
    program: 'shopee',
    productName: 'Sonoff Zigbee 3.0 USB Dongle Plus (E)',
    productUrl: 'https://shopee.vn/product/123456789',
    affiliateUrl: createAffiliateLink('shopee', '/product/123456789'),
    price: 180000,
    badge: 'Best Seller',
    description: 'Dongle Zigbee tốt nhất cho Home Assistant, hỗ trợ Zigbee 3.0, firmware cập nhật qua OTA',
  },
  {
    id: 'xiaomi-smart-bulb',
    program: 'shopee',
    productName: 'Xiaomi Mi Smart LED Bulb Essential (WiFi)',
    productUrl: 'https://shopee.vn/product/987654321',
    affiliateUrl: createAffiliateLink('shopee', '/product/987654321'),
    price: 120000,
    originalPrice: 150000,
    badge: 'Budget Pick',
    description: 'Bóng đèn WiFi giá rẻ, không cần hub, tích hợp Google Home, Alexa, Mi Home',
  },
  {
    id: 'aqara-motion-sensor',
    program: 'lazada',
    productName: 'Aqara Motion Sensor P1 (Zigbee 3.0)',
    productUrl: 'https://www.lazada.vn/products/456789123',
    affiliateUrl: createAffiliateLink('lazada', '/products/456789123'),
    price: 220000,
    badge: 'Best Seller',
    description: 'Cảm biến chuyển động Zigbee 3.0, pin CR2450 dùng 2 năm, góc rộng 170°',
  },
  {
    id: 'sonoff-mini-r4',
    program: 'gearvn',
    productName: 'Sonoff MINI R4 Matter Switch',
    productUrl: 'https://gearvn.com/sonoff-mini-r4',
    affiliateUrl: createAffiliateLink('gearvn', '/sonoff-mini-r4'),
    price: 160000,
    badge: 'New',
    description: 'Công tắc thông minh Matter, nắm trong tay, hỗ trợ Apple Home, HA, Alexa, Google',
  },
  {
    id: 'raspberry-pi-4-4gb',
    program: 'amazon',
    productName: 'Raspberry Pi 4 Model B 4GB',
    productUrl: 'https://www.amazon.com/dp/B07TD42S24',
    affiliateUrl: createAffiliateLink('amazon', '/dp/B07TD42S24', { tag: 'smarthomevn-20' }),
    price: 1200000,
    badge: 'Premium',
    description: 'Chạy Home Assistant OS mượt mà, 4GB RAM, Gigabit Ethernet, USB 3.0',
  },
];