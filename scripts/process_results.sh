#!/bin/bash

# ===================================================================
# SAST Results Processing Script
# ===================================================================
# This script processes SAST scan results and generates reports
# Usage: ./process_results.sh <scanner_name> <scan_type>

set -euo pipefail

SCANNER_NAME="${1:-unknown}"
SCAN_TYPE="${2:-full}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RESULTS_DIR="./sast-results"
CONFIG_FILE="ci-config.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p "$RESULTS_DIR"

echo -e "${BLUE}🔍 Processing $SCANNER_NAME scan results...${NC}"

# Load configuration
if command -v yq >/dev/null 2>&1; then
    SEVERITY_THRESHOLD=$(yq '.sast.severity_threshold' "$CONFIG_FILE")
    MAX_CRITICAL=$(yq '.sast.max_critical_vulnerabilities' "$CONFIG_FILE")
    MAX_HIGH=$(yq '.sast.max_high_vulnerabilities' "$CONFIG_FILE")
else
    echo -e "${YELLOW}⚠️  yq not found, using default thresholds${NC}"
    SEVERITY_THRESHOLD="medium"
    MAX_CRITICAL=0
    MAX_HIGH=5
fi

# Function to process CodeQL results
process_codeql_results() {
    echo -e "${BLUE}📊 Processing CodeQL results...${NC}"
    
    if [ -f "codeql-results.sarif" ]; then
        # Extract vulnerability counts from SARIF
        critical_count=0
        high_count=0
        medium_count=0
        low_count=0
        
        # Simple parsing - in real implementation, use proper SARIF parser
        if command -v jq >/dev/null 2>&1; then
            total_results=$(jq '.runs[0].results | length' codeql-results.sarif 2>/dev/null || echo "0")
            echo "Total CodeQL findings: $total_results"
        fi
        
        # Generate summary
        cat > "$RESULTS_DIR/codeql-summary.json" << EOF
{
  "scanner": "codeql",
  "timestamp": "$TIMESTAMP",
  "scan_type": "$SCAN_TYPE",
  "vulnerabilities": {
    "critical": $critical_count,
    "high": $high_count,
    "medium": $medium_count,
    "low": $low_count
  },
  "total_findings": $((critical_count + high_count + medium_count + low_count)),
  "status": "completed"
}
EOF
    else
        echo -e "${YELLOW}⚠️  No CodeQL results file found${NC}"
    fi
}

# Function to process Semgrep results
process_semgrep_results() {
    echo -e "${BLUE}📊 Processing Semgrep results...${NC}"
    
    if [ -f "semgrep-results.json" ]; then
        # Process Semgrep JSON output
        if command -v jq >/dev/null 2>&1; then
            critical_count=$(jq '[.results[] | select(.extra.severity == "ERROR")] | length' semgrep-results.json)
            high_count=$(jq '[.results[] | select(.extra.severity == "WARNING")] | length' semgrep-results.json)
            medium_count=$(jq '[.results[] | select(.extra.severity == "INFO")] | length' semgrep-results.json)
            total_count=$(jq '.results | length' semgrep-results.json)
            
            echo -e "${GREEN}✅ Semgrep scan completed${NC}"
            echo "Critical: $critical_count, High: $high_count, Medium: $medium_count"
        fi
        
        # Generate summary
        cat > "$RESULTS_DIR/semgrep-summary.json" << EOF
{
  "scanner": "semgrep",
  "timestamp": "$TIMESTAMP",
  "scan_type": "$SCAN_TYPE",
  "vulnerabilities": {
    "critical": ${critical_count:-0},
    "high": ${high_count:-0},
    "medium": ${medium_count:-0},
    "low": 0
  },
  "total_findings": ${total_count:-0},
  "status": "completed"
}
EOF
    else
        echo -e "${YELLOW}⚠️  No Semgrep results file found${NC}"
    fi
}

# Function to process Bandit results
process_bandit_results() {
    echo -e "${BLUE}📊 Processing Bandit results...${NC}"
    
    if [ -f "bandit-report.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            high_count=$(jq '[.results[] | select(.issue_severity == "HIGH")] | length' bandit-report.json)
            medium_count=$(jq '[.results[] | select(.issue_severity == "MEDIUM")] | length' bandit-report.json)
            low_count=$(jq '[.results[] | select(.issue_severity == "LOW")] | length' bandit-report.json)
            total_count=$(jq '.results | length' bandit-report.json)
            
            echo -e "${GREEN}✅ Bandit scan completed${NC}"
            echo "High: $high_count, Medium: $medium_count, Low: $low_count"
        fi
        
        # Generate summary
        cat > "$RESULTS_DIR/bandit-summary.json" << EOF
{
  "scanner": "bandit",
  "timestamp": "$TIMESTAMP",
  "scan_type": "$SCAN_TYPE",
  "vulnerabilities": {
    "critical": 0,
    "high": ${high_count:-0},
    "medium": ${medium_count:-0},
    "low": ${low_count:-0}
  },
  "total_findings": ${total_count:-0},
  "status": "completed"
}
EOF
    else
        echo -e "${YELLOW}⚠️  No Bandit results file found${NC}"
    fi
}

# Function to process ESLint results
process_eslint_results() {
    echo -e "${BLUE}📊 Processing ESLint results...${NC}"
    
    if [ -f "eslint-report.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            error_count=$(jq '[.[].messages[] | select(.severity == 2)] | length' eslint-report.json)
            warning_count=$(jq '[.[].messages[] | select(.severity == 1)] | length' eslint-report.json)
            total_count=$(jq '[.[].messages[]] | length' eslint-report.json)
            
            echo -e "${GREEN}✅ ESLint scan completed${NC}"
            echo "Errors: $error_count, Warnings: $warning_count"
        fi
        
        # Generate summary
        cat > "$RESULTS_DIR/eslint-summary.json" << EOF
{
  "scanner": "eslint",
  "timestamp": "$TIMESTAMP",
  "scan_type": "$SCAN_TYPE",
  "vulnerabilities": {
    "critical": 0,
    "high": ${error_count:-0},
    "medium": ${warning_count:-0},
    "low": 0
  },
  "total_findings": ${total_count:-0},
  "status": "completed"
}
EOF
    else
        echo -e "${YELLOW}⚠️  No ESLint results file found${NC}"
    fi
}

# Function to generate overall summary
generate_overall_summary() {
    echo -e "${BLUE}📋 Generating overall summary...${NC}"
    
    total_critical=0
    total_high=0
    total_medium=0
    total_low=0
    
    # Aggregate results from all scanners
    for summary_file in "$RESULTS_DIR"/*-summary.json; do
        if [ -f "$summary_file" ] && command -v jq >/dev/null 2>&1; then
            critical=$(jq '.vulnerabilities.critical' "$summary_file")
            high=$(jq '.vulnerabilities.high' "$summary_file")
            medium=$(jq '.vulnerabilities.medium' "$summary_file")
            low=$(jq '.vulnerabilities.low' "$summary_file")
            
            total_critical=$((total_critical + critical))
            total_high=$((total_high + high))
            total_medium=$((total_medium + medium))
            total_low=$((total_low + low))
        fi
    done
    
    # Determine overall status
    status="success"
    if [ "$total_critical" -gt "$MAX_CRITICAL" ]; then
        status="failure"
        echo -e "${RED}❌ Critical vulnerabilities ($total_critical) exceed threshold ($MAX_CRITICAL)${NC}"
    elif [ "$total_high" -gt "$MAX_HIGH" ]; then
        status="failure"
        echo -e "${RED}❌ High vulnerabilities ($total_high) exceed threshold ($MAX_HIGH)${NC}"
    else
        echo -e "${GREEN}✅ Vulnerability counts within acceptable thresholds${NC}"
    fi
    
    # Generate overall summary
    cat > "$RESULTS_DIR/overall-summary.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "scan_type": "$SCAN_TYPE",
  "status": "$status",
  "thresholds": {
    "severity_threshold": "$SEVERITY_THRESHOLD",
    "max_critical": $MAX_CRITICAL,
    "max_high": $MAX_HIGH
  },
  "total_vulnerabilities": {
    "critical": $total_critical,
    "high": $total_high,
    "medium": $total_medium,
    "low": $total_low
  },
  "total_findings": $((total_critical + total_high + total_medium + total_low)),
  "scanners_run": [
EOF

    # Add list of scanners that ran
    first=true
    for summary_file in "$RESULTS_DIR"/*-summary.json; do
        if [ -f "$summary_file" ] && command -v jq >/dev/null 2>&1; then
            scanner=$(jq -r '.scanner' "$summary_file")
            if [ "$first" = true ]; then
                echo "    \"$scanner\"" >> "$RESULTS_DIR/overall-summary.json"
                first=false
            else
                echo "    ,\"$scanner\"" >> "$RESULTS_DIR/overall-summary.json"
            fi
        fi
    done
    
    echo "  ]" >> "$RESULTS_DIR/overall-summary.json"
    echo "}" >> "$RESULTS_DIR/overall-summary.json"
    
    # Display summary
    echo -e "${BLUE}📊 Scan Summary:${NC}"
    echo "Critical: $total_critical"
    echo "High: $total_high"
    echo "Medium: $total_medium"
    echo "Low: $total_low"
    echo "Status: $status"
}

# Main processing logic
case "$SCANNER_NAME" in
    "codeql")
        process_codeql_results
        ;;
    "semgrep")
        process_semgrep_results
        ;;
    "bandit")
        process_bandit_results
        ;;
    "eslint")
        process_eslint_results
        ;;
    *)
        echo -e "${YELLOW}⚠️  Unknown scanner: $SCANNER_NAME${NC}"
        ;;
esac

# Always generate overall summary at the end
generate_overall_summary

# Set GitHub Actions output if running in CI
if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "scan_status=$status" >> "$GITHUB_OUTPUT"
    echo "total_critical=$total_critical" >> "$GITHUB_OUTPUT"
    echo "total_high=$total_high" >> "$GITHUB_OUTPUT"
    echo "total_findings=$((total_critical + total_high + total_medium + total_low))" >> "$GITHUB_OUTPUT"
fi

echo -e "${GREEN}✅ Results processing completed${NC}"
exit 0
