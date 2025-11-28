import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';
import { NextRequest, NextResponse } from 'next/server';
import { RateLimitError } from './errors';
import { logger } from './logger';

/**
 * Rate limit configuration
 */
const RATE_LIMIT_CONFIG = {
  // Global rate limit: 10 requests per 10 seconds
  global: {
    requests: 10,
    window: '10 s',
  },
  // Per-endpoint rate limits
  generate: {
    requests: 5,
    window: '60 s', // 5 generations per minute
  },
  custom_generate: {
    requests: 5,
    window: '60 s',
  },
  captcha: {
    requests: 3,
    window: '60 s', // Limit CAPTCHA attempts
  },
};

/**
 * Initialize Redis client if credentials are available
 */
function getRedisClient(): Redis | null {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;

  if (!url || !token) {
    logger.warn('Rate limiting disabled: UPSTASH_REDIS_REST_URL or UPSTASH_REDIS_REST_TOKEN not set');
    return null;
  }

  return new Redis({
    url,
    token,
  });
}

/**
 * Create rate limiter instances
 */
const redis = getRedisClient();

export const rateLimiters = {
  global: redis
    ? new Ratelimit({
        redis,
        limiter: Ratelimit.slidingWindow(
          RATE_LIMIT_CONFIG.global.requests,
          RATE_LIMIT_CONFIG.global.window
        ),
        analytics: true,
        prefix: 'ratelimit:global',
      })
    : null,

  generate: redis
    ? new Ratelimit({
        redis,
        limiter: Ratelimit.slidingWindow(
          RATE_LIMIT_CONFIG.generate.requests,
          RATE_LIMIT_CONFIG.generate.window
        ),
        analytics: true,
        prefix: 'ratelimit:generate',
      })
    : null,

  customGenerate: redis
    ? new Ratelimit({
        redis,
        limiter: Ratelimit.slidingWindow(
          RATE_LIMIT_CONFIG.custom_generate.requests,
          RATE_LIMIT_CONFIG.custom_generate.window
        ),
        analytics: true,
        prefix: 'ratelimit:custom_generate',
      })
    : null,

  captcha: redis
    ? new Ratelimit({
        redis,
        limiter: Ratelimit.slidingWindow(
          RATE_LIMIT_CONFIG.captcha.requests,
          RATE_LIMIT_CONFIG.captcha.window
        ),
        analytics: true,
        prefix: 'ratelimit:captcha',
      })
    : null,
};

/**
 * Get identifier for rate limiting (IP address or cookie hash)
 */
export function getRateLimitIdentifier(request: NextRequest): string {
  // Try to get IP address
  const ip =
    request.headers.get('x-forwarded-for')?.split(',')[0] ||
    request.headers.get('x-real-ip') ||
    'unknown';

  // Also consider cookie to allow per-user rate limiting
  const cookie = request.headers.get('cookie');

  // Use IP as primary identifier
  return ip;
}

/**
 * Check rate limit for a request
 */
export async function checkRateLimit(
  request: NextRequest,
  limiterType: keyof typeof rateLimiters = 'global'
): Promise<{
  success: boolean;
  limit: number;
  remaining: number;
  reset: number;
  retryAfter?: number;
}> {
  const limiter = rateLimiters[limiterType];

  // If rate limiting is not configured, allow all requests
  if (!limiter) {
    return {
      success: true,
      limit: 0,
      remaining: 0,
      reset: 0,
    };
  }

  const identifier = getRateLimitIdentifier(request);
  const result = await limiter.limit(identifier);

  if (!result.success) {
    const retryAfter = Math.ceil((result.reset - Date.now()) / 1000);
    logger.warn({
      identifier,
      limiterType,
      limit: result.limit,
      remaining: result.remaining,
      retryAfter,
    }, 'Rate limit exceeded');

    return {
      success: false,
      limit: result.limit,
      remaining: result.remaining,
      reset: result.reset,
      retryAfter,
    };
  }

  return {
    success: true,
    limit: result.limit,
    remaining: result.remaining,
    reset: result.reset,
  };
}

/**
 * Middleware to enforce rate limits
 */
export async function withRateLimit(
  request: NextRequest,
  limiterType: keyof typeof rateLimiters = 'global'
): Promise<void> {
  const result = await checkRateLimit(request, limiterType);

  if (!result.success) {
    throw new RateLimitError(
      `Rate limit exceeded. Try again in ${result.retryAfter} seconds.`,
      result.retryAfter
    );
  }
}

/**
 * Add rate limit headers to response
 */
export function addRateLimitHeaders(
  response: NextResponse,
  rateLimit: {
    limit: number;
    remaining: number;
    reset: number;
  }
): NextResponse {
  response.headers.set('X-RateLimit-Limit', rateLimit.limit.toString());
  response.headers.set('X-RateLimit-Remaining', rateLimit.remaining.toString());
  response.headers.set('X-RateLimit-Reset', new Date(rateLimit.reset).toISOString());

  return response;
}

/**
 * Helper to check and apply rate limit in one call
 */
export async function applyRateLimit(
  request: NextRequest,
  limiterType: keyof typeof rateLimiters = 'global'
): Promise<{
  success: boolean;
  limit: number;
  remaining: number;
  reset: number;
  retryAfter?: number;
}> {
  const result = await checkRateLimit(request, limiterType);

  if (!result.success) {
    throw new RateLimitError(
      `Rate limit exceeded. Try again in ${result.retryAfter} seconds.`,
      result.retryAfter
    );
  }

  return result;
}
