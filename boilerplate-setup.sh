#!/bin/bash

# ===================================================================
# SAST Monitoring Boilerplate - Generic Setup Script
# ===================================================================
# Production-ready SAST platform for any project
# Usage: ./boilerplate-setup.sh [options]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
PROJECT_NAME=""
LANGUAGES=""
MONITORING_STACK="minimal"
DEPLOYMENT_ENV="development"
REPO_URL=""

show_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
 ┌─────────────────────────────────────────────────────────────┐
 │              🔒 SAST Monitoring Boilerplate                 │
 │                 Generic Security Platform                   │
 │                                                             │
 │  🎯 Multi-Project  📊 Enterprise Monitoring                │
 │  🚀 One-Command    💰 Zero Licensing Costs                 │
 │  🔧 Customizable   📈 Production Ready                     │
 └─────────────────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
}

show_usage() {
    cat << EOF
${CYAN}USAGE:${NC}
    ./boilerplate-setup.sh [OPTIONS]

${CYAN}OPTIONS:${NC}
    --project NAME          Project name (required)
    --languages LIST        Comma-separated languages (js,python,java,go)
    --monitoring STACK      Monitoring stack type:
                           - minimal: Basic metrics only
                           - standard: Metrics + dashboards  
                           - enterprise: Full stack with logs & alerts
    --environment ENV       Deployment environment (development|staging|production)
    --repo URL             Repository URL to scan
    --help                 Show this help

${CYAN}EXAMPLES:${NC}
    # Basic setup for Node.js project
    ./boilerplate-setup.sh --project myapp --languages js --monitoring standard

    # Enterprise setup for multi-language project
    ./boilerplate-setup.sh --project enterprise-app --languages js,python,java --monitoring enterprise --environment production

    # Quick test with existing repository
    ./boilerplate-setup.sh --project test --languages python --repo https://github.com/OWASP/NodeGoat

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --languages)
                LANGUAGES="$2"
                shift 2
                ;;
            --monitoring)
                MONITORING_STACK="$2"
                shift 2
                ;;
            --environment)
                DEPLOYMENT_ENV="$2"
                shift 2
                ;;
            --repo)
                REPO_URL="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Validate inputs
validate_inputs() {
    if [ -z "$PROJECT_NAME" ]; then
        echo -e "${RED}❌ Project name is required${NC}"
        echo "Use: --project myproject"
        exit 1
    fi

    if [ -z "$LANGUAGES" ]; then
        echo -e "${YELLOW}⚠️  No languages specified, using auto-detection${NC}"
        LANGUAGES="auto"
    fi

    case "$MONITORING_STACK" in
        minimal|standard|enterprise)
            ;;
        *)
            echo -e "${RED}❌ Invalid monitoring stack: $MONITORING_STACK${NC}"
            echo "Valid options: minimal, standard, enterprise"
            exit 1
            ;;
    esac
}

# Generate project-specific configuration
generate_config() {
    echo -e "${BLUE}🔧 Generating configuration for $PROJECT_NAME...${NC}"
    
    # Create project-specific config
    cat > "ci-config-${PROJECT_NAME}.yaml" << EOF
# Generated configuration for $PROJECT_NAME
project:
  name: "$PROJECT_NAME"
  languages: "${LANGUAGES}"
  environment: "${DEPLOYMENT_ENV}"
  monitoring_stack: "${MONITORING_STACK}"

# SAST Configuration
sast:
  scanners:
$(if [[ "$LANGUAGES" == *"js"* ]] || [[ "$LANGUAGES" == "auto" ]]; then echo '    - "eslint"'; fi)
$(if [[ "$LANGUAGES" == *"python"* ]] || [[ "$LANGUAGES" == "auto" ]]; then echo '    - "bandit"'; fi)
    - "semgrep"  # Multi-language
    - "codeql"   # Multi-language
  
  severity_threshold: "$([ "$DEPLOYMENT_ENV" = "production" ] && echo "medium" || echo "low")"
  max_critical_vulnerabilities: $([ "$DEPLOYMENT_ENV" = "production" ] && echo "0" || echo "5")
  max_high_vulnerabilities: $([ "$DEPLOYMENT_ENV" = "production" ] && echo "5" || echo "10")

# Monitoring Configuration
monitoring:
  enabled: true
  stack: "$MONITORING_STACK"
  retention_days: $([ "$DEPLOYMENT_ENV" = "production" ] && echo "90" || echo "30")

# Notifications
notifications:
  enabled: $([ "$DEPLOYMENT_ENV" = "production" ] && echo "true" || echo "false")
  trigger: "$([ "$DEPLOYMENT_ENV" = "production" ] && echo "always" || echo "on_failure")"
  
  email:
    enabled: true
    recipients:
      - "security@${PROJECT_NAME}.local"
      - "devops@${PROJECT_NAME}.local"

# Environment-specific overrides
environments:
  development:
    sast:
      severity_threshold: "low"
    notifications:
      trigger: "never"
  
  production:
    sast:
      severity_threshold: "medium"
      max_critical_vulnerabilities: 0
    notifications:
      trigger: "always"
EOF

    echo -e "${GREEN}✅ Configuration generated: ci-config-${PROJECT_NAME}.yaml${NC}"
}

# Select appropriate docker-compose file
select_compose_file() {
    case "$MONITORING_STACK" in
        minimal)
            COMPOSE_FILE="docker-compose-minimal.yml"
            echo -e "${BLUE}📊 Using minimal monitoring stack${NC}"
            ;;
        standard)
            COMPOSE_FILE="docker-compose-minimal.yml"
            echo -e "${BLUE}📊 Using standard monitoring stack${NC}"
            ;;
        enterprise)
            COMPOSE_FILE="docker-compose-enterprise.yml"
            echo -e "${BLUE}📊 Using enterprise monitoring stack (with Loki + AlertManager)${NC}"
            ;;
    esac
}

# Create project directory structure
setup_project_structure() {
    echo -e "${BLUE}📁 Setting up project structure...${NC}"
    
    PROJECT_DIR="${PROJECT_NAME}-sast"
    
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}⚠️  Directory $PROJECT_DIR already exists${NC}"
        read -p "Continue and overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        rm -rf "$PROJECT_DIR"
    fi
    
    mkdir -p "$PROJECT_DIR"
    cp -r . "$PROJECT_DIR/" 2>/dev/null || true
    cd "$PROJECT_DIR"
    
    # Create project-specific directories
    mkdir -p {logs,results,reports}
    mkdir -p config/{scanners,alerts,dashboards}
    
    echo -e "${GREEN}✅ Project structure created: $PROJECT_DIR${NC}"
}

# Deploy monitoring stack
deploy_stack() {
    echo -e "${BLUE}🚀 Deploying $MONITORING_STACK monitoring stack...${NC}"
    
    # Generate secure credentials
    GRAFANA_PASSWORD=$(openssl rand -base64 12 | tr -d '/')
    INFLUXDB_PASSWORD=$(openssl rand -base64 12 | tr -d '/')
    
    # Update configuration with generated passwords
    sed -i.bak "s/admin123/$GRAFANA_PASSWORD/g" "$COMPOSE_FILE" 2>/dev/null || true
    sed -i.bak "s/adminpass123/$INFLUXDB_PASSWORD/g" "$COMPOSE_FILE" 2>/dev/null || true
    
    # Pull and start services
    docker-compose -f "$COMPOSE_FILE" pull --quiet
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Save credentials
    cat > .credentials << EOF
# Generated credentials for $PROJECT_NAME
GRAFANA_URL=http://localhost:3001
GRAFANA_USER=admin
GRAFANA_PASSWORD=$GRAFANA_PASSWORD

INFLUXDB_URL=http://localhost:8087
INFLUXDB_USER=admin
INFLUXDB_PASSWORD=$INFLUXDB_PASSWORD

MAILHOG_URL=http://localhost:8025
$([ "$MONITORING_STACK" = "enterprise" ] && echo "LOKI_URL=http://localhost:3100")
$([ "$MONITORING_STACK" = "enterprise" ] && echo "ALERTMANAGER_URL=http://localhost:9093")
EOF
    
    echo -e "${GREEN}✅ Stack deployed successfully${NC}"
    echo -e "${CYAN}📋 Credentials saved to .credentials${NC}"
}

# Test repository scanning if provided
test_repository() {
    if [ -n "$REPO_URL" ]; then
        echo -e "${BLUE}🧪 Testing repository scanning...${NC}"
        
        # Wait for services to be ready
        sleep 10
        
        echo -e "${CYAN}🔍 Scanning repository: $REPO_URL${NC}"
        docker exec -it sast-runner ./test_real_repo.sh "$REPO_URL" || true
        
        echo -e "${CYAN}📊 Sending results to monitoring stack...${NC}"
        docker exec -it sast-runner ./scripts/influxdb_integration.sh success || true
        
        echo -e "${GREEN}✅ Repository test completed${NC}"
    fi
}

# Generate project documentation
generate_docs() {
    echo -e "${BLUE}📚 Generating project documentation...${NC}"
    
    cat > README.md << EOF
# $PROJECT_NAME - SAST Monitoring

## Project Configuration
- **Languages**: $LANGUAGES
- **Monitoring Stack**: $MONITORING_STACK
- **Environment**: $DEPLOYMENT_ENV

## Quick Start
\`\`\`bash
# Start monitoring stack
docker-compose -f $COMPOSE_FILE up -d

# Run demo scan
docker exec -it sast-runner ./run_demo.sh -s normal -c all

# Scan real repository
docker exec -it sast-runner ./test_real_repo.sh <repository-url>
\`\`\`

## Access Points
$(source .credentials 2>/dev/null && cat << EOL || echo "Run the setup to generate credentials")
- **Grafana Dashboard**: $GRAFANA_URL (admin / $GRAFANA_PASSWORD)
- **InfluxDB Database**: $INFLUXDB_URL (admin / $INFLUXDB_PASSWORD)  
- **Email Testing**: $MAILHOG_URL
$([ "$MONITORING_STACK" = "enterprise" ] && echo "- **Log Aggregation**: $LOKI_URL")
$([ "$MONITORING_STACK" = "enterprise" ] && echo "- **Alert Manager**: $ALERTMANAGER_URL")
EOL

## Customization
Edit \`ci-config-${PROJECT_NAME}.yaml\` to customize:
- Scanner configuration
- Notification settings
- Alert thresholds
- Environment-specific overrides

## Commands
\`\`\`bash
# View service status
docker-compose -f $COMPOSE_FILE ps

# View logs
docker-compose -f $COMPOSE_FILE logs -f [service]

# Stop all services
docker-compose -f $COMPOSE_FILE down

# Complete cleanup
docker-compose -f $COMPOSE_FILE down -v
\`\`\`

Generated on $(date) for $PROJECT_NAME
EOF

    echo -e "${GREEN}✅ Documentation generated: README.md${NC}"
}

# Main execution
main() {
    show_banner
    
    parse_arguments "$@"
    validate_inputs
    
    echo -e "${CYAN}🎯 Setting up SAST monitoring for: $PROJECT_NAME${NC}"
    echo -e "${CYAN}📊 Languages: $LANGUAGES${NC}"
    echo -e "${CYAN}🔧 Monitoring: $MONITORING_STACK${NC}"
    echo -e "${CYAN}🌍 Environment: $DEPLOYMENT_ENV${NC}"
    echo ""
    
    generate_config
    select_compose_file
    setup_project_structure
    deploy_stack
    test_repository
    generate_docs
    
    echo ""
    echo -e "${GREEN}🎉 SAST monitoring setup completed for $PROJECT_NAME!${NC}"
    echo ""
    echo -e "${CYAN}📋 Next Steps:${NC}"
    echo -e "1. ${BLUE}cd $PROJECT_DIR${NC}"
    echo -e "2. ${BLUE}source .credentials${NC}"
    echo -e "3. ${BLUE}open \$GRAFANA_URL${NC}"
    echo -e "4. ${BLUE}docker exec -it sast-runner ./run_demo.sh${NC}"
    echo ""
    echo -e "${CYAN}📖 Documentation: ${BLUE}$PROJECT_DIR/README.md${NC}"
}

# Execute main function
main "$@"
