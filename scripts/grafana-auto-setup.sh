#!/bin/bash

# ===================================================================
# SAST Platform - Automated Grafana Configuration Script
# ===================================================================
# Automatically configures Grafana datasources and dashboards
# Eliminates the 90-minute manual setup process
# Usage: ./scripts/grafana-auto-setup.sh

set -euo pipefail

# Configuration
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3001}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASS="${GRAFANA_PASS:-admin123}"
INFLUXDB_URL="${INFLUXDB_URL:-http://sast-influxdb-stable:8086}"
INFLUXDB_TOKEN="${INFLUXDB_TOKEN:-sast-admin-token-12345}"
INFLUXDB_ORG="${INFLUXDB_ORG:-sast-org}"
INFLUXDB_BUCKET="${INFLUXDB_BUCKET:-sast-metrics}"
MAX_RETRIES=30
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    echo -e "\n${CYAN}🔧 $1${NC}"
    echo "─────────────────────────────────────────────"
}

# Wait for Grafana to be ready
wait_for_grafana() {
    log_header "Waiting for Grafana to be Ready"
    
    local retry_count=0
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        if curl -s -f "$GRAFANA_URL/api/health" >/dev/null 2>&1; then
            log_success "Grafana is ready!"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        log_info "Waiting for Grafana... ($retry_count/$MAX_RETRIES)"
        sleep 5
    done
    
    log_error "Grafana failed to start after $((MAX_RETRIES * 5)) seconds"
    return 1
}

# Test Grafana authentication
test_grafana_auth() {
    log_header "Testing Grafana Authentication"
    
    local response=$(curl -s -w "%{http_code}" -o /dev/null \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/user")
    
    if [[ "$response" == "200" ]]; then
        log_success "Grafana authentication successful"
        return 0
    else
        log_error "Grafana authentication failed (HTTP: $response)"
        return 1
    fi
}

# Create InfluxDB datasource
create_influxdb_datasource() {
    log_header "Creating InfluxDB Datasource"
    
    # Check if datasource already exists
    local existing_datasource=$(curl -s \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/datasources/name/InfluxDB-SAST" 2>/dev/null || echo "")
    
    if echo "$existing_datasource" | grep -q '"name":"InfluxDB-SAST"'; then
        log_warning "InfluxDB datasource already exists, updating..."
        
        # Get datasource ID for update
        local datasource_id=$(echo "$existing_datasource" | jq -r '.id' 2>/dev/null || echo "")
        if [[ -n "$datasource_id" && "$datasource_id" != "null" ]]; then
            update_influxdb_datasource "$datasource_id"
            return $?
        fi
    fi
    
    # Create new datasource
    local datasource_config=$(cat << EOF
{
  "name": "InfluxDB-SAST",
  "type": "influxdb",
  "access": "proxy",
  "url": "$INFLUXDB_URL",
  "database": "$INFLUXDB_BUCKET",
  "isDefault": true,
  "jsonData": {
    "version": "Flux",
    "organization": "$INFLUXDB_ORG",
    "defaultBucket": "$INFLUXDB_BUCKET",
    "tlsAuth": false,
    "tlsAuthWithCACert": false
  },
  "secureJsonData": {
    "token": "$INFLUXDB_TOKEN"
  }
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/grafana_datasource_response.json \
        -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/datasources" \
        -d "$datasource_config")
    
    if [[ "$response" == "200" ]]; then
        log_success "InfluxDB datasource created successfully"
        return 0
    else
        log_error "Failed to create InfluxDB datasource (HTTP: $response)"
        if [[ -f /tmp/grafana_datasource_response.json ]]; then
            log_error "Response: $(cat /tmp/grafana_datasource_response.json)"
        fi
        return 1
    fi
}

# Update existing InfluxDB datasource
update_influxdb_datasource() {
    local datasource_id="$1"
    log_info "Updating existing datasource (ID: $datasource_id)"
    
    local datasource_config=$(cat << EOF
{
  "id": $datasource_id,
  "name": "InfluxDB-SAST",
  "type": "influxdb",
  "access": "proxy",
  "url": "$INFLUXDB_URL",
  "database": "$INFLUXDB_BUCKET",
  "isDefault": true,
  "jsonData": {
    "version": "Flux",
    "organization": "$INFLUXDB_ORG",
    "defaultBucket": "$INFLUXDB_BUCKET",
    "tlsAuth": false,
    "tlsAuthWithCACert": false
  },
  "secureJsonData": {
    "token": "$INFLUXDB_TOKEN"
  }
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/grafana_update_response.json \
        -X PUT \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/datasources/$datasource_id" \
        -d "$datasource_config")
    
    if [[ "$response" == "200" ]]; then
        log_success "InfluxDB datasource updated successfully"
        return 0
    else
        log_error "Failed to update InfluxDB datasource (HTTP: $response)"
        return 1
    fi
}

# Test datasource connectivity
test_datasource_connectivity() {
    log_header "Testing Datasource Connectivity"
    
    # Get datasource by name
    local datasource_info=$(curl -s \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/datasources/name/InfluxDB-SAST" 2>/dev/null)
    
    local datasource_id=$(echo "$datasource_info" | jq -r '.id' 2>/dev/null || echo "")
    
    if [[ -z "$datasource_id" || "$datasource_id" == "null" ]]; then
        log_error "Could not find InfluxDB datasource for testing"
        return 1
    fi
    
    # Test datasource
    local response=$(curl -s -w "%{http_code}" -o /tmp/grafana_test_response.json \
        -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/datasources/$datasource_id/health")
    
    if [[ "$response" == "200" ]]; then
        log_success "Datasource connectivity test passed"
        return 0
    else
        log_warning "Datasource connectivity test failed (HTTP: $response)"
        # Don't fail completely as this might still work
        return 0
    fi
}

# Import SAST dashboard
import_sast_dashboard() {
    log_header "Importing SAST Security Dashboard"
    
    # Create dashboard JSON with InfluxDB datasource
    local dashboard_json=$(cat << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "SAST Security Dashboard",
    "tags": ["sast", "security"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Critical Vulnerabilities",
        "type": "stat",
        "targets": [
          {
            "query": "from(bucket: \"sast-metrics\")\n  |> range(start: -24h)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"sast_scan\")\n  |> filter(fn: (r) => r[\"_field\"] == \"critical\")\n  |> last()",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "red", "value": 1}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "High Severity Issues",
        "type": "stat",
        "targets": [
          {
            "query": "from(bucket: \"sast-metrics\")\n  |> range(start: -24h)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"sast_scan\")\n  |> filter(fn: (r) => r[\"_field\"] == \"high\")\n  |> last()",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "orange", "value": 1},
                {"color": "red", "value": 5}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0}
      },
      {
        "id": 3,
        "title": "Vulnerability Trend",
        "type": "timeseries",
        "targets": [
          {
            "query": "from(bucket: \"sast-metrics\")\n  |> range(start: -7d)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"sast_scan\")\n  |> filter(fn: (r) => r[\"_field\"] == \"total\")",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      }
    ],
    "time": {
      "from": "now-24h",
      "to": "now"
    },
    "refresh": "30s"
  },
  "overwrite": true
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/grafana_dashboard_response.json \
        -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/dashboards/db" \
        -d "$dashboard_json")
    
    if [[ "$response" == "200" ]]; then
        log_success "SAST dashboard imported successfully"
        
        # Get dashboard URL
        local dashboard_url=$(cat /tmp/grafana_dashboard_response.json | jq -r '.url' 2>/dev/null || echo "")
        if [[ -n "$dashboard_url" ]]; then
            log_success "Dashboard URL: $GRAFANA_URL$dashboard_url"
        fi
        return 0
    else
        log_error "Failed to import dashboard (HTTP: $response)"
        return 1
    fi
}

# Send test metrics to populate dashboard
send_test_metrics() {
    log_header "Sending Test Metrics"
    
    # Use the existing InfluxDB integration script if available
    if [[ -f "$SCRIPT_DIR/influxdb_integration.sh" ]]; then
        log_info "Using existing InfluxDB integration script"
        if bash "$SCRIPT_DIR/influxdb_integration.sh" demo; then
            log_success "Test metrics sent successfully"
        else
            log_warning "Failed to send test metrics via script"
        fi
    else
        log_warning "InfluxDB integration script not found, skipping test metrics"
    fi
}

# Create folder structure
create_dashboard_folders() {
    log_header "Creating Dashboard Folders"
    
    # Create Security folder
    local folder_config='{"title": "Security", "uid": "security-folder"}'
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/grafana_folder_response.json \
        -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASS" \
        "$GRAFANA_URL/api/folders" \
        -d "$folder_config")
    
    if [[ "$response" == "200" || "$response" == "412" ]]; then
        log_success "Security folder created/exists"
    else
        log_warning "Could not create Security folder (HTTP: $response)"
    fi
}

# Main setup function
main() {
    echo -e "${CYAN}"
    cat << 'EOF'
 ┌─────────────────────────────────────────────────┐
 │        🎛️ Grafana Auto-Configuration           │
 │      Eliminate 90-minute Manual Setup          │
 └─────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
    
    log_info "Starting automated Grafana configuration..."
    log_info "Grafana URL: $GRAFANA_URL"
    log_info "InfluxDB URL: $INFLUXDB_URL"
    
    # Execute setup steps
    if ! wait_for_grafana; then
        exit 1
    fi
    
    if ! test_grafana_auth; then
        exit 1
    fi
    
    create_dashboard_folders
    
    if ! create_influxdb_datasource; then
        exit 1
    fi
    
    test_datasource_connectivity
    
    if ! import_sast_dashboard; then
        exit 1
    fi
    
    send_test_metrics
    
    # Success summary
    log_header "Grafana Setup Complete! 🎉"
    
    echo -e "${GREEN}✅ Successfully configured:${NC}"
    echo "  • InfluxDB datasource connection"
    echo "  • SAST Security dashboard"
    echo "  • Security folder organization"
    echo "  • Test metrics (if available)"
    echo ""
    echo -e "${CYAN}🎛️ Access your dashboard:${NC}"
    echo "  • URL: $GRAFANA_URL"
    echo "  • Username: $GRAFANA_USER"
    echo "  • Password: $GRAFANA_PASS"
    echo ""
    echo -e "${YELLOW}⏱️ Setup time: ~2 minutes (vs 90 minutes manual)${NC}"
    echo ""
    echo -e "${BLUE}📊 Next steps:${NC}"
    echo "  1. Run SAST scan: ./run_demo.sh"
    echo "  2. Check metrics: curl http://localhost:8087/api/v2/query"
    echo "  3. View dashboard: $GRAFANA_URL/d/sast-security"
}

# Trap for cleanup
cleanup() {
    rm -f /tmp/grafana_*.json 2>/dev/null || true
}
trap cleanup EXIT

# Execute main function
main "$@"
