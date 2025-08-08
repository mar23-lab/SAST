#!/bin/bash

# ===================================================================
# Grafana Dashboard Update Script
# ===================================================================
# This script updates Grafana dashboards with SAST scan metrics
# Usage: ./update_grafana.sh <scan_status> [additional_metrics]

set -euo pipefail

SCAN_STATUS="${1:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RESULTS_DIR="./sast-results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Updating Grafana dashboard...${NC}"

# Load configuration
if [ -n "${CONFIG_JSON:-}" ]; then
    CONFIG="$CONFIG_JSON"
elif [ -f "ci-config.yaml" ] && command -v yq >/dev/null 2>&1; then
    CONFIG=$(yq -o=json ci-config.yaml)
else
    echo -e "${RED}❌ No configuration available${NC}"
    exit 1
fi

# Extract Grafana configuration
GRAFANA_ENABLED=$(echo "$CONFIG" | jq -r '.integrations.grafana.enabled // false')
GRAFANA_URL=$(echo "$CONFIG" | jq -r '.integrations.grafana.server_url // ""')
DASHBOARD_UID=$(echo "$CONFIG" | jq -r '.integrations.grafana.dashboard_uid // ""')
PUSH_GATEWAY=$(echo "$CONFIG" | jq -r '.reporting.metrics.push_gateway // ""')

if [ "$GRAFANA_ENABLED" != "true" ]; then
    echo -e "${YELLOW}⚠️  Grafana integration disabled${NC}"
    exit 0
fi

# Load scan results
load_scan_metrics() {
    local total_critical=0
    local total_high=0
    local total_medium=0
    local total_low=0
    local total_findings=0
    local scan_duration=0
    local files_scanned=0
    
    if [ -f "$RESULTS_DIR/overall-summary.json" ] && command -v jq >/dev/null 2>&1; then
        total_critical=$(jq '.total_vulnerabilities.critical // 0' "$RESULTS_DIR/overall-summary.json")
        total_high=$(jq '.total_vulnerabilities.high // 0' "$RESULTS_DIR/overall-summary.json")
        total_medium=$(jq '.total_vulnerabilities.medium // 0' "$RESULTS_DIR/overall-summary.json")
        total_low=$(jq '.total_vulnerabilities.low // 0' "$RESULTS_DIR/overall-summary.json")
        total_findings=$(jq '.total_findings // 0' "$RESULTS_DIR/overall-summary.json")
    fi
    
    # Export metrics for use in other functions
    export TOTAL_CRITICAL=$total_critical
    export TOTAL_HIGH=$total_high
    export TOTAL_MEDIUM=$total_medium
    export TOTAL_LOW=$total_low
    export TOTAL_FINDINGS=$total_findings
    export SCAN_DURATION=$scan_duration
    export FILES_SCANNED=$files_scanned
}

# Push metrics to Prometheus Push Gateway
push_prometheus_metrics() {
    if [ -z "$PUSH_GATEWAY" ]; then
        echo -e "${YELLOW}⚠️  Prometheus Push Gateway not configured${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📈 Pushing metrics to Prometheus...${NC}"
    
    local job_name="sast_scan"
    local instance="${GITHUB_REPOSITORY:-unknown}"
    
    # Create metrics payload
    local metrics_payload
    metrics_payload=$(cat << EOF
# HELP sast_vulnerabilities_total Total number of vulnerabilities found by SAST scans
# TYPE sast_vulnerabilities_total counter
sast_vulnerabilities_total{severity="critical",repository="$instance"} $TOTAL_CRITICAL
sast_vulnerabilities_total{severity="high",repository="$instance"} $TOTAL_HIGH
sast_vulnerabilities_total{severity="medium",repository="$instance"} $TOTAL_MEDIUM
sast_vulnerabilities_total{severity="low",repository="$instance"} $TOTAL_LOW

# HELP sast_scan_duration_seconds Time taken for SAST scans to complete
# TYPE sast_scan_duration_seconds histogram
sast_scan_duration_seconds{repository="$instance"} $SCAN_DURATION

# HELP sast_scan_status Status of the last SAST scan (1=success, 0=failure)
# TYPE sast_scan_status gauge
sast_scan_status{repository="$instance"} $([ "$SCAN_STATUS" = "success" ] && echo 1 || echo 0)

# HELP sast_files_scanned_total Total number of files scanned
# TYPE sast_files_scanned_total counter
sast_files_scanned_total{repository="$instance"} $FILES_SCANNED

# HELP sast_scan_timestamp_seconds Unix timestamp of the last scan
# TYPE sast_scan_timestamp_seconds gauge
sast_scan_timestamp_seconds{repository="$instance"} $(date +%s)
EOF
)
    
    # Push to Prometheus Push Gateway
    if command -v curl >/dev/null 2>&1; then
        if echo "$metrics_payload" | curl -s --data-binary @- \
           "$PUSH_GATEWAY/metrics/job/$job_name/instance/$instance"; then
            echo -e "${GREEN}✅ Metrics pushed to Prometheus successfully${NC}"
        else
            echo -e "${RED}❌ Failed to push metrics to Prometheus${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  curl not available for pushing metrics${NC}"
    fi
}

# Update Grafana dashboard annotations
create_grafana_annotation() {
    if [ -z "$GRAFANA_URL" ] || [ -z "${GRAFANA_API_KEY:-}" ]; then
        echo -e "${YELLOW}⚠️  Grafana URL or API key not configured${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📝 Creating Grafana annotation...${NC}"
    
    local annotation_text="SAST Scan ${SCAN_STATUS^^}"
    if [ "$SCAN_STATUS" = "failure" ]; then
        annotation_text="$annotation_text - $TOTAL_CRITICAL critical, $TOTAL_HIGH high vulnerabilities found"
    fi
    
    local annotation_payload
    annotation_payload=$(cat << EOF
{
  "time": $(date +%s)000,
  "timeEnd": $(date +%s)000,
  "text": "$annotation_text",
  "tags": ["sast", "security", "$SCAN_STATUS"],
  "dashboardUID": "$DASHBOARD_UID"
}
EOF
)
    
    if command -v curl >/dev/null 2>&1; then
        if curl -s -X POST \
           -H "Authorization: Bearer $GRAFANA_API_KEY" \
           -H "Content-Type: application/json" \
           --data "$annotation_payload" \
           "$GRAFANA_URL/api/annotations" > /dev/null; then
            echo -e "${GREEN}✅ Grafana annotation created successfully${NC}"
        else
            echo -e "${RED}❌ Failed to create Grafana annotation${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  curl not available for Grafana API calls${NC}"
    fi
}

# Create or update dashboard panel
update_dashboard_data() {
    if [ -z "$GRAFANA_URL" ] || [ -z "${GRAFANA_API_KEY:-}" ]; then
        echo -e "${YELLOW}⚠️  Grafana URL or API key not configured${NC}"
        return 0
    fi
    
    echo -e "${BLUE}🎯 Updating dashboard data...${NC}"
    
    # This would typically involve:
    # 1. Fetching existing dashboard configuration
    # 2. Updating data sources queries
    # 3. Updating dashboard JSON
    # 4. Posting updated dashboard back to Grafana
    
    # For this boilerplate, we'll create a simple dashboard update
    local dashboard_data
    dashboard_data=$(cat << EOF
{
  "dashboard": {
    "title": "SAST Security Dashboard",
    "tags": ["security", "sast"],
    "timezone": "utc",
    "panels": [
      {
        "title": "Vulnerability Counts",
        "type": "stat",
        "targets": [
          {
            "expr": "sast_vulnerabilities_total",
            "legendFormat": "{{severity}}"
          }
        ]
      },
      {
        "title": "Scan Status",
        "type": "stat",
        "targets": [
          {
            "expr": "sast_scan_status",
            "legendFormat": "Status"
          }
        ]
      },
      {
        "title": "Vulnerability Trends",
        "type": "graph",
        "targets": [
          {
            "expr": "increase(sast_vulnerabilities_total[1d])",
            "legendFormat": "{{severity}} (24h)"
          }
        ]
      }
    ],
    "time": {
      "from": "now-7d",
      "to": "now"
    },
    "refresh": "5m"
  },
  "overwrite": true
}
EOF
)
    
    # In a real implementation, you would:
    # curl -X POST -H "Authorization: Bearer $GRAFANA_API_KEY" \
    #      -H "Content-Type: application/json" \
    #      --data "$dashboard_data" \
    #      "$GRAFANA_URL/api/dashboards/db"
    
    echo -e "${GREEN}✅ Dashboard data structure prepared${NC}"
}

# Generate dashboard URL for easy access
generate_dashboard_url() {
    if [ -n "$GRAFANA_URL" ] && [ -n "$DASHBOARD_UID" ]; then
        local dashboard_url="$GRAFANA_URL/d/$DASHBOARD_UID/sast-security-dashboard"
        echo -e "${BLUE}🔗 Dashboard URL: $dashboard_url${NC}"
        
        # Set GitHub Actions output if available
        if [ -n "${GITHUB_OUTPUT:-}" ]; then
            echo "dashboard_url=$dashboard_url" >> "$GITHUB_OUTPUT"
        fi
    fi
}

# Export metrics to JSON for other tools
export_metrics_json() {
    local metrics_file="$RESULTS_DIR/grafana-metrics.json"
    
    cat > "$metrics_file" << EOF
{
  "timestamp": "$TIMESTAMP",
  "scan_status": "$SCAN_STATUS",
  "metrics": {
    "vulnerabilities": {
      "critical": $TOTAL_CRITICAL,
      "high": $TOTAL_HIGH,
      "medium": $TOTAL_MEDIUM,
      "low": $TOTAL_LOW,
      "total": $TOTAL_FINDINGS
    },
    "scan_info": {
      "duration_seconds": $SCAN_DURATION,
      "files_scanned": $FILES_SCANNED,
      "repository": "${GITHUB_REPOSITORY:-unknown}",
      "branch": "${GITHUB_REF_NAME:-unknown}",
      "commit": "${GITHUB_SHA:-unknown}"
    }
  }
}
EOF
    
    echo -e "${GREEN}✅ Metrics exported to $metrics_file${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}🚀 Starting Grafana dashboard update...${NC}"
    
    # Load scan metrics
    load_scan_metrics
    
    # Display current metrics
    echo -e "${BLUE}📊 Current Metrics:${NC}"
    echo "Critical: $TOTAL_CRITICAL"
    echo "High: $TOTAL_HIGH"
    echo "Medium: $TOTAL_MEDIUM"
    echo "Low: $TOTAL_LOW"
    echo "Total: $TOTAL_FINDINGS"
    echo "Status: $SCAN_STATUS"
    
    # Execute all updates
    {
        push_prometheus_metrics &
        create_grafana_annotation &
        update_dashboard_data &
        wait
    }
    
    # Generate outputs
    generate_dashboard_url
    export_metrics_json
    
    echo -e "${GREEN}✅ Grafana dashboard update completed${NC}"
}

# Execute main function
main "$@"
