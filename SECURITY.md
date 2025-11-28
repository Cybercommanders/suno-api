# Security Guide

## Overview

This document outlines the security features and best practices for the Suno API project.

## Security Features

### 1. Input Validation

All API endpoints use **Zod schemas** for input validation:

- Prevents injection attacks
- Validates data types and formats
- Provides detailed error messages
- Enforces length limits on user input

### 2. Rate Limiting

Rate limiting protects against abuse and DoS attacks:

- **Global limit**: 10 requests per 10 seconds
- **Generate endpoints**: 5 requests per 60 seconds
- **CAPTCHA operations**: 3 requests per 60 seconds

**Setup (Optional but Recommended):**

```bash
# Sign up for free at https://upstash.com
# Add to .env:
UPSTASH_REDIS_REST_URL=your_redis_url
UPSTASH_REDIS_REST_TOKEN=your_redis_token
```

### 3. CORS Configuration

Cross-Origin Resource Sharing is configured securely:

- **Development**: Allows all origins (`*`)
- **Production**: Restricts to allowed domains

**Configuration:**

```bash
# .env
ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

### 4. Sensitive Data Protection

All logs are automatically sanitized:

- Cookies are redacted
- API keys are hidden
- Tokens are masked
- Passwords are removed

Sensitive fields automatically redacted:
- `cookie`, `cookies`
- `authorization`, `token`
- `password`, `secret`
- `api_key`, `apikey`
- `__client`, `__session`
- `twocaptcha_key`, `suno_cookie`

### 5. Error Handling

Standardized error responses prevent information leakage:

- Production errors hide internal details
- Development errors show full stack traces
- Proper HTTP status codes
- Consistent error format

### 6. Environment Variable Validation

Required variables are checked at startup:

```typescript
// Validated at startup - app won't start with missing config
SUNO_COOKIE (required)
TWOCAPTCHA_KEY (required)
BROWSER (optional, default: chromium)
```

## Security Best Practices

### 1. Cookie Management

**Never commit cookies to version control:**

```bash
# Always in .gitignore
.env
.env.local
.env.production
```

**Rotate cookies regularly:**
- Update `SUNO_COOKIE` every 30 days
- Use different cookies for dev/staging/production

### 2. API Key Protection

**2Captcha API Key:**
- Store only in environment variables
- Never log the key
- Use separate keys for different environments
- Monitor usage at https://2captcha.com

### 3. Rate Limiting

**Enable rate limiting in production:**

```bash
# Recommended: Use Upstash Redis
UPSTASH_REDIS_REST_URL=https://your-redis.upstash.io
UPSTASH_REDIS_REST_TOKEN=your_token
```

**Without Redis:**
- Rate limiting is disabled
- Monitor server resources
- Consider implementing IP-based limits at the network level

### 4. CORS Configuration

**Production setup:**

```bash
# Restrict to your domains only
ALLOWED_ORIGINS=https://app.example.com,https://dashboard.example.com

# Never use * in production
# ALLOWED_ORIGINS=*  ❌ WRONG
```

### 5. Logging

**Configure appropriate log levels:**

```bash
# Production
LOG_LEVEL=warn

# Development
LOG_LEVEL=debug

# Staging
LOG_LEVEL=info
```

**Never log:**
- Full cookie values
- API keys or tokens
- User passwords
- Payment information

## Vulnerability Reporting

If you discover a security vulnerability:

1. **DO NOT** open a public GitHub issue
2. Email the maintainers directly
3. Provide detailed information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Security Checklist

Before deploying to production:

- [ ] All environment variables are set
- [ ] `ALLOWED_ORIGINS` configured (not `*`)
- [ ] Rate limiting enabled with Redis
- [ ] `LOG_LEVEL` set to `warn` or `error`
- [ ] Cookies rotated from development values
- [ ] Separate 2Captcha keys for prod/dev
- [ ] HTTPS enabled on your domain
- [ ] Security headers configured (if using reverse proxy)
- [ ] Regular dependency updates scheduled
- [ ] Monitoring and alerting configured

## Monitoring

### Health Check

Monitor service health:

```bash
curl https://your-api.com/api/health
```

Response:
```json
{
  "status": "healthy",
  "services": {
    "redis": { "status": "connected", "latency": 12 },
    "captcha": { "status": "configured" },
    "suno": { "status": "configured" }
  }
}
```

### Rate Limit Headers

Check rate limits in responses:

```
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 2025-01-15T10:30:00.000Z
```

## Common Security Issues

### Issue: Exposed API Keys in Logs

**Problem:** Seeing API keys in application logs

**Solution:**
- Logs are automatically sanitized
- Update to latest version
- Set `LOG_LEVEL=warn` in production

### Issue: CORS Errors in Production

**Problem:** Browser blocking requests due to CORS

**Solution:**
```bash
# Add your frontend domain
ALLOWED_ORIGINS=https://your-frontend.com
```

### Issue: Rate Limit False Positives

**Problem:** Legitimate users being rate limited

**Solution:**
- Increase limits in `src/lib/ratelimit.ts`
- Use Redis for distributed rate limiting
- Implement API key authentication for trusted clients

## Security Updates

This project uses:
- Dependabot for dependency updates
- npm audit for vulnerability scanning
- Trivy for Docker security scanning

Run security audit:

```bash
npm audit
npm audit fix
```

## Compliance

### Data Protection

- No user data is stored on the server
- All requests are proxied to Suno.ai
- Cookies are user-provided
- No database or persistent storage

### GDPR Considerations

- This is a stateless API wrapper
- No personal data collection
- Users control their own Suno cookies
- Logs can be configured to not persist

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Next.js Security](https://nextjs.org/docs/app/building-your-application/deploying/production-checklist#security)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)

## License

Security improvements are licensed under the same LGPL-3.0-or-later license as the main project.
