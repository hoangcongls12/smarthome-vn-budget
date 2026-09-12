import { getCollection } from 'astro:content';

export async function GET({ site }) {
  let posts = [];
  try {
    posts = await getCollection('blog');
  } catch (e) {
    posts = [];
  }
  
  const staticPages = ['', '/review', '/huong-dan', '/automation', '/so-sanh', '/budget-build', '/archives', '/tags', '/about', '/contact', '/privacy', '/terms', '/disclaimer'];
  
  const allUrls = [
    ...staticPages.map((page) => `${site}${page}/`),
    ...posts.map((post) => `${site}/blog/${post.slug}/`),
  ];

  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${allUrls.map((url) => `  <url>
    <loc>${url}</loc>
    <changefreq>weekly</changefreq>
    <priority>${url === site ? '1.0' : '0.8'}</priority>
  </url>`).join('\n')}
</urlset>`;

  return new Response(sitemap, {
    headers: {
      'Content-Type': 'application/xml',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}