# Smart Home VN Budget - Development Notes

## 📋 Sprint 1 Progress Tracker

### ✅ Completed (Day 1)
- [x] Project charter & Sprint 1 plan
- [x] Niche selection: Smart Home Budget VN
- [x] Technical stack finalized (Astro + Tailwind + Cloudflare Pages)
- [x] GitHub repo structure created
- [x] Core components: SEO, Header, Footer, UI kit (Button, Card, Badge, Image, AnchorLink)
- [x] Layouts: BaseLayout, ArticleLayout
- [x] Homepage with hero, categories, budget build highlight, latest posts, newsletter
- [x] 3 pilot articles created as Markdown content
- [x] Affiliate system: data structure, link cloaking function
- [x] Cloudflare Pages config (wrangler.toml, _redirects, headers)
- [x] PWA manifest, sitemap, RSS feed
- [x] GitHub Actions CI/CD workflow
- [x] README with full documentation

### 🔄 In Progress / Next Steps

#### Day 2 (Technical Setup)
- [ ] Initialize Git repo & push to GitHub
- [ ] Connect to Cloudflare Pages
- [ ] Configure custom domain (smarthomevn.pages.dev)
- [ ] Set up GA4 & GSC
- [ ] Deploy Umami analytics (Cloudflare Workers)
- [ ] Verify all redirects & headers work

#### Day 3 (Brand & Content System)
- [ ] Create 3 logo/brand options (Canva)
- [ ] Finalize topical map (25-30 keywords)
- [ ] Create content brief template in Notion
- [ ] Set up Notion workspace with all databases

#### Day 4-5 (Affiliate & Systems)
- [ ] Register 5 affiliate programs
- [ ] Populate affiliate link database
- [ ] Test cloaking redirects
- [ ] Configure UTM tracking

#### Day 7-10 (Content Production)
- [ ] Write 3 pilot articles (already drafted in content/blog/)
- [ ] Owner review & approval
- [ ] Publish & submit to GSC

#### Day 11+ (Launch & Monitor)
- [ ] Submit sitemap to GSC
- [ ] Monitor indexing
- [ ] Set up weekly reporting template
- [ ] Plan Sprint 2 content

## 🎯 Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | Astro 4.x | Static, fast, zero-JS default, MDX support |
| Hosting | Cloudflare Pages | Free, unlimited bandwidth, edge network VN, Functions support |
| Styling | Tailwind CSS | Utility-first, small bundle, dark mode ready |
| Content | Markdown/MDX + Content Collections | Type-safe, version controlled, no CMS cost |
| Analytics | GA4 + Umami | Privacy-friendly backup, free self-hosted |
| Affiliate Cloaking | Cloudflare Pages Functions | Free, serverless, edge runtime |
| Language | Vietnamese only | Target market VN, SEO opportunity |
| Monetization | Affiliate only (start) | No product creation, low risk |

## 📊 KPI Targets (Revisited)

| Metric | Month 1 | Month 3 | Month 6 |
|--------|---------|---------|---------|
| Articles Published | 12 | 35 | 70 |
| Indexed Pages | 10 | 30 | 60 |
| Organic Clicks/Month | 100 | 800 | 3000 |
| Affiliate Clicks/Month | 20 | 150 | 600 |
| Revenue/Month | $5-15 | $50-100 | $150-300 |

## 🔑 Environment Variables Needed

### Required for Production
- `GA4_MEASUREMENT_ID` - Google Analytics 4 Measurement ID
- `UMAMI_WEBSITE_ID` - Umami website ID
- `UMAMI_SCRIPT_URL` - Umami script URL (self-hosted)
- `CLOUDFLARE_ACCOUNT_ID` - Cloudflare account ID
- `CLOUDFLARE_API_TOKEN` - Cloudflare API token (Pages deploy permission)

### Affiliate Program IDs
- `SHOPEE_AFFILIATE_ID`
- `LAZADA_AFFILIATE_ID`
- `AMAZON_ASSOCIATES_TAG`
- `GEARVN_REF`
- `ANPHUOC_REF`
- `ALIEXPRESS_AFF_FID`

### Optional
- `TWITTER_HANDLE`
- `FACEBOOK_APP_ID`
- Newsletter API keys (ButtonDown, MailerLite)

## 🛠 Tools & Accounts to Create

| Tool | Purpose | Status |
|------|---------|--------|
| GitHub | Repository hosting | ⏳ |
| Cloudflare Pages | Hosting + Functions | ⏳ |
| Cloudflare Workers | Umami analytics | ⏳ |
| Google Analytics 4 | Traffic tracking | ⏳ |
| Google Search Console | SEO monitoring | ⏳ |
| Ahrefs Webmaster Tools | Backlink/keyword data | ⏳ |
| Notion | Project management | ✅ Template ready |
| Canva | Logo/brand assets | ⏳ |
| Shopee Affiliate | Affiliate program | ⏳ |
| Lazada Affiliate | Affiliate program | ⏳ |
| Amazon Associates SG | Affiliate program | ⏳ |
| GearVN/AnPhuoc Direct | Affiliate program | ⏳ |

## 📝 Content Pipeline (Next 10 Articles)

### Priority 1: Pillar + Cluster (Week 1-2)
1. ✅ Budget Build Guide (<5tr) - PILLAR
2. ✅ Sonoff Dongle Review - CLUSTER
3. ✅ Smart Bulb Comparison - CLUSTER

### Priority 2: High-Intent Commercial (Week 2-3)
4. **Sonoff MINI R4 Matter Switch Review** - `sonoff mini r4`, `matter switch`
5. **Aqara Sensor Full Lineup Review** - `aqara sensor`, `zigbee sensor`
6. **Raspberry Pi 4 vs Mini PC cho HA** - `home assistant hardware`, `mini pc ha`
6. **Zigbee2MQTT vs ZHA So sánh** - `zigbee2mqtt vs zha`
7. **Top 10 Automation Ideas cho người mới** - `home assistant automation`
8. **Cách flash Tasmota cho Sonoff/ESP** - `flash tasmota`, `sonoff tasmota`
9. **Matter/Thread giải thích cho người Việt** - `matter protocol`, `thread protocol`
10. **Smart Home bảo mật: VLAN, Firewall, Local-only** - `smart home security`

### Priority 3: Long-tail Informational (Week 3-4)
11. **Cài đặt Home Assistant OS trên Proxmox/VM**
12. **Backup & Restore Home Assistant hoàn chỉnh**
13. **Tích hợp Google Home/Apple HomeKit với HA**
14. **Node-RED cho người không code**
15. **Frigate NVR với Coral TPU - Hướng dẫn chi tiết**

## 💡 Ideas for Scale (Post Month 3)

### Content Expansion
- Video content (YouTube/TikTok/Reels) - repurpose articles
- Email newsletter - weekly deals + new content
- Tool/Calculator: "Smart Home Cost Calculator"
- Comparison tables as interactive components
- User-generated content: "Setup của bạn"

### Monetization
- Direct brand partnerships (higher commission)
- Digital product: "Smart Home Starter Checklist PDF" (lead magnet)
- Course: "Xây Smart Home từ A-Z" (premium)
- Consulting: "Tư vấn thiết kế hệ thống" (high ticket)

### Technical
- Search functionality (Pagefind/Algolia)
- Comments system (Giscus)
- User accounts (wishlist, price alerts)
- API for price tracking

## 🚨 Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Algorithm update | Medium | High | Diversify traffic: social, email, direct |
| Affiliate program shutdown | Low | High | Multiple programs, direct relationships |
| Content velocity too slow | High | Medium | Batch writing, templates, AI-assisted outlines |
| Technical SEO issues | Low | High | Regular audits, Cloudflare Workers for headers |
| Competitor enters niche | Medium | Medium | Build brand, community, email list |
| Burnout (solo) | Medium | High | Sustainable pace (5-7h/week), systems over heroics |

## 📅 Weekly Routine (Owner - 1h/week)

### Sunday (30 min)
- [ ] Review weekly report in Notion
- [ ] Approve/reject content briefs
- [ ] Strategic decision: pivot/scale/maintain
- [ ] Check revenue & affiliate dashboard

### Wednesday (15 min)
- [ ] Quick traffic check (GA4/Umami)
- [ ] Respond to comments/questions
- [ ] Share new content to social

### As needed (15 min)
- [ ] Affiliate program updates
- [ ] Technical issues
- [ ] Partnership inquiries

---

**Last Updated**: Sprint 1 - Day 1 Complete
**Next Review**: End of Day 2 (Technical Setup Complete)