# Smart Home VN Budget - Project README

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ (LTS recommended)
- npm 9+ or pnpm 8+
- Git

### Installation
```bash
# Clone repository
git clone https://github.com/smarthomevn/smarthome-vn-budget.git
cd smarthome-vn-budget

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env
# Edit .env with your values

# Start development server
npm run dev
```

Visit `http://localhost:4321` to see the site.

## 📁 Project Structure

```
smarthome-vn-budget/
├── public/                 # Static assets
│   ├── _redirects         # Cloudflare Pages redirects
│   ├── site.webmanifest   # PWA manifest
│   ├── favicon.svg        # Favicon
│   ├── icons/             # PWA icons
│   └── images/            # Static images
├── src/
│   ├── components/        # Reusable components
│   │   ├── ui/           # Base UI components (Button, Card, Badge, etc.)
│   │   └── layout/       # Layout components (Header, Footer)
│   ├── content/          # Content collections
│   │   ├── blog/         # Blog posts (Markdown/MDX)
│   │   └── config.ts     # Content schema
│   ├── data/             # Static data
│   │   ├── site.ts       # Site configuration
│   │   └── affiliate.ts  # Affiliate links & programs
│   ├── layouts/          # Page layouts
│   │   ├── BaseLayout.astro
│   │   └── ArticleLayout.astro
│   ├── pages/            # Route pages
│   │   ├── index.astro   # Homepage
│   │   ├── 404.astro
│   │   ├── rss.xml.js
│   │   └── sitemap-index.xml.js
│   ├── styles/           # Global styles
│   │   └── global.css
│   └── utils/            # Utility functions
│       ├── seo.ts        # SEO helpers
│       └── helpers.ts    # General helpers
├── astro.config.mjs      # Astro configuration
├── tailwind.config.mjs   # Tailwind CSS configuration
├── tsconfig.json         # TypeScript configuration
├── wrangler.toml         # Cloudflare Pages config
├── package.json
└── README.md
```

## 🛠 Available Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server at localhost:4321 |
| `npm run build` | Build production site to `dist/` |
| `npm run preview` | Preview production build locally |
| `npm run format` | Format code with Prettier |
| `npm run lint` | Lint code with ESLint |
| `npm run astro` | Run Astro CLI commands |

## 📝 Content Management

### Adding a new blog post

1. Create new file in `src/content/blog/` with `.md` or `.mdx` extension
2. Add frontmatter (see existing posts for schema)
3. Write content in Markdown/MDX
4. Images: place in `public/images/blog/` and reference as `/images/blog/filename.jpg`

### Frontmatter Schema

```yaml
---
title: 'Bài viết mới'              # Required, max 100 chars
description: 'Mô tả ngắn'          # Required, max 200 chars
pubDate: '2024-09-10'             # Required, ISO date
updatedDate: '2024-09-10'         # Optional
author: 'Tác giả'                 # Optional, default from config
category: 'Review'                # Required
tags: ['tag1', 'tag2']            # Optional array
ogImage: '/og-image.jpg'          # Optional, for social sharing
readingTime: 10                   # Optional, auto-calculated if missing
featured: false                   # Optional, show on homepage
draft: false                      # Optional, exclude from production
affiliateLinks: []                # Optional, see affiliate.ts
---
```

## 🎨 Styling

- **Framework**: Tailwind CSS v3.4+
- **Typography**: `@tailwindcss/typography` for prose content
- **Forms**: `@tailwindcss/forms` for form styling
- **Aspect Ratio**: `@tailwindcss/aspect-ratio`
- **Custom Colors**: Primary (Sky), Accent (Fuchsia)
- **Dark Mode**: Not implemented (can be added via `class` strategy)

## 🔧 Key Features

### SEO Optimized
- Dynamic meta tags per page
- Open Graph & Twitter Cards
- JSON-LD Structured Data (Article, Breadcrumb, WebSite, Organization)
- Sitemap & RSS feed auto-generated
- Canonical URLs
- robots.txt ready

### Performance
- Static site generation (SSG)
- Zero JS by default (Astro islands)
- Optimized images (Astro Image - configure in astro.config.mjs)
- Preconnect/dns-prefetch for fonts & analytics
- Cloudflare Pages edge caching

### Affiliate System
- Centralized affiliate link management (`src/data/affiliate.ts`)
- Cloaked links via `/go/:slug` redirects (Cloudflare Pages Functions)
- UTM parameter auto-injection
- Multiple program support (Shopee, Lazada, Amazon, GearVN, etc.)

### Analytics Ready
- Google Analytics 4 (GA4)
- Umami (self-hosted, privacy-friendly)
- Easy to add more

## 🚀 Deployment

### Cloudflare Pages (Recommended)

1. Push to GitHub
2. Connect repository in Cloudflare Pages
3. Build settings:
   - Build command: `npm run build`
   - Output directory: `dist`
   - Node version: 18 (or 20)
4. Add environment variables in Pages dashboard
5. Deploy!

### Alternative: Vercel/Netlify

```bash
# Vercel
npx vercel --prod

# Netlify
npx netlify deploy --prod --dir=dist
```

### Custom Domain

1. Add domain in Cloudflare Pages → Custom domains
2. Update `SITE_URL` in environment variables
3. Update `site` in `astro.config.mjs`
4. Redeploy

## 📊 Analytics Setup

### Google Analytics 4
1. Create GA4 property at analytics.google.com
2. Copy Measurement ID (G-XXXXXXXXXX)
3. Add to `.env` and Cloudflare Pages env vars

### Umami (Self-hosted - Free on Cloudflare Workers)
1. Fork [umami-software/umami](https://github.com/umami-software/umami)
2. Deploy to Cloudflare Workers (free tier)
3. Add script URL and Website ID to env vars

## 💰 Affiliate Setup

1. Register for affiliate programs:
   - Shopee Affiliate (Vietnam)
   - Lazada Affiliate (Vietnam)
   - Amazon Associates (Singapore/US)
   - GearVN/AnPhuoc (Direct contact)
   - AliExpress EPN
2. Add your affiliate IDs to `.env`
3. Update `src/data/affiliate.ts` with your tracking parameters
4. Use `createAffiliateLink()` in content

## 🧪 Testing

```bash
# Type checking
npx astro check

# Lint
npm run lint

# Format check
npm run format -- --check

# Build test
npm run build
```

## 📦 Production Checklist

- [ ] Update `SITE_URL` in `astro.config.mjs` and env vars
- [ ] Configure GA4 Measurement ID
- [ ] Set up Umami or alternative analytics
- [ ] Register affiliate programs & add IDs
- [ ] Generate PWA icons (use `pwa-asset-generator`)
- [ ] Create `og-default.jpg` (1200x630) for social sharing
- [ ] Create category OG images
- [ ] Set up custom domain & SSL
- [ ] Submit sitemap to Google Search Console
- [ ] Configure Cloudflare caching rules
- [ ] Test all affiliate links
- [ ] Verify 404 page works
- [ ] Test mobile responsiveness
- [ ] Check Core Web Vitals

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## 📄 License

MIT License - Feel free to use for your own projects.

## 🙏 Acknowledgments

- [Astro](https://astro.build) - The web framework for content-driven websites
- [Tailwind CSS](https://tailwindcss.com) - Utility-first CSS framework
- [Cloudflare Pages](https://pages.cloudflare.com) - Free static site hosting
- [Home Assistant](https://home-assistant.io) - Open source home automation
- Vietnamese Smart Home Community

---

**Built with ❤️ for the Vietnamese Smart Home community**