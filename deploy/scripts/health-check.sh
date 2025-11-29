#!/bin/bash

###############################################################################
# Suno API - Health Check Script
# Monitors the health of the Suno API service
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_URL="${API_URL:-http://localhost:3000}"
HEALTH_ENDPOINT="${API_URL}/api/health"
TIMEOUT=10

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

check_health() {
    log_info "Checking health at: $HEALTH_ENDPOINT"

    # Make request
    RESPONSE=$(curl -s -w "\n%{http_code}" --max-time $TIMEOUT "$HEALTH_ENDPOINT" 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_error "Failed to connect to health endpoint"
        return 1
    fi

    # Extract HTTP code and body
    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    # Check HTTP code
    if [ "$HTTP_CODE" -eq 200 ]; then
        log_info "✓ HTTP Status: $HTTP_CODE (OK)"
    elif [ "$HTTP_CODE" -eq 503 ]; then
        log_error "✗ HTTP Status: $HTTP_CODE (Service Unavailable)"
        echo "$BODY" | jq '.'
        return 1
    else
        log_warn "⚠ HTTP Status: $HTTP_CODE"
    fi

    # Parse JSON response
    if ! echo "$BODY" | jq . > /dev/null 2>&1; then
        log_error "Invalid JSON response"
        echo "$BODY"
        return 1
    fi

    # Extract status
    STATUS=$(echo "$BODY" | jq -r '.status')

    echo ""
    echo "Health Status:"
    echo "=============="

    # Pretty print response
    echo "$BODY" | jq '.'

    echo ""
    echo "Status Summary:"
    echo "==============="

    # Check overall status
    case "$STATUS" in
        "healthy")
            echo -e "${GREEN}● Service is HEALTHY${NC}"
            ;;
        "degraded")
            echo -e "${YELLOW}▲ Service is DEGRADED${NC}"
            log_warn "Some non-critical services may be down"
            ;;
        "unhealthy")
            echo -e "${RED}✗ Service is UNHEALTHY${NC}"
            log_error "Critical services are down"
            return 1
            ;;
        *)
            echo -e "${YELLOW}? Unknown status: $STATUS${NC}"
            return 1
            ;;
    esac

    # Check services
    echo ""
    echo "Service Details:"
    echo "================"

    # Redis
    REDIS_STATUS=$(echo "$BODY" | jq -r '.services.redis.status // "not_configured"')
    if [ "$REDIS_STATUS" = "connected" ]; then
        REDIS_LATENCY=$(echo "$BODY" | jq -r '.services.redis.latency')
        echo -e "  Redis:   ${GREEN}✓ Connected${NC} (latency: ${REDIS_LATENCY}ms)"
    elif [ "$REDIS_STATUS" = "disconnected" ]; then
        echo -e "  Redis:   ${YELLOW}○ Not configured${NC} (rate limiting disabled)"
    else
        echo -e "  Redis:   ${RED}✗ Error${NC}"
    fi

    # CAPTCHA
    CAPTCHA_STATUS=$(echo "$BODY" | jq -r '.services.captcha.status')
    if [ "$CAPTCHA_STATUS" = "configured" ]; then
        echo -e "  CAPTCHA: ${GREEN}✓ Configured${NC}"
    else
        echo -e "  CAPTCHA: ${RED}✗ Not configured${NC}"
    fi

    # Suno
    SUNO_STATUS=$(echo "$BODY" | jq -r '.services.suno.status')
    if [ "$SUNO_STATUS" = "configured" ]; then
        echo -e "  Suno:    ${GREEN}✓ Configured${NC}"
    else
        echo -e "  Suno:    ${RED}✗ Not configured${NC}"
    fi

    # Memory
    echo ""
    echo "Memory Usage:"
    echo "============="
    RSS=$(echo "$BODY" | jq -r '.memory.rss')
    HEAP_USED=$(echo "$BODY" | jq -r '.memory.heapUsed')
    HEAP_TOTAL=$(echo "$BODY" | jq -r '.memory.heapTotal')

    echo "  RSS:       ${RSS} MB"
    echo "  Heap Used: ${HEAP_USED} MB"
    echo "  Heap Total: ${HEAP_TOTAL} MB"

    # Uptime
    UPTIME=$(echo "$BODY" | jq -r '.uptime')
    UPTIME_HOURS=$((UPTIME / 3600))
    UPTIME_MINS=$(((UPTIME % 3600) / 60))

    echo ""
    echo "Uptime: ${UPTIME_HOURS}h ${UPTIME_MINS}m"

    # Return based on status
    if [ "$STATUS" = "healthy" ]; then
        return 0
    elif [ "$STATUS" = "degraded" ]; then
        return 0
    else
        return 1
    fi
}

# Continuous monitoring mode
monitor_mode() {
    log_info "Starting continuous health monitoring..."
    log_info "Press Ctrl+C to stop"
    echo ""

    while true; do
        clear
        echo "==============================================="
        echo "  Suno API Health Monitor"
        echo "  $(date)"
        echo "==============================================="
        echo ""

        check_health

        echo ""
        echo "Next check in 30 seconds..."
        sleep 30
    done
}

# Main
main() {
    if [ "$1" = "monitor" ] || [ "$1" = "-m" ]; then
        monitor_mode
    else
        check_health
        exit $?
    fi
}

# Run
main "$@"
