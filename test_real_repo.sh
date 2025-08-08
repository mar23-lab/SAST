#!/bin/bash

# ===================================================================
# Real Repository SAST Testing Script
# ===================================================================
# Скрипт для тестирования SAST на реальном репозитории
# Usage: ./test_real_repo.sh <repo_url> [branch]

set -euo pipefail

REPO_URL="${1:-}"
BRANCH="${2:-main}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

show_usage() {
    cat << EOF
🔍 Real Repository SAST Testing

USAGE:
    ./test_real_repo.sh <repo_url> [branch]

EXAMPLES:
    ./test_real_repo.sh https://github.com/user/vulnerable-app
    ./test_real_repo.sh https://github.com/user/nodejs-app main
    ./test_real_repo.sh https://github.com/user/python-app develop

SUPPORTED LANGUAGES:
    - JavaScript/TypeScript (ESLint)
    - Python (Bandit)
    - Multiple languages (Semgrep)

EOF
}

if [ -z "$REPO_URL" ]; then
    show_usage
    exit 1
fi

echo -e "${BLUE}🔍 Testing SAST on Real Repository${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""
echo -e "${CYAN}Repository: $REPO_URL${NC}"
echo -e "${CYAN}Branch: $BRANCH${NC}"
echo -e "${CYAN}Timestamp: $TIMESTAMP${NC}"
echo ""

# Определяем имя репозитория
REPO_NAME=$(basename "$REPO_URL" .git)
WORK_DIR="/tmp/sast-test-$REPO_NAME-$(date +%s)"

echo -e "${BLUE}📥 Cloning repository...${NC}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if git clone -b "$BRANCH" "$REPO_URL" . 2>/dev/null; then
    echo -e "${GREEN}✅ Repository cloned successfully${NC}"
else
    echo -e "${RED}❌ Failed to clone repository${NC}"
    exit 1
fi

# Определяем тип проекта
detect_project_type() {
    local project_types=()
    
    if [ -f "package.json" ]; then
        project_types+=("JavaScript/Node.js")
    fi
    
    if find . -name "*.py" -type f | head -1 | grep -q .; then
        project_types+=("Python")
    fi
    
    if find . -name "*.java" -type f | head -1 | grep -q .; then
        project_types+=("Java")
    fi
    
    if find . -name "*.go" -type f | head -1 | grep -q .; then
        project_types+=("Go")
    fi
    
    if [ ${#project_types[@]} -eq 0 ]; then
        project_types+=("Generic")
    fi
    
    echo "${project_types[@]}"
}

PROJECT_TYPES=$(detect_project_type)
echo -e "${BLUE}📋 Detected project types: ${PROJECT_TYPES}${NC}"

# Подсчитаем файлы
TOTAL_FILES=$(find . -type f | wc -l | tr -d ' ')
CODE_FILES=$(find . \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" \) -type f | wc -l | tr -d ' ')
LINES_OF_CODE=$(find . \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.java" -o -name "*.go" \) -type f -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")

echo -e "${BLUE}📊 Repository statistics:${NC}"
echo "  Total files: $TOTAL_FILES"
echo "  Code files: $CODE_FILES"  
echo "  Lines of code: $LINES_OF_CODE"
echo ""

# Создаем директорию для результатов
RESULTS_DIR="$WORK_DIR/sast-results"
mkdir -p "$RESULTS_DIR"

# Функция для запуска Semgrep
run_semgrep() {
    echo -e "${BLUE}🔍 Running Semgrep scan...${NC}"
    
    if command -v semgrep >/dev/null 2>&1; then
        semgrep --config=auto --json --output="$RESULTS_DIR/semgrep-results.json" . 2>/dev/null || true
        
        if [ -f "$RESULTS_DIR/semgrep-results.json" ]; then
            local findings=$(jq '.results | length' "$RESULTS_DIR/semgrep-results.json" 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ Semgrep: $findings findings${NC}"
        else
            echo -e "${YELLOW}⚠️  Semgrep: No results file generated${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Semgrep not installed${NC}"
    fi
}

# Функция для запуска Bandit (Python)
run_bandit() {
    if [[ "$PROJECT_TYPES" == *"Python"* ]]; then
        echo -e "${BLUE}🐍 Running Bandit scan (Python)...${NC}"
        
        if command -v bandit >/dev/null 2>&1; then
            bandit -r . -f json -o "$RESULTS_DIR/bandit-results.json" 2>/dev/null || true
            
            if [ -f "$RESULTS_DIR/bandit-results.json" ]; then
                local findings=$(jq '.results | length' "$RESULTS_DIR/bandit-results.json" 2>/dev/null || echo "0")
                echo -e "${GREEN}✅ Bandit: $findings findings${NC}"
            else
                echo -e "${YELLOW}⚠️  Bandit: No results file generated${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Bandit not installed${NC}"
        fi
    fi
}

# Функция для запуска ESLint (JavaScript/TypeScript)
run_eslint() {
    if [[ "$PROJECT_TYPES" == *"JavaScript"* ]] && [ -f "package.json" ]; then
        echo -e "${BLUE}📜 Running ESLint scan (JavaScript/TypeScript)...${NC}"
        
        # Установим ESLint если есть package.json
        if command -v npm >/dev/null 2>&1; then
            npm install --no-save eslint @typescript-eslint/parser eslint-plugin-security 2>/dev/null || true
            
            # Создаем временный конфиг ESLint
            cat > .eslintrc.json << EOF
{
  "env": {
    "node": true,
    "es2021": true
  },
  "extends": ["eslint:recommended"],
  "plugins": ["security"],
  "rules": {
    "security/detect-object-injection": "error",
    "security/detect-non-literal-fs-filename": "error",
    "security/detect-unsafe-regex": "error",
    "security/detect-buffer-noassert": "error",
    "security/detect-child-process": "error",
    "security/detect-disable-mustache-escape": "error",
    "security/detect-eval-with-expression": "error",
    "security/detect-no-csrf-before-method-override": "error",
    "security/detect-non-literal-regexp": "error",
    "security/detect-possible-timing-attacks": "error",
    "security/detect-pseudoRandomBytes": "error"
  }
}
EOF
            
            npx eslint . --ext .js,.ts --format json --output-file "$RESULTS_DIR/eslint-results.json" 2>/dev/null || true
            
            if [ -f "$RESULTS_DIR/eslint-results.json" ]; then
                local findings=$(jq '[.[].messages[]] | length' "$RESULTS_DIR/eslint-results.json" 2>/dev/null || echo "0")
                echo -e "${GREEN}✅ ESLint: $findings findings${NC}"
            else
                echo -e "${YELLOW}⚠️  ESLint: No results file generated${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  npm not available for ESLint${NC}"
        fi
    fi
}

# Запускаем сканеры
echo -e "${BLUE}🚀 Starting SAST scans...${NC}"
echo ""

run_semgrep
run_bandit
run_eslint

echo ""
echo -e "${BLUE}📊 Processing results...${NC}"

# Обрабатываем результаты
total_critical=0
total_high=0
total_medium=0
total_low=0

# Обработка результатов Semgrep
if [ -f "$RESULTS_DIR/semgrep-results.json" ]; then
    critical=$(jq '[.results[] | select(.extra.severity == "ERROR")] | length' "$RESULTS_DIR/semgrep-results.json" 2>/dev/null || echo "0")
    high=$(jq '[.results[] | select(.extra.severity == "WARNING")] | length' "$RESULTS_DIR/semgrep-results.json" 2>/dev/null || echo "0")
    medium=$(jq '[.results[] | select(.extra.severity == "INFO")] | length' "$RESULTS_DIR/semgrep-results.json" 2>/dev/null || echo "0")
    
    total_critical=$((total_critical + critical))
    total_high=$((total_high + high))
    total_medium=$((total_medium + medium))
fi

# Обработка результатов Bandit
if [ -f "$RESULTS_DIR/bandit-results.json" ]; then
    high_bandit=$(jq '[.results[] | select(.issue_severity == "HIGH")] | length' "$RESULTS_DIR/bandit-results.json" 2>/dev/null || echo "0")
    medium_bandit=$(jq '[.results[] | select(.issue_severity == "MEDIUM")] | length' "$RESULTS_DIR/bandit-results.json" 2>/dev/null || echo "0")
    low_bandit=$(jq '[.results[] | select(.issue_severity == "LOW")] | length' "$RESULTS_DIR/bandit-results.json" 2>/dev/null || echo "0")
    
    total_high=$((total_high + high_bandit))
    total_medium=$((total_medium + medium_bandit))
    total_low=$((total_low + low_bandit))
fi

# Обработка результатов ESLint
if [ -f "$RESULTS_DIR/eslint-results.json" ]; then
    error_eslint=$(jq '[.[].messages[] | select(.severity == 2)] | length' "$RESULTS_DIR/eslint-results.json" 2>/dev/null || echo "0")
    warning_eslint=$(jq '[.[].messages[] | select(.severity == 1)] | length' "$RESULTS_DIR/eslint-results.json" 2>/dev/null || echo "0")
    
    total_high=$((total_high + error_eslint))
    total_medium=$((total_medium + warning_eslint))
fi

total_findings=$((total_critical + total_high + total_medium + total_low))

# Определяем статус
status="success"
if [ "$total_critical" -gt 0 ]; then
    status="failure"
elif [ "$total_high" -gt 5 ]; then
    status="failure"
fi

# Создаем общий отчет
cat > "$RESULTS_DIR/overall-summary.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "repository": "$REPO_URL",
  "branch": "$BRANCH",
  "scan_type": "real_repository",
  "status": "$status",
  "repository_info": {
    "name": "$REPO_NAME",
    "total_files": $TOTAL_FILES,
    "code_files": $CODE_FILES,
    "lines_of_code": $LINES_OF_CODE,
    "project_types": $(echo "$PROJECT_TYPES" | jq -R 'split(" ")')
  },
  "total_vulnerabilities": {
    "critical": $total_critical,
    "high": $total_high,
    "medium": $total_medium,
    "low": $total_low
  },
  "total_findings": $total_findings,
  "scanners_run": [
    "semgrep",
    "bandit",
    "eslint"
  ]
}
EOF

# Отображаем результаты
echo ""
echo -e "${BLUE}┌─────────────────────────────────────┐${NC}"
echo -e "${BLUE}│          Scan Results Summary       │${NC}"
echo -e "${BLUE}├─────────────────────────────────────┤${NC}"
echo -e "${BLUE}│${NC} 🔴 Critical: $(printf '%3d' $total_critical)                   ${BLUE}│${NC}"
echo -e "${BLUE}│${NC} 🟠 High:     $(printf '%3d' $total_high)                   ${BLUE}│${NC}"
echo -e "${BLUE}│${NC} 🟡 Medium:   $(printf '%3d' $total_medium)                   ${BLUE}│${NC}"
echo -e "${BLUE}│${NC} 🔵 Low:      $(printf '%3d' $total_low)                   ${BLUE}│${NC}"
echo -e "${BLUE}├─────────────────────────────────────┤${NC}"
echo -e "${BLUE}│${NC} 📊 Total:    $(printf '%3d' $total_findings)                   ${BLUE}│${NC}"

if [ "$status" = "success" ]; then
    echo -e "${BLUE}│${NC} ✅ Status:   ${GREEN}PASS${NC}                   ${BLUE}│${NC}"
else
    echo -e "${BLUE}│${NC} ❌ Status:   ${RED}FAIL${NC}                   ${BLUE}│${NC}"
fi

echo -e "${BLUE}└─────────────────────────────────────┘${NC}"

echo ""
echo -e "${BLUE}📁 Repository: $REPO_NAME${NC}"
echo -e "${BLUE}📏 Lines of Code: $LINES_OF_CODE${NC}"
echo -e "${BLUE}📄 Code Files: $CODE_FILES${NC}"
echo ""

# Копируем результаты в основную директорию SAST
echo -e "${BLUE}📤 Copying results to SAST directory...${NC}"
cp -r "$RESULTS_DIR"/* /app/sast-results/ 2>/dev/null || true

echo -e "${GREEN}✅ Real repository scan completed!${NC}"
echo ""
echo -e "${CYAN}📋 Next steps:${NC}"
echo "1. Send metrics to InfluxDB: ./scripts/influxdb_integration.sh $status"
echo "2. Update Grafana: ./scripts/update_grafana.sh $status"
echo "3. Send notifications: ./scripts/send_notifications.sh $status 'Real Repository Scan'"
echo ""
echo -e "${CYAN}📊 Results saved in: $RESULTS_DIR${NC}"

# Cleanup
cd /
rm -rf "$WORK_DIR"
