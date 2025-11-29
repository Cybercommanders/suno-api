#!/bin/bash

###############################################################################
# Suno API - Docker Deployment Script
# This script deploys the Suno API using Docker Compose
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEPLOY_DIR="${PROJECT_ROOT}/deploy/docker"

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

check_requirements() {
    log_info "Checking requirements..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    log_info "✓ All requirements met"
}

check_env_file() {
    log_info "Checking environment configuration..."

    if [ ! -f "${PROJECT_ROOT}/.env" ]; then
        log_warn ".env file not found. Creating from .env.example..."

        if [ -f "${PROJECT_ROOT}/.env.example" ]; then
            cp "${PROJECT_ROOT}/.env.example" "${PROJECT_ROOT}/.env"
            log_warn "Please edit .env file with your credentials before continuing."
            log_warn "Required: SUNO_COOKIE and TWOCAPTCHA_KEY"
            exit 1
        else
            log_error ".env.example file not found!"
            exit 1
        fi
    fi

    # Check required variables
    source "${PROJECT_ROOT}/.env"

    if [ -z "$SUNO_COOKIE" ]; then
        log_error "SUNO_COOKIE is not set in .env file"
        exit 1
    fi

    if [ -z "$TWOCAPTCHA_KEY" ]; then
        log_error "TWOCAPTCHA_KEY is not set in .env file"
        exit 1
    fi

    log_info "✓ Environment configured"
}

build_image() {
    log_info "Building Docker image..."

    cd "${PROJECT_ROOT}"

    docker build \
        --build-arg SUNO_COOKIE="${SUNO_COOKIE}" \
        -t suno-api:latest \
        -f Dockerfile \
        .

    log_info "✓ Docker image built successfully"
}

deploy_services() {
    log_info "Deploying services with Docker Compose..."

    cd "${DEPLOY_DIR}"

    # Use docker compose or docker-compose depending on what's available
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi

    # Stop existing containers
    log_info "Stopping existing containers..."
    $COMPOSE_CMD -f docker-compose.prod.yml down || true

    # Start services
    log_info "Starting services..."
    $COMPOSE_CMD -f docker-compose.prod.yml up -d

    log_info "✓ Services deployed successfully"
}

check_health() {
    log_info "Checking service health..."

    # Wait for service to start
    sleep 10

    MAX_RETRIES=12
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -f http://localhost:3000/api/health &> /dev/null; then
            log_info "✓ Service is healthy!"
            return 0
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        log_warn "Waiting for service to be healthy... (attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 5
    done

    log_error "Service health check failed after $MAX_RETRIES attempts"
    log_error "Check logs with: docker logs suno-api-prod"
    exit 1
}

show_logs() {
    log_info "Showing recent logs..."
    docker logs --tail 50 suno-api-prod
}

show_status() {
    log_info "Service status:"

    cd "${DEPLOY_DIR}"

    if docker compose version &> /dev/null; then
        docker compose -f docker-compose.prod.yml ps
    else
        docker-compose -f docker-compose.prod.yml ps
    fi
}

main() {
    log_info "Starting Suno API deployment..."
    log_info "Project root: ${PROJECT_ROOT}"

    check_requirements
    check_env_file
    build_image
    deploy_services
    check_health
    show_status

    log_info ""
    log_info "======================================"
    log_info "  Deployment completed successfully!  "
    log_info "======================================"
    log_info ""
    log_info "Service URL: http://localhost:3000"
    log_info "Health check: http://localhost:3000/api/health"
    log_info ""
    log_info "Useful commands:"
    log_info "  View logs:    docker logs -f suno-api-prod"
    log_info "  Stop service: cd ${DEPLOY_DIR} && docker compose -f docker-compose.prod.yml down"
    log_info "  Restart:      cd ${DEPLOY_DIR} && docker compose -f docker-compose.prod.yml restart"
    log_info ""
}

# Run main function
main "$@"
