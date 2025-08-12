#!/bin/bash
# 🔧 SAST Integration Tester - Connection Validation Framework
# Tests all external integrations before deployment

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/ci-config.yaml"
TIMEOUT_SECONDS=30

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Usage function
show_help() {
    cat << EOF

╔══════════════════════════════════════════════════════════════╗
║           🔧 SAST INTEGRATION TESTER                        ║
║                                                              ║
║     Validate All External Connections Before Deployment     ║
║                                                              ║
║  Tests: Docker, Email, Slack, Jira, Grafana, GitHub        ║
║  Features: Health checks, Authentication, Connectivity      ║
╚══════════════════════════════════════════════════════════════╝

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -c, --config FILE       Configuration file (default: ci-config.yaml)
    -t, --test TYPE         Test specific integration type
    -a, --all              Test all integrations (default)
    -q, --quiet            Quiet mode with minimal output
    -v, --verbose          Verbose output with details
    -h, --help             Show this help

TEST TYPES:
    docker                 Docker and containerization
    email                  Email/SMTP connectivity
    slack                  Slack webhook integration
    jira                   Jira API connectivity
    grafana               Grafana API and dashboards
    github                GitHub API and authentication
    monitoring            Monitoring stack (Prometheus, InfluxDB)
    all                   Run all available tests

EXAMPLES:
    # Test all integrations
    $0 --all
    
    # Test specific integration
    $0 --test email
    
    # Quiet mode for CI/CD
    $0 --quiet
    
    # Verbose troubleshooting
    $0 --verbose

REQUIREMENTS:
    - Configuration file (ci-config.yaml)
    - Network connectivity
    - Valid API credentials (for external services)

EOF
}

# Parse command line arguments
QUIET=false
VERBOSE=false
TEST_TYPE="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -t|--test)
            TEST_TYPE="$2"
            shift 2
            ;;
        -a|--all)
            TEST_TYPE="all"
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Load configuration if available
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from: $CONFIG_FILE"
        
        # Parse YAML config (basic extraction)
        if command -v yq >/dev/null 2>&1; then
            # Use yq if available
            SLACK_WEBHOOK=$(yq eval '.notifications.slack.webhook_url // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
            EMAIL_SMTP_HOST=$(yq eval '.notifications.email.smtp_host // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
            EMAIL_SMTP_PORT=$(yq eval '.notifications.email.smtp_port // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
            JIRA_URL=$(yq eval '.integrations.jira.url // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
            GRAFANA_URL=$(yq eval '.integrations.grafana.url // ""' "$CONFIG_FILE" 2>/dev/null || echo "")
        else
            # Fallback to grep/sed parsing
            SLACK_WEBHOOK=$(grep -A 5 "slack:" "$CONFIG_FILE" | grep "webhook_url:" | sed 's/.*webhook_url: *\(.*\)/\1/' | tr -d '"' || echo "")
            EMAIL_SMTP_HOST=$(grep -A 10 "email:" "$CONFIG_FILE" | grep "smtp_host:" | sed 's/.*smtp_host: *\(.*\)/\1/' | tr -d '"' || echo "")
            EMAIL_SMTP_PORT=$(grep -A 10 "email:" "$CONFIG_FILE" | grep "smtp_port:" | sed 's/.*smtp_port: *\(.*\)/\1/' | tr -d '"' || echo "")
            JIRA_URL=$(grep -A 5 "jira:" "$CONFIG_FILE" | grep "url:" | sed 's/.*url: *\(.*\)/\1/' | tr -d '"' || echo "")
            GRAFANA_URL=$(grep -A 5 "grafana:" "$CONFIG_FILE" | grep "url:" | sed 's/.*url: *\(.*\)/\1/' | tr -d '"' || echo "")
        fi
        
        [[ $VERBOSE == true ]] && log_info "Configuration loaded successfully"
    else
        log_warning "Configuration file not found: $CONFIG_FILE"
        log_info "Using environment variables and defaults"
    fi
}

# Test Docker availability and functionality
test_docker() {
    log_step "Testing Docker integration..."
    
    # Check if Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed or not in PATH"
        FAILED_TESTS+=("docker-install")
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        FAILED_TESTS+=("docker-daemon")
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Test basic Docker functionality
    if docker run --rm hello-world >/dev/null 2>&1; then
        log_success "Docker is working correctly"
        ((TESTS_PASSED++))
    else
        log_error "Docker basic functionality test failed"
        FAILED_TESTS+=("docker-functionality")
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Check Docker Compose
    if command -v docker-compose >/dev/null 2>&1; then
        log_success "Docker Compose is available"
        ((TESTS_PASSED++))
    else
        log_warning "Docker Compose not found (using docker compose)"
        if docker compose version >/dev/null 2>&1; then
            log_success "Docker Compose v2 is available"
            ((TESTS_PASSED++))
        else
            log_error "No Docker Compose found"
            FAILED_TESTS+=("docker-compose")
            ((TESTS_FAILED++))
            return 1
        fi
    fi
    
    return 0
}

# Test email/SMTP connectivity
test_email() {
    log_step "Testing email/SMTP integration..."
    
    if [[ -z "${EMAIL_SMTP_HOST:-}" ]]; then
        log_warning "Email SMTP host not configured, skipping test"
        return 0
    fi
    
    # Test SMTP connectivity
    if command -v nc >/dev/null 2>&1; then
        local port="${EMAIL_SMTP_PORT:-587}"
        if timeout $TIMEOUT_SECONDS nc -z "$EMAIL_SMTP_HOST" "$port" 2>/dev/null; then
            log_success "SMTP connectivity to $EMAIL_SMTP_HOST:$port successful"
            ((TESTS_PASSED++))
        else
            log_error "Cannot connect to SMTP server $EMAIL_SMTP_HOST:$port"
            FAILED_TESTS+=("email-smtp")
            ((TESTS_FAILED++))
            return 1
        fi
    else
        log_warning "netcat (nc) not available, skipping SMTP connectivity test"
    fi
    
    return 0
}

# Test Slack webhook
test_slack() {
    log_step "Testing Slack webhook integration..."
    
    if [[ -z "${SLACK_WEBHOOK:-}" ]]; then
        log_warning "Slack webhook not configured, skipping test"
        return 0
    fi
    
    # Test webhook accessibility
    local test_payload='{"text":"SAST Integration Test - Please ignore"}'
    
    if command -v curl >/dev/null 2>&1; then
        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST \
            -H "Content-type: application/json" \
            --data "$test_payload" \
            --connect-timeout $TIMEOUT_SECONDS \
            "$SLACK_WEBHOOK" 2>/dev/null || echo "000")
        
        if [[ "$response" == "200" ]]; then
            log_success "Slack webhook connectivity successful"
            ((TESTS_PASSED++))
        else
            log_error "Slack webhook test failed (HTTP $response)"
            FAILED_TESTS+=("slack-webhook")
            ((TESTS_FAILED++))
            return 1
        fi
    else
        log_warning "curl not available, skipping Slack webhook test"
    fi
    
    return 0
}

# Test Jira API connectivity
test_jira() {
    log_step "Testing Jira API integration..."
    
    if [[ -z "${JIRA_URL:-}" ]]; then
        log_warning "Jira URL not configured, skipping test"
        return 0
    fi
    
    # Test Jira API accessibility
    if command -v curl >/dev/null 2>&1; then
        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout $TIMEOUT_SECONDS \
            "$JIRA_URL/rest/api/2/serverInfo" 2>/dev/null || echo "000")
        
        if [[ "$response" == "200" || "$response" == "401" ]]; then
            log_success "Jira API endpoint accessible"
            ((TESTS_PASSED++))
        else
            log_error "Jira API test failed (HTTP $response)"
            FAILED_TESTS+=("jira-api")
            ((TESTS_FAILED++))
            return 1
        fi
    else
        log_warning "curl not available, skipping Jira API test"
    fi
    
    return 0
}

# Test Grafana API connectivity
test_grafana() {
    log_step "Testing Grafana integration..."
    
    local grafana_url="${GRAFANA_URL:-http://localhost:3001}"
    
    # Test Grafana API accessibility
    if command -v curl >/dev/null 2>&1; then
        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout $TIMEOUT_SECONDS \
            "$grafana_url/api/health" 2>/dev/null || echo "000")
        
        if [[ "$response" == "200" ]]; then
            log_success "Grafana API accessible"
            ((TESTS_PASSED++))
        else
            log_warning "Grafana not accessible (HTTP $response) - may not be running"
            # Not counted as failure since Grafana might not be started yet
        fi
    else
        log_warning "curl not available, skipping Grafana test"
    fi
    
    return 0
}

# Test GitHub API connectivity
test_github() {
    log_step "Testing GitHub API integration..."
    
    # Test GitHub API accessibility
    if command -v curl >/dev/null 2>&1; then
        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout $TIMEOUT_SECONDS \
            "https://api.github.com/rate_limit" 2>/dev/null || echo "000")
        
        if [[ "$response" == "200" ]]; then
            log_success "GitHub API accessible"
            ((TESTS_PASSED++))
        else
            log_error "GitHub API test failed (HTTP $response)"
            FAILED_TESTS+=("github-api")
            ((TESTS_FAILED++))
            return 1
        fi
    else
        log_warning "curl not available, skipping GitHub API test"
    fi
    
    return 0
}

# Test monitoring stack
test_monitoring() {
    log_step "Testing monitoring stack integration..."
    
    # Test Prometheus
    if command -v curl >/dev/null 2>&1; then
        local prom_response
        prom_response=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout $TIMEOUT_SECONDS \
            "http://localhost:9090/-/healthy" 2>/dev/null || echo "000")
        
        if [[ "$prom_response" == "200" ]]; then
            log_success "Prometheus accessible"
            ((TESTS_PASSED++))
        else
            log_warning "Prometheus not accessible (HTTP $prom_response) - may not be running"
        fi
        
        # Test InfluxDB
        local influx_response
        influx_response=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout $TIMEOUT_SECONDS \
            "http://localhost:8087/health" 2>/dev/null || echo "000")
        
        if [[ "$influx_response" == "200" ]]; then
            log_success "InfluxDB accessible"
            ((TESTS_PASSED++))
        else
            log_warning "InfluxDB not accessible (HTTP $influx_response) - may not be running"
        fi
    else
        log_warning "curl not available, skipping monitoring stack tests"
    fi
    
    return 0
}

# Run all tests
run_all_tests() {
    log_info "Running comprehensive integration tests..."
    
    test_docker
    test_email
    test_slack
    test_jira
    test_grafana
    test_github
    test_monitoring
}

# Run specific test
run_specific_test() {
    local test_type="$1"
    
    case "$test_type" in
        docker)
            test_docker
            ;;
        email)
            test_email
            ;;
        slack)
            test_slack
            ;;
        jira)
            test_jira
            ;;
        grafana)
            test_grafana
            ;;
        github)
            test_github
            ;;
        monitoring)
            test_monitoring
            ;;
        *)
            log_error "Unknown test type: $test_type"
            log_info "Available tests: docker, email, slack, jira, grafana, github, monitoring, all"
            exit 1
            ;;
    esac
}

# Generate test report
generate_report() {
    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    INTEGRATION TEST REPORT                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
    
    echo "📊 Test Results Summary:"
    echo "  ✅ Tests Passed: $TESTS_PASSED"
    echo "  ❌ Tests Failed: $TESTS_FAILED"
    echo "  📈 Success Rate: $(( TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED + 1) ))%"
    echo
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "❌ Failed Tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  • $test"
        done
        echo
    fi
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 All critical integrations are working correctly!"
        echo "🚀 System is ready for deployment."
    else
        echo "⚠️  Some integrations need attention before deployment."
        echo "🔧 Please review failed tests and fix configurations."
    fi
    
    echo
    return $TESTS_FAILED
}

# Main execution
main() {
    if [[ $QUIET == false ]]; then
        echo
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║              🔧 SAST INTEGRATION TESTER                     ║"
        echo "║                                                              ║"
        echo "║     Validate All External Connections Before Deployment     ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo
    fi
    
    # Load configuration
    load_config
    
    # Run tests
    if [[ "$TEST_TYPE" == "all" ]]; then
        run_all_tests
    else
        run_specific_test "$TEST_TYPE"
    fi
    
    # Generate report
    if [[ $QUIET == false ]]; then
        generate_report
    fi
    
    exit $TESTS_FAILED
}

# Execute main function
main "$@"
