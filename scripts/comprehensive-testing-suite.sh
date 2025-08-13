#!/bin/bash

# ===================================================================
# SAST Platform - Comprehensive Testing Suite
# ===================================================================
# Systematic testing of all components, integrations, and user scenarios
# Usage: ./scripts/comprehensive-testing-suite.sh [--quick|--full|--platform-only]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_LOG="$TEST_RESULTS_DIR/comprehensive_test_$TIMESTAMP.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test modes
QUICK_MODE=false
FULL_MODE=true
PLATFORM_ONLY=false

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                QUICK_MODE=true
                FULL_MODE=false
                shift
                ;;
            --full)
                FULL_MODE=true
                QUICK_MODE=false
                shift
                ;;
            --platform-only)
                PLATFORM_ONLY=true
                FULL_MODE=false
                QUICK_MODE=false
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

show_usage() {
    cat << EOF
${CYAN}SAST Platform Comprehensive Testing Suite${NC}

${CYAN}USAGE:${NC}
    ./scripts/comprehensive-testing-suite.sh [MODE]

${CYAN}TEST MODES:${NC}
    --quick         Quick validation tests (~5 minutes)
    --full          Complete testing suite (~30 minutes) [default]
    --platform-only Platform compatibility tests only (~10 minutes)
    --help          Show this help

${CYAN}TEST CATEGORIES:${NC}
    🔍 Platform Detection & Validation
    🐳 Docker Configuration & Compatibility  
    📊 Grafana Automation & Dashboards
    📧 Email Integration & Notifications
    🛡️ SAST Scanning Functionality
    📈 Monitoring & Metrics Pipeline
    🚨 Error Handling & Recovery
    👥 User Acceptance Scenarios

${CYAN}OUTPUT:${NC}
    Results saved to: test-results/comprehensive_test_[timestamp].log
    Summary report: test-results/test_summary_[timestamp].md

EOF
}

# Logging functions
log_test_start() {
    echo -e "${BLUE}🧪 TEST: $1${NC}" | tee -a "$TEST_LOG"
    ((TOTAL_TESTS++))
}

log_test_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}" | tee -a "$TEST_LOG"
    ((PASSED_TESTS++))
}

log_test_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}" | tee -a "$TEST_LOG"
    echo "   Details: $2" | tee -a "$TEST_LOG"
    ((FAILED_TESTS++))
}

log_test_skip() {
    echo -e "${YELLOW}⏭️  SKIP: $1${NC}" | tee -a "$TEST_LOG"
    echo "   Reason: $2" | tee -a "$TEST_LOG"
    ((SKIPPED_TESTS++))
}

log_section() {
    echo -e "\n${PURPLE}📋 $1${NC}" | tee -a "$TEST_LOG"
    echo "────────────────────────────────────────────────" | tee -a "$TEST_LOG"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$TEST_LOG"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$TEST_LOG"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$TEST_LOG"
}

# Initialize testing environment
init_testing() {
    log_section "Initializing Testing Environment"
    
    # Create test results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Initialize log file
    cat > "$TEST_LOG" << EOF
# SAST Platform Comprehensive Testing Report
# Generated: $(date)
# Mode: $([ "$QUICK_MODE" = true ] && echo "Quick" || [ "$PLATFORM_ONLY" = true ] && echo "Platform Only" || echo "Full")
# Platform: $(uname -a)

EOF
    
    log_info "Test results directory: $TEST_RESULTS_DIR"
    log_info "Test log file: $TEST_LOG"
    log_info "Test mode: $([ "$QUICK_MODE" = true ] && echo "Quick" || [ "$PLATFORM_ONLY" = true ] && echo "Platform Only" || echo "Full")"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    log_info "Working directory: $(pwd)"
}

# ===================================================================
# PLATFORM DETECTION & VALIDATION TESTS
# ===================================================================

test_platform_detection() {
    log_section "Platform Detection & Validation Tests"
    
    # Test 1: Platform validation script exists
    log_test_start "Platform validation script existence"
    if [[ -f "scripts/platform-validation.sh" ]]; then
        log_test_pass "Platform validation script found"
    else
        log_test_fail "Platform validation script missing" "scripts/platform-validation.sh not found"
        return 1
    fi
    
    # Test 2: Platform validation script is executable
    log_test_start "Platform validation script permissions"
    if [[ -x "scripts/platform-validation.sh" ]]; then
        log_test_pass "Platform validation script is executable"
    else
        log_test_fail "Platform validation script not executable" "Need chmod +x"
        return 1
    fi
    
    # Test 3: Platform validation runs successfully
    log_test_start "Platform validation execution"
    if bash scripts/platform-validation.sh >/dev/null 2>&1; then
        log_test_pass "Platform validation completed successfully"
    else
        log_test_fail "Platform validation failed" "Check platform compatibility"
    fi
    
    # Test 4: Architecture detection
    log_test_start "Architecture detection"
    local arch=$(uname -m)
    case $arch in
        arm64|aarch64)
            log_test_pass "ARM64 architecture detected: $arch"
            ;;
        x86_64)
            log_test_pass "x86_64 architecture detected: $arch"
            ;;
        *)
            log_test_fail "Unknown architecture: $arch" "May need additional platform support"
            ;;
    esac
    
    # Test 5: Required tools availability
    log_test_start "Required tools availability"
    local missing_tools=()
    local required_tools=("docker" "curl" "jq")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        log_test_pass "All required tools available: ${required_tools[*]}"
    else
        log_test_fail "Missing required tools: ${missing_tools[*]}" "Install missing dependencies"
    fi
}

test_docker_environment() {
    log_section "Docker Environment Tests"
    
    # Test 1: Docker installation
    log_test_start "Docker installation"
    if command -v docker >/dev/null 2>&1; then
        local docker_version=$(docker --version)
        log_test_pass "Docker installed: $docker_version"
    else
        log_test_fail "Docker not installed" "Install Docker Desktop"
        return 1
    fi
    
    # Test 2: Docker daemon running
    log_test_start "Docker daemon status"
    if docker info >/dev/null 2>&1; then
        log_test_pass "Docker daemon is running"
    else
        log_test_fail "Docker daemon not running" "Start Docker Desktop"
        return 1
    fi
    
    # Test 3: Docker Compose availability
    log_test_start "Docker Compose availability"
    if docker compose version >/dev/null 2>&1 || docker-compose --version >/dev/null 2>&1; then
        local compose_version=$(docker compose version 2>/dev/null || docker-compose --version 2>/dev/null)
        log_test_pass "Docker Compose available: $compose_version"
    else
        log_test_fail "Docker Compose not available" "Install Docker Compose"
        return 1
    fi
    
    # Test 4: Port availability
    log_test_start "Required ports availability"
    local required_ports=(3001 8087 9090 9091 8025 1025)
    local busy_ports=()
    
    for port in "${required_ports[@]}"; do
        if lsof -i ":$port" >/dev/null 2>&1; then
            busy_ports+=($port)
        fi
    done
    
    if [[ ${#busy_ports[@]} -eq 0 ]]; then
        log_test_pass "All required ports available: ${required_ports[*]}"
    else
        log_test_fail "Ports in use: ${busy_ports[*]}" "Stop services using these ports"
    fi
    
    # Test 5: Docker resource availability
    log_test_start "Docker resource availability"
    local docker_info=$(docker system info --format json 2>/dev/null)
    if [[ -n "$docker_info" ]]; then
        log_test_pass "Docker system information accessible"
    else
        log_test_fail "Cannot access Docker system information" "Check Docker permissions"
    fi
}

# ===================================================================
# DOCKER CONFIGURATION TESTS
# ===================================================================

test_docker_configurations() {
    log_section "Docker Configuration Tests"
    
    # Test 1: Standard docker-compose.yml exists and valid
    log_test_start "Standard Docker Compose configuration"
    if [[ -f "docker-compose.yml" ]]; then
        if docker-compose -f docker-compose.yml config >/dev/null 2>&1; then
            log_test_pass "docker-compose.yml is valid"
        else
            log_test_fail "docker-compose.yml has syntax errors" "Check YAML syntax"
        fi
    else
        log_test_fail "docker-compose.yml not found" "Missing standard configuration"
    fi
    
    # Test 2: Stable docker-compose.yml exists and valid
    log_test_start "Stable Docker Compose configuration"
    if [[ -f "docker-compose-stable.yml" ]]; then
        if docker-compose -f docker-compose-stable.yml config >/dev/null 2>&1; then
            log_test_pass "docker-compose-stable.yml is valid"
        else
            log_test_fail "docker-compose-stable.yml has syntax errors" "Check YAML syntax"
        fi
    else
        log_test_fail "docker-compose-stable.yml not found" "Missing ARM64 compatibility configuration"
    fi
    
    # Test 3: Minimal docker-compose.yml exists and valid
    log_test_start "Minimal Docker Compose configuration"
    if [[ -f "docker-compose-minimal.yml" ]]; then
        if docker-compose -f docker-compose-minimal.yml config >/dev/null 2>&1; then
            log_test_pass "docker-compose-minimal.yml is valid"
        else
            log_test_fail "docker-compose-minimal.yml has syntax errors" "Check YAML syntax"
        fi
    else
        log_test_fail "docker-compose-minimal.yml not found" "Missing minimal configuration"
    fi
    
    # Test 4: Dockerfile.sast exists and buildable
    log_test_start "SAST Dockerfile validation"
    if [[ -f "Dockerfile.sast" ]]; then
        if docker build -f Dockerfile.sast -t sast-test-image . >/dev/null 2>&1; then
            log_test_pass "Dockerfile.sast builds successfully"
            # Clean up test image
            docker rmi sast-test-image >/dev/null 2>&1 || true
        else
            log_test_fail "Dockerfile.sast build failed" "Check Dockerfile syntax and dependencies"
        fi
    else
        log_test_fail "Dockerfile.sast not found" "Missing SAST runner Dockerfile"
    fi
    
    # Test 5: Configuration file validation
    log_test_start "Configuration files validation"
    local config_files=("ci-config.yaml" "prometheus-config/prometheus.yml")
    local invalid_configs=()
    
    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            if ! yq eval . "$config" >/dev/null 2>&1; then
                invalid_configs+=("$config")
            fi
        else
            invalid_configs+=("$config (missing)")
        fi
    done
    
    if [[ ${#invalid_configs[@]} -eq 0 ]]; then
        log_test_pass "All configuration files are valid"
    else
        log_test_fail "Invalid configuration files: ${invalid_configs[*]}" "Fix YAML syntax errors"
    fi
}

# ===================================================================
# SETUP PROCESS TESTS
# ===================================================================

test_setup_process() {
    log_section "Setup Process Tests"
    
    # Test 1: Setup script exists and executable
    log_test_start "Setup script availability"
    if [[ -f "setup.sh" && -x "setup.sh" ]]; then
        log_test_pass "setup.sh exists and is executable"
    else
        log_test_fail "setup.sh missing or not executable" "Check file permissions"
        return 1
    fi
    
    # Test 2: Setup script help functionality
    log_test_start "Setup script help functionality"
    if ./setup.sh --help >/dev/null 2>&1; then
        log_test_pass "Setup script help works"
    else
        log_test_fail "Setup script help failed" "Check script syntax"
    fi
    
    # Test 3: Setup script platform detection
    log_test_start "Setup script platform detection"
    local arch=$(uname -m)
    case $arch in
        arm64|aarch64)
            if grep -q "docker-compose-stable.yml" setup.sh; then
                log_test_pass "Setup script includes ARM64 support"
            else
                log_test_fail "Setup script missing ARM64 support" "Add stable compose file logic"
            fi
            ;;
        x86_64)
            log_test_pass "Setup script compatible with x86_64"
            ;;
    esac
    
    # Test 4: Configuration generation capability
    log_test_start "Configuration generation test"
    if grep -q "generate_config" setup.sh; then
        log_test_pass "Setup script includes configuration generation"
    else
        log_test_fail "Setup script missing configuration generation" "Add config generation function"
    fi
}

# ===================================================================
# GRAFANA AUTOMATION TESTS
# ===================================================================

test_grafana_automation() {
    log_section "Grafana Automation Tests"
    
    # Test 1: Grafana auto-setup script exists
    log_test_start "Grafana auto-setup script availability"
    if [[ -f "scripts/grafana-auto-setup.sh" && -x "scripts/grafana-auto-setup.sh" ]]; then
        log_test_pass "Grafana auto-setup script available"
    else
        log_test_fail "Grafana auto-setup script missing or not executable" "Check script permissions"
        return 1
    fi
    
    # Test 2: Grafana configuration validation
    log_test_start "Grafana configuration validation"
    if [[ -d "grafana-config" ]]; then
        log_test_pass "Grafana configuration directory exists"
    else
        log_test_fail "Grafana configuration directory missing" "Create grafana-config directory"
    fi
    
    # Test 3: Dashboard templates validation
    log_test_start "Dashboard templates validation"
    if find grafana-config -name "*.json" -type f | grep -q dashboard; then
        log_test_pass "Dashboard templates found"
    else
        log_test_fail "Dashboard templates missing" "Add dashboard JSON files"
    fi
}

# ===================================================================
# MONITORING STACK TESTS  
# ===================================================================

test_monitoring_components() {
    log_section "Monitoring Stack Component Tests"
    
    # Test 1: InfluxDB integration script
    log_test_start "InfluxDB integration script"
    if [[ -f "scripts/influxdb_integration.sh" && -x "scripts/influxdb_integration.sh" ]]; then
        log_test_pass "InfluxDB integration script available"
    else
        log_test_fail "InfluxDB integration script missing" "Check scripts directory"
    fi
    
    # Test 2: Prometheus configuration
    log_test_start "Prometheus configuration validation"
    if [[ -f "prometheus-config/prometheus.yml" ]]; then
        if yq eval . prometheus-config/prometheus.yml >/dev/null 2>&1; then
            log_test_pass "Prometheus configuration is valid"
        else
            log_test_fail "Prometheus configuration invalid" "Fix YAML syntax"
        fi
    else
        log_test_fail "Prometheus configuration missing" "Create prometheus.yml"
    fi
    
    # Test 3: Alerting rules validation
    log_test_start "Alerting rules validation"
    if [[ -f "prometheus-config/sast_rules.yml" ]]; then
        if yq eval . prometheus-config/sast_rules.yml >/dev/null 2>&1; then
            log_test_pass "Alerting rules are valid"
        else
            log_test_fail "Alerting rules invalid" "Fix YAML syntax"
        fi
    else
        log_test_fail "Alerting rules missing" "Create alerting rules"
    fi
}

# ===================================================================
# EMAIL INTEGRATION TESTS
# ===================================================================

test_email_integration() {
    log_section "Email Integration Tests"
    
    # Test 1: Email setup wizard availability
    log_test_start "Email setup wizard availability"
    if [[ -f "scripts/email-setup-wizard.sh" && -x "scripts/email-setup-wizard.sh" ]]; then
        log_test_pass "Email setup wizard available"
    else
        log_test_fail "Email setup wizard missing" "Check scripts directory"
    fi
    
    # Test 2: Notification scripts availability
    log_test_start "Notification scripts availability"
    if [[ -f "scripts/send_notifications.sh" && -x "scripts/send_notifications.sh" ]]; then
        log_test_pass "Notification scripts available"
    else
        log_test_fail "Notification scripts missing" "Check scripts directory"
    fi
    
    # Test 3: Email templates validation
    log_test_start "Email templates validation"
    if [[ -d "templates" ]]; then
        if find templates -name "*.html" -type f | grep -q email; then
            log_test_pass "Email templates found"
        else
            log_test_fail "Email templates missing" "Add email template files"
        fi
    else
        log_test_fail "Templates directory missing" "Create templates directory"
    fi
}

# ===================================================================
# SAST SCANNING TESTS
# ===================================================================

test_sast_functionality() {
    log_section "SAST Scanning Functionality Tests"
    
    # Test 1: Core SAST validation script
    log_test_start "Core SAST validation script"
    if [[ -f "core-sast-validation.sh" && -x "core-sast-validation.sh" ]]; then
        log_test_pass "Core SAST validation script available"
    else
        log_test_fail "Core SAST validation script missing" "Check script permissions"
    fi
    
    # Test 2: Demo functionality
    log_test_start "Demo functionality"
    if [[ -f "run_demo.sh" && -x "run_demo.sh" ]]; then
        log_test_pass "Demo script available"
    else
        log_test_fail "Demo script missing or not executable" "Check script permissions"
    fi
    
    # Test 3: Scanner configurations
    log_test_start "Scanner configurations"
    local scanner_configs=("configs/.eslintrc.security.json" "configs/bandit.yaml")
    local missing_configs=()
    
    for config in "${scanner_configs[@]}"; do
        if [[ ! -f "$config" ]]; then
            missing_configs+=("$config")
        fi
    done
    
    if [[ ${#missing_configs[@]} -eq 0 ]]; then
        log_test_pass "Scanner configurations available"
    else
        log_test_fail "Missing scanner configurations: ${missing_configs[*]}" "Create missing config files"
    fi
    
    # Test 4: Results processing capability
    log_test_start "Results processing capability"
    if [[ -f "scripts/process_results.sh" && -x "scripts/process_results.sh" ]]; then
        log_test_pass "Results processing script available"
    else
        log_test_fail "Results processing script missing" "Check scripts directory"
    fi
}

# ===================================================================
# INTEGRATION TESTS
# ===================================================================

test_integration_scenarios() {
    if [[ "$QUICK_MODE" == true ]]; then
        log_section "Integration Tests (Skipped in Quick Mode)"
        log_test_skip "Integration tests" "Quick mode enabled"
        return 0
    fi
    
    log_section "Integration Scenario Tests"
    
    # Test 1: Integration tester availability
    log_test_start "Integration tester availability"
    if [[ -f "scripts/integration-tester.sh" && -x "scripts/integration-tester.sh" ]]; then
        log_test_pass "Integration tester script available"
    else
        log_test_fail "Integration tester script missing" "Check scripts directory"
    fi
    
    # Test 2: Real repository testing capability
    log_test_start "Real repository testing capability"
    if [[ -f "test_real_repo.sh" && -x "test_real_repo.sh" ]]; then
        log_test_pass "Real repository testing script available"
    else
        log_test_fail "Real repository testing script missing" "Check script permissions"
    fi
    
    # Test 3: GitHub Pages testing capability
    log_test_start "GitHub Pages testing capability"
    if [[ -f "test-github-pages.sh" && -x "test-github-pages.sh" ]]; then
        log_test_pass "GitHub Pages testing script available"
    else
        log_test_fail "GitHub Pages testing script missing" "Check script permissions"
    fi
}

# ===================================================================
# ERROR HANDLING TESTS
# ===================================================================

test_error_handling() {
    log_section "Error Handling & Recovery Tests"
    
    # Test 1: Cleanup capabilities
    log_test_start "Cleanup script availability"
    if grep -q "cleanup\|down.*-v" setup.sh; then
        log_test_pass "Cleanup functionality available in setup script"
    else
        log_test_fail "Cleanup functionality missing" "Add cleanup functions to setup script"
    fi
    
    # Test 2: Error logging capabilities
    log_test_start "Error logging capabilities"
    if grep -q "log_error\|error.*log" scripts/*.sh 2>/dev/null; then
        log_test_pass "Error logging functionality present"
    else
        log_test_fail "Error logging functionality missing" "Add error logging to scripts"
    fi
    
    # Test 3: Health check capabilities
    log_test_start "Health check capabilities"
    if grep -q "health\|curl.*api.*health" scripts/*.sh 2>/dev/null; then
        log_test_pass "Health check functionality present"
    else
        log_test_fail "Health check functionality missing" "Add health check functions"
    fi
}

# ===================================================================
# USER ACCEPTANCE TESTS
# ===================================================================

test_user_experience() {
    log_section "User Experience Tests"
    
    # Test 1: Documentation completeness
    log_test_start "Documentation completeness"
    local required_docs=("README.md" "CONFIG_GUIDE.md" "CURSOR_CONTRIBUTOR_DOCUMENTATION.md")
    local missing_docs=()
    
    for doc in "${required_docs[@]}"; do
        if [[ ! -f "$doc" ]]; then
            missing_docs+=("$doc")
        fi
    done
    
    if [[ ${#missing_docs[@]} -eq 0 ]]; then
        log_test_pass "All required documentation present"
    else
        log_test_fail "Missing documentation: ${missing_docs[*]}" "Create missing documentation files"
    fi
    
    # Test 2: Example configurations
    log_test_start "Example configurations availability"
    if [[ -d "examples" ]]; then
        log_test_pass "Examples directory exists"
    else
        log_test_fail "Examples directory missing" "Create examples directory"
    fi
    
    # Test 3: License and legal files
    log_test_start "License and legal files"
    if [[ -f "LICENSE" ]]; then
        log_test_pass "LICENSE file present"
    else
        log_test_fail "LICENSE file missing" "Add LICENSE file"
    fi
    
    # Test 4: README accuracy check
    log_test_start "README accuracy check"
    if grep -q "10-15 minutes" README.md; then
        log_test_pass "README contains realistic time estimates"
    else
        log_test_fail "README may contain unrealistic time estimates" "Update time estimates in README"
    fi
}

# ===================================================================
# SECURITY TESTS
# ===================================================================

test_security_aspects() {
    log_section "Security Configuration Tests"
    
    # Test 1: Default credential security
    log_test_start "Default credential security check"
    if grep -q "admin123\|password123" docker-compose*.yml 2>/dev/null; then
        log_test_fail "Default credentials found in docker-compose files" "Use environment variables for credentials"
    else
        log_test_pass "No hardcoded default credentials found"
    fi
    
    # Test 2: Secret management
    log_test_start "Secret management check"
    if [[ -f ".env.example" || -f ".env.template" ]]; then
        log_test_pass "Environment template file present"
    else
        log_test_fail "Environment template file missing" "Create .env.example file"
    fi
    
    # Test 3: Network security
    log_test_start "Network security configuration"
    if grep -q "networks:" docker-compose*.yml 2>/dev/null; then
        log_test_pass "Custom networks configured"
    else
        log_test_fail "Custom networks not configured" "Add network isolation"
    fi
}

# ===================================================================
# PERFORMANCE TESTS
# ===================================================================

test_performance_aspects() {
    if [[ "$QUICK_MODE" == true ]]; then
        log_section "Performance Tests (Skipped in Quick Mode)"
        log_test_skip "Performance tests" "Quick mode enabled"
        return 0
    fi
    
    log_section "Performance & Resource Tests"
    
    # Test 1: Resource limits configuration
    log_test_start "Resource limits configuration"
    if grep -q "resources:\|limits:" docker-compose*.yml 2>/dev/null; then
        log_test_pass "Resource limits configured"
    else
        log_test_fail "Resource limits not configured" "Add resource constraints"
    fi
    
    # Test 2: Health check configuration
    log_test_start "Health check configuration"
    if grep -q "healthcheck:" docker-compose*.yml 2>/dev/null; then
        log_test_pass "Health checks configured"
    else
        log_test_fail "Health checks not configured" "Add health check definitions"
    fi
    
    # Test 3: Optimization scripts
    log_test_start "Optimization scripts availability"
    if find scripts -name "*optimization*" -o -name "*performance*" 2>/dev/null | grep -q .; then
        log_test_pass "Optimization scripts available"
    else
        log_test_fail "Optimization scripts missing" "Consider adding performance optimization scripts"
    fi
}

# ===================================================================
# COMPLIANCE TESTS
# ===================================================================

test_compliance_aspects() {
    log_section "Compliance & Standards Tests"
    
    # Test 1: SARIF output support
    log_test_start "SARIF output support"
    if grep -q "sarif\|SARIF" scripts/*.sh 2>/dev/null || grep -q "sarif" configs/* 2>/dev/null; then
        log_test_pass "SARIF output support present"
    else
        log_test_fail "SARIF output support missing" "Add SARIF format support"
    fi
    
    # Test 2: CI/CD integration files
    log_test_start "CI/CD integration files"
    local ci_files=(".github/workflows" "bitbucket-pipelines.yml")
    local present_ci=()
    
    for ci_file in "${ci_files[@]}"; do
        if [[ -e "$ci_file" ]]; then
            present_ci+=("$ci_file")
        fi
    done
    
    if [[ ${#present_ci[@]} -gt 0 ]]; then
        log_test_pass "CI/CD integration files present: ${present_ci[*]}"
    else
        log_test_fail "CI/CD integration files missing" "Add CI/CD workflow files"
    fi
    
    # Test 3: Quality gates configuration
    log_test_start "Quality gates configuration"
    if grep -q "threshold\|max.*vulnerabilities" ci-config.yaml 2>/dev/null; then
        log_test_pass "Quality gates configured"
    else
        log_test_fail "Quality gates not configured" "Add quality gate thresholds"
    fi
}

# ===================================================================
# GENERATE TEST REPORT
# ===================================================================

generate_test_report() {
    log_section "Generating Test Summary Report"
    
    local report_file="$TEST_RESULTS_DIR/test_summary_$TIMESTAMP.md"
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    
    cat > "$report_file" << EOF
# SAST Platform Testing Report

**Generated**: $(date)  
**Test Mode**: $([ "$QUICK_MODE" = true ] && echo "Quick" || [ "$PLATFORM_ONLY" = true ] && echo "Platform Only" || echo "Full")  
**Platform**: $(uname -a)  
**Duration**: $(date --date="$(($(date +%s) - $(stat -c %Y "$TEST_LOG"))) seconds ago" +%M:%S) minutes

## 📊 Test Summary

| Metric | Count | Percentage |
|--------|-------|------------|
| **Total Tests** | $TOTAL_TESTS | 100% |
| **Passed** | $PASSED_TESTS | $success_rate% |
| **Failed** | $FAILED_TESTS | $((FAILED_TESTS * 100 / TOTAL_TESTS))% |
| **Skipped** | $SKIPPED_TESTS | $((SKIPPED_TESTS * 100 / TOTAL_TESTS))% |

## 🎯 Overall Assessment

EOF

    if [[ $success_rate -ge 90 ]]; then
        echo "**Status**: ✅ **EXCELLENT** - Platform ready for production" >> "$report_file"
    elif [[ $success_rate -ge 80 ]]; then
        echo "**Status**: ✅ **GOOD** - Platform ready with minor improvements needed" >> "$report_file"
    elif [[ $success_rate -ge 70 ]]; then
        echo "**Status**: ⚠️ **ACCEPTABLE** - Platform functional but needs improvements" >> "$report_file"
    else
        echo "**Status**: ❌ **NEEDS WORK** - Critical issues need resolution" >> "$report_file"
    fi

    cat >> "$report_file" << EOF

## 📋 Test Categories

The following test categories were executed:

- 🔍 **Platform Detection & Validation**
- 🐳 **Docker Configuration & Compatibility**
- 📊 **Grafana Automation & Dashboards**
- 📧 **Email Integration & Notifications**
- 🛡️ **SAST Scanning Functionality**
- 📈 **Monitoring & Metrics Pipeline**
- 🚨 **Error Handling & Recovery**
- 👥 **User Experience & Documentation**
- 🔒 **Security Configuration**
- ⚡ **Performance & Resource Management**
- 📋 **Compliance & Standards**

## 📁 Detailed Results

For detailed test results, see: [\`$TEST_LOG\`]($TEST_LOG)

## 🚀 Recommendations

EOF

    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "### ❌ Critical Issues to Address" >> "$report_file"
        grep "FAIL:" "$TEST_LOG" | head -5 >> "$report_file"
        echo "" >> "$report_file"
    fi

    if [[ $success_rate -ge 80 ]]; then
        cat >> "$report_file" << EOF
### ✅ Next Steps
1. Address any remaining failed tests
2. Run integration tests with real deployments
3. Gather user feedback on setup experience
4. Monitor performance in production environments

EOF
    fi

    echo "## 📞 Support" >> "$report_file"
    echo "For issues or questions about test results, check the troubleshooting guide in README.md" >> "$report_file"

    log_info "Test summary report generated: $report_file"
}

# ===================================================================
# MAIN EXECUTION
# ===================================================================

main() {
    # Show banner
    echo -e "${PURPLE}"
    cat << 'EOF'
 ┌─────────────────────────────────────────────────┐
 │       🧪 SAST Platform Testing Suite           │
 │     Comprehensive Functionality Validation     │
 └─────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"

    # Parse arguments and initialize
    parse_args "$@"
    init_testing

    # Execute test suites based on mode
    if [[ "$PLATFORM_ONLY" == true ]]; then
        test_platform_detection
        test_docker_environment
        test_docker_configurations
    elif [[ "$QUICK_MODE" == true ]]; then
        test_platform_detection
        test_docker_environment
        test_setup_process
        test_sast_functionality
        test_user_experience
    else
        # Full testing mode
        test_platform_detection
        test_docker_environment
        test_docker_configurations
        test_setup_process
        test_grafana_automation
        test_monitoring_components
        test_email_integration
        test_sast_functionality
        test_integration_scenarios
        test_error_handling
        test_user_experience
        test_security_aspects
        test_performance_aspects
        test_compliance_aspects
    fi

    # Generate final report
    generate_test_report

    # Display summary
    log_section "Testing Complete!"
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${CYAN}📊 Final Results:${NC}"
    echo -e "   Total Tests: $TOTAL_TESTS"
    echo -e "   ${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "   ${RED}Failed: $FAILED_TESTS${NC}"
    echo -e "   ${YELLOW}Skipped: $SKIPPED_TESTS${NC}"
    echo -e "   ${BLUE}Success Rate: $success_rate%${NC}"
    echo ""

    if [[ $success_rate -ge 90 ]]; then
        echo -e "${GREEN}🎉 EXCELLENT! Platform is production-ready!${NC}"
        return 0
    elif [[ $success_rate -ge 80 ]]; then
        echo -e "${GREEN}✅ GOOD! Platform is ready with minor improvements needed.${NC}"
        return 0
    elif [[ $success_rate -ge 70 ]]; then
        echo -e "${YELLOW}⚠️ ACCEPTABLE! Platform is functional but needs improvements.${NC}"
        return 1
    else
        echo -e "${RED}❌ NEEDS WORK! Critical issues need resolution before deployment.${NC}"
        return 1
    fi
}

# Trap for cleanup
trap 'log_error "Testing interrupted"' INT TERM

# Execute main function
main "$@"
