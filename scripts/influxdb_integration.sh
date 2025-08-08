#!/bin/bash

# ===================================================================
# InfluxDB Integration Script
# ===================================================================
# Скрипт для отправки метрик SAST в InfluxDB
# Usage: ./influxdb_integration.sh <scan_status> [additional_data]

set -euo pipefail

SCAN_STATUS="${1:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RESULTS_DIR="./sast-results"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Отправка метрик в InfluxDB...${NC}"

# Конфигурация InfluxDB
INFLUXDB_URL="${INFLUXDB_URL:-http://localhost:8086}"
INFLUXDB_TOKEN="${INFLUXDB_TOKEN:-}"
INFLUXDB_ORG="${INFLUXDB_ORG:-sast-org}"
INFLUXDB_BUCKET="${INFLUXDB_BUCKET:-sast-metrics}"

# Проверка конфигурации
if [ -z "$INFLUXDB_TOKEN" ]; then
    echo -e "${RED}❌ INFLUXDB_TOKEN не установлен${NC}"
    exit 1
fi

# Загрузка метрик сканирования
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
        files_scanned=$(jq '.files_scanned // 0' "$RESULTS_DIR/overall-summary.json")
    fi
    
    # Экспорт метрик для использования в других функциях
    export TOTAL_CRITICAL=$total_critical
    export TOTAL_HIGH=$total_high
    export TOTAL_MEDIUM=$total_medium
    export TOTAL_LOW=$total_low
    export TOTAL_FINDINGS=$total_findings
    export SCAN_DURATION=$scan_duration
    export FILES_SCANNED=$files_scanned
}

# Отправка метрик в InfluxDB
send_metrics_to_influxdb() {
    echo -e "${BLUE}📈 Отправка метрик в InfluxDB...${NC}"
    
    local repository="${GITHUB_REPOSITORY:-unknown}"
    local branch="${GITHUB_REF_NAME:-unknown}"
    local commit="${GITHUB_SHA:-unknown}"
    local timestamp_ns=$(date +%s)000000000  # Nanoseconds
    
    # Создание линейного протокола InfluxDB
    local metrics_data
    metrics_data=$(cat << EOF
sast_vulnerabilities,repository=$repository,branch=$branch,severity=critical value=${TOTAL_CRITICAL}i ${timestamp_ns}
sast_vulnerabilities,repository=$repository,branch=$branch,severity=high value=${TOTAL_HIGH}i ${timestamp_ns}
sast_vulnerabilities,repository=$repository,branch=$branch,severity=medium value=${TOTAL_MEDIUM}i ${timestamp_ns}
sast_vulnerabilities,repository=$repository,branch=$branch,severity=low value=${TOTAL_LOW}i ${timestamp_ns}
sast_scan_status,repository=$repository,branch=$branch value=$([ "$SCAN_STATUS" = "success" ] && echo 1 || echo 0)i ${timestamp_ns}
sast_scan_duration,repository=$repository,branch=$branch value=${SCAN_DURATION} ${timestamp_ns}
sast_files_scanned,repository=$repository,branch=$branch value=${FILES_SCANNED}i ${timestamp_ns}
sast_total_findings,repository=$repository,branch=$branch value=${TOTAL_FINDINGS}i ${timestamp_ns}
EOF
)
    
    # Отправка в InfluxDB
    if command -v curl >/dev/null 2>&1; then
        local response
        response=$(curl -s -w "%{http_code}" \
            -X POST \
            -H "Authorization: Token $INFLUXDB_TOKEN" \
            -H "Content-Type: text/plain; charset=utf-8" \
            --data "$metrics_data" \
            "$INFLUXDB_URL/api/v2/write?org=$INFLUXDB_ORG&bucket=$INFLUXDB_BUCKET&precision=ns")
        
        local http_code="${response: -3}"
        if [ "$http_code" = "204" ]; then
            echo -e "${GREEN}✅ Метрики успешно отправлены в InfluxDB${NC}"
        else
            echo -e "${RED}❌ Ошибка отправки метрик в InfluxDB (HTTP $http_code)${NC}"
            echo "Response: ${response%???}"
        fi
    else
        echo -e "${YELLOW}⚠️  curl недоступен для отправки метрик${NC}"
    fi
}

# Создание дашборда в Grafana (опционально)
create_grafana_dashboard() {
    if [ -n "${GRAFANA_URL:-}" ] && [ -n "${GRAFANA_API_KEY:-}" ]; then
        echo -e "${BLUE}📊 Создание/обновление дашборда Grafana...${NC}"
        
        local dashboard_json
        dashboard_json=$(cat << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "SAST Security Metrics (InfluxDB)",
    "tags": ["sast", "security", "influxdb"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Vulnerabilities by Severity",
        "type": "timeseries",
        "targets": [
          {
            "query": "from(bucket: \"sast-metrics\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"sast_vulnerabilities\")\n  |> group(columns: [\"severity\"])",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Scan Status",
        "type": "stat",
        "targets": [
          {
            "query": "from(bucket: \"sast-metrics\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"sast_scan_status\")\n  |> last()",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
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
        
        if curl -s -X POST \
           -H "Authorization: Bearer $GRAFANA_API_KEY" \
           -H "Content-Type: application/json" \
           --data "$dashboard_json" \
           "$GRAFANA_URL/api/dashboards/db" > /dev/null; then
            echo -e "${GREEN}✅ Дашборд Grafana обновлен${NC}"
        else
            echo -e "${RED}❌ Ошибка обновления дашборда Grafana${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Grafana не настроена для создания дашборда${NC}"
    fi
}

# Экспорт метрик в JSON для других инструментов
export_metrics_json() {
    local metrics_file="$RESULTS_DIR/influxdb-metrics.json"
    
    cat > "$metrics_file" << EOF
{
  "timestamp": "$TIMESTAMP",
  "scan_status": "$SCAN_STATUS",
  "influxdb": {
    "url": "$INFLUXDB_URL",
    "org": "$INFLUXDB_ORG",
    "bucket": "$INFLUXDB_BUCKET"
  },
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
    
    echo -e "${GREEN}✅ Метрики экспортированы в $metrics_file${NC}"
}

# Основная функция
main() {
    echo -e "${GREEN}🚀 Начало интеграции с InfluxDB...${NC}"
    
    # Загрузка метрик сканирования
    load_scan_metrics
    
    # Отображение текущих метрик
    echo -e "${BLUE}📊 Текущие метрики:${NC}"
    echo "Critical: $TOTAL_CRITICAL"
    echo "High: $TOTAL_HIGH"
    echo "Medium: $TOTAL_MEDIUM"
    echo "Low: $TOTAL_LOW"
    echo "Total: $TOTAL_FINDINGS"
    echo "Status: $SCAN_STATUS"
    
    # Выполнение всех операций
    {
        send_metrics_to_influxdb &
        create_grafana_dashboard &
        wait
    }
    
    # Экспорт результатов
    export_metrics_json
    
    echo -e "${GREEN}✅ Интеграция с InfluxDB завершена${NC}"
}

# Запуск основной функции
main "$@"
