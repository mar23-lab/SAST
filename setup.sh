#!/bin/bash

# ===================================================================
# SAST Platform - Automated Setup Script
# ===================================================================
# One-command installation for complete SAST platform with monitoring
# Usage: ./setup.sh [--production|--demo|--minimal]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Default values
DEPLOYMENT_MODE="demo"
PROJECT_NAME=""
EMAIL=""
QUICK_MODE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --demo|--production|--minimal)
                DEPLOYMENT_MODE="${1#--}"
                shift
                ;;
            --quick)
                DEPLOYMENT_MODE="quick"
                QUICK_MODE=true
                shift
                ;;
            --project)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --email)
                EMAIL="$2"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Banner
show_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
 ┌─────────────────────────────────────────────────────────────┐
 │                   🔒 SAST Platform Setup                    │
 │              Enterprise Security Scanning                   │
 │                                                             │
 │  🔍 Multi-Scanner SAST  📊 Real-time Dashboards           │
 │  📧 Smart Notifications  🐳 Docker-Ready                   │
 │  🚀 Production-Ready     💰 Cost-Effective                 │
 └─────────────────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
}

# Usage information
show_usage() {
    cat << EOF
${CYAN}USAGE:${NC}
    ./setup.sh [MODE] [OPTIONS]

${CYAN}MODES:${NC}
    --demo        Demo environment (default)
    --production  Production deployment
    --minimal     Minimal services only
    --quick       Quick interactive setup for new projects

${CYAN}OPTIONS:${NC}
    --project NAME    Project name (for quick mode)
    --email EMAIL     Contact email (for quick mode)
    --help           Show this help

${CYAN}EXAMPLES:${NC}
    ./setup.sh --demo                                    # Safe testing environment
    ./setup.sh --production                              # Full production setup
    ./setup.sh --minimal                                 # Essential services only
    ./setup.sh --quick --project "MyApp" --email "me@company.com"  # Quick project setup

EOF
}

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${PURPLE}🔧 $1${NC}"; }

# Prerequisites check
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        missing_deps+=("docker")
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        missing_deps+=("docker-compose")
    fi
    
    # Check jq
    if ! command -v jq >/dev/null 2>&1; then
        log_warning "jq not found - installing..."
        if command -v brew >/dev/null 2>&1; then
            brew install jq >/dev/null 2>&1 || true
        else
            log_error "Please install jq manually"
            missing_deps+=("jq")
        fi
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install:"
        echo "- Docker: https://docs.docker.com/get-docker/"
        echo "- Docker Compose: https://docs.docker.com/compose/install/"
        echo "- jq: https://stedolan.github.io/jq/download/"
        exit 1
    fi
    
    # Check available ports
    local required_ports=(3001 8087 9090 9091 8025 1025)
    local busy_ports=()
    
    for port in "${required_ports[@]}"; do
        if lsof -i ":$port" >/dev/null 2>&1; then
            busy_ports+=("$port")
        fi
    done
    
    if [ ${#busy_ports[@]} -gt 0 ]; then
        log_warning "Ports in use: ${busy_ports[*]}"
        echo "Services will use alternative ports if needed"
    fi
    
    # Detect platform and set appropriate configuration
    detect_platform_configuration
    
    log_success "Prerequisites check completed"
}

# Platform detection and configuration selection
detect_platform_configuration() {
    log_step "Detecting platform configuration..."
    
    # Run platform validation script if available
    if [[ -f "scripts/platform-validation.sh" ]]; then
        log_info "Running automated platform compatibility check..."
        if bash scripts/platform-validation.sh >/dev/null 2>&1; then
            log_success "Platform validation passed"
        else
            log_warning "Platform validation found potential issues"
        fi
    fi
    
    local platform_arch=$(uname -m)
    case $platform_arch in
        arm64|aarch64)
            log_warning "ARM64/Apple Silicon detected"
            log_info "Using stable configuration for better compatibility"
            if [[ -f "docker-compose-stable.yml" ]]; then
                export COMPOSE_FILE="docker-compose-stable.yml"
                export DOCKER_DEFAULT_PLATFORM=linux/amd64
                log_success "Using: docker-compose-stable.yml"
                
                # Add environment variables to shell profile
                if ! grep -q "DOCKER_DEFAULT_PLATFORM" ~/.bashrc ~/.zshrc 2>/dev/null; then
                    echo "export DOCKER_DEFAULT_PLATFORM=linux/amd64" >> ~/.bashrc 2>/dev/null || true
                    echo "export DOCKER_DEFAULT_PLATFORM=linux/amd64" >> ~/.zshrc 2>/dev/null || true
                fi
            else
                log_warning "Stable compose file not found, using standard configuration"
                export COMPOSE_FILE="docker-compose.yml"
            fi
            ;;
        x86_64)
            log_success "x86_64 platform detected - using standard configuration"
            export COMPOSE_FILE="docker-compose.yml"
            ;;
        *)
            log_warning "Unknown architecture: $platform_arch - using standard configuration"
            export COMPOSE_FILE="docker-compose.yml"
            ;;
    esac
    
    log_info "Selected compose file: ${COMPOSE_FILE:-docker-compose.yml}"
}

# Generate secure configuration
generate_config() {
    log_step "Generating secure configuration..."
    
    # Generate secure passwords
    GRAFANA_PASSWORD=$(openssl rand -base64 16 | tr -d '/' | head -c 12)
    INFLUXDB_PASSWORD=$(openssl rand -base64 16 | tr -d '/' | head -c 12)
    INFLUXDB_TOKEN=$(openssl rand -hex 16)
    
    # Create environment file
    cat > .env << EOF
# Generated configuration for SAST Platform
DEPLOYMENT_MODE=$DEPLOYMENT_MODE
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Service Passwords
GRAFANA_ADMIN_PASSWORD=$GRAFANA_PASSWORD
INFLUXDB_ADMIN_PASSWORD=$INFLUXDB_PASSWORD
INFLUXDB_TOKEN=$INFLUXDB_TOKEN

# Service Ports
GRAFANA_PORT=3001
INFLUXDB_PORT=8087
PROMETHEUS_PORT=9090
PUSHGATEWAY_PORT=9091
MAILHOG_WEB_PORT=8025
MAILHOG_SMTP_PORT=1025
EOF
    
    log_success "Configuration generated"
}

# Select deployment compose file
select_compose_file() {
    case "$DEPLOYMENT_MODE" in
        --production)
            COMPOSE_FILE="docker-compose.yml"
            log_info "Using production configuration"
            ;;
        --minimal)
            COMPOSE_FILE="docker-compose-minimal.yml"
            log_info "Using minimal configuration"
            ;;
        --demo|*)
            COMPOSE_FILE="docker-compose-minimal.yml"
            DEPLOYMENT_MODE="demo"
            log_info "Using demo configuration"
            ;;
    esac
}

# Deploy services
deploy_services() {
    log_step "Deploying SAST platform services..."
    
    # Pull latest images
    log_info "Pulling Docker images..."
    docker-compose -f "$COMPOSE_FILE" pull --quiet
    
    # Start services
    log_info "Starting services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to initialize..."
    sleep 10
    
    # Check service health
    local services=("grafana" "influxdb" "prometheus" "sast-runner" "mailhog")
    local healthy_services=0
    
    for service in "${services[@]}"; do
        if docker ps --filter "name=sast-$service" --filter "status=running" --format "{{.Names}}" | grep -q "sast-$service"; then
            healthy_services=$((healthy_services + 1))
            log_success "$service is running"
        else
            log_warning "$service may need more time to start"
        fi
    done
    
    if [ $healthy_services -ge 4 ]; then
        log_success "Services deployed successfully ($healthy_services/5 running)"
    else
        log_warning "Some services may still be starting. Check with: docker-compose -f $COMPOSE_FILE ps"
    fi
}

# Initialize monitoring
setup_monitoring() {
    log_step "Setting up monitoring and dashboards..."
    
    # Wait for InfluxDB to be ready
    local retries=0
    while [ $retries -lt 30 ]; do
        if curl -s http://localhost:8087/health >/dev/null 2>&1; then
            log_success "InfluxDB is ready"
            break
        fi
        sleep 2
        retries=$((retries + 1))
    done
    
    # Wait for Grafana to be ready
    retries=0
    while [ $retries -lt 30 ]; do
        if curl -s http://localhost:3001/api/health >/dev/null 2>&1; then
            log_success "Grafana is ready"
            break
        fi
        sleep 2
        retries=$((retries + 1))
    done
    
    # Automated Grafana configuration
    log_info "Configuring Grafana dashboards automatically..."
    sleep 5  # Give Grafana more time to fully initialize
    
    # Run automated Grafana setup if script exists
    if [[ -f "scripts/grafana-auto-setup.sh" ]]; then
        log_info "Running automated Grafana configuration..."
        if bash scripts/grafana-auto-setup.sh; then
            log_success "Grafana configured automatically (vs 90-minute manual setup)"
        else
            log_warning "Automated Grafana setup failed - check logs"
            log_info "You can run it manually: ./scripts/grafana-auto-setup.sh"
        fi
    else
        log_warning "Grafana auto-setup script not found"
        log_info "Using manual dashboard configuration"
    fi
    
    log_success "Monitoring setup completed"
}

# Run demo test
run_demo_test() {
    if [ "$DEPLOYMENT_MODE" = "demo" ]; then
        log_step "Running demo test..."
        
        # Run demo scan
        docker exec sast-runner ./run_demo.sh -s normal -c all >/dev/null 2>&1 || true
        
        # Send metrics to monitoring
        docker exec sast-runner ./scripts/influxdb_integration.sh success >/dev/null 2>&1 || true
        
        log_success "Demo test completed"
    fi
}

# Generate access information
generate_access_info() {
    log_step "Generating access information..."
    
    # Read credentials from .env
    source .env
    
    cat > ACCESS_INFO.md << EOF
# 🎉 SAST Platform - Access Information

## 🌐 Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana Dashboards** | http://localhost:$GRAFANA_PORT | admin / $GRAFANA_ADMIN_PASSWORD |
| **InfluxDB Database** | http://localhost:$INFLUXDB_PORT | admin / $INFLUXDB_ADMIN_PASSWORD |
| **Prometheus Metrics** | http://localhost:$PROMETHEUS_PORT | No authentication |
| **Email Testing (MailHog)** | http://localhost:$MAILHOG_WEB_PORT | No authentication |

## 📊 Dashboards

### Primary InfluxDB Dashboard
- **URL**: http://localhost:$GRAFANA_PORT/d/bb0e2238-59f0-42ce-a4e7-1e1c0242f277/sast-security-dashboard-influxdb
- **Features**: Real-time vulnerability tracking, trend analysis

### Prometheus Dashboard  
- **URL**: http://localhost:$GRAFANA_PORT/d/sast-security-dashboard/sast-security-dashboard
- **Features**: Alerting, performance monitoring

## 🧪 Testing Commands

### Run Demo Scan
\`\`\`bash
docker exec -it sast-runner ./run_demo.sh -s critical -c all
\`\`\`

### Test Real Repository
\`\`\`bash
docker exec -it sast-runner ./test_real_repo.sh https://github.com/OWASP/NodeGoat
\`\`\`

### Send Test Metrics
\`\`\`bash
docker exec -it sast-runner ./scripts/influxdb_integration.sh success
\`\`\`

## 🔧 Management Commands

### Check Service Status
\`\`\`bash
docker-compose -f $COMPOSE_FILE ps
\`\`\`

### View Logs
\`\`\`bash
docker-compose -f $COMPOSE_FILE logs -f [service_name]
\`\`\`

### Stop Platform
\`\`\`bash
docker-compose -f $COMPOSE_FILE down
\`\`\`

### Complete Cleanup
\`\`\`bash
docker-compose -f $COMPOSE_FILE down -v
\`\`\`

## 📋 Next Steps

1. **Login to Grafana**: http://localhost:$GRAFANA_PORT
2. **Run a demo scan**: Use the commands above
3. **View results**: Check dashboards for vulnerability data
4. **Configure notifications**: Edit ci-config.yaml
5. **Test real repositories**: Use test_real_repo.sh script

---
Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Mode: $DEPLOYMENT_MODE
EOF
    
    log_success "Access information saved to ACCESS_INFO.md"
}

# Quick mode setup for new projects
setup_quick_mode() {
    log_step "Starting quick project setup..."
    
    # Get project info if not provided
    if [[ -z "$PROJECT_NAME" ]]; then
        DEFAULT_PROJECT_NAME=$(basename "$(pwd)")
        read -p "Project name [$DEFAULT_PROJECT_NAME]: " PROJECT_NAME
        PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}
    fi
    
    if [[ -z "$EMAIL" ]]; then
        read -p "Your email [user@example.com]: " EMAIL
        EMAIL=${EMAIL:-"user@example.com"}
    fi
    
    echo ""
    log_info "Configuration Summary:"
    echo "  Project: $PROJECT_NAME"
    echo "  Email: $EMAIL"
    echo "  Features: GitHub Actions, Dashboard, Notifications"
    echo ""
    
    read -p "Continue with setup? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_warning "Setup cancelled."
        exit 0
    fi
    
    # Create basic project structure
    log_step "Creating project structure..."
    mkdir -p .github/workflows
    
    # Generate customized configuration
    log_step "Generating configuration..."
    cp ci-config.yaml "${PROJECT_NAME}-config.yaml"
    
    # Update configuration with project details
    if command -v sed >/dev/null 2>&1; then
        sed -i.bak "s/CI-SAST-Boilerplate/$PROJECT_NAME/g" "${PROJECT_NAME}-config.yaml"
        sed -i.bak "s/devops@company.com/$EMAIL/g" "${PROJECT_NAME}-config.yaml"
        rm "${PROJECT_NAME}-config.yaml.bak" 2>/dev/null || true
    fi
    
    # Create basic GitHub Actions workflow
    cat > .github/workflows/sast-security-scan.yml << EOF
name: SAST Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  sast-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Run Security Scan
      uses: ./.github/workflows/sast-security-scan.yml
      env:
        PROJECT_NAME: $PROJECT_NAME
        CONTACT_EMAIL: $EMAIL
EOF

    log_success "Quick setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Commit the generated files:"
    echo "   git add ."
    echo "   git commit -m 'Add SAST security scanning'"
    echo ""
    echo "2. Push to enable GitHub Actions:"
    echo "   git push origin main"
    echo ""
    echo "3. Configure secrets in GitHub (optional):"
    echo "   - SLACK_WEBHOOK for Slack notifications"
    echo "   - EMAIL_SMTP_PASSWORD for email alerts"
    echo ""
    echo "4. Run full platform setup when ready:"
    echo "   ./setup.sh --demo"
}

# Cleanup function
cleanup_on_error() {
    log_error "Setup failed. Cleaning up..."
    docker-compose -f "$COMPOSE_FILE" down >/dev/null 2>&1 || true
    exit 1
}

# Main execution
main() {
    # Set error handler
    trap cleanup_on_error ERR
    
    # Parse command line arguments
    parse_args "$@"
    
    # Show banner
    show_banner
    
    # Handle quick mode separately
    if [[ "$QUICK_MODE" == "true" ]]; then
        setup_quick_mode
        return 0
    fi
    
    log_info "Starting SAST Platform setup in $DEPLOYMENT_MODE mode..."
    echo ""
    
    # Execute setup steps
    check_prerequisites
    generate_config
    select_compose_file
    deploy_services
    setup_monitoring
    run_demo_test
    generate_access_info
    
    echo ""
    echo -e "${GREEN}🎉 SAST Platform setup completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}📚 Quick Access:${NC}"
    
    # Read credentials for display
    source .env
    echo -e "  Grafana:  ${BLUE}http://localhost:$GRAFANA_PORT${NC} (admin / $GRAFANA_ADMIN_PASSWORD)"
    echo -e "  InfluxDB: ${BLUE}http://localhost:$INFLUXDB_PORT${NC} (admin / $INFLUXDB_ADMIN_PASSWORD)"
    echo -e "  MailHog:  ${BLUE}http://localhost:$MAILHOG_WEB_PORT${NC}"
    echo ""
    echo -e "${CYAN}📖 Documentation:${NC}"
    echo -e "  Full details: ${BLUE}ACCESS_INFO.md${NC}"
    echo -e "  Installation guide: ${BLUE}INSTALLATION_GUIDE.md${NC}"
    echo -e "  Comprehensive review: ${BLUE}COMPREHENSIVE_REVIEW.md${NC}"
    echo ""
    echo -e "${CYAN}🧪 Try Demo:${NC}"
    echo -e "  ${BLUE}docker exec -it sast-runner ./run_demo.sh -s critical -c all${NC}"
    echo ""
}

# Execute main function
main "$@"
