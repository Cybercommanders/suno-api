# Administrator Panel Guide

The Suno API Administrator Panel is an interactive menu system that provides easy access to all deployment, management, and monitoring tools.

## Quick Start

### Launch the Admin Panel

```bash
./admin.sh
```

## Features

### 🔧 **1. Environment & Configuration**

Manage environment variables and configuration:

- **Validate Environment** - Check all required variables are set
- **View Configuration** - Display current settings (sanitized)
- **Edit .env File** - Open .env in your editor
- **Create .env** - Create from example template
- **Test Variables** - Verify all environment variables

**Example:**
```bash
# Launch admin panel
./admin.sh

# Select: 1 (Environment & Configuration)
# Select: 1 (Validate Environment Configuration)
```

---

### 🚀 **2. Deployment**

Deploy to various platforms:

- **Docker Deployment** - Automated Docker deployment
- **VPS Deployment** - Ubuntu/systemd deployment
- **Vercel Deployment** - Serverless deployment
- **Build Docker Image** - Build image only
- **Pull Latest Code** - Update from Git
- **Update Dependencies** - Run npm install

**Example:**
```bash
# Deploy with Docker
./admin.sh
# Select: 2 (Deployment)
# Select: 1 (Deploy with Docker)
```

---

### ⚙️ **3. Service Management**

Control the running service:

- **Start Service** - Start Suno API service
- **Stop Service** - Stop running service
- **Restart Service** - Restart service
- **Service Status** - Check current status
- **Enable Auto-start** - Enable on boot
- **Disable Auto-start** - Disable on boot

**Works with:**
- Docker containers
- Systemd services (VPS)

**Example:**
```bash
# Restart service
./admin.sh
# Select: 3 (Service Management)
# Select: 3 (Restart Service)
```

---

### 📊 **4. Monitoring & Health**

Monitor service health and performance:

- **Check Health** - Single health check
- **Monitor Health** - Continuous monitoring (30s interval)
- **Test API Endpoints** - Verify API accessibility
- **System Resources** - CPU, memory, disk usage
- **Error Summary** - Recent errors from logs

**Example:**
```bash
# Continuous health monitoring
./admin.sh
# Select: 4 (Monitoring & Health)
# Select: 2 (Monitor Service Health - continuous)
# Press Ctrl+C to stop
```

---

### 📝 **5. Logs & Debugging**

View and analyze logs:

- **Live Logs (Docker)** - Follow Docker container logs
- **Live Logs (systemd)** - Follow systemd journal
- **Last 50 Lines** - Recent log entries
- **Last 100 Lines** - More log history
- **Search Errors** - Find specific errors
- **Export Logs** - Save logs to file

**Example:**
```bash
# Search for errors
./admin.sh
# Select: 5 (Logs & Debugging)
# Select: 5 (Search Logs for Errors)
# Enter: captcha
```

---

### 🛠️ **6. Utilities**

Development and maintenance tools:

- **Run Tests** - Execute test suite
- **Build Application** - Build production bundle
- **Clean Build** - Remove build artifacts
- **Update Playwright** - Update browser binaries
- **Check for Updates** - See available Git updates
- **Backup Configuration** - Backup .env file
- **System Information** - Show installed versions

**Example:**
```bash
# Run tests
./admin.sh
# Select: 6 (Utilities)
# Select: 1 (Run Tests)
```

---

### 📚 **7. Documentation**

Access project documentation:

- **View README** - Main project documentation
- **Deployment Guide** - Complete deployment instructions
- **Security Guide** - Security best practices
- **Development Guide** - Developer handbook
- **API Documentation** - Open Swagger docs in browser
- **List All Docs** - Show all .md files

**Example:**
```bash
# View deployment guide
./admin.sh
# Select: 7 (Documentation)
# Select: 2 (View Deployment Guide)
# Use arrow keys to scroll, 'q' to quit
```

---

## Navigation

### Menu Controls

- **Number Keys (0-9)** - Select menu options
- **Enter** - Confirm selection
- **9** - Return to previous menu (in submenus)
- **0** - Exit application (from main menu)
- **Ctrl+C** - Interrupt running command
- **Arrow Keys** - Scroll in documentation viewer
- **q** - Quit documentation viewer

### Color Codes

- 🟢 **Green** - Success, available options
- 🔴 **Red** - Errors, exit option
- 🟡 **Yellow** - Warnings, back option
- 🔵 **Blue** - Information, separators
- 🟣 **Cyan** - Headers, prompts

---

## Common Workflows

### First-Time Setup

```bash
./admin.sh

# 1. Create environment
1 → 4 (Create .env from example)
# Edit and save .env file

# 2. Validate configuration
1 → 1 (Validate Environment)

# 3. Deploy
2 → 1 (Deploy with Docker)

# 4. Check health
4 → 1 (Check Health)
```

### Daily Operations

```bash
./admin.sh

# Check service status
3 → 4 (Service Status)

# View recent logs
5 → 3 (View Last 50 Lines)

# Monitor health
4 → 2 (Monitor Health - continuous)
```

### Troubleshooting

```bash
./admin.sh

# 1. Check health
4 → 1 (Check Service Health)

# 2. View errors
5 → 5 (Search Logs for Errors)

# 3. Check system resources
4 → 4 (Check System Resources)

# 4. Restart service
3 → 3 (Restart Service)

# 5. Verify health
4 → 1 (Check Service Health)
```

### Updating

```bash
./admin.sh

# 1. Check for updates
6 → 5 (Check for Updates)

# 2. Backup configuration
6 → 6 (Backup Configuration)

# 3. Pull latest code
2 → 5 (Pull Latest Code)

# 4. Update dependencies
2 → 6 (Update Dependencies)

# 5. Rebuild
6 → 2 (Build Application)

# 6. Restart
3 → 3 (Restart Service)
```

---

## Advanced Usage

### Custom API URL

Set a custom API URL for health checks:

```bash
API_URL=https://api.example.com ./admin.sh
```

### Custom Editor

Use a different text editor for .env:

```bash
EDITOR=vim ./admin.sh
```

### Run Specific Actions

You can also run scripts directly:

```bash
# Validate environment
./deploy/scripts/validate-env.sh

# Check health
./deploy/scripts/health-check.sh

# Deploy Docker
./deploy/scripts/deploy-docker.sh
```

---

## Keyboard Shortcuts

When viewing logs or documentation:

- **Space** - Page down
- **b** - Page up
- **g** - Go to top
- **G** - Go to bottom
- **/pattern** - Search forward
- **?pattern** - Search backward
- **n** - Next search result
- **N** - Previous search result
- **q** - Quit viewer

---

## Troubleshooting

### Admin Panel Won't Start

```bash
# Check if script is executable
ls -la admin.sh

# Make executable if needed
chmod +x admin.sh

# Run with bash explicitly
bash admin.sh
```

### Permission Denied

Some operations require sudo/root:

```bash
# VPS deployment
sudo ./admin.sh
# Then select: 2 → 2

# Or run specific script
sudo ./deploy/scripts/deploy-vps.sh
```

### Scripts Not Found

Ensure you're in the project root:

```bash
cd /path/to/suno-api
./admin.sh
```

### Docker Commands Fail

Ensure Docker is running:

```bash
# Check Docker status
docker ps

# Start Docker (if needed)
sudo systemctl start docker
```

### Service Detection Issues

The admin panel auto-detects Docker or systemd services. If detection fails:

- Ensure service is properly deployed
- Check service names match expected patterns
- Run deployment script first

---

## Tips & Best Practices

### 1. Regular Health Monitoring

Set up a terminal window with continuous monitoring:

```bash
./admin.sh
# Select: 4 → 2 (Monitor Health)
# Leave running in dedicated terminal
```

### 2. Log Analysis

Export logs for detailed analysis:

```bash
./admin.sh
# Select: 5 → 6 (Export Logs)
# Opens in: logs_export_YYYYMMDD_HHMMSS.log
```

### 3. Pre-Deployment Checks

Always validate before deploying:

```bash
./admin.sh
# 1. Validate: 1 → 1
# 2. Backup: 6 → 6
# 3. Deploy: 2 → 1
# 4. Verify: 4 → 1
```

### 4. Quick Status Check

For a quick overview:

```bash
./admin.sh
# Select: 4 → 1 (Check Health)
# Shows all services in one view
```

---

## Integration with Other Tools

### Cron Jobs

Schedule health checks:

```bash
# Add to crontab
*/15 * * * * /path/to/deploy/scripts/health-check.sh >> /var/log/suno-health.log 2>&1
```

### Monitoring Systems

Export health data:

```bash
# Get health JSON
curl http://localhost:3000/api/health | jq '.'
```

### CI/CD Pipelines

Use scripts in automated workflows:

```bash
# In your CI/CD
./deploy/scripts/validate-env.sh
./deploy/scripts/deploy-docker.sh
./deploy/scripts/health-check.sh
```

---

## Security Notes

### Sensitive Information

The admin panel automatically sanitizes sensitive data when displaying configuration:

- Cookies shown as: `abc123...xyz789`
- API keys masked similarly
- Full values never displayed

### File Permissions

Ensure .env has proper permissions:

```bash
chmod 600 .env
```

### Root Access

VPS deployment requires root:

```bash
sudo ./admin.sh
# Select: 2 → 2 (Deploy to VPS)
```

---

## Support

### Getting Help

- Press **7** in main menu for documentation
- View specific guides from documentation menu
- Check troubleshooting sections

### Reporting Issues

If you encounter problems:

1. Export logs: `5 → 6`
2. Note error messages
3. Check system info: `6 → 7`
4. Report on GitHub Issues

---

## Examples

### Example 1: Fresh Deployment

```bash
$ ./admin.sh

╔════════════════════════════════════════════════════════════╗
║           Suno API - Administrator Panel                ║
╚════════════════════════════════════════════════════════════╝

Main Menu:

  1) Environment & Configuration
  2) Deployment
  3) Service Management
  4) Monitoring & Health
  5) Logs & Debugging
  6) Utilities
  7) Documentation

  0) Exit

Select option: 1

Environment & Configuration:

  1) Validate Environment Configuration
  2) View Current Configuration (sanitized)
  3) Edit .env File
  4) Create .env from Example
  5) Test Environment Variables

  9) Back to Main Menu

Select option: 1

[INFO] Validating Environment Configuration...

Required Variables:
===================
✓ SUNO_COOKIE is set (abc123...xyz789)
✓ TWOCAPTCHA_KEY is set (def456...uvw012)

✓ All checks passed!

Press Enter to continue...
```

### Example 2: Monitoring Health

```bash
$ ./admin.sh

# Select: 4 (Monitoring & Health)
# Select: 2 (Monitor Service Health - continuous)

===============================================
  Suno API Health Monitor
  2025-01-15 10:30:00
===============================================

Health Status:
==============
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
  "uptime": 7200
}

Status Summary:
===============
● Service is HEALTHY

Service Details:
================
  Redis:   ✓ Connected (latency: 12ms)
  CAPTCHA: ✓ Configured
  Suno:    ✓ Configured

Memory Usage:
=============
  RSS:       150 MB
  Heap Used: 80 MB
  Heap Total: 120 MB

Uptime: 2h 0m

Next check in 30 seconds...
```

---

## Quick Reference

| Task | Menu Path |
|------|-----------|
| Validate Config | 1 → 1 |
| Deploy Docker | 2 → 1 |
| Deploy VPS | 2 → 2 |
| Check Health | 4 → 1 |
| Monitor Health | 4 → 2 |
| View Logs | 5 → 1/2 |
| Restart Service | 3 → 3 |
| Run Tests | 6 → 1 |
| View Docs | 7 → (1-6) |

---

## Version Information

- **Admin Panel Version**: 1.0.0
- **Compatible with**: Suno API v1.1.0+
- **Platforms**: Linux, macOS
- **Requirements**: Bash 4.0+

---

## License

This admin panel is part of the Suno API project and is licensed under LGPL-3.0-or-later.

---

**Enjoy managing your Suno API deployment! 🚀**
