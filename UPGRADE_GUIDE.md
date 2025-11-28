# Upgrade Guide - Security, Testing & Monitoring

This guide helps you understand and use the new security, testing, and monitoring features added to Suno API.

## What's New?

### 🔒 Security Enhancements

1. **Input Validation** - All endpoints now validate input with Zod schemas
2. **Rate Limiting** - Protect against abuse (requires optional Redis setup)
3. **Secure CORS** - Environment-based origin restrictions
4. **Log Sanitization** - Sensitive data automatically redacted
5. **Error Handling** - Standardized, secure error responses
6. **Environment Validation** - Required config checked at startup

### 🧪 Testing Infrastructure

1. **Vitest Framework** - Fast, modern testing
2. **Unit Tests** - Core functionality covered
3. **Coverage Reports** - Track test coverage
4. **CI/CD Pipeline** - Automated testing on GitHub

### 📊 Monitoring & Observability

1. **Health Check Endpoint** - Monitor service status
2. **Structured Logging** - JSON logs with request tracing
3. **Performance Timers** - Track operation duration
4. **Rate Limit Headers** - Transparent quota information

## Installation

### 1. Install New Dependencies

```bash
npm install
```

New packages added:
- `zod` - Input validation
- `@upstash/ratelimit` - Rate limiting
- `@upstash/redis` - Redis client
- `nanoid` - Request ID generation
- `vitest` - Testing framework (dev)

### 2. Update Environment Variables

Copy new variables from `.env.example` to your `.env`:

```bash
# Optional: Enable rate limiting (recommended for production)
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=

# Optional: Restrict CORS in production
ALLOWED_ORIGINS=

# Optional: Configure logging
LOG_LEVEL=info
NODE_ENV=development
```

### 3. Run Tests (Optional)

```bash
npm test
```

## Migration Guide

### For Existing Deployments

**No breaking changes!** All new features are backward compatible.

#### Quick Migration

Your existing setup will continue to work without any changes. However, to benefit from new features:

1. **Add environment validation** (automatic)
   - App checks required env vars at startup
   - Missing vars? Clear error message tells you what's needed

2. **Enable rate limiting** (optional but recommended)
   ```bash
   # Sign up at https://upstash.com (free tier available)
   # Add to .env:
   UPSTASH_REDIS_REST_URL=https://your-redis.upstash.io
   UPSTASH_REDIS_REST_TOKEN=your_token
   ```

3. **Configure CORS for production** (recommended)
   ```bash
   # In production .env:
   ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
   NODE_ENV=production
   ```

4. **Set up monitoring** (recommended)
   - Health check: `https://your-api.com/api/health`
   - Monitor this endpoint for service status

### For Developers

#### 1. Using Input Validation in Custom Code

Before:
```typescript
export async function POST(req: NextRequest) {
  const body = await req.json();
  // No validation - risky!
  const { prompt } = body;
}
```

After:
```typescript
import { validateRequest, generateSchema } from '@/lib/validation';

export async function POST(req: NextRequest) {
  const body = await req.json();
  const data = validateRequest(generateSchema, body);
  // data is now type-safe and validated
  const { prompt } = data;
}
```

#### 2. Using Error Handling

Before:
```typescript
export async function POST(req: NextRequest) {
  try {
    // ... your code ...
    return new NextResponse(JSON.stringify(result));
  } catch (error) {
    return new NextResponse(JSON.stringify({ error: error.message }), {
      status: 500
    });
  }
}
```

After:
```typescript
import { withErrorHandling } from '@/lib/errors';

export const POST = withErrorHandling(async (req: NextRequest) => {
  // ... your code ...
  // Errors are automatically caught and formatted
  return new NextResponse(JSON.stringify(result));
});
```

#### 3. Using Structured Logging

Before:
```typescript
console.log('Generating song for prompt:', prompt);
console.error('Error:', error);
```

After:
```typescript
import { logger } from '@/lib/logger';

logger.info({ prompt, userId: 123 }, 'Generating song');
logger.error({ error: error.message }, 'Generation failed');
// Sensitive data automatically sanitized!
```

#### 4. Adding Rate Limiting

Before:
```typescript
export async function POST(req: NextRequest) {
  // No protection
}
```

After:
```typescript
import { applyRateLimit } from '@/lib/ratelimit';

export async function POST(req: NextRequest) {
  await applyRateLimit(req, 'generate');
  // Request blocked if limit exceeded
}
```

## Feature Details

### 1. Input Validation

**Location:** `src/lib/validation.ts`

#### Available Schemas

- `generateSchema` - Basic generation
- `customGenerateSchema` - Custom generation
- `extendAudioSchema` - Extend audio
- `generateLyricsSchema` - Generate lyrics
- And more...

#### Usage

```typescript
import { validateRequest, generateSchema } from '@/lib/validation';

// Throws ValidationError if invalid
const data = validateRequest(generateSchema, body);

// Safe validation (returns error object)
const result = safeValidateRequest(generateSchema, body);
if (!result.success) {
  // Handle validation error
  console.log(result.error);
}
```

### 2. Rate Limiting

**Location:** `src/lib/ratelimit.ts`

#### Default Limits

- Global: 10 requests / 10 seconds
- Generate: 5 requests / 60 seconds
- CAPTCHA: 3 requests / 60 seconds

#### Configuration

Edit `src/lib/ratelimit.ts` to adjust limits:

```typescript
const RATE_LIMIT_CONFIG = {
  generate: {
    requests: 10,  // Increase limit
    window: '60 s',
  },
};
```

#### Checking Rate Limits

```typescript
import { checkRateLimit } from '@/lib/ratelimit';

const result = await checkRateLimit(req, 'generate');
console.log(`Remaining: ${result.remaining}/${result.limit}`);
```

### 3. Error Handling

**Location:** `src/lib/errors.ts`

#### Error Types

```typescript
import {
  ValidationError,      // 400
  AuthenticationError,  // 401
  PaymentRequiredError, // 402
  RateLimitError,       // 429
  InternalError,        // 500
  CaptchaError,         // 500
} from '@/lib/errors';

// Throw with details
throw new ValidationError('Invalid prompt', {
  field: 'prompt',
  value: prompt
});
```

#### Error Response Format

```json
{
  "error": {
    "message": "Validation failed",
    "code": "VALIDATION_ERROR",
    "statusCode": 400,
    "details": [
      {
        "path": "prompt",
        "message": "Prompt is required"
      }
    ]
  }
}
```

### 4. Logging

**Location:** `src/lib/logger.ts`

#### Basic Logging

```typescript
import { logger } from '@/lib/logger';

logger.info({ userId: 123, action: 'generate' }, 'User action');
logger.error({ error: err }, 'Operation failed');
logger.debug({ data: obj }, 'Debug info');
```

#### Performance Tracking

```typescript
import { startTimer } from '@/lib/logger';

const timer = startTimer('generate_song', requestId);

// Mark checkpoints
timer.checkpoint('validation_complete');
timer.checkpoint('captcha_solved');

// End timer
timer.end({ songId: 'abc123' });
// Logs: { operation: 'generate_song', duration: 1234, checkpoints: {...} }
```

#### Request-Scoped Logging

```typescript
import { createRequestLogger } from '@/lib/logger';

export async function POST(req: NextRequest) {
  const logger = createRequestLogger();
  logger.info('Request started');
  // All logs include the same requestId
}
```

### 5. Health Check

**Endpoint:** `GET /api/health`

#### Response

```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:00:00.000Z",
  "uptime": 3600,
  "environment": "production",
  "version": "1.1.0",
  "services": {
    "redis": { "status": "connected", "latency": 12 },
    "captcha": { "status": "configured" },
    "suno": { "status": "configured" }
  },
  "memory": {
    "rss": 150,
    "heapUsed": 80,
    "heapTotal": 120,
    "external": 10
  }
}
```

#### Monitoring

```bash
# Check health
curl https://your-api.com/api/health

# Monitor with uptime tool
# Status 200 = healthy/degraded
# Status 503 = unhealthy
```

### 6. CORS Configuration

**Location:** `src/lib/utils.ts`

#### Development

```typescript
// Allows all origins
ALLOWED_ORIGINS=
```

#### Production

```typescript
// Restrict to specific domains
ALLOWED_ORIGINS=https://app.example.com,https://dashboard.example.com
```

#### Usage

```typescript
import { getCorsHeaders } from '@/lib/utils';

// Get CORS headers based on request origin
const headers = getCorsHeaders(request.headers.get('origin'));

return new NextResponse(data, {
  headers: {
    'Content-Type': 'application/json',
    ...headers
  }
});
```

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Watch mode
npm test -- --watch

# Coverage
npm run test:coverage

# UI mode
npm run test:ui
```

### Writing Tests

```typescript
import { describe, it, expect } from 'vitest';

describe('MyFeature', () => {
  it('should work correctly', () => {
    expect(myFunction()).toBe(expected);
  });
});
```

## CI/CD Pipeline

### GitHub Actions

Automatically runs on push/PR:
- ✅ Linting
- ✅ Type checking
- ✅ Tests
- ✅ Build
- ✅ Security scan
- ✅ Docker build

### Local CI Simulation

```bash
npm run lint
npx tsc --noEmit
npm test
npm run build
npm audit
```

## Performance Impact

### Overhead

- **Input validation**: ~1-2ms per request
- **Rate limiting** (with Redis): ~5-15ms per request
- **Rate limiting** (without Redis): ~0ms (disabled)
- **Logging**: ~0.1ms per log statement
- **Error handling**: Negligible

### Optimization Tips

1. **Disable rate limiting in development**
   ```bash
   # Don't set UPSTASH_REDIS_REST_URL in .env
   ```

2. **Reduce log level in production**
   ```bash
   LOG_LEVEL=warn
   ```

3. **Use Redis for distributed rate limiting**
   - Prevents issues with multiple server instances

## Troubleshooting

### Issue: Environment validation errors on startup

**Error:** `Environment validation failed: SUNO_COOKIE is required`

**Solution:**
```bash
# Ensure .env has required variables
SUNO_COOKIE=your_cookie
TWOCAPTCHA_KEY=your_key
```

### Issue: Rate limiting not working

**Symptom:** All requests are allowed

**Cause:** Redis not configured (this is okay for development)

**Solution (if needed):**
```bash
# Add Redis config to .env
UPSTASH_REDIS_REST_URL=https://...
UPSTASH_REDIS_REST_TOKEN=...
```

### Issue: CORS errors in production

**Error:** `Access to fetch blocked by CORS policy`

**Solution:**
```bash
# Add your frontend domain to .env
ALLOWED_ORIGINS=https://your-frontend.com
```

### Issue: Tests failing

**Error:** Various test failures

**Solution:**
```bash
# Install dev dependencies
npm install

# Ensure test environment is set
NODE_ENV=test npm test
```

## Rollback

If you need to temporarily disable new features:

1. **Disable input validation:** Remove `validateRequest()` calls (not recommended)
2. **Disable rate limiting:** Don't set Redis env vars
3. **Use old error handling:** Don't use `withErrorHandling` wrapper
4. **Use old logging:** Use `console.log` instead of `logger`

## Support

- **Documentation:** See [DEVELOPMENT.md](./DEVELOPMENT.md)
- **Security:** See [SECURITY.md](./SECURITY.md)
- **Issues:** https://github.com/gcui-art/suno-api/issues

## Next Steps

1. ✅ Run tests: `npm test`
2. ✅ Check health: `curl http://localhost:3000/api/health`
3. ✅ Review security: Read [SECURITY.md](./SECURITY.md)
4. ✅ Set up rate limiting: Add Redis credentials
5. ✅ Configure monitoring: Add health check to your monitoring tool

## Summary of Changes

| Feature | File | Impact | Required? |
|---------|------|--------|-----------|
| Input Validation | `src/lib/validation.ts` | Safer API | Auto (backward compatible) |
| Error Handling | `src/lib/errors.ts` | Better errors | Auto (backward compatible) |
| Logging | `src/lib/logger.ts` | Sanitized logs | Auto |
| Rate Limiting | `src/lib/ratelimit.ts` | Abuse protection | Optional (needs Redis) |
| CORS Config | `src/lib/utils.ts` | Secure origins | Optional (configure for prod) |
| Health Check | `src/app/api/health/route.ts` | Monitoring | Auto |
| Tests | `tests/**/*.test.ts` | Quality assurance | Auto |
| CI/CD | `.github/workflows/ci.yml` | Automated checks | Auto |

All features are **non-breaking** and **backward compatible**! 🎉
