// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    author: z.string().default('Smart Home VN Budget Team'),
    category: z.string(),
    tags: z.array(z.string()).default([]),
    ogImage: z.string().optional(),
    readingTime: z.number().optional(),
    featured: z.boolean().default(false),
    draft: z.boolean().default(false),
    affiliateLinks: z.array(z.object({
      id: z.string(),
      program: z.string(),
      productName: z.string(),
      url: z.string(),
    })).optional(),
  }),
});

export const collections = { blog };