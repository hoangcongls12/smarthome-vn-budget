// src/utils/seo.ts
export interface SEOProps {
  title: string;
  description: string;
  canonical?: string;
  ogImage?: string;
  ogType?: 'website' | 'article';
  twitterCard?: 'summary' | 'summary_large_image';
  publishedTime?: string;
  modifiedTime?: string;
  author?: string;
  section?: string;
  tags?: string[];
  noindex?: boolean;
  nofollow?: boolean;
  jsonLd?: Record<string, unknown>;
}

export const SITE = {
  name: 'Smart Home VN Budget',
  description: 'Xây dựng Smart Home giá rẻ cho người Việt - Review thiết bị, Hướng dẫn cài đặt Home Assistant, Automation tiết kiệm điện',
  url: 'https://smarthomevn.pages.dev',
  ogImage: '/og-default.jpg',
  twitterHandle: '@smarthomevn',
  author: 'Smart Home VN Budget Team',
} as const;

export function generateSEO(props: SEOProps) {
  const url = props.canonical ? `${SITE.url}${props.canonical}` : SITE.url;
  const ogImage = props.ogImage ? `${SITE.url}${props.ogImage}` : SITE.ogImage;

  const metaTags = [
    { name: 'viewport', content: 'width=device-width, initial-scale=1' },
    { name: 'description', content: props.description },
    { name: 'theme-color', content: '#0ea5e9' },
    { property: 'og:site_name', content: SITE.name },
    { property: 'og:title', content: props.title },
    { property: 'og:description', content: props.description },
    { property: 'og:url', content: url },
    { property: 'og:image', content: ogImage },
    { property: 'og:type', content: props.ogType || 'website' },
    { name: 'twitter:card', content: props.twitterCard || 'summary_large_image' },
    { name: 'twitter:site', content: SITE.twitterHandle },
    { name: 'twitter:title', content: props.title },
    { name: 'twitter:description', content: props.description },
    { name: 'twitter:image', content: ogImage },
  ];

  if (props.publishedTime) {
    metaTags.push({ property: 'article:published_time', content: props.publishedTime });
  }
  if (props.modifiedTime) {
    metaTags.push({ property: 'article:modified_time', content: props.modifiedTime });
  }
  if (props.author) {
    metaTags.push({ property: 'article:author', content: props.author });
  }
  if (props.section) {
    metaTags.push({ property: 'article:section', content: props.section });
  }
  if (props.tags && props.tags.length > 0) {
    props.tags.forEach((tag) => {
      metaTags.push({ property: 'article:tag', content: tag });
    });
  }
  if (props.noindex) {
    metaTags.push({ name: 'robots', content: 'noindex' });
  }
  if (props.nofollow) {
    metaTags.push({ name: 'robots', content: 'nofollow' });
  }

  const jsonLd = props.jsonLd ? [props.jsonLd] : [];

  return { metaTags, jsonLd, canonical: url };
}

export function generateArticleJsonLd(props: {
  title: string;
  description: string;
  url: string;
  image: string;
  publishedTime: string;
  modifiedTime: string;
  author: string;
  publisher: string;
}) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: props.title,
    description: props.description,
    url: props.url,
    image: props.image,
    datePublished: props.publishedTime,
    dateModified: props.modifiedTime,
    author: {
      '@type': 'Person',
      name: props.author,
    },
    publisher: {
      '@type': 'Organization',
      name: props.publisher,
      logo: {
        '@type': 'ImageObject',
        url: `${SITE.url}/logo.png`,
      },
    },
    mainEntityOfPage: {
      '@type': 'WebPage',
      '@id': props.url,
    },
  };
}

export function generateBreadcrumbJsonLd(items: Array<{ name: string; url: string }>) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: item.url,
    })),
  };
}

export function generateWebSiteJsonLd() {
  return {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: SITE.name,
    url: SITE.url,
    potentialAction: {
      '@type': 'SearchAction',
      target: {
        '@type': 'EntryPoint',
        urlTemplate: `${SITE.url}/search?q={search_term_string}`,
      },
      'query-input': 'required name=search_term_string',
    },
  };
}

export function generateOrganizationJsonLd() {
  return {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: SITE.name,
    url: SITE.url,
    logo: `${SITE.url}/logo.png`,
    sameAs: [
      'https://github.com/smarthomevn',
      'https://twitter.com/smarthomevn',
      'https://facebook.com/smarthomevn',
    ],
    contactPoint: {
      '@type': 'ContactPoint',
      telephone: '',
      contactType: 'customer service',
      availableLanguage: ['Vietnamese', 'English'],
    },
  };
}