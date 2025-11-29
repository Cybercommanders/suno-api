# Deployment Scripts

This directory contains deployment scripts and configurations for various platforms.

## Quick Start

### 1. Validate Environment

```bash
./scripts/validate-env.sh
```

### 2. Choose Your Platform

#### Docker (Recommended)
```bash
./scripts/deploy-docker.sh
```

#### VPS (Ubuntu)
```bash
sudo ./scripts/deploy-vps.sh
```

#### Vercel
```bash
vercel --prod
```

### 3. Check Health

```bash
./scripts/health-check.sh
```

## Directory Structure

```
deploy/
├── docker/
│   ├── docker-compose.prod.yml   # Production compose file
│   ├── nginx.conf                  # Nginx reverse proxy config
│   └── ssl/                        # SSL certificates (add your own)
├── vps/
│   └── suno-api.service           # Systemd service file
├── scripts/
│   ├── deploy-docker.sh           # Docker deployment script
│   ├── deploy-vps.sh              # VPS deployment script
│   ├── validate-env.sh            # Environment validation
│   └── health-check.sh            # Health monitoring script
└── README.md                       # This file
```

## Scripts Overview

### deploy-docker.sh

Automated Docker deployment with Docker Compose.

**Features:**
- Validates environment configuration
- Builds Docker image
- Deploys with Docker Compose (API + Redis + Nginx)
- Runs health checks
- Shows service status

**Usage:**
```bash
./scripts/deploy-docker.sh
```

**Requirements:**
- Docker 20.10+
- Docker Compose 2.0+
- .env file configured

---

### deploy-vps.sh

Complete VPS deployment automation for Ubuntu servers.

**Features:**
- Installs system dependencies
- Installs Node.js 20
- Creates application user
- Deploys application files
- Configures systemd service
- Runs health checks

**Usage:**
```bash
sudo ./scripts/deploy-vps.sh
```

**Requirements:**
- Ubuntu 20.04+
- Root access
- 2GB+ RAM

---

### validate-env.sh

Validates environment configuration before deployment.

**Checks:**
- Required variables (SUNO_COOKIE, TWOCAPTCHA_KEY)
- Optional variables (Redis, CORS, etc.)
- Production security settings
- Provides detailed warnings and errors

**Usage:**
```bash
./scripts/validate-env.sh
```

**Exit codes:**
- 0: All checks passed
- 1: Errors found (deployment should not proceed)

---

### health-check.sh

Monitors service health and displays detailed status.

**Features:**
- Checks health endpoint
- Displays service status
- Shows memory usage
- Validates all services
- Continuous monitoring mode

**Usage:**
```bash
# Single check
./scripts/health-check.sh

# Continuous monitoring
./scripts/health-check.sh monitor

# Custom API URL
API_URL=https://api.example.com ./scripts/health-check.sh
```

**Exit codes:**
- 0: Service healthy
- 1: Service unhealthy or unavailable

---

## Docker Deployment

### Files

- **docker-compose.prod.yml** - Production compose configuration
  - Suno API service
  - Redis (optional, for rate limiting)
  - Nginx (optional, reverse proxy with SSL)

- **nginx.conf** - Nginx configuration
  - Reverse proxy
  - SSL/TLS termination
  - Rate limiting
  - Security headers

### Quick Start

```bash
cd docker
docker compose -f docker-compose.prod.yml up -d
```

### Configuration

Edit `docker-compose.prod.yml` to customize:
- Port mappings
- Resource limits
- Environment variables
- Volume mounts

### SSL Setup

1. Get SSL certificates (Let's Encrypt recommended):
   ```bash
   sudo certbot certonly --standalone -d yourdomain.com
   ```

2. Copy to ssl/ directory:
   ```bash
   sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/cert.pem
   sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/key.pem
   ```

3. Restart Nginx:
   ```bash
   docker compose -f docker-compose.prod.yml restart nginx
   ```

---

## VPS Deployment

### Files

- **suno-api.service** - Systemd service configuration
  - Auto-restart on failure
  - Logging to journald
  - Resource limits
  - Security settings

### Manual Setup

1. Copy service file:
   ```bash
   sudo cp vps/suno-api.service /etc/systemd/system/
   ```

2. Reload systemd:
   ```bash
   sudo systemctl daemon-reload
   ```

3. Enable and start:
   ```bash
   sudo systemctl enable suno-api
   sudo systemctl start suno-api
   ```

4. Check status:
   ```bash
   sudo systemctl status suno-api
   ```

### Service Management

```bash
# Start
sudo systemctl start suno-api

# Stop
sudo systemctl stop suno-api

# Restart
sudo systemctl restart suno-api

# View logs
sudo journalctl -u suno-api -f

# Check status
sudo systemctl status suno-api
```

---

## Vercel Deployment

See `vercel.json` in project root for configuration.

### Quick Deploy

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

### Configuration

The `vercel.json` file configures:
- Function timeouts (60-300 seconds)
- Memory allocation (3GB)
- Environment variables
- CORS headers
- Regions

### Add Secrets

```bash
vercel env add SUNO_COOKIE
vercel env add TWOCAPTCHA_KEY
vercel env add UPSTASH_REDIS_REST_URL
vercel env add UPSTASH_REDIS_REST_TOKEN
```

---

## Environment Variables

### Required

```bash
SUNO_COOKIE=your_cookie_here
TWOCAPTCHA_KEY=your_api_key_here
```

### Optional (Recommended for Production)

```bash
# Rate limiting
UPSTASH_REDIS_REST_URL=https://your-redis.upstash.io
UPSTASH_REDIS_REST_TOKEN=your_token

# Security
ALLOWED_ORIGINS=https://yourdomain.com
NODE_ENV=production
LOG_LEVEL=warn

# Browser
BROWSER=chromium
BROWSER_HEADLESS=true
BROWSER_LOCALE=en
BROWSER_DISABLE_GPU=true  # Required for Docker
```

---

## Monitoring

### Health Check Endpoint

```bash
curl http://localhost:3000/api/health
```

Response:
```json
{
  "status": "healthy",
  "services": {
    "redis": { "status": "connected", "latency": 12 },
    "captcha": { "status": "configured" },
    "suno": { "status": "configured" }
  },
  "memory": {
    "rss": 150,
    "heapUsed": 80,
    "heapTotal": 120
  },
  "uptime": 3600
}
```

### Continuous Monitoring

```bash
# Use health check script
./scripts/health-check.sh monitor

# Or setup cron job
*/5 * * * * /path/to/deploy/scripts/health-check.sh >> /var/log/suno-health.log 2>&1
```

---

## Troubleshooting

### Script Permission Denied

```bash
chmod +x scripts/*.sh
```

### Docker Compose Not Found

```bash
# Install Docker Compose v2
sudo apt install docker-compose-plugin
```

### Port Already in Use

```bash
# Find what's using port 3000
sudo lsof -i :3000

# Kill process or change port in docker-compose.yml
```

### Service Won't Start

```bash
# Check logs
docker logs suno-api-prod
# or
sudo journalctl -u suno-api -n 50

# Validate environment
./scripts/validate-env.sh
```

### Health Check Fails

```bash
# Check if service is running
docker ps
# or
sudo systemctl status suno-api

# Check logs
./scripts/health-check.sh

# Verify environment variables
```

---

## Best Practices

### Security

1. **Always use HTTPS in production**
2. **Set ALLOWED_ORIGINS to specific domains**
3. **Use strong secrets for Redis/databases**
4. **Keep dependencies updated**
5. **Enable rate limiting**
6. **Use firewall rules**

### Performance

1. **Enable Redis for rate limiting**
2. **Use production-grade reverse proxy (Nginx)**
3. **Set appropriate resource limits**
4. **Monitor memory and CPU usage**
5. **Use CDN for static assets**

### Reliability

1. **Setup health monitoring**
2. **Configure automatic restarts**
3. **Keep backups of .env file**
4. **Use systemd/Docker restart policies**
5. **Monitor logs regularly**

---

## Support

For detailed deployment instructions, see:
- [DEPLOYMENT.md](../DEPLOYMENT.md) - Complete deployment guide
- [README.md](../README.md) - Project overview
- [SECURITY.md](../SECURITY.md) - Security best practices

For issues:
- GitHub Issues: https://github.com/gcui-art/suno-api/issues

---

## License

LGPL-3.0-or-later - see [LICENSE](../LICENSE)
