#!/bin/bash

###############################################################################
# Suno API - Environment Validation Script
# Validates that all required environment variables are set
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Check if .env file exists
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
    echo -e "${RED}[ERROR]${NC} .env file not found at ${PROJECT_ROOT}/.env"
    echo -e "${YELLOW}[INFO]${NC} Copy .env.example to .env and fill in your credentials"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Validating environment configuration..."
echo ""

# Source .env file
set -a
source "${PROJECT_ROOT}/.env"
set +a

ERRORS=0
WARNINGS=0

# Required variables
check_required() {
    local var_name=$1
    local var_value=${!var_name}

    if [ -z "$var_value" ]; then
        echo -e "${RED}✗${NC} $var_name is not set (REQUIRED)"
        ERRORS=$((ERRORS + 1))
    else
        # Mask sensitive values
        if [[ $var_name =~ (COOKIE|KEY|TOKEN|SECRET|PASSWORD) ]]; then
            local masked_value="${var_value:0:10}...${var_value: -4}"
            echo -e "${GREEN}✓${NC} $var_name is set ($masked_value)"
        else
            echo -e "${GREEN}✓${NC} $var_name is set ($var_value)"
        fi
    fi
}

# Optional variables
check_optional() {
    local var_name=$1
    local var_value=${!var_name}
    local default_value=$2

    if [ -z "$var_value" ]; then
        echo -e "${YELLOW}○${NC} $var_name not set (optional, default: $default_value)"
        WARNINGS=$((WARNINGS + 1))
    else
        if [[ $var_name =~ (TOKEN|SECRET) ]]; then
            local masked_value="${var_value:0:10}..."
            echo -e "${GREEN}✓${NC} $var_name is set ($masked_value)"
        else
            echo -e "${GREEN}✓${NC} $var_name is set ($var_value)"
        fi
    fi
}

echo "Required Variables:"
echo "==================="
check_required "SUNO_COOKIE"
check_required "TWOCAPTCHA_KEY"

echo ""
echo "Browser Configuration:"
echo "======================"
check_optional "BROWSER" "chromium"
check_optional "BROWSER_HEADLESS" "true"
check_optional "BROWSER_LOCALE" "en"
check_optional "BROWSER_GHOST_CURSOR" "false"
check_optional "BROWSER_DISABLE_GPU" "false"

echo ""
echo "Rate Limiting (Optional):"
echo "========================="
check_optional "UPSTASH_REDIS_REST_URL" "not configured"
check_optional "UPSTASH_REDIS_REST_TOKEN" "not configured"

if [ -z "$UPSTASH_REDIS_REST_URL" ] && [ -z "$UPSTASH_REDIS_REST_TOKEN" ]; then
    echo -e "${YELLOW}[WARN]${NC} Rate limiting is disabled (Redis not configured)"
    echo -e "${YELLOW}[INFO]${NC} For production, consider setting up Upstash Redis"
fi

echo ""
echo "Security Configuration:"
echo "======================="
check_optional "ALLOWED_ORIGINS" "*"
check_optional "LOG_LEVEL" "info"
check_optional "NODE_ENV" "development"

if [ "$NODE_ENV" = "production" ] && [ "$ALLOWED_ORIGINS" = "*" ]; then
    echo -e "${RED}[ERROR]${NC} ALLOWED_ORIGINS should not be '*' in production!"
    echo -e "${YELLOW}[INFO]${NC} Set specific domains: ALLOWED_ORIGINS=https://yourdomain.com"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Validation Summary:"
echo "==================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Configuration valid with $WARNINGS warnings${NC}"
    echo -e "${YELLOW}[INFO]${NC} Warnings indicate optional missing configurations"
    exit 0
else
    echo -e "${RED}✗ Configuration invalid: $ERRORS errors, $WARNINGS warnings${NC}"
    echo ""
    echo "Please fix the errors above before deploying."
    exit 1
fi
