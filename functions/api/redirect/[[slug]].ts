// Cloudflare Pages Function for Affiliate Link Cloaking
// Place in functions/api/redirect/[[slug]].ts

import type { PagesFunction } from '@cloudflare/workers-types';

interface Env {
  // Affiliate mapping stored in KV or hardcoded
  AFFILIATE_LINKS: KVNamespace;
}

const AFFILIATE_MAP: Record<string, string> = {
  // Format: 'slug': 'https://actual-affiliate-url.com'
  // These should be moved to KV in production
  'sonoff-zbdongle-e': 'https://shopee.vn/product/123456789?utm_source=smarthomevn&utm_medium=affiliate&utm_campaign=content',
  'xiaomi-smart-bulb': 'https://shopee.vn/product/987654321?utm_source=smarthomevn&utm_medium=affiliate&utm_campaign=content',
  'aqara-motion-sensor': 'https://www.lazada.vn/products/456789123?utm_source=smarthomevn&utm_medium=affiliate&utm_campaign=content',
  'sonoff-mini-r4': 'https://gearvn.com/sonoff-mini-r4?ref=smarthomevn',
  'raspberry-pi-4-4gb': 'https://www.amazon.com/dp/B07TD42S24?tag=smarthomevn-20',
  // Add more mappings here
};

export const onRequestGet: PagesFunction<Env> = async (context) => {
  const { params, request } = context;
  const slug = params.slug as string;
  
  // Log click for analytics (optional)
  const clickData = {
    slug,
    timestamp: new Date().toISOString(),
    referer: request.headers.get('referer') || 'direct',
    userAgent: request.headers.get('user-agent') || 'unknown',
    ip: request.headers.get('cf-connecting-ip') || 'unknown',
  };
  
  // In production, send to analytics endpoint or KV
  console.log('Affiliate click:', JSON.stringify(clickData));
  
  // Get destination URL
  const destination = AFFILIATE_MAP[slug];
  
  if (!destination) {
    // Log missing slug for monitoring
    console.warn('Affiliate slug not found:', slug);
    
    // Redirect to homepage with error param
    return Response.redirect('/?affiliate_error=invalid_slug', 302);
  }
  
  // Redirect with 302 (temporary) - preserves referer for affiliate tracking
  return Response.redirect(destination, 302);
};

// Optional: POST for creating new links (admin only)
export const onRequestPost: PagesFunction<Env> = async (context) => {
  const { request, env } = context;
  
  // Verify admin authentication (implement your auth)
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401 });
  }
  
  const body = await request.json() as { slug: string; url: string };
  
  if (!body.slug || !body.url) {
    return new Response('Missing slug or url', { status: 400 });
  }
  
  // Validate URL
  try {
    new URL(body.url);
  } catch {
    return new Response('Invalid URL', { status: 400 });
  }
  
  // Store in KV (requires KV namespace binding)
  // await env.AFFILIATE_LINKS.put(body.slug, body.url);
  
  return new Response(JSON.stringify({ success: true, slug: body.slug }), {
    headers: { 'Content-Type': 'application/json' },
  });
};