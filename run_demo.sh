#!/bin/bash

# ===================================================================
# CI/CD SAST Boilerplate - Demo Mode Runner
# ===================================================================
# This script simulates a complete CI pipeline run with test data
# Usage: ./run_demo.sh [options]

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/ci-config.yaml"
DEMO_RESULTS_DIR="$SCRIPT_DIR/demo-results"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Demo configuration
DEMO_COMPONENT=""
DEMO_SCENARIO="normal"
VERBOSE=false
INTERACTIVE=false

# Display usage information
show_usage() {
    cat << EOF
🧪 CI/CD SAST Boilerplate - Demo Mode

USAGE:
    ./run_demo.sh [OPTIONS]

OPTIONS:
    -c, --component COMPONENT    Run specific component demo
                                 (slack|email|jira|grafana|all)
    -s, --scenario SCENARIO      Demo scenario to simulate
                                 (normal|critical|failure|success)
    -v, --verbose               Enable verbose output
    -i, --interactive           Interactive mode with prompts
    -h, --help                  Show this help message

SCENARIOS:
    normal                      Standard scan with mixed findings
    critical                    Scan with critical vulnerabilities
    failure                     Simulated scan failure
    success                     Clean scan with no issues

COMPONENTS:
    slack                       Test Slack notifications
    email                       Test email notifications  
    jira                        Test Jira ticket creation
    grafana                     Test Grafana dashboard updates
    all                         Test all integrations (default)

EXAMPLES:
    ./run_demo.sh                                    # Full demo
    ./run_demo.sh -c slack -s critical              # Slack demo with critical findings
    ./run_demo.sh -i                                # Interactive mode
    ./run_demo.sh -v -s failure                     # Verbose scan failure demo

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--component)
                DEMO_COMPONENT="$2"
                shift 2
                ;;
            -s|--scenario)
                DEMO_SCENARIO="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -h|--help)
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

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}🔍 $1${NC}"
    fi
}

log_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check required commands
    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check optional commands
    if ! command -v yq >/dev/null 2>&1; then
        log_warning "yq not found - installing..."
        if command -v brew >/dev/null 2>&1; then
            brew install yq >/dev/null 2>&1 || true
        else
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 2>/dev/null || true
            sudo chmod +x /usr/local/bin/yq 2>/dev/null || true
        fi
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them and try again."
        exit 1
    fi
    
    # Check configuration file
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    log_success "Prerequisites check completed"
}

# Setup demo environment
setup_demo_environment() {
    log_step "Setting up demo environment..."
    
    # Create demo results directory
    mkdir -p "$DEMO_RESULTS_DIR"
    
    # Enable demo mode in configuration
    export DEMO_MODE="true"
    export CONFIG_JSON=$(yq -o=json "$CONFIG_FILE" | jq '.demo_mode.enabled = true')
    
    # Set demo environment variables
    export GITHUB_REPOSITORY="demo/sast-boilerplate"
    export GITHUB_REF_NAME="main"
    export GITHUB_SHA="abc123def456"
    export GITHUB_SERVER_URL="https://github.com"
    export GITHUB_RUN_ID="123456789"
    export GITHUB_OUTPUT="$DEMO_RESULTS_DIR/github_output.txt"
    
    log_verbose "Demo environment variables set"
    log_success "Demo environment setup completed"
}

# Generate demo vulnerability data based on scenario
generate_demo_data() {
    log_step "Generating demo data for scenario: $DEMO_SCENARIO..."
    
    local critical=0 high=0 medium=0 low=0
    local scan_status="success"
    local scan_duration="2m 15s"
    
    case "$DEMO_SCENARIO" in
        "normal")
            critical=1
            high=3
            medium=8
            low=5
            scan_status="success"
            ;;
        "critical")
            critical=5
            high=12
            medium=25
            low=10
            scan_status="failure"
            ;;
        "failure")
            critical=0
            high=0
            medium=0
            low=0
            scan_status="failure"
            scan_duration="0m 30s"
            ;;
        "success")
            critical=0
            high=0
            medium=2
            low=3
            scan_status="success"
            ;;
        *)
            log_warning "Unknown scenario '$DEMO_SCENARIO', using 'normal'"
            critical=1
            high=3
            medium=8
            low=5
            scan_status="success"
            ;;
    esac
    
    # Create demo summary file
    cat > "$DEMO_RESULTS_DIR/overall-summary.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "scan_type": "demo",
  "status": "$scan_status",
  "demo_mode": true,
  "scenario": "$DEMO_SCENARIO",
  "thresholds": {
    "severity_threshold": "medium",
    "max_critical": 0,
    "max_high": 5
  },
  "total_vulnerabilities": {
    "critical": $critical,
    "high": $high,
    "medium": $medium,
    "low": $low
  },
  "total_findings": $((critical + high + medium + low)),
  "scan_duration": "$scan_duration",
  "files_scanned": 247,
  "lines_of_code": 15420,
  "scanners_run": ["codeql", "semgrep", "bandit", "eslint"]
}
EOF
    
    # Create individual scanner results
    create_scanner_demo_results "codeql" $((critical / 2)) $((high / 2))
    create_scanner_demo_results "semgrep" $((critical / 2)) $((high / 2))
    create_scanner_demo_results "bandit" 0 $((high / 4))
    create_scanner_demo_results "eslint" 0 $((medium / 4))
    
    log_verbose "Generated $((critical + high + medium + low)) demo vulnerabilities"
    log_success "Demo data generation completed"
}

# Create individual scanner demo results
create_scanner_demo_results() {
    local scanner="$1"
    local critical_count="$2"
    local high_count="$3"
    
    cat > "$DEMO_RESULTS_DIR/${scanner}-summary.json" << EOF
{
  "scanner": "$scanner",
  "timestamp": "$TIMESTAMP",
  "scan_type": "demo",
  "demo_mode": true,
  "vulnerabilities": {
    "critical": $critical_count,
    "high": $high_count,
    "medium": $((RANDOM % 5 + 1)),
    "low": $((RANDOM % 3 + 1))
  },
  "total_findings": $((critical_count + high_count + (RANDOM % 5 + 1) + (RANDOM % 3 + 1))),
  "status": "completed"
}
EOF
}

# Interactive mode prompts
run_interactive_mode() {
    if [ "$INTERACTIVE" != true ]; then
        return 0
    fi
    
    echo -e "${CYAN}🤖 Welcome to Interactive Demo Mode!${NC}"
    echo
    
    # Component selection
    if [ -z "$DEMO_COMPONENT" ]; then
        echo "Which component would you like to test?"
        echo "1) All components (default)"
        echo "2) Slack notifications"
        echo "3) Email notifications"
        echo "4) Jira integration"
        echo "5) Grafana dashboard"
        read -p "Enter your choice (1-5): " choice
        
        case $choice in
            2) DEMO_COMPONENT="slack" ;;
            3) DEMO_COMPONENT="email" ;;
            4) DEMO_COMPONENT="jira" ;;
            5) DEMO_COMPONENT="grafana" ;;
            *) DEMO_COMPONENT="all" ;;
        esac
    fi
    
    # Scenario selection
    if [ "$DEMO_SCENARIO" = "normal" ]; then
        echo
        echo "Which scenario would you like to simulate?"
        echo "1) Normal scan (default) - Mixed findings"
        echo "2) Critical vulnerabilities - Many serious issues"
        echo "3) Scan failure - Technical failure scenario"
        echo "4) Clean scan - No significant issues"
        read -p "Enter your choice (1-4): " choice
        
        case $choice in
            2) DEMO_SCENARIO="critical" ;;
            3) DEMO_SCENARIO="failure" ;;
            4) DEMO_SCENARIO="success" ;;
            *) DEMO_SCENARIO="normal" ;;
        esac
    fi
    
    echo
    echo -e "${GREEN}Configuration:${NC}"
    echo "Component: $DEMO_COMPONENT"
    echo "Scenario: $DEMO_SCENARIO"
    echo
    read -p "Press Enter to continue or Ctrl+C to cancel..."
}

# Demo Slack integration
demo_slack() {
    log_step "🧪 [DEMO] Testing Slack integration..."
    
    # Create demo webhook URL if not set
    local demo_webhook="https://hooks.slack.com/services/DEMO/DEMO/DEMO"
    export SLACK_WEBHOOK="${SLACK_WEBHOOK:-$demo_webhook}"
    
    # Update config for demo
    local demo_config
    demo_config=$(echo "$CONFIG_JSON" | jq '
        .demo_mode.enabled = true |
        .integrations.slack.enabled = true |
        .integrations.slack.channel = "#demo-alerts" |
        .integrations.slack.username = "Demo-Security-Bot" |
        .demo_mode.label_prefix = "[🧪 DEMO]"
    ')
    export CONFIG_JSON="$demo_config"
    
    log_info "Simulating Slack notification..."
    
    if [ "$VERBOSE" = true ]; then
        log_verbose "Demo webhook: $demo_webhook"
        log_verbose "Demo channel: #demo-alerts"
    fi
    
    # Use a timeout to simulate network call without actually making it
    (
        echo "🔔 Slack notification sent to #demo-alerts"
        echo "   Message: 🧪 [DEMO] SAST Scan $DEMO_SCENARIO - demo/sast-boilerplate"
        echo "   Vulnerabilities: $(jq '.total_vulnerabilities' "$DEMO_RESULTS_DIR/overall-summary.json")"
        sleep 2
    ) &
    local pid=$!
    
    # Show progress
    local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    while kill -0 $pid 2>/dev/null; do
        printf "\r${BLUE}📡 Sending Slack notification... ${spinner:$i:1}${NC}"
        i=$(( (i+1) % ${#spinner} ))
        sleep 0.1
    done
    printf "\r"
    
    wait $pid
    log_success "Slack demo completed - notification would be sent to #demo-alerts"
}

# Demo email integration
demo_email() {
    log_step "🧪 [DEMO] Testing email integration..."
    
    local demo_recipients=$(echo "$CONFIG_JSON" | jq -r '.demo_mode.demo_recipients[]' | tr '\n' ',' | sed 's/,$//')
    
    log_info "Simulating email notification..."
    
    if [ "$VERBOSE" = true ]; then
        log_verbose "Demo recipients: $demo_recipients"
        log_verbose "SMTP server: demo-smtp.example.com"
    fi
    
    # Simulate email sending
    (
        echo "📧 Email notification sent to: $demo_recipients"
        echo "   Subject: [🧪 DEMO] SAST Alert - demo/sast-boilerplate"
        echo "   Content: Vulnerability summary and scan results"
        sleep 2
    ) &
    local pid=$!
    
    # Show progress
    local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    while kill -0 $pid 2>/dev/null; do
        printf "\r${BLUE}📨 Sending email notification... ${spinner:$i:1}${NC}"
        i=$(( (i+1) % ${#spinner} ))
        sleep 0.1
    done
    printf "\r"
    
    wait $pid
    log_success "Email demo completed - notification would be sent to demo recipients"
}

# Demo Jira integration
demo_jira() {
    log_step "🧪 [DEMO] Testing Jira integration..."
    
    local demo_project=$(echo "$CONFIG_JSON" | jq -r '.demo_mode.demo_jira_project')
    local total_critical=$(jq '.total_vulnerabilities.critical' "$DEMO_RESULTS_DIR/overall-summary.json")
    local total_high=$(jq '.total_vulnerabilities.high' "$DEMO_RESULTS_DIR/overall-summary.json")
    
    log_info "Simulating Jira ticket creation..."
    
    if [ "$VERBOSE" = true ]; then
        log_verbose "Demo project: $demo_project"
        log_verbose "Critical vulnerabilities: $total_critical"
        log_verbose "High vulnerabilities: $total_high"
    fi
    
    # Only create ticket for critical/high findings or failures
    if [ "$total_critical" -gt 0 ] || [ "$total_high" -gt 0 ] || [ "$(jq -r '.status' "$DEMO_RESULTS_DIR/overall-summary.json")" = "failure" ]; then
        (
            echo "🎫 Jira ticket created in project: $demo_project"
            echo "   Ticket ID: DEMO-$(date +%s | tail -c 4)"
            echo "   Title: [🧪 DEMO] SAST Scan $DEMO_SCENARIO - Security Vulnerabilities Found"
            echo "   Priority: High"
            echo "   Labels: security-vulnerability, sast-scan, auto-created, demo"
            sleep 2
        ) &
        local pid=$!
        
        # Show progress
        local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        while kill -0 $pid 2>/dev/null; do
            printf "\r${BLUE}🎫 Creating Jira ticket... ${spinner:$i:1}${NC}"
            i=$(( (i+1) % ${#spinner} ))
            sleep 0.1
        done
        printf "\r"
        
        wait $pid
        log_success "Jira demo completed - ticket would be created in $demo_project"
    else
        log_info "No Jira ticket created - no critical/high vulnerabilities found"
    fi
}

# Demo Grafana integration
demo_grafana() {
    log_step "🧪 [DEMO] Testing Grafana integration..."
    
    local dashboard_uid=$(echo "$CONFIG_JSON" | jq -r '.integrations.grafana.dashboard_uid')
    local total_findings=$(jq '.total_findings' "$DEMO_RESULTS_DIR/overall-summary.json")
    
    log_info "Simulating Grafana dashboard update..."
    
    if [ "$VERBOSE" = true ]; then
        log_verbose "Dashboard UID: $dashboard_uid"
        log_verbose "Total findings: $total_findings"
        log_verbose "Demo Grafana URL: https://demo-grafana.example.com"
    fi
    
    # Simulate dashboard update
    (
        echo "📊 Grafana dashboard updated"
        echo "   Dashboard: SAST Security Dashboard ($dashboard_uid)"
        echo "   Metrics pushed to Prometheus"
        echo "   Annotation created for scan event"
        echo "   URL: https://demo-grafana.example.com/d/$dashboard_uid/sast-security-dashboard"
        sleep 2
    ) &
    local pid=$!
    
    # Show progress
    local spinner="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    while kill -0 $pid 2>/dev/null; do
        printf "\r${BLUE}📊 Updating Grafana dashboard... ${spinner:$i:1}${NC}"
        i=$(( (i+1) % ${#spinner} ))
        sleep 0.1
    done
    printf "\r"
    
    wait $pid
    
    # Create demo metrics file
    cat > "$DEMO_RESULTS_DIR/grafana-metrics.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "demo_mode": true,
  "dashboard_url": "https://demo-grafana.example.com/d/$dashboard_uid/sast-security-dashboard",
  "metrics_pushed": [
    "sast_vulnerabilities_total",
    "sast_scan_duration_seconds", 
    "sast_scan_status",
    "sast_files_scanned_total"
  ]
}
EOF
    
    log_success "Grafana demo completed - dashboard would be updated"
}

# Run demo pipeline simulation
run_demo_pipeline() {
    log_step "🧪 [DEMO] Simulating complete SAST pipeline..."
    
    echo
    echo -e "${CYAN}==================== 🧪 DEMO MODE ====================${NC}"
    echo -e "${CYAN}Scenario: $DEMO_SCENARIO${NC}"
    echo -e "${CYAN}Component: $DEMO_COMPONENT${NC}"
    echo -e "${CYAN}Repository: demo/sast-boilerplate${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo
    
    # Simulate SAST scanning
    log_step "Running SAST scans..."
    local scanners=("codeql" "semgrep" "bandit" "eslint")
    
    for scanner in "${scanners[@]}"; do
        log_info "🔍 Running $scanner scanner..."
        sleep 1
        log_success "$scanner scan completed"
    done
    
    echo
    
    # Display scan results
    display_scan_results
    
    echo
    
    # Run integration demos based on component selection
    case "$DEMO_COMPONENT" in
        "slack")
            demo_slack
            ;;
        "email")
            demo_email
            ;;
        "jira")
            demo_jira
            ;;
        "grafana")
            demo_grafana
            ;;
        "all"|"")
            demo_slack
            echo
            demo_email
            echo
            demo_jira
            echo
            demo_grafana
            ;;
        *)
            log_error "Unknown component: $DEMO_COMPONENT"
            exit 1
            ;;
    esac
}

# Display scan results summary
display_scan_results() {
    log_step "📊 Scan Results Summary"
    
    local summary_file="$DEMO_RESULTS_DIR/overall-summary.json"
    local critical=$(jq '.total_vulnerabilities.critical' "$summary_file")
    local high=$(jq '.total_vulnerabilities.high' "$summary_file")
    local medium=$(jq '.total_vulnerabilities.medium' "$summary_file")
    local low=$(jq '.total_vulnerabilities.low' "$summary_file")
    local total=$(jq '.total_findings' "$summary_file")
    local status=$(jq -r '.status' "$summary_file")
    
    echo -e "${BLUE}┌─────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│          Vulnerability Summary      │${NC}"
    echo -e "${BLUE}├─────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} 🔴 Critical: $(printf '%3d' $critical)                   ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 🟠 High:     $(printf '%3d' $high)                   ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 🟡 Medium:   $(printf '%3d' $medium)                   ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 🔵 Low:      $(printf '%3d' $low)                   ${BLUE}│${NC}"
    echo -e "${BLUE}├─────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} 📊 Total:    $(printf '%3d' $total)                   ${BLUE}│${NC}"
    
    if [ "$status" = "success" ]; then
        echo -e "${BLUE}│${NC} ✅ Status:   ${GREEN}PASS${NC}                   ${BLUE}│${NC}"
    else
        echo -e "${BLUE}│${NC} ❌ Status:   ${RED}FAIL${NC}                   ${BLUE}│${NC}"
    fi
    
    echo -e "${BLUE}└─────────────────────────────────────┘${NC}"
    
    if [ "$VERBOSE" = true ]; then
        echo
        log_verbose "Scan duration: $(jq -r '.scan_duration' "$summary_file")"
        log_verbose "Files scanned: $(jq '.files_scanned' "$summary_file")"
        log_verbose "Lines of code: $(jq '.lines_of_code' "$summary_file")"
        log_verbose "Scanners used: $(jq -r '.scanners_run | join(", ")' "$summary_file")"
    fi
}

# Generate demo report
generate_demo_report() {
    log_step "📝 Generating demo report..."
    
    local report_file="$DEMO_RESULTS_DIR/demo-report.md"
    
    cat > "$report_file" << EOF
# 🧪 SAST Demo Report

**Generated:** $TIMESTAMP  
**Mode:** Demo Mode  
**Scenario:** $DEMO_SCENARIO  
**Component:** $DEMO_COMPONENT  

## Scan Summary

$(jq -r '. as $summary | 
"- **Critical:** \($summary.total_vulnerabilities.critical)
- **High:** \($summary.total_vulnerabilities.high) 
- **Medium:** \($summary.total_vulnerabilities.medium)
- **Low:** \($summary.total_vulnerabilities.low)
- **Total Findings:** \($summary.total_findings)
- **Status:** \($summary.status | ascii_upcase)
- **Duration:** \($summary.scan_duration)
- **Files Scanned:** \($summary.files_scanned)
- **Lines of Code:** \($summary.lines_of_code)"' "$DEMO_RESULTS_DIR/overall-summary.json")

## Scanners Used

$(jq -r '.scanners_run[] | "- " + .' "$DEMO_RESULTS_DIR/overall-summary.json")

## Integration Tests

$([ "$DEMO_COMPONENT" = "all" ] || [ "$DEMO_COMPONENT" = "slack" ] && echo "- ✅ Slack notification sent to #demo-alerts")
$([ "$DEMO_COMPONENT" = "all" ] || [ "$DEMO_COMPONENT" = "email" ] && echo "- ✅ Email notification sent to demo recipients")
$([ "$DEMO_COMPONENT" = "all" ] || [ "$DEMO_COMPONENT" = "jira" ] && echo "- ✅ Jira ticket created (if needed)")
$([ "$DEMO_COMPONENT" = "all" ] || [ "$DEMO_COMPONENT" = "grafana" ] && echo "- ✅ Grafana dashboard updated")

## Demo Data Location

All demo files are stored in: \`$DEMO_RESULTS_DIR\`

---
*This is a demonstration run with simulated data. No actual vulnerabilities were scanned.*
EOF
    
    log_success "Demo report generated: $report_file"
}

# Cleanup demo environment
cleanup_demo() {
    log_step "🧹 Cleaning up demo environment..."
    
    # Optionally remove demo results (ask user)
    if [ "$INTERACTIVE" = true ]; then
        echo
        read -p "Remove demo results directory? (y/N): " cleanup_choice
        if [[ $cleanup_choice =~ ^[Yy]$ ]]; then
            rm -rf "$DEMO_RESULTS_DIR"
            log_success "Demo results cleaned up"
        else
            log_info "Demo results preserved in: $DEMO_RESULTS_DIR"
        fi
    else
        log_info "Demo results preserved in: $DEMO_RESULTS_DIR"
    fi
    
    # Clear demo environment variables
    unset DEMO_MODE CONFIG_JSON GITHUB_REPOSITORY GITHUB_REF_NAME GITHUB_SHA
    unset GITHUB_SERVER_URL GITHUB_RUN_ID GITHUB_OUTPUT
    
    log_success "Demo environment cleanup completed"
}

# Main execution function
main() {
    echo -e "${PURPLE}🧪 CI/CD SAST Boilerplate - Demo Mode${NC}"
    echo -e "${PURPLE}======================================${NC}"
    echo
    
    # Parse arguments and run interactive mode if needed
    parse_arguments "$@"
    run_interactive_mode
    
    # Setup and run demo
    check_prerequisites
    setup_demo_environment
    generate_demo_data
    
    echo
    run_demo_pipeline
    echo
    
    # Generate report and cleanup
    generate_demo_report
    echo
    cleanup_demo
    
    echo
    echo -e "${GREEN}🎉 Demo completed successfully!${NC}"
    echo
    echo -e "${CYAN}📚 Next Steps:${NC}"
    echo "1. Review the demo report: $DEMO_RESULTS_DIR/demo-report.md"
    echo "2. Customize ci-config.yaml for your environment"  
    echo "3. Set up required secrets in your GitHub repository"
    echo "4. Push to trigger real CI/CD pipeline"
    echo
    echo -e "${CYAN}📖 Documentation:${NC}"
    echo "- Configuration guide: CONFIG_GUIDE.md"
    echo "- Architecture overview: docs/ARCHITECTURE.md"
    echo "- Troubleshooting: docs/TROUBLESHOOTING.md"
}

# Execute main function with all arguments
main "$@"
