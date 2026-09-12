// functions/api/redirect/[slug].ts
// Cloudflare Pages Function for affiliate link cloaking
// Deploy: npx wrangler pages deploy dist --project-name=smarthome-vn-budget

import { AFFILIATE_LINKS } from '../../src/data/affiliate';

interface Env {
  // Bindings
  AFFILIATE_KV?: KVNamespace;
  // Secrets (set in Cloudflare Pages dashboard)
  GA4_MEASUREMENT_ID?: string;
  UMAMI_WEBSITE_ID?: string;
}

interface AffiliateLink {
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

// In-memory fallback (for development)
const linkMap: Record<string, AffiliateLink> = Object.fromEntries(
  AFFILIATE_LINKS.map((link) => [link.id, link])
);

export async function onRequestGet(context: RequestContext<Env>): Promise<Response> {
  const { params, request, env } = context;
  const slug = params.slug as string;

  // Look up link
  let link = linkMap[slug];

  // Try KV if available (production)
  if (!link && env.AFFILIATE_KV) {
    const kvData = await env.AFFILIATE_KV.get(`affiliate:${slug}`, 'json');
    if (kvData) link = kvData as AffiliateLink;
  }

  if (!link) {
    return new Response('Link not found', { status: 404 });
  }

  // Track click (async, don't await)
  trackClick(slug, link, request, env).catch(console.error);

  // Redirect to affiliate URL
  return Response.redirect(link.affiliateUrl, 302);
}

async function trackClick(
  slug: string,
  link: AffiliateLink,
  request: Request,
  env: Env
): Promise<void> {
  const timestamp = new Date().toISOString();
  const referer = request.headers.get('referer') || 'direct';
  const userAgent = request.headers.get('user-agent') || 'unknown';
  const ip = request.headers.get('cf-connecting-ip') || 'unknown';
  const country = request.headers.get('cf-ipcountry') || 'unknown';

  // Log to console (visible in Cloudflare Pages Functions logs)
  console.log(
    JSON.stringify({
      event: 'affiliate_click',
      slug,
      program: link.program,
      productName: link.productName,
      timestamp,
      referer,
      userAgent,
      ip: ip.substring(0, 8) + 'xxx', // Partial IP for privacy
      country,
    })
  );

  // Send to GA4 Measurement Protocol (if configured)
  if (env.GA4_MEASUREMENT_ID) {
    await sendGA4Event(env.GA4_MEASUREMENT_ID, {
      client_id: getClientId(request),
      events: [
        {
          name: 'affiliate_click',
          params: {
            affiliate_program: link.program,
            affiliate_product: link.productName,
            affiliate_slug: slug,
            link_url: link.affiliateUrl,
            referer,
            country,
          },
        },
      ],
    });
  }

  // Send to Umami (if configured)
  if (env.UMAMI_WEBSITE_ID) {
    await sendUmamiEvent(env.UMAMI_WEBSITE_ID, {
      type: 'event',
      payload: {
        event_name: 'affiliate_click',
        event_data: {
          slug,
          program: link.program,
          product: link.productName,
        },
        hostname: new URL(request.url).hostname,
        url: link.affiliateUrl,
        referrer: referer,
      },
    });
  }
}

function getClientId(request: Request): string {
  // Try to get GA client ID from cookie
  const cookie = request.headers.get('cookie') || '';
  const gaMatch = cookie.match(/_ga=([^;]+)/);
  if (gaMatch) {
    const parts = gaMatch[1].split('.');
    if (parts.length >= 4) {
      return `${parts[2]}.${parts[3]}`;
    }
  }
  // Generate anonymous ID from IP + User Agent
  const ip = request.headers.get('cf-connecting-ip') || 'unknown';
  const ua = request.headers.get('user-agent') || 'unknown';
  return hashString(`${ip}|${ua}`).substring(0, 16);
}

function hashString(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return Math.abs(hash).toString(16);
}

async function sendGA4Event(measurementId: string, data: any): Promise<void> {
  try {
    await fetch(`https://www.google-analytics.com/mp/collect?measurement_id=${measurementId}&api_secret=${''}`, {
      method: 'POST',
      body: JSON.stringify(data),
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    console.error('GA4 event failed:', e);
  }
}

async function sendUmamiEvent(websiteId: string, data: any): Promise<void> {
  try {
    // Umami typically receives events via script, but can accept API
    // This is a placeholder for custom Umami endpoint
    console.log('Umami event:', data);
  } catch (e) {
    console.error('Umami event failed:', e);
  }
}