#!/bin/bash

###############################################################################
# Suno API - VPS Deployment Script
# This script deploys the Suno API on a VPS with systemd
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="suno-api"
APP_USER="suno"
APP_DIR="/opt/suno-api"
SERVICE_FILE="/etc/systemd/system/suno-api.service"
NODE_VERSION="20"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}==>${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        log_info "Please run: sudo $0"
        exit 1
    fi
}

install_dependencies() {
    log_step "Installing system dependencies..."

    # Update package list
    apt-get update

    # Install required packages
    apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
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
        libcups2 \
        xvfb

    log_info "✓ System dependencies installed"
}

install_node() {
    log_step "Installing Node.js ${NODE_VERSION}..."

    # Check if Node.js is already installed
    if command -v node &> /dev/null; then
        CURRENT_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$CURRENT_VERSION" -ge "$NODE_VERSION" ]; then
            log_info "✓ Node.js $CURRENT_VERSION is already installed"
            return 0
        fi
    fi

    # Install Node.js using NodeSource
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt-get install -y nodejs

    log_info "✓ Node.js $(node -v) installed"
    log_info "✓ npm $(npm -v) installed"
}

create_user() {
    log_step "Creating application user..."

    if id "$APP_USER" &>/dev/null; then
        log_info "✓ User $APP_USER already exists"
    else
        useradd -r -s /bin/bash -d "$APP_DIR" -m "$APP_USER"
        log_info "✓ User $APP_USER created"
    fi
}

setup_application() {
    log_step "Setting up application..."

    # Create app directory if it doesn't exist
    mkdir -p "$APP_DIR"

    # Copy application files
    log_info "Copying application files..."
    rsync -av --exclude='node_modules' --exclude='.next' --exclude='.git' \
        "${PROJECT_ROOT}/" "$APP_DIR/"

    # Set ownership
    chown -R $APP_USER:$APP_USER "$APP_DIR"

    log_info "✓ Application files copied"
}

install_app_dependencies() {
    log_step "Installing application dependencies..."

    cd "$APP_DIR"

    # Install npm dependencies as app user
    su - $APP_USER -c "cd $APP_DIR && PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci --production"

    # Install Playwright browsers
    su - $APP_USER -c "cd $APP_DIR && npx playwright install chromium"

    log_info "✓ Application dependencies installed"
}

build_application() {
    log_step "Building application..."

    cd "$APP_DIR"

    # Build Next.js app as app user
    su - $APP_USER -c "cd $APP_DIR && npm run build"

    log_info "✓ Application built successfully"
}

setup_environment() {
    log_step "Setting up environment configuration..."

    if [ ! -f "$APP_DIR/.env" ]; then
        if [ -f "$APP_DIR/.env.example" ]; then
            cp "$APP_DIR/.env.example" "$APP_DIR/.env"
            chown $APP_USER:$APP_USER "$APP_DIR/.env"
            chmod 600 "$APP_DIR/.env"

            log_warn "Created .env file from example"
            log_warn "Please edit $APP_DIR/.env with your credentials"
            log_warn "Required: SUNO_COOKIE and TWOCAPTCHA_KEY"

            # Pause for user to edit
            read -p "Press enter after editing .env file..."
        else
            log_error ".env.example not found!"
            exit 1
        fi
    else
        log_info "✓ .env file already exists"
    fi

    # Verify required variables
    source "$APP_DIR/.env"

    if [ -z "$SUNO_COOKIE" ]; then
        log_error "SUNO_COOKIE is not set in .env"
        exit 1
    fi

    if [ -z "$TWOCAPTCHA_KEY" ]; then
        log_error "TWOCAPTCHA_KEY is not set in .env"
        exit 1
    fi

    log_info "✓ Environment configured"
}

setup_systemd() {
    log_step "Setting up systemd service..."

    # Copy service file
    cp "${PROJECT_ROOT}/deploy/vps/suno-api.service" "$SERVICE_FILE"

    # Reload systemd
    systemctl daemon-reload

    # Enable service
    systemctl enable suno-api

    log_info "✓ Systemd service configured"
}

start_service() {
    log_step "Starting service..."

    # Start service
    systemctl restart suno-api

    # Wait for service to start
    sleep 5

    # Check status
    if systemctl is-active --quiet suno-api; then
        log_info "✓ Service started successfully"
    else
        log_error "Service failed to start"
        log_error "Check logs with: journalctl -u suno-api -n 50"
        exit 1
    fi
}

check_health() {
    log_step "Checking service health..."

    MAX_RETRIES=12
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -f http://localhost:3000/api/health &> /dev/null; then
            log_info "✓ Service is healthy!"

            # Show health status
            echo ""
            echo "Health Status:"
            curl -s http://localhost:3000/api/health | jq '.'
            return 0
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        log_warn "Waiting for service... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 5
    done

    log_error "Service health check failed"
    log_error "Check logs with: journalctl -u suno-api -n 50"
    exit 1
}

show_summary() {
    log_info ""
    log_info "=============================================="
    log_info "  Suno API VPS Deployment Completed!        "
    log_info "=============================================="
    log_info ""
    log_info "Service URL: http://localhost:3000"
    log_info "Health check: http://localhost:3000/api/health"
    log_info ""
    log_info "Useful commands:"
    log_info "  Status:  systemctl status suno-api"
    log_info "  Logs:    journalctl -u suno-api -f"
    log_info "  Stop:    systemctl stop suno-api"
    log_info "  Start:   systemctl start suno-api"
    log_info "  Restart: systemctl restart suno-api"
    log_info ""
    log_info "Application directory: $APP_DIR"
    log_info "Configuration file: $APP_DIR/.env"
    log_info ""
}

main() {
    log_info "Starting Suno API VPS deployment..."

    check_root
    install_dependencies
    install_node
    create_user
    setup_application
    install_app_dependencies
    build_application
    setup_environment
    setup_systemd
    start_service
    check_health
    show_summary

    log_info "Deployment completed successfully!"
}

# Run main function
main "$@"
