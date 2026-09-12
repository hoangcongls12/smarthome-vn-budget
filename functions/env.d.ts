# Cloudflare Pages Functions - Type Declarations
// Place in functions/_middleware.ts or types.d.ts

/// <reference types="@cloudflare/workers-types" />

declare namespace App {
  interface Locals {
    // Add any local variables here
  }
}

interface Env {
  AFFILIATE_LINKS: KVNamespace;
  ANALYTICS: AnalyticsEngineDataset;
}

interface KVNamespace {
  get(key: string, type?: 'text' | 'json' | 'arrayBuffer' | 'stream'): Promise<string | null>;
  put(key: string, value: string, options?: { expirationTtl?: number; metadata?: unknown }): Promise<void>;
  delete(key: string): Promise<void>;
  list(options?: { prefix?: string; limit?: number; cursor?: string }): Promise<{ keys: Array<{ name: string; expiration?: number; metadata?: unknown }>; list_complete: boolean; cursor?: string }>;
}

interface AnalyticsEngineDataset {
  writeDataPoint(blobs: Array<string | number | boolean>, indexes?: string[]): void;
}