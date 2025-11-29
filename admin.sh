#!/bin/bash

###############################################################################
# Suno API - Administrator Menu
# Interactive menu for managing deployment and operations
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEPLOY_SCRIPTS="${PROJECT_ROOT}/deploy/scripts"

# Global variables
CONTINUE_MENU=true

# Functions
clear_screen() {
    clear
    echo ""
}

print_header() {
    clear_screen
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}           Suno API - Administrator Panel                ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_separator() {
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

pause_for_input() {
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read -r
}

# Menu Functions

show_main_menu() {
    print_header
    echo -e "${WHITE}Main Menu:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Environment & Configuration"
    echo -e "  ${GREEN}2)${NC} Deployment"
    echo -e "  ${GREEN}3)${NC} Service Management"
    echo -e "  ${GREEN}4)${NC} Monitoring & Health"
    echo -e "  ${GREEN}5)${NC} Logs & Debugging"
    echo -e "  ${GREEN}6)${NC} Utilities"
    echo -e "  ${GREEN}7)${NC} Documentation"
    echo ""
    echo -e "  ${RED}0)${NC} Exit"
    echo ""
    print_separator
}

show_environment_menu() {
    print_header
    echo -e "${WHITE}Environment & Configuration:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Validate Environment Configuration"
    echo -e "  ${GREEN}2)${NC} View Current Configuration (sanitized)"
    echo -e "  ${GREEN}3)${NC} Edit .env File"
    echo -e "  ${GREEN}4)${NC} Create .env from Example"
    echo -e "  ${GREEN}5)${NC} Test Environment Variables"
    echo ""
    echo -e "  ${YELLOW}9)${NC} Back to Main Menu"
    echo ""
    print_separator
}

show_deployment_menu() {
    print_header
    echo -e "${WHITE}Deployment Options:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Deploy with Docker"
    echo -e "  ${GREEN}2)${NC} Deploy to VPS (systemd)"
    echo -e "  ${GREEN}3)${NC} Deploy to Vercel"
    echo -e "  ${GREEN}4)${NC} Build Docker Image Only"
    echo -e "  ${GREEN}5)${NC} Pull Latest Code from Git"
    echo -e "  ${GREEN}6)${NC} Update Dependencies (npm install)"
    echo ""
    echo -e "  ${YELLOW}9)${NC} Back to Main Menu"
    echo ""
    print_separator
}

show_service_menu() {
    print_header
    echo -e "${WHITE}Service Management:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Start Service"
    echo -e "  ${GREEN}2)${NC} Stop Service"
    echo -e "  ${GREEN}3)${NC} Restart Service"
    echo -e "  ${GREEN}4)${NC} Service Status"
    echo -e "  ${GREEN}5)${NC} Enable Service (auto-start)"
    echo -e "  ${GREEN}6)${NC} Disable Service"
    echo ""
    echo -e "  ${YELLOW}9)${NC} Back to Main Menu"
    echo ""
    print_separator
}

show_monitoring_menu() {
    print_header
    echo -e "${WHITE}Monitoring & Health:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Check Service Health (once)"
    echo -e "  ${GREEN}2)${NC} Monitor Service Health (continuous)"
    echo -e "  ${GREEN}3)${NC} Test API Endpoints"
    echo -e "  ${GREEN}4)${NC} Check System Resources"
    echo -e "  ${GREEN}5)${NC} View Error Summary"
    echo ""
    echo -e "  ${YELLOW}9)${NC} Back to Main Menu"
    echo ""
    print_separator
}

show_logs_menu() {
    print_header
    echo -e "${WHITE}Logs & Debugging:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} View Live Logs (Docker)"
    echo -e "  ${GREEN}2)${NC} View Live Logs (systemd)"
    echo -e "  ${GREEN}3)${NC} View Last 50 Lines"
    echo -e "  ${GREEN}4)${NC} View Last 100 Lines"
    echo -e "  ${GREEN}5)${NC} Search Logs for Errors"
    echo -e "  ${GREEN}6)${NC} Export Logs to File"
    echo ""
    echo -e "  ${YELLOW}9)${NC} Back to Main Menu"
    echo ""
    print_separator
}

show_utilities_menu() {
    print_header
    echo -e "${WHITE}Utilities:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Run Tests"
    echo -e "  ${GREEN}2)${NC} Build Application"
    echo -e "  ${GREEN}3)${NC} Clean Build Artifacts"
    echo -e "  ${GREEN}4)${NC} Update Playwright Browsers"
    echo -e "  ${GREEN}5)${NC} Check for Updates"
    echo -e "  ${GREEN}6)${NC} Backup Configuration"
    echo -e "  ${GREEN}7)${NC} System Information"
    echo ""
    echo -e "  ${YELLOW}9)${NC} Back to Main Menu"
    echo ""
    print_separator
}

show_documentation_menu() {
    print_header
    echo -e "${WHITE}Documentation:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} View README"
    echo -e "  ${GREEN}2)${NC} View Deployment Guide"
    echo -e "  ${GREEN}3)${NC} View Security Guide"
    echo -e "  ${GREEN}4)${NC} View Development Guide"
    echo -e "  ${GREEN}5)${NC} View API Documentation (browser)"
    echo -e "  ${GREEN}6)${NC} List All Documentation Files"
    echo ""
    echo -e "  ${YELLOW}9)${NC} Back to Main Menu"
    echo ""
    print_separator
}

# Action Functions

validate_environment() {
    print_header
    echo -e "${WHITE}Validating Environment Configuration...${NC}"
    echo ""

    if [ -f "${DEPLOY_SCRIPTS}/validate-env.sh" ]; then
        bash "${DEPLOY_SCRIPTS}/validate-env.sh"
    else
        log_error "Validation script not found!"
    fi

    pause_for_input
}

view_configuration() {
    print_header
    echo -e "${WHITE}Current Configuration (sanitized):${NC}"
    echo ""

    if [ -f "${PROJECT_ROOT}/.env" ]; then
        # Show .env but sanitize sensitive values
        while IFS= read -r line; do
            if [[ $line =~ ^[[:space:]]*# ]] || [[ -z $line ]]; then
                echo "$line"
            elif [[ $line =~ ^([^=]+)=(.*)$ ]]; then
                key="${BASH_REMATCH[1]}"
                value="${BASH_REMATCH[2]}"

                # Sanitize sensitive values
                if [[ $key =~ (COOKIE|KEY|TOKEN|SECRET|PASSWORD) ]]; then
                    sanitized="${value:0:10}...${value: -4}"
                    echo -e "${GREEN}$key${NC}=${YELLOW}$sanitized${NC}"
                else
                    echo -e "${GREEN}$key${NC}=$value"
                fi
            fi
        done < "${PROJECT_ROOT}/.env"
    else
        log_error ".env file not found!"
    fi

    pause_for_input
}

edit_env_file() {
    print_header
    echo -e "${WHITE}Editing .env File...${NC}"
    echo ""

    if [ -f "${PROJECT_ROOT}/.env" ]; then
        ${EDITOR:-nano} "${PROJECT_ROOT}/.env"
        log_success ".env file edited"
    else
        log_error ".env file not found!"
        echo ""
        echo "Would you like to create it from .env.example? (y/n)"
        read -r response
        if [[ $response =~ ^[Yy]$ ]]; then
            create_env_from_example
        fi
    fi

    pause_for_input
}

create_env_from_example() {
    print_header
    echo -e "${WHITE}Creating .env from Example...${NC}"
    echo ""

    if [ -f "${PROJECT_ROOT}/.env.example" ]; then
        cp "${PROJECT_ROOT}/.env.example" "${PROJECT_ROOT}/.env"
        log_success ".env file created from example"
        echo ""
        log_warn "Please edit .env file with your credentials"
        echo ""
        echo "Open for editing now? (y/n)"
        read -r response
        if [[ $response =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} "${PROJECT_ROOT}/.env"
        fi
    else
        log_error ".env.example not found!"
    fi

    pause_for_input
}

test_environment_vars() {
    print_header
    echo -e "${WHITE}Testing Environment Variables...${NC}"
    echo ""

    source "${PROJECT_ROOT}/.env" 2>/dev/null || true

    echo "Testing required variables:"
    echo ""

    # Test SUNO_COOKIE
    if [ -n "$SUNO_COOKIE" ]; then
        log_success "SUNO_COOKIE is set (${#SUNO_COOKIE} characters)"
    else
        log_error "SUNO_COOKIE is not set"
    fi

    # Test TWOCAPTCHA_KEY
    if [ -n "$TWOCAPTCHA_KEY" ]; then
        log_success "TWOCAPTCHA_KEY is set (${#TWOCAPTCHA_KEY} characters)"
    else
        log_error "TWOCAPTCHA_KEY is not set"
    fi

    echo ""
    echo "Testing optional variables:"
    echo ""

    # Test optional vars
    [ -n "$UPSTASH_REDIS_REST_URL" ] && log_success "Redis URL configured" || log_warn "Redis URL not set"
    [ -n "$ALLOWED_ORIGINS" ] && log_success "ALLOWED_ORIGINS: $ALLOWED_ORIGINS" || log_warn "ALLOWED_ORIGINS not set"
    [ -n "$LOG_LEVEL" ] && log_success "LOG_LEVEL: $LOG_LEVEL" || log_warn "LOG_LEVEL not set (default: info)"

    pause_for_input
}

deploy_docker() {
    print_header
    echo -e "${WHITE}Deploying with Docker...${NC}"
    echo ""

    if [ -f "${DEPLOY_SCRIPTS}/deploy-docker.sh" ]; then
        bash "${DEPLOY_SCRIPTS}/deploy-docker.sh"
    else
        log_error "Docker deployment script not found!"
    fi

    pause_for_input
}

deploy_vps() {
    print_header
    echo -e "${WHITE}Deploying to VPS...${NC}"
    echo ""

    log_warn "This requires root privileges!"
    echo ""

    if [ -f "${DEPLOY_SCRIPTS}/deploy-vps.sh" ]; then
        sudo bash "${DEPLOY_SCRIPTS}/deploy-vps.sh"
    else
        log_error "VPS deployment script not found!"
    fi

    pause_for_input
}

deploy_vercel() {
    print_header
    echo -e "${WHITE}Deploying to Vercel...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"

    if command -v vercel &> /dev/null; then
        echo "Choose deployment type:"
        echo "  1) Production"
        echo "  2) Preview"
        echo ""
        read -p "Selection: " deploy_type

        case $deploy_type in
            1)
                vercel --prod
                ;;
            2)
                vercel
                ;;
            *)
                log_error "Invalid selection"
                ;;
        esac
    else
        log_error "Vercel CLI not installed!"
        echo ""
        echo "Install with: npm install -g vercel"
    fi

    pause_for_input
}

build_docker_image() {
    print_header
    echo -e "${WHITE}Building Docker Image...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"

    source .env 2>/dev/null || true

    docker build \
        --build-arg SUNO_COOKIE="${SUNO_COOKIE}" \
        -t suno-api:latest \
        -f Dockerfile \
        .

    if [ $? -eq 0 ]; then
        log_success "Docker image built successfully"
    else
        log_error "Docker image build failed"
    fi

    pause_for_input
}

git_pull() {
    print_header
    echo -e "${WHITE}Pulling Latest Code...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"

    git pull

    if [ $? -eq 0 ]; then
        log_success "Code updated successfully"
    else
        log_error "Git pull failed"
    fi

    pause_for_input
}

npm_install() {
    print_header
    echo -e "${WHITE}Installing Dependencies...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"

    npm install

    if [ $? -eq 0 ]; then
        log_success "Dependencies installed successfully"
    else
        log_error "npm install failed"
    fi

    pause_for_input
}

service_control() {
    local action=$1

    print_header
    echo -e "${WHITE}Service Control: ${action}${NC}"
    echo ""

    # Detect service type
    if docker ps -a | grep -q suno-api-prod; then
        # Docker service
        case $action in
            start)
                docker start suno-api-prod
                ;;
            stop)
                docker stop suno-api-prod
                ;;
            restart)
                docker restart suno-api-prod
                ;;
            status)
                docker ps -a | grep suno-api-prod
                ;;
        esac
    elif systemctl list-units --full -all | grep -q suno-api.service; then
        # Systemd service
        case $action in
            start)
                sudo systemctl start suno-api
                ;;
            stop)
                sudo systemctl stop suno-api
                ;;
            restart)
                sudo systemctl restart suno-api
                ;;
            status)
                sudo systemctl status suno-api
                ;;
            enable)
                sudo systemctl enable suno-api
                ;;
            disable)
                sudo systemctl disable suno-api
                ;;
        esac
    else
        log_error "No service found (neither Docker nor systemd)"
    fi

    pause_for_input
}

check_health() {
    print_header
    echo -e "${WHITE}Checking Service Health...${NC}"
    echo ""

    if [ -f "${DEPLOY_SCRIPTS}/health-check.sh" ]; then
        bash "${DEPLOY_SCRIPTS}/health-check.sh"
    else
        log_error "Health check script not found!"
    fi

    pause_for_input
}

monitor_health() {
    print_header
    echo -e "${WHITE}Starting Health Monitor...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""

    if [ -f "${DEPLOY_SCRIPTS}/health-check.sh" ]; then
        bash "${DEPLOY_SCRIPTS}/health-check.sh" monitor
    else
        log_error "Health check script not found!"
    fi

    pause_for_input
}

test_api_endpoints() {
    print_header
    echo -e "${WHITE}Testing API Endpoints...${NC}"
    echo ""

    API_URL="${API_URL:-http://localhost:3000}"

    echo "Testing: $API_URL"
    echo ""

    # Test health endpoint
    echo -e "${CYAN}1. Testing /api/health${NC}"
    if curl -f "$API_URL/api/health" &> /dev/null; then
        log_success "Health endpoint is accessible"
    else
        log_error "Health endpoint failed"
    fi

    echo ""

    # Test get_limit endpoint
    echo -e "${CYAN}2. Testing /api/get_limit${NC}"
    if curl -f "$API_URL/api/get_limit" &> /dev/null; then
        log_success "Get limit endpoint is accessible"
    else
        log_error "Get limit endpoint failed"
    fi

    pause_for_input
}

check_system_resources() {
    print_header
    echo -e "${WHITE}System Resources:${NC}"
    echo ""

    # CPU
    echo -e "${CYAN}CPU Usage:${NC}"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'

    echo ""

    # Memory
    echo -e "${CYAN}Memory Usage:${NC}"
    free -h

    echo ""

    # Disk
    echo -e "${CYAN}Disk Usage:${NC}"
    df -h | grep -E '^/dev/'

    echo ""

    # Docker (if running)
    if command -v docker &> /dev/null; then
        echo -e "${CYAN}Docker Resources:${NC}"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No running containers"
    fi

    pause_for_input
}

view_error_summary() {
    print_header
    echo -e "${WHITE}Error Summary:${NC}"
    echo ""

    # Check Docker logs
    if docker ps -a | grep -q suno-api-prod; then
        echo -e "${CYAN}Docker Errors (last 20):${NC}"
        docker logs suno-api-prod 2>&1 | grep -i error | tail -20
    fi

    echo ""

    # Check systemd logs
    if systemctl list-units --full -all | grep -q suno-api.service; then
        echo -e "${CYAN}Systemd Errors (last 20):${NC}"
        sudo journalctl -u suno-api | grep -i error | tail -20
    fi

    pause_for_input
}

view_logs() {
    local log_type=$1

    print_header
    echo -e "${WHITE}Viewing Logs: ${log_type}${NC}"
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
    echo ""

    case $log_type in
        docker-live)
            docker logs -f suno-api-prod
            ;;
        systemd-live)
            sudo journalctl -u suno-api -f
            ;;
        docker-50)
            docker logs --tail 50 suno-api-prod
            ;;
        docker-100)
            docker logs --tail 100 suno-api-prod
            ;;
        systemd-50)
            sudo journalctl -u suno-api -n 50
            ;;
        systemd-100)
            sudo journalctl -u suno-api -n 100
            ;;
    esac

    pause_for_input
}

search_logs_for_errors() {
    print_header
    echo -e "${WHITE}Searching Logs for Errors...${NC}"
    echo ""

    read -p "Enter search term (default: error): " search_term
    search_term=${search_term:-error}

    echo ""
    echo -e "${CYAN}Searching for: $search_term${NC}"
    echo ""

    if docker ps -a | grep -q suno-api-prod; then
        echo -e "${YELLOW}Docker Logs:${NC}"
        docker logs suno-api-prod 2>&1 | grep -i "$search_term" | tail -50
    elif systemctl list-units --full -all | grep -q suno-api.service; then
        echo -e "${YELLOW}Systemd Logs:${NC}"
        sudo journalctl -u suno-api | grep -i "$search_term" | tail -50
    fi

    pause_for_input
}

export_logs() {
    print_header
    echo -e "${WHITE}Exporting Logs...${NC}"
    echo ""

    timestamp=$(date +%Y%m%d_%H%M%S)
    output_file="${PROJECT_ROOT}/logs_export_${timestamp}.log"

    if docker ps -a | grep -q suno-api-prod; then
        docker logs suno-api-prod > "$output_file" 2>&1
    elif systemctl list-units --full -all | grep -q suno-api.service; then
        sudo journalctl -u suno-api > "$output_file"
    fi

    if [ -f "$output_file" ]; then
        log_success "Logs exported to: $output_file"
    else
        log_error "Failed to export logs"
    fi

    pause_for_input
}

run_tests() {
    print_header
    echo -e "${WHITE}Running Tests...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"
    npm test

    pause_for_input
}

build_application() {
    print_header
    echo -e "${WHITE}Building Application...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"
    npm run build

    if [ $? -eq 0 ]; then
        log_success "Build completed successfully"
    else
        log_error "Build failed"
    fi

    pause_for_input
}

clean_build() {
    print_header
    echo -e "${WHITE}Cleaning Build Artifacts...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"

    rm -rf .next
    rm -rf node_modules/.cache

    log_success "Build artifacts cleaned"

    pause_for_input
}

update_playwright() {
    print_header
    echo -e "${WHITE}Updating Playwright Browsers...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"
    npx playwright install chromium

    log_success "Playwright browsers updated"

    pause_for_input
}

check_for_updates() {
    print_header
    echo -e "${WHITE}Checking for Updates...${NC}"
    echo ""

    cd "${PROJECT_ROOT}"

    echo -e "${CYAN}Fetching latest changes...${NC}"
    git fetch

    echo ""
    echo -e "${CYAN}Current branch:${NC}"
    git branch --show-current

    echo ""
    echo -e "${CYAN}Status:${NC}"
    git status -sb

    echo ""
    echo -e "${CYAN}Available updates:${NC}"
    git log HEAD..@{u} --oneline || echo "Already up to date"

    pause_for_input
}

backup_configuration() {
    print_header
    echo -e "${WHITE}Backing Up Configuration...${NC}"
    echo ""

    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir="${PROJECT_ROOT}/backups"

    mkdir -p "$backup_dir"

    if [ -f "${PROJECT_ROOT}/.env" ]; then
        cp "${PROJECT_ROOT}/.env" "$backup_dir/.env.backup_${timestamp}"
        log_success "Configuration backed up to: $backup_dir/.env.backup_${timestamp}"
    else
        log_error ".env file not found"
    fi

    pause_for_input
}

show_system_info() {
    print_header
    echo -e "${WHITE}System Information:${NC}"
    echo ""

    echo -e "${CYAN}OS:${NC}"
    uname -a

    echo ""
    echo -e "${CYAN}Node.js:${NC}"
    node -v 2>/dev/null || echo "Not installed"

    echo ""
    echo -e "${CYAN}npm:${NC}"
    npm -v 2>/dev/null || echo "Not installed"

    echo ""
    echo -e "${CYAN}Docker:${NC}"
    docker -v 2>/dev/null || echo "Not installed"

    echo ""
    echo -e "${CYAN}Docker Compose:${NC}"
    docker compose version 2>/dev/null || docker-compose -v 2>/dev/null || echo "Not installed"

    echo ""
    echo -e "${CYAN}Git:${NC}"
    git --version 2>/dev/null || echo "Not installed"

    pause_for_input
}

view_documentation() {
    local doc_file=$1

    print_header

    if [ -f "${PROJECT_ROOT}/${doc_file}" ]; then
        less "${PROJECT_ROOT}/${doc_file}"
    else
        log_error "Documentation file not found: $doc_file"
        pause_for_input
    fi
}

open_api_docs() {
    print_header
    echo -e "${WHITE}Opening API Documentation...${NC}"
    echo ""

    API_URL="${API_URL:-http://localhost:3000}"
    DOCS_URL="${API_URL}/docs"

    log_info "Opening: $DOCS_URL"

    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "$DOCS_URL"
    elif command -v open &> /dev/null; then
        open "$DOCS_URL"
    else
        echo "Please open in your browser: $DOCS_URL"
    fi

    pause_for_input
}

list_documentation() {
    print_header
    echo -e "${WHITE}Available Documentation Files:${NC}"
    echo ""

    cd "${PROJECT_ROOT}"

    find . -maxdepth 2 -name "*.md" -not -path "./node_modules/*" | while read -r file; do
        echo -e "${GREEN}•${NC} $file"
    done

    pause_for_input
}

# Menu Navigation

handle_environment_menu() {
    while true; do
        show_environment_menu
        read -p "Select option: " choice

        case $choice in
            1) validate_environment ;;
            2) view_configuration ;;
            3) edit_env_file ;;
            4) create_env_from_example ;;
            5) test_environment_vars ;;
            9) break ;;
            *) log_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

handle_deployment_menu() {
    while true; do
        show_deployment_menu
        read -p "Select option: " choice

        case $choice in
            1) deploy_docker ;;
            2) deploy_vps ;;
            3) deploy_vercel ;;
            4) build_docker_image ;;
            5) git_pull ;;
            6) npm_install ;;
            9) break ;;
            *) log_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

handle_service_menu() {
    while true; do
        show_service_menu
        read -p "Select option: " choice

        case $choice in
            1) service_control "start" ;;
            2) service_control "stop" ;;
            3) service_control "restart" ;;
            4) service_control "status" ;;
            5) service_control "enable" ;;
            6) service_control "disable" ;;
            9) break ;;
            *) log_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

handle_monitoring_menu() {
    while true; do
        show_monitoring_menu
        read -p "Select option: " choice

        case $choice in
            1) check_health ;;
            2) monitor_health ;;
            3) test_api_endpoints ;;
            4) check_system_resources ;;
            5) view_error_summary ;;
            9) break ;;
            *) log_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

handle_logs_menu() {
    while true; do
        show_logs_menu
        read -p "Select option: " choice

        case $choice in
            1)
                if docker ps -a | grep -q suno-api-prod; then
                    view_logs "docker-live"
                else
                    log_error "Docker container not found"
                    pause_for_input
                fi
                ;;
            2)
                if systemctl list-units --full -all | grep -q suno-api.service; then
                    view_logs "systemd-live"
                else
                    log_error "Systemd service not found"
                    pause_for_input
                fi
                ;;
            3)
                if docker ps -a | grep -q suno-api-prod; then
                    view_logs "docker-50"
                else
                    view_logs "systemd-50"
                fi
                ;;
            4)
                if docker ps -a | grep -q suno-api-prod; then
                    view_logs "docker-100"
                else
                    view_logs "systemd-100"
                fi
                ;;
            5) search_logs_for_errors ;;
            6) export_logs ;;
            9) break ;;
            *) log_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

handle_utilities_menu() {
    while true; do
        show_utilities_menu
        read -p "Select option: " choice

        case $choice in
            1) run_tests ;;
            2) build_application ;;
            3) clean_build ;;
            4) update_playwright ;;
            5) check_for_updates ;;
            6) backup_configuration ;;
            7) show_system_info ;;
            9) break ;;
            *) log_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

handle_documentation_menu() {
    while true; do
        show_documentation_menu
        read -p "Select option: " choice

        case $choice in
            1) view_documentation "README.md" ;;
            2) view_documentation "DEPLOYMENT.md" ;;
            3) view_documentation "SECURITY.md" ;;
            4) view_documentation "DEVELOPMENT.md" ;;
            5) open_api_docs ;;
            6) list_documentation ;;
            9) break ;;
            *) log_error "Invalid option" ; sleep 1 ;;
        esac
    done
}

# Main Loop

main() {
    while $CONTINUE_MENU; do
        show_main_menu
        read -p "Select option: " choice

        case $choice in
            1) handle_environment_menu ;;
            2) handle_deployment_menu ;;
            3) handle_service_menu ;;
            4) handle_monitoring_menu ;;
            5) handle_logs_menu ;;
            6) handle_utilities_menu ;;
            7) handle_documentation_menu ;;
            0)
                clear_screen
                echo -e "${GREEN}Thank you for using Suno API Administrator Panel!${NC}"
                echo ""
                exit 0
                ;;
            *)
                log_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Run
main
