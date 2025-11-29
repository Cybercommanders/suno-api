# Deployment Guide

Complete guide for deploying the Suno API to various platforms.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Deployment Options](#deployment-options)
   - [Vercel (Easiest)](#vercel-deployment)
   - [Docker (Recommended)](#docker-deployment)
   - [VPS (Full Control)](#vps-deployment)
4. [Post-Deployment](#post-deployment)
5. [Monitoring](#monitoring)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

- **Suno.ai Account** with cookie access
- **2Captcha Account** with API key ([sign up](https://2captcha.com))
- **Git** installed locally

### Platform-Specific

- **Vercel**: Vercel account ([sign up](https://vercel.com))
- **Docker**: Docker & Docker Compose installed
- **VPS**: Ubuntu 20.04+ server with root access

---

## Environment Setup

### 1. Get Suno Cookie

1. Visit [suno.com/create](https://suno.com/create) in your browser
2. Open Developer Tools (F12)
3. Go to Network tab
4. Refresh the page
5. Find a request to `?__clerk_api_version`
6. Copy the `Cookie` header value

### 2. Get 2Captcha API Key

1. Sign up at [2captcha.com](https://2captcha.com)
2. Top up your balance (costs ~$0.001-$0.004 per CAPTCHA)
3. Get your API key from [settings](https://2captcha.com/enterpage#recognition)

### 3. Create Environment File

```bash
cp .env.example .env
```

Edit `.env` with your credentials:

```bash
# Required
SUNO_COOKIE=your_cookie_here
TWOCAPTCHA_KEY=your_api_key_here

# Optional (for production)
UPSTASH_REDIS_REST_URL=https://your-redis.upstash.io
UPSTASH_REDIS_REST_TOKEN=your_token
ALLOWED_ORIGINS=https://yourdomain.com
NODE_ENV=production
LOG_LEVEL=warn
```

### 4. Validate Configuration

```bash
./deploy/scripts/validate-env.sh
```

This checks that all required variables are set correctly.

---

## Deployment Options

## Vercel Deployment

**Best for:** Quick deployment, serverless, automatic scaling

### Requirements

- Vercel account
- GitHub repository

### Steps

#### Option A: One-Click Deploy

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Fgcui-art%2Fsuno-api)

1. Click the button above
2. Connect your GitHub account
3. Add environment variables:
   - `SUNO_COOKIE`
   - `TWOCAPTCHA_KEY`
4. Deploy!

#### Option B: CLI Deploy

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel

# Add secrets
vercel env add SUNO_COOKIE
vercel env add TWOCAPTCHA_KEY

# Production deploy
vercel --prod
```

### Configuration

The `vercel.json` file configures:
- Function timeouts (60-300s)
- Memory allocation (3GB)
- CORS headers
- Environment variables

### Limitations

⚠️ **Important Vercel Limitations:**

- Browser automation can be unreliable
- Cold starts may timeout
- 50MB function size limit
- Not recommended for heavy usage

**For production, use Docker or VPS deployment.**

---

## Docker Deployment

**Best for:** Production, consistent environments, easy scaling

### Requirements

- Docker 20.10+
- Docker Compose 2.0+
- Linux server (recommended)

### Quick Start

```bash
# Run deployment script
./deploy/scripts/deploy-docker.sh
```

This script will:
1. Check requirements
2. Validate environment
3. Build Docker image
4. Deploy services
5. Run health checks

### Manual Deployment

```bash
# Build image
docker build -t suno-api:latest .

# Run with Docker Compose
cd deploy/docker
docker compose -f docker-compose.prod.yml up -d

# Check health
curl http://localhost:3000/api/health
```

### Services

The Docker Compose setup includes:

#### 1. Suno API (Main Service)
- Port: 3000
- Auto-restart enabled
- Health checks configured
- Resource limits set

#### 2. Redis (Optional - Rate Limiting)
- Port: 6379
- 256MB memory limit
- Data persistence

#### 3. Nginx (Optional - Reverse Proxy)
- Ports: 80, 443
- SSL/TLS termination
- Rate limiting
- Security headers

### Configuration

Edit `deploy/docker/docker-compose.prod.yml`:

```yaml
environment:
  - NODE_ENV=production
  - LOG_LEVEL=warn
  # Add your variables
```

### SSL/TLS Setup

1. Get SSL certificates (Let's Encrypt recommended)
2. Place in `deploy/docker/ssl/`
   - `cert.pem` - Certificate
   - `key.pem` - Private key
3. Nginx will automatically use them

### Managing Services

```bash
# View logs
docker logs -f suno-api-prod

# Restart
docker restart suno-api-prod

# Stop all
cd deploy/docker
docker compose -f docker-compose.prod.yml down

# Update
git pull
./deploy/scripts/deploy-docker.sh
```

---

## VPS Deployment

**Best for:** Full control, custom requirements, high performance

### Requirements

- Ubuntu 20.04+ server
- Root/sudo access
- 2GB+ RAM
- 2+ CPU cores

### Automated Deployment

```bash
# On your server
git clone https://github.com/gcui-art/suno-api.git
cd suno-api

# Run deployment script (as root)
sudo ./deploy/scripts/deploy-vps.sh
```

This script will:
1. Install system dependencies
2. Install Node.js 20
3. Create app user
4. Copy and build application
5. Setup systemd service
6. Start and enable service
7. Run health checks

### Manual Deployment

#### 1. Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs

# Install system packages
sudo apt install -y \
    build-essential \
    git \
    libnss3 \
    libdbus-1-3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libxkbcommon0 \
    libasound2 \
    libcups2
```

#### 2. Create App User

```bash
sudo useradd -r -s /bin/bash -d /opt/suno-api -m suno
```

#### 3. Deploy Application

```bash
# Clone repository
sudo git clone https://github.com/gcui-art/suno-api.git /opt/suno-api
cd /opt/suno-api

# Install dependencies
sudo -u suno npm ci --production

# Install Playwright
sudo -u suno npx playwright install chromium

# Build application
sudo -u suno npm run build

# Setup environment
sudo cp .env.example .env
sudo nano .env  # Edit with your credentials
sudo chown suno:suno .env
sudo chmod 600 .env
```

#### 4. Setup Systemd Service

```bash
# Copy service file
sudo cp deploy/vps/suno-api.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable suno-api
sudo systemctl start suno-api

# Check status
sudo systemctl status suno-api
```

#### 5. Setup Nginx (Optional)

```bash
# Install Nginx
sudo apt install -y nginx

# Create site configuration
sudo nano /etc/nginx/sites-available/suno-api
```

Add configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/suno-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 6. Setup SSL with Certbot

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is configured automatically
```

### Managing VPS Service

```bash
# View logs
sudo journalctl -u suno-api -f

# Restart service
sudo systemctl restart suno-api

# Stop service
sudo systemctl stop suno-api

# Check status
sudo systemctl status suno-api

# Update application
cd /opt/suno-api
sudo -u suno git pull
sudo -u suno npm ci --production
sudo -u suno npm run build
sudo systemctl restart suno-api
```

---

## Post-Deployment

### 1. Verify Health

```bash
# Run health check script
./deploy/scripts/health-check.sh

# Or manually
curl http://your-domain.com/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "services": {
    "redis": { "status": "connected" },
    "captcha": { "status": "configured" },
    "suno": { "status": "configured" }
  }
}
```

### 2. Test API

```bash
# Test generation endpoint
curl -X POST http://your-domain.com/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A beautiful piano melody",
    "make_instrumental": false
  }'
```

### 3. Setup Monitoring

#### Option A: Simple Health Checks

```bash
# Add to crontab
*/5 * * * * /path/to/deploy/scripts/health-check.sh >> /var/log/suno-health.log 2>&1
```

#### Option B: Uptime Robot

1. Sign up at [uptimerobot.com](https://uptimerobot.com)
2. Add HTTP(s) monitor
3. URL: `https://your-domain.com/api/health`
4. Interval: 5 minutes

#### Option C: Custom Monitoring

Use the health check script in monitor mode:

```bash
./deploy/scripts/health-check.sh monitor
```

### 4. Configure Backups

```bash
# Backup .env file
sudo cp /opt/suno-api/.env /opt/suno-api/.env.backup

# Backup logs (if any)
sudo tar -czf suno-logs-$(date +%Y%m%d).tar.gz /opt/suno-api/logs/
```

---

## Monitoring

### Health Endpoint

```bash
GET /api/health
```

Returns:
- Service status
- Redis connection
- CAPTCHA configuration
- Memory usage
- Uptime

### Logs

**Docker:**
```bash
docker logs -f suno-api-prod
```

**VPS (systemd):**
```bash
sudo journalctl -u suno-api -f
```

**VPS (file):**
```bash
tail -f /opt/suno-api/logs/application.log
```

### Metrics

Monitor these metrics:

- **Response Time**: Should be < 2s (excluding CAPTCHA)
- **Error Rate**: Should be < 1%
- **Memory Usage**: Should be < 2GB
- **CPU Usage**: Should be < 80%
- **Health Status**: Should be "healthy"

---

## Troubleshooting

### Issue: Environment Variables Not Set

**Error:** `Environment validation failed`

**Solution:**
```bash
# Check .env file
cat .env

# Validate
./deploy/scripts/validate-env.sh

# Fix missing variables
nano .env
```

### Issue: Service Won't Start

**Docker:**
```bash
# Check logs
docker logs suno-api-prod

# Check if port is in use
sudo lsof -i :3000

# Restart
docker restart suno-api-prod
```

**VPS:**
```bash
# Check status
sudo systemctl status suno-api

# Check logs
sudo journalctl -u suno-api -n 50

# Check permissions
ls -la /opt/suno-api

# Restart
sudo systemctl restart suno-api
```

### Issue: Health Check Fails

**Symptoms:** `/api/health` returns unhealthy status

**Diagnosis:**
```bash
./deploy/scripts/health-check.sh
```

**Common causes:**
- Suno cookie expired → Update in .env
- 2Captcha key invalid → Check balance
- Redis not connected → Check Redis service

### Issue: CAPTCHA Solving Fails

**Symptoms:** Generation requests timeout

**Solutions:**
1. Check 2Captcha balance
2. Verify `TWOCAPTCHA_KEY` is correct
3. Check Playwright browser installation:
   ```bash
   npx playwright install chromium
   ```

### Issue: Rate Limiting Not Working

**Symptoms:** No rate limit headers

**Cause:** Redis not configured

**Solution:**
```bash
# Sign up at upstash.com
# Add to .env:
UPSTASH_REDIS_REST_URL=https://...
UPSTASH_REDIS_REST_TOKEN=...

# Restart service
```

### Issue: High Memory Usage

**Symptoms:** Memory > 4GB

**Solutions:**
1. Restart service to clear memory
2. Reduce concurrent requests
3. Enable rate limiting
4. Increase server RAM

### Issue: CORS Errors

**Symptoms:** Browser blocks requests

**Solution:**
```bash
# In .env, set:
ALLOWED_ORIGINS=https://your-frontend.com

# Or for development:
ALLOWED_ORIGINS=*

# Restart service
```

---

## Security Checklist

Before going to production:

- [ ] Change all default credentials
- [ ] Enable HTTPS/SSL
- [ ] Configure `ALLOWED_ORIGINS` (not `*`)
- [ ] Set `NODE_ENV=production`
- [ ] Set `LOG_LEVEL=warn` or `error`
- [ ] Enable rate limiting with Redis
- [ ] Setup firewall rules
- [ ] Enable automatic security updates
- [ ] Configure backup strategy
- [ ] Setup monitoring and alerts
- [ ] Review and restrict file permissions
- [ ] Enable fail2ban (VPS)
- [ ] Use strong passwords
- [ ] Keep dependencies updated

---

## Performance Optimization

### 1. Enable Rate Limiting

Prevents abuse and reduces costs:

```bash
# Setup Upstash Redis (free tier available)
UPSTASH_REDIS_REST_URL=https://...
UPSTASH_REDIS_REST_TOKEN=...
```

### 2. Optimize Logging

```bash
# Production
LOG_LEVEL=warn

# Development
LOG_LEVEL=debug
```

### 3. Resource Limits (Docker)

Edit `docker-compose.prod.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
```

### 4. Caching (Advanced)

Add CDN for static assets:
- CloudFlare
- AWS CloudFront
- Fastly

---

## Scaling

### Horizontal Scaling

**Docker Swarm:**
```bash
docker swarm init
docker stack deploy -c docker-compose.prod.yml suno
```

**Kubernetes:**
- Use provided Kubernetes manifests (coming soon)

### Vertical Scaling

Increase server resources:
- RAM: 4GB → 8GB
- CPU: 2 cores → 4 cores
- Storage: Add SSD

### Load Balancing

Use Nginx or HAProxy to distribute traffic across multiple instances.

---

## Backup & Recovery

### Backup

```bash
# Environment file
cp .env .env.backup

# Database (if added)
# mysqldump or pg_dump

# Logs
tar -czf logs-backup.tar.gz logs/
```

### Recovery

```bash
# Restore environment
cp .env.backup .env

# Restart services
systemctl restart suno-api
```

---

## Support

- **Documentation**: [README.md](./README.md)
- **Security**: [SECURITY.md](./SECURITY.md)
- **Development**: [DEVELOPMENT.md](./DEVELOPMENT.md)
- **Issues**: https://github.com/gcui-art/suno-api/issues

---

## License

LGPL-3.0-or-later - see [LICENSE](./LICENSE)
