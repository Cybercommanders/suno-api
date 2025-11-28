import { NextRequest, NextResponse } from 'next/server';
import { corsHeaders } from '@/lib/utils';

/**
 * System health metrics
 */
interface HealthMetrics {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  uptime: number;
  environment: string;
  version: string;
  services: {
    redis?: {
      status: 'connected' | 'disconnected';
      latency?: number;
    };
    captcha?: {
      status: 'configured' | 'not_configured';
    };
    suno?: {
      status: 'configured' | 'not_configured';
    };
  };
  memory: {
    rss: number;
    heapUsed: number;
    heapTotal: number;
    external: number;
  };
}

/**
 * Check Redis connection
 */
async function checkRedis(): Promise<{ status: 'connected' | 'disconnected'; latency?: number }> {
  const hasRedisConfig = Boolean(
    process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN
  );

  if (!hasRedisConfig) {
    return { status: 'disconnected' };
  }

  try {
    // Try to ping Redis
    const { Redis } = await import('@upstash/redis');
    const redis = new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL!,
      token: process.env.UPSTASH_REDIS_REST_TOKEN!,
    });

    const start = Date.now();
    await redis.ping();
    const latency = Date.now() - start;

    return { status: 'connected', latency };
  } catch (error) {
    return { status: 'disconnected' };
  }
}

/**
 * Check CAPTCHA service configuration
 */
function checkCaptcha(): { status: 'configured' | 'not_configured' } {
  const hasConfig = Boolean(process.env.TWOCAPTCHA_KEY);
  return { status: hasConfig ? 'configured' : 'not_configured' };
}

/**
 * Check Suno configuration
 */
function checkSuno(): { status: 'configured' | 'not_configured' } {
  const hasConfig = Boolean(process.env.SUNO_COOKIE);
  return { status: hasConfig ? 'configured' : 'not_configured' };
}

/**
 * Get memory usage
 */
function getMemoryUsage() {
  const usage = process.memoryUsage();
  return {
    rss: Math.round(usage.rss / 1024 / 1024), // MB
    heapUsed: Math.round(usage.heapUsed / 1024 / 1024), // MB
    heapTotal: Math.round(usage.heapTotal / 1024 / 1024), // MB
    external: Math.round(usage.external / 1024 / 1024), // MB
  };
}

/**
 * Determine overall health status
 */
function determineHealthStatus(services: HealthMetrics['services']): HealthMetrics['status'] {
  // Critical: Suno must be configured
  if (services.suno?.status === 'not_configured') {
    return 'unhealthy';
  }

  // Critical: CAPTCHA must be configured
  if (services.captcha?.status === 'not_configured') {
    return 'unhealthy';
  }

  // Degraded: Redis is optional but recommended
  if (services.redis?.status === 'disconnected') {
    return 'degraded';
  }

  return 'healthy';
}

export async function GET(request: NextRequest) {
  try {
    const [redis, captcha, suno] = await Promise.all([
      checkRedis(),
      Promise.resolve(checkCaptcha()),
      Promise.resolve(checkSuno()),
    ]);

    const services = { redis, captcha, suno };
    const status = determineHealthStatus(services);

    const metrics: HealthMetrics = {
      status,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      version: '1.1.0', // Match package.json
      services,
      memory: getMemoryUsage(),
    };

    const httpStatus = status === 'healthy' ? 200 : status === 'degraded' ? 200 : 503;

    return new NextResponse(JSON.stringify(metrics, null, 2), {
      status: httpStatus,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        ...corsHeaders,
      },
    });
  } catch (error) {
    return new NextResponse(
      JSON.stringify({
        status: 'unhealthy',
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      }),
      {
        status: 503,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  }
}

export async function OPTIONS(request: Request) {
  return new Response(null, {
    status: 200,
    headers: corsHeaders,
  });
}
