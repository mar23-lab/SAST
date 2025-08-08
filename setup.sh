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

DEPLOYMENT_MODE="${1:-demo}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    ./setup.sh [MODE]

${CYAN}MODES:${NC}
    --demo        Demo environment (default)
    --production  Production deployment
    --minimal     Minimal services only

${CYAN}EXAMPLES:${NC}
    ./setup.sh --demo        # Safe testing environment
    ./setup.sh --production  # Full production setup
    ./setup.sh --minimal     # Essential services only

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
    
    log_success "Prerequisites check completed"
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
    
    # Create InfluxDB dashboard if not exists
    log_info "Setting up Grafana dashboards..."
    sleep 5  # Give Grafana more time to fully initialize
    
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
    
    # Parse arguments
    if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
        show_usage
        exit 0
    fi
    
    DEPLOYMENT_MODE="${1:-demo}"
    
    # Show banner
    show_banner
    
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
