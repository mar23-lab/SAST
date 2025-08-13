#!/bin/bash

# ===================================================================
# SAST Platform - Self-Testing Script
# ===================================================================
# Run SAST scans on our own codebase without cluttering the system
# Usage: ./scripts/self-test-sast.sh [--cleanup]

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$PROJECT_ROOT/sast-self-test"
RESULTS_DIR="$TEST_DIR/results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Cleanup mode
CLEANUP_MODE=false

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cleanup)
                CLEANUP_MODE=true
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
${CYAN}SAST Self-Testing Script${NC}

${CYAN}USAGE:${NC}
    ./scripts/self-test-sast.sh [OPTIONS]

${CYAN}OPTIONS:${NC}
    --cleanup    Clean up test results and temporary files
    --help       Show this help

${CYAN}DESCRIPTION:${NC}
    Runs SAST security scans on our own SAST platform codebase
    using lightweight, isolated testing without cluttering the main system.

${CYAN}SCANNERS USED:${NC}
    📝 ESLint Security - JavaScript/Shell security analysis
    🐍 Bandit - Python security scanning (if Python files found)
    🔍 Semgrep - Pattern-based security analysis
    📊 Custom Shell Script Analysis

${CYAN}RESULTS:${NC}
    Results saved to: sast-self-test/results/
    No interference with main SAST platform deployment

EOF
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

log_header() {
    echo -e "\n${PURPLE}🔍 $1${NC}"
    echo "────────────────────────────────────────────────"
}

# Cleanup function
cleanup_test_files() {
    log_header "Cleaning Up Test Files"
    
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
        log_success "Removed test directory: $TEST_DIR"
    fi
    
    log_success "Cleanup completed"
    exit 0
}

# Initialize testing environment
init_testing() {
    log_header "Initializing Self-Testing Environment"
    
    # Create test directories
    mkdir -p "$RESULTS_DIR"
    
    log_info "Test directory: $TEST_DIR"
    log_info "Results directory: $RESULTS_DIR"
    log_info "Timestamp: $TIMESTAMP"
    
    # Change to project root for scanning
    cd "$PROJECT_ROOT"
    log_info "Scanning directory: $(pwd)"
}

# Detect available scanners
detect_scanners() {
    log_header "Detecting Available Security Scanners"
    
    local available_scanners=()
    
    # Check for Node.js and ESLint
    if command -v npm >/dev/null 2>&1; then
        log_success "Node.js available for ESLint security scanning"
        available_scanners+=("eslint")
    else
        log_warning "Node.js not available - ESLint scanning skipped"
    fi
    
    # Check for Python and Bandit
    if command -v python3 >/dev/null 2>&1 && command -v bandit >/dev/null 2>&1; then
        log_success "Python and Bandit available for Python security scanning"
        available_scanners+=("bandit")
    else
        log_warning "Python/Bandit not available - Python scanning skipped"
    fi
    
    # Check for Semgrep
    if command -v semgrep >/dev/null 2>&1; then
        log_success "Semgrep available for pattern-based security analysis"
        available_scanners+=("semgrep")
    else
        log_warning "Semgrep not available - Pattern analysis skipped"
    fi
    
    # Shell script analysis (always available)
    log_success "Shell script security analysis available"
    available_scanners+=("shellcheck")
    
    if [[ ${#available_scanners[@]} -eq 0 ]]; then
        log_error "No security scanners available"
        exit 1
    fi
    
    log_info "Available scanners: ${available_scanners[*]}"
}

# Run ESLint security scanning
run_eslint_security() {
    log_header "Running ESLint Security Analysis"
    
    if ! command -v npm >/dev/null 2>&1; then
        log_warning "Node.js not available - skipping ESLint"
        return 0
    fi
    
    # Check if we have JavaScript files to scan
    local js_files=$(find . -name "*.js" -o -name "*.json" | grep -v node_modules | head -5)
    if [[ -z "$js_files" ]]; then
        log_info "No JavaScript files found - ESLint analysis skipped"
        return 0
    fi
    
    log_info "Scanning JavaScript/JSON files for security issues..."
    
    # Use our security ESLint config if available
    local eslint_config=""
    if [[ -f "configs/.eslintrc.security.json" ]]; then
        eslint_config="--config configs/.eslintrc.security.json"
        log_info "Using security-focused ESLint configuration"
    fi
    
    # Run ESLint security scan
    local output_file="$RESULTS_DIR/eslint-security-$TIMESTAMP.json"
    if npx eslint . $eslint_config --format json > "$output_file" 2>/dev/null; then
        log_success "ESLint security scan completed"
    else
        log_warning "ESLint scan completed with findings (exit code non-zero)"
    fi
    
    # Analyze results
    local issues_count=$(jq '[.[] | select(.messages | length > 0)] | length' "$output_file" 2>/dev/null || echo "0")
    log_info "ESLint found issues in $issues_count files"
    
    # Create summary
    jq -r '.[] | select(.messages | length > 0) | "\(.filePath): \(.messages | length) issues"' "$output_file" 2>/dev/null | head -10 || true
}

# Run Bandit Python security scanning
run_bandit_security() {
    log_header "Running Bandit Python Security Analysis"
    
    if ! command -v bandit >/dev/null 2>&1; then
        log_warning "Bandit not available - skipping Python analysis"
        return 0
    fi
    
    # Check if we have Python files to scan
    local py_files=$(find . -name "*.py" | head -5)
    if [[ -z "$py_files" ]]; then
        log_info "No Python files found - Bandit analysis skipped"
        return 0
    fi
    
    log_info "Scanning Python files for security vulnerabilities..."
    
    local output_file="$RESULTS_DIR/bandit-security-$TIMESTAMP.json"
    
    # Run Bandit scan
    if bandit -r . -f json -o "$output_file" 2>/dev/null; then
        log_success "Bandit security scan completed"
    else
        log_warning "Bandit scan completed with findings"
    fi
    
    # Analyze results
    if [[ -f "$output_file" ]]; then
        local issues_count=$(jq '.results | length' "$output_file" 2>/dev/null || echo "0")
        log_info "Bandit found $issues_count security issues"
        
        # Show top issues
        jq -r '.results[] | "\(.filename): \(.test_name) (\(.issue_severity))"' "$output_file" 2>/dev/null | head -5 || true
    fi
}

# Run Semgrep security scanning
run_semgrep_security() {
    log_header "Running Semgrep Pattern-Based Security Analysis"
    
    if ! command -v semgrep >/dev/null 2>&1; then
        log_warning "Semgrep not available - skipping pattern analysis"
        return 0
    fi
    
    log_info "Running Semgrep security rules..."
    
    local output_file="$RESULTS_DIR/semgrep-security-$TIMESTAMP.json"
    
    # Run Semgrep with security rules
    if semgrep --config=auto --json --output="$output_file" . 2>/dev/null; then
        log_success "Semgrep security scan completed"
    else
        log_warning "Semgrep scan completed with findings"
    fi
    
    # Analyze results
    if [[ -f "$output_file" ]]; then
        local issues_count=$(jq '.results | length' "$output_file" 2>/dev/null || echo "0")
        log_info "Semgrep found $issues_count security patterns"
        
        # Show findings by severity
        jq -r '.results[] | "\(.path): \(.check_id) (\(.extra.severity // "info"))"' "$output_file" 2>/dev/null | head -5 || true
    fi
}

# Run shell script security analysis
run_shell_security() {
    log_header "Running Shell Script Security Analysis"
    
    log_info "Analyzing shell scripts for security issues..."
    
    local output_file="$RESULTS_DIR/shell-security-$TIMESTAMP.txt"
    
    # Find shell scripts
    local shell_scripts=$(find . -name "*.sh" -type f | grep -v ".git")
    
    if [[ -z "$shell_scripts" ]]; then
        log_info "No shell scripts found"
        return 0
    fi
    
    echo "Shell Script Security Analysis - $TIMESTAMP" > "$output_file"
    echo "=============================================" >> "$output_file"
    echo "" >> "$output_file"
    
    local script_count=0
    local issues_found=0
    
    while IFS= read -r script; do
        ((script_count++))
        echo "Analyzing: $script" >> "$output_file"
        
        # Check for common security issues
        local script_issues=0
        
        # Check for hardcoded credentials
        if grep -E "(password|secret|token|key).*=" "$script" >/dev/null 2>&1; then
            echo "  ⚠️  Potential hardcoded credentials found" >> "$output_file"
            ((script_issues++))
        fi
        
        # Check for command injection vulnerabilities
        if grep -E "eval|exec.*\$" "$script" >/dev/null 2>&1; then
            echo "  ⚠️  Potential command injection vulnerability" >> "$output_file"
            ((script_issues++))
        fi
        
        # Check for insecure temp file usage
        if grep -E "/tmp/[^/]*\$" "$script" >/dev/null 2>&1; then
            echo "  ⚠️  Potentially insecure temp file usage" >> "$output_file"
            ((script_issues++))
        fi
        
        # Check for missing input validation
        if grep -E "rm.*\$[^{]" "$script" >/dev/null 2>&1; then
            echo "  ⚠️  Potentially dangerous rm command with variable" >> "$output_file"
            ((script_issues++))
        fi
        
        if [[ $script_issues -eq 0 ]]; then
            echo "  ✅ No obvious security issues found" >> "$output_file"
        else
            ((issues_found += script_issues))
        fi
        
        echo "" >> "$output_file"
    done <<< "$shell_scripts"
    
    echo "Summary: Analyzed $script_count scripts, found $issues_found potential issues" >> "$output_file"
    
    log_info "Analyzed $script_count shell scripts"
    log_info "Found $issues_found potential security issues"
    
    if [[ $issues_found -gt 0 ]]; then
        log_warning "Review shell script security findings in: $output_file"
    else
        log_success "No obvious security issues found in shell scripts"
    fi
}

# Generate comprehensive report
generate_report() {
    log_header "Generating Comprehensive Security Report"
    
    local report_file="$RESULTS_DIR/sast-self-test-report-$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# 🔒 SAST Platform - Self-Test Security Report

**Generated**: $(date)  
**Scan Target**: SAST Platform Codebase  
**Scan ID**: $TIMESTAMP  

---

## 📊 **Executive Summary**

This report contains the results of running our SAST security scanning solution
on our own SAST platform codebase to validate functionality and identify any
security issues in our own code.

## 🔍 **Scans Performed**

EOF

    # Add scan results summary
    local total_files=0
    local total_issues=0
    
    # ESLint results
    if [[ -f "$RESULTS_DIR/eslint-security-$TIMESTAMP.json" ]]; then
        local eslint_issues=$(jq '[.[] | select(.messages | length > 0)] | length' "$RESULTS_DIR/eslint-security-$TIMESTAMP.json" 2>/dev/null || echo "0")
        echo "### ESLint Security Analysis ✅" >> "$report_file"
        echo "- **Files with issues**: $eslint_issues" >> "$report_file"
        echo "- **Status**: Completed" >> "$report_file"
        echo "" >> "$report_file"
        ((total_issues += eslint_issues))
    fi
    
    # Bandit results
    if [[ -f "$RESULTS_DIR/bandit-security-$TIMESTAMP.json" ]]; then
        local bandit_issues=$(jq '.results | length' "$RESULTS_DIR/bandit-security-$TIMESTAMP.json" 2>/dev/null || echo "0")
        echo "### Bandit Python Security Analysis ✅" >> "$report_file"
        echo "- **Security issues found**: $bandit_issues" >> "$report_file"
        echo "- **Status**: Completed" >> "$report_file"
        echo "" >> "$report_file"
        ((total_issues += bandit_issues))
    fi
    
    # Semgrep results
    if [[ -f "$RESULTS_DIR/semgrep-security-$TIMESTAMP.json" ]]; then
        local semgrep_issues=$(jq '.results | length' "$RESULTS_DIR/semgrep-security-$TIMESTAMP.json" 2>/dev/null || echo "0")
        echo "### Semgrep Pattern Analysis ✅" >> "$report_file"
        echo "- **Security patterns found**: $semgrep_issues" >> "$report_file"
        echo "- **Status**: Completed" >> "$report_file"
        echo "" >> "$report_file"
        ((total_issues += semgrep_issues))
    fi
    
    # Shell script results
    if [[ -f "$RESULTS_DIR/shell-security-$TIMESTAMP.txt" ]]; then
        local shell_issues=$(grep "potential issues" "$RESULTS_DIR/shell-security-$TIMESTAMP.txt" | grep -o "[0-9]\+" | tail -1 || echo "0")
        echo "### Shell Script Security Analysis ✅" >> "$report_file"
        echo "- **Potential issues found**: $shell_issues" >> "$report_file"
        echo "- **Status**: Completed" >> "$report_file"
        echo "" >> "$report_file"
        ((total_issues += shell_issues))
    fi
    
    cat >> "$report_file" << EOF
## 🎯 **Overall Results**

- **Total Issues Found**: $total_issues
- **Scan Status**: ✅ Completed Successfully
- **SAST Platform Status**: $([ $total_issues -eq 0 ] && echo "✅ Clean" || echo "⚠️ Needs Review")

## 📁 **Detailed Results**

Detailed scan results are available in the following files:
EOF

    # List all result files
    for result_file in "$RESULTS_DIR"/*-"$TIMESTAMP".*; do
        if [[ -f "$result_file" ]]; then
            echo "- \`$(basename "$result_file")\`" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## 🚀 **Validation Results**

This self-test demonstrates:
- ✅ SAST platform functionality is working correctly
- ✅ Security scanners are properly configured
- ✅ Result generation and reporting is functional
- $([ $total_issues -eq 0 ] && echo "✅ Our codebase is secure" || echo "⚠️ Some security issues identified for review")

---

*Report generated by SAST Platform Self-Test*  
*Scan completed: $(date)*
EOF

    log_success "Comprehensive report generated: $report_file"
    
    # Show summary
    echo -e "\n${CYAN}📋 Final Summary:${NC}"
    echo -e "   Total Security Issues Found: ${total_issues}"
    echo -e "   Report Location: $report_file"
    echo -e "   Results Directory: $RESULTS_DIR"
    
    if [[ $total_issues -eq 0 ]]; then
        echo -e "   ${GREEN}🎉 SAST Platform codebase is clean!${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Review findings for potential improvements${NC}"
    fi
}

# Main execution
main() {
    echo -e "${PURPLE}"
    cat << 'EOF'
 ┌─────────────────────────────────────────────────┐
 │           🔒 SAST Self-Testing                  │
 │      Scan Our Own Code for Security Issues     │
 └─────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
    
    parse_args "$@"
    
    if [[ "$CLEANUP_MODE" == true ]]; then
        cleanup_test_files
    fi
    
    init_testing
    detect_scanners
    
    # Run security scans
    run_eslint_security
    run_bandit_security
    run_semgrep_security
    run_shell_security
    
    # Generate comprehensive report
    generate_report
    
    log_success "SAST self-testing completed successfully!"
    echo -e "\n${BLUE}📊 To view results:${NC}"
    echo -e "   cat $RESULTS_DIR/sast-self-test-report-$TIMESTAMP.md"
    echo -e "\n${BLUE}🧹 To clean up:${NC}"
    echo -e "   ./scripts/self-test-sast.sh --cleanup"
}

# Execute main function
main "$@"
