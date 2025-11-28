# Development Guide

## Table of Contents

1. [Getting Started](#getting-started)
2. [Project Structure](#project-structure)
3. [Security Features](#security-features)
4. [Testing](#testing)
5. [Monitoring](#monitoring)
6. [API Development](#api-development)
7. [Best Practices](#best-practices)

## Getting Started

### Prerequisites

- Node.js 20+ and npm
- Git
- (Optional) Docker for containerized deployment
- (Optional) Upstash Redis account for rate limiting

### Installation

```bash
# Clone the repository
git clone https://github.com/gcui-art/suno-api.git
cd suno-api

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Edit .env with your credentials
# Required: SUNO_COOKIE and TWOCAPTCHA_KEY
```

### Running Locally

```bash
# Development mode with hot reload
npm run dev

# Production build
npm run build
npm start

# Run tests
npm test

# Run tests with UI
npm run test:ui

# Generate coverage report
npm run test:coverage
```

### Environment Setup

#### Required Variables

```bash
SUNO_COOKIE=your_cookie_here
TWOCAPTCHA_KEY=your_key_here
```

#### Optional Variables

```bash
# Rate limiting (recommended for production)
UPSTASH_REDIS_REST_URL=https://your-redis.upstash.io
UPSTASH_REDIS_REST_TOKEN=your_token

# CORS configuration
ALLOWED_ORIGINS=https://yourdomain.com

# Logging
LOG_LEVEL=info  # debug, info, warn, error

# Browser settings
BROWSER=chromium
BROWSER_HEADLESS=true
BROWSER_LOCALE=en
```

## Project Structure

```
suno-api/
├── src/
│   ├── app/
│   │   └── api/                 # API route handlers
│   │       ├── generate/
│   │       ├── custom_generate/
│   │       ├── health/          # 🆕 Health check endpoint
│   │       └── .../
│   └── lib/
│       ├── SunoApi.ts          # Core API client
│       ├── env.ts              # 🆕 Environment validation
│       ├── validation.ts       # 🆕 Request validation schemas
│       ├── errors.ts           # 🆕 Error handling
│       ├── logger.ts           # 🆕 Structured logging
│       ├── ratelimit.ts        # 🆕 Rate limiting
│       └── utils.ts            # Utilities + enhanced CORS
├── tests/                       # 🆕 Test files
│   ├── setup.ts
│   ├── validation.test.ts
│   ├── errors.test.ts
│   └── logger.test.ts
├── .github/
│   └── workflows/
│       └── ci.yml              # 🆕 CI/CD pipeline
├── vitest.config.ts            # 🆕 Test configuration
├── SECURITY.md                 # 🆕 Security documentation
└── DEVELOPMENT.md              # 🆕 This file
```

## Security Features

### 1. Input Validation with Zod

All API endpoints use Zod schemas for validation:

```typescript
import { validateRequest, generateSchema } from '@/lib/validation';

// In your API route
const data = await req.json();
const validated = validateRequest(generateSchema, data);
// validated is now type-safe and guaranteed valid
```

#### Available Schemas

- `generateSchema` - Basic music generation
- `customGenerateSchema` - Custom music with lyrics/tags
- `extendAudioSchema` - Extend existing audio
- `generateLyricsSchema` - Generate lyrics
- `getAudioSchema` - Get audio information
- And more...

### 2. Error Handling

Centralized error handling with standardized responses:

```typescript
import { withErrorHandling, ValidationError } from '@/lib/errors';

export const POST = withErrorHandling(async (req: NextRequest) => {
  // Your code here
  if (invalid) {
    throw new ValidationError('Invalid input');
  }
  // Errors are automatically formatted and returned
});
```

#### Error Types

- `ValidationError` (400) - Invalid input
- `AuthenticationError` (401) - Auth failed
- `PaymentRequiredError` (402) - Insufficient credits
- `RateLimitError` (429) - Rate limit exceeded
- `InternalError` (500) - Server error
- `CaptchaError` (500) - CAPTCHA solving failed

### 3. Logging

Structured logging with automatic sanitization:

```typescript
import { logger, startTimer } from '@/lib/logger';

// Basic logging
logger.info({ userId: 123 }, 'User action');

// Performance tracking
const timer = startTimer('generate_song', requestId);
// ... do work ...
timer.checkpoint('captcha_solved');
// ... more work ...
timer.end({ songId: 'abc123' });

// Sensitive data is automatically redacted
logger.info({ cookie: 'secret' }); // Logs: { cookie: '[REDACTED]' }
```

### 4. Rate Limiting

Protect your API from abuse:

```typescript
import { applyRateLimit } from '@/lib/ratelimit';

export async function POST(req: NextRequest) {
  // Apply rate limiting
  const rateLimit = await applyRateLimit(req, 'generate');

  // Rate limit headers are automatically added to response
  // If limit exceeded, RateLimitError is thrown
}
```

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Watch mode
npm test -- --watch

# Coverage report
npm run test:coverage

# UI mode (opens browser)
npm run test:ui
```

### Writing Tests

#### Unit Test Example

```typescript
// tests/myfeature.test.ts
import { describe, it, expect } from 'vitest';
import { myFunction } from '../src/lib/myfeature';

describe('MyFeature', () => {
  it('should do something', () => {
    const result = myFunction('input');
    expect(result).toBe('expected');
  });
});
```

#### Integration Test Example

```typescript
// tests/api/generate.test.ts
import { describe, it, expect } from 'vitest';
import { sunoApi } from '../src/lib/SunoApi';

describe('Generate API', () => {
  it('should validate input', async () => {
    // Mock API calls and test behavior
  });
});
```

### Test Coverage Goals

- Target: 80% coverage
- Critical paths: 100% coverage
- Error handling: 100% coverage

## Monitoring

### Health Check

Monitor service health:

```bash
GET /api/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:00:00.000Z",
  "uptime": 3600,
  "environment": "production",
  "version": "1.1.0",
  "services": {
    "redis": {
      "status": "connected",
      "latency": 12
    },
    "captcha": {
      "status": "configured"
    },
    "suno": {
      "status": "configured"
    }
  },
  "memory": {
    "rss": 150,
    "heapUsed": 80,
    "heapTotal": 120,
    "external": 10
  }
}
```

Status codes:
- `200` - Healthy or degraded (warning)
- `503` - Unhealthy (critical services down)

### Logging

View logs in development:

```bash
npm run dev
# Logs will show in color with pretty formatting
```

Production logging outputs JSON:

```json
{
  "level": "info",
  "time": 1642251600000,
  "requestId": "abc123",
  "msg": "Request completed",
  "duration": 1234
}
```

## API Development

### Creating a New Endpoint

1. **Create validation schema** (`src/lib/validation.ts`):

```typescript
export const myNewSchema = z.object({
  param1: z.string().min(1),
  param2: z.number().optional(),
});

export type MyNewInput = z.infer<typeof myNewSchema>;
```

2. **Create route handler** (`src/app/api/mynew/route.ts`):

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { withErrorHandling } from '@/lib/errors';
import { validateRequest, myNewSchema } from '@/lib/validation';
import { applyRateLimit } from '@/lib/ratelimit';
import { corsHeaders } from '@/lib/utils';

export const POST = withErrorHandling(async (req: NextRequest) => {
  // Rate limiting
  await applyRateLimit(req);

  // Validation
  const body = await req.json();
  const data = validateRequest(myNewSchema, body);

  // Business logic
  const result = await doSomething(data);

  // Response
  return new NextResponse(JSON.stringify(result), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
});

export async function OPTIONS(request: Request) {
  return new Response(null, {
    status: 200,
    headers: corsHeaders,
  });
}
```

3. **Write tests** (`tests/api/mynew.test.ts`):

```typescript
import { describe, it, expect } from 'vitest';
import { validateRequest, myNewSchema } from '@/lib/validation';

describe('My New Endpoint', () => {
  it('should validate valid input', () => {
    const result = validateRequest(myNewSchema, {
      param1: 'test',
    });
    expect(result.param1).toBe('test');
  });
});
```

### Best Practices for Routes

1. **Always use `withErrorHandling`** wrapper
2. **Validate all input** with Zod schemas
3. **Apply rate limiting** for expensive operations
4. **Add CORS headers** to all responses
5. **Include OPTIONS handler** for CORS preflight
6. **Use structured logging** with request IDs
7. **Return consistent error format**

## Best Practices

### Code Style

```typescript
// ✅ Good
const result = await api.generate(prompt);
logger.info({ result }, 'Generation complete');

// ❌ Bad
const result = await api.generate(prompt);
console.log('Generated:', result);
```

### Error Handling

```typescript
// ✅ Good
throw new ValidationError('Invalid prompt', { field: 'prompt' });

// ❌ Bad
throw new Error('Invalid prompt');
```

### Logging

```typescript
// ✅ Good
logger.info({ userId, action: 'generate' }, 'Song generated');

// ❌ Bad
logger.info(`User ${userId} generated a song`);
```

### Type Safety

```typescript
// ✅ Good
const data: GenerateInput = validateRequest(generateSchema, body);

// ❌ Bad
const data: any = body;
```

## CI/CD Pipeline

GitHub Actions workflow automatically:

1. ✅ Lints code (ESLint)
2. ✅ Runs tests
3. ✅ Checks types (TypeScript)
4. ✅ Builds application
5. ✅ Scans for vulnerabilities (npm audit, Trivy)
6. ✅ Builds Docker image (on main/develop)

### Running CI Locally

```bash
# Lint
npm run lint

# Type check
npx tsc --noEmit

# Tests
npm test

# Build
npm run build

# Security audit
npm audit
```

## Debugging

### Enable Debug Logs

```bash
LOG_LEVEL=debug npm run dev
```

### Test Specific File

```bash
npm test -- tests/validation.test.ts
```

### Debug in VSCode

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Tests",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["test", "--", "--run"],
      "console": "integratedTerminal"
    }
  ]
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Ensure CI passes
6. Submit a pull request

### Code Review Checklist

- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No console.log statements
- [ ] Error handling added
- [ ] Input validation added
- [ ] Logs are sanitized
- [ ] Types are correct
- [ ] CI passes

## Resources

- [Next.js Docs](https://nextjs.org/docs)
- [Vitest Docs](https://vitest.dev/)
- [Zod Docs](https://zod.dev/)
- [Pino Logger](https://getpino.io/)
- [Upstash Redis](https://docs.upstash.com/redis)

## Getting Help

- Check [README.md](./README.md) for general info
- Review [SECURITY.md](./SECURITY.md) for security questions
- Open an issue on GitHub
- Read the code - it's well-commented!

## License

LGPL-3.0-or-later - see [LICENSE](./LICENSE)
