#!/bin/bash

# ===================================================================
# Email Demo Setup Script
# ===================================================================
# Скрипт для настройки и тестирования email уведомлений с MailHog
# Usage: ./setup_email_demo.sh

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📧 Настройка demo email окружения...${NC}"

# Конфигурация для MailHog
MAILHOG_SMTP_HOST="${EMAIL_SMTP_SERVER:-localhost}"
MAILHOG_SMTP_PORT="${EMAIL_SMTP_PORT:-1025}"
MAILHOG_WEB_PORT="8025"

# Обновление конфигурации для demo режима
update_config_for_email_demo() {
    echo -e "${BLUE}🔧 Обновление конфигурации для email demo...${NC}"
    
    # Создание временного конфигурационного файла для demo
    local demo_config_file="ci-config-email-demo.yaml"
    
    # Копируем базовую конфигурацию
    cp ci-config.yaml "$demo_config_file"
    
    # Обновляем email настройки для demo
    if command -v yq >/dev/null 2>&1; then
        yq eval '.demo_mode.enabled = true' -i "$demo_config_file"
        yq eval '.notifications.email.enabled = true' -i "$demo_config_file"
        yq eval '.notifications.email.smtp_server = "'"$MAILHOG_SMTP_HOST"'"' -i "$demo_config_file"
        yq eval '.notifications.email.smtp_port = '"$MAILHOG_SMTP_PORT"'' -i "$demo_config_file"
        yq eval '.notifications.email.sender_email = "sast-demo@test.local"' -i "$demo_config_file"
        yq eval '.notifications.email.sender_name = "SAST Demo Bot"' -i "$demo_config_file"
        yq eval '.notifications.email.recipients = ["security-team@test.local", "devops-team@test.local"]' -i "$demo_config_file"
        yq eval '.notifications.email.subject_prefix = "[🧪 SAST DEMO]"' -i "$demo_config_file"
        yq eval '.notifications.trigger = "always"' -i "$demo_config_file"
        
        echo -e "${GREEN}✅ Конфигурация обновлена для email demo${NC}"
    else
        echo -e "${YELLOW}⚠️  yq не найден, используется базовая конфигурация${NC}"
    fi
    
    export EMAIL_DEMO_CONFIG="$demo_config_file"
}

# Создание HTML шаблона для email
create_email_template() {
    echo -e "${BLUE}📝 Создание HTML шаблона для email...${NC}"
    
    mkdir -p templates
    
    cat > templates/email-notification.html << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SAST Scan Results</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background: #2c3e50;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px 5px 0 0;
        }
        .content {
            background: #f9f9f9;
            padding: 20px;
            border: 1px solid #ddd;
        }
        .status {
            padding: 10px;
            border-radius: 5px;
            text-align: center;
            font-weight: bold;
            margin: 10px 0;
        }
        .status.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.failure {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 10px;
            margin: 20px 0;
        }
        .metric {
            background: white;
            padding: 15px;
            border-radius: 5px;
            text-align: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .metric .value {
            font-size: 2em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .metric .label {
            color: #666;
            font-size: 0.9em;
        }
        .critical { color: #dc3545; }
        .high { color: #fd7e14; }
        .medium { color: #ffc107; }
        .low { color: #6c757d; }
        .footer {
            background: #34495e;
            color: white;
            padding: 15px;
            text-align: center;
            border-radius: 0 0 5px 5px;
            font-size: 0.9em;
        }
        .demo-badge {
            background: #17a2b8;
            color: white;
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 0.8em;
            display: inline-block;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="demo-badge">🧪 DEMO MODE</div>
        <h1>{{SCAN_TITLE}}</h1>
        <p>{{REPOSITORY}} • {{BRANCH}} • {{TIMESTAMP}}</p>
    </div>
    
    <div class="content">
        <div class="status {{STATUS_CLASS}}">
            {{STATUS_EMOJI}} Status: {{STATUS}}
        </div>
        
        <h3>📊 Vulnerability Summary</h3>
        <div class="metrics">
            <div class="metric">
                <div class="value critical">{{CRITICAL_COUNT}}</div>
                <div class="label">🔴 Critical</div>
            </div>
            <div class="metric">
                <div class="value high">{{HIGH_COUNT}}</div>
                <div class="label">🟠 High</div>
            </div>
            <div class="metric">
                <div class="value medium">{{MEDIUM_COUNT}}</div>
                <div class="label">🟡 Medium</div>
            </div>
            <div class="metric">
                <div class="value low">{{LOW_COUNT}}</div>
                <div class="label">🔵 Low</div>
            </div>
        </div>
        
        <h3>📋 Scan Details</h3>
        <ul>
            <li><strong>Total Findings:</strong> {{TOTAL_FINDINGS}}</li>
            <li><strong>Files Scanned:</strong> {{FILES_SCANNED}}</li>
            <li><strong>Scan Duration:</strong> {{SCAN_DURATION}}</li>
            <li><strong>Scanners Used:</strong> {{SCANNERS_USED}}</li>
        </ul>
        
        {{#if CUSTOM_MESSAGE}}
        <h3>ℹ️ Additional Information</h3>
        <p>{{CUSTOM_MESSAGE}}</p>
        {{/if}}
        
        <p>
            <a href="{{GITHUB_URL}}" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                📂 View Repository
            </a>
            {{#if DASHBOARD_URL}}
            <a href="{{DASHBOARD_URL}}" style="background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-left: 10px;">
                📊 View Dashboard
            </a>
            {{/if}}
        </p>
    </div>
    
    <div class="footer">
        <p>🧪 This is a demonstration email generated by SAST Demo Mode</p>
        <p>Generated at {{TIMESTAMP}} • Powered by SAST Security Boilerplate</p>
    </div>
</body>
</html>
EOF

    echo -e "${GREEN}✅ HTML шаблон создан${NC}"
}

# Функция для отправки тестового email
send_test_email() {
    local status="${1:-success}"
    local scenario="${2:-normal}"
    
    echo -e "${BLUE}📧 Отправка тестового email (status: $status, scenario: $scenario)...${NC}"
    
    # Загружаем demo данные
    local critical=1 high=3 medium=8 low=5
    case "$scenario" in
        "critical")
            critical=5; high=12; medium=25; low=10
            ;;
        "failure")
            critical=0; high=0; medium=0; low=0
            ;;
        "success")
            critical=0; high=0; medium=2; low=3
            ;;
    esac
    
    local total=$((critical + high + medium + low))
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local repository="${GITHUB_REPOSITORY:-demo/sast-boilerplate}"
    local branch="${GITHUB_REF_NAME:-main}"
    
    # Создание содержимого email
    local email_subject="[🧪 SAST DEMO] ${status^^} - $repository"
    local email_body
    email_body=$(cat << EOF
Subject: $email_subject
From: SAST Demo Bot <sast-demo@test.local>
To: security-team@test.local, devops-team@test.local
Content-Type: text/html; charset=UTF-8

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background: #2c3e50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .status { padding: 10px; border-radius: 5px; text-align: center; font-weight: bold; margin: 10px 0; }
        .success { background: #d4edda; color: #155724; }
        .failure { background: #f8d7da; color: #721c24; }
        .metrics { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin: 20px 0; }
        .metric { background: white; padding: 15px; text-align: center; border-radius: 5px; }
        .demo-badge { background: #17a2b8; color: white; padding: 5px 10px; border-radius: 15px; font-size: 0.8em; }
    </style>
</head>
<body>
    <div class="header">
        <div class="demo-badge">🧪 DEMO MODE</div>
        <h1>SAST Scan Report</h1>
        <p>$repository • $branch • $timestamp</p>
    </div>
    
    <div class="content">
        <div class="status $([ "$status" = "success" ] && echo "success" || echo "failure")">
            $([ "$status" = "success" ] && echo "✅" || echo "❌") Status: ${status^^}
        </div>
        
        <h3>📊 Vulnerability Summary</h3>
        <div class="metrics">
            <div class="metric">
                <div style="font-size: 2em; color: #dc3545;">$critical</div>
                <div>🔴 Critical</div>
            </div>
            <div class="metric">
                <div style="font-size: 2em; color: #fd7e14;">$high</div>
                <div>🟠 High</div>
            </div>
            <div class="metric">
                <div style="font-size: 2em; color: #ffc107;">$medium</div>
                <div>🟡 Medium</div>
            </div>
            <div class="metric">
                <div style="font-size: 2em; color: #6c757d;">$low</div>
                <div>🔵 Low</div>
            </div>
        </div>
        
        <h3>📋 Scan Details</h3>
        <ul>
            <li><strong>Total Findings:</strong> $total</li>
            <li><strong>Files Scanned:</strong> 247</li>
            <li><strong>Scan Duration:</strong> 2m 15s</li>
            <li><strong>Scanners Used:</strong> CodeQL, Semgrep, Bandit, ESLint</li>
        </ul>
        
        <p>
            <a href="https://github.com/$repository" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                📂 View Repository
            </a>
            <a href="http://localhost:3000/d/sast-security-dashboard" style="background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-left: 10px;">
                📊 View Dashboard
            </a>
        </p>
    </div>
    
    <div style="background: #34495e; color: white; padding: 15px; text-align: center; font-size: 0.9em;">
        <p>🧪 This is a demonstration email generated by SAST Demo Mode</p>
        <p>Generated at $timestamp • Powered by SAST Security Boilerplate</p>
    </div>
</body>
</html>
EOF
)
    
    # Отправка email через MailHog
    if command -v curl >/dev/null 2>&1; then
        if echo "$email_body" | curl -s --url "smtp://$MAILHOG_SMTP_HOST:$MAILHOG_SMTP_PORT" \
           --mail-from "sast-demo@test.local" \
           --mail-rcpt "security-team@test.local" \
           --mail-rcpt "devops-team@test.local" \
           --upload-file - > /dev/null; then
            echo -e "${GREEN}✅ Тестовый email отправлен успешно${NC}"
            echo -e "${BLUE}🌐 Проверьте MailHog Web UI: http://localhost:$MAILHOG_WEB_PORT${NC}"
        else
            echo -e "${RED}❌ Ошибка отправки email${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  curl недоступен для отправки email${NC}"
    fi
}

# Проверка доступности MailHog
check_mailhog_status() {
    echo -e "${BLUE}🔍 Проверка статуса MailHog...${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        if curl -s "http://localhost:$MAILHOG_WEB_PORT" > /dev/null; then
            echo -e "${GREEN}✅ MailHog Web UI доступен на порту $MAILHOG_WEB_PORT${NC}"
        else
            echo -e "${YELLOW}⚠️  MailHog Web UI недоступен${NC}"
        fi
        
        if curl -s "smtp://localhost:$MAILHOG_SMTP_PORT" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ MailHog SMTP сервер доступен на порту $MAILHOG_SMTP_PORT${NC}"
        else
            echo -e "${YELLOW}⚠️  MailHog SMTP сервер недоступен${NC}"
        fi
    fi
}

# Демонстрация различных сценариев
demo_email_scenarios() {
    echo -e "${BLUE}📧 Демонстрация различных email сценариев...${NC}"
    
    echo -e "${CYAN}1. Успешное сканирование...${NC}"
    send_test_email "success" "success"
    sleep 2
    
    echo -e "${CYAN}2. Сканирование с критическими уязвимостями...${NC}"
    send_test_email "failure" "critical"
    sleep 2
    
    echo -e "${CYAN}3. Неудачное сканирование...${NC}"
    send_test_email "failure" "failure"
    sleep 2
    
    echo -e "${CYAN}4. Обычное сканирование...${NC}"
    send_test_email "success" "normal"
    
    echo -e "${GREEN}✅ Все demo emails отправлены${NC}"
    echo -e "${BLUE}🌐 Откройте MailHog Web UI для просмотра: http://localhost:$MAILHOG_WEB_PORT${NC}"
}

# Основная функция
main() {
    echo -e "${GREEN}🚀 Запуск email demo setup...${NC}"
    
    # Обновляем конфигурацию
    update_config_for_email_demo
    
    # Создаем шаблон
    create_email_template
    
    # Проверяем статус MailHog
    check_mailhog_status
    
    echo
    echo -e "${BLUE}Выберите действие:${NC}"
    echo "1) Отправить один тестовый email"
    echo "2) Демонстрация всех сценариев"
    echo "3) Только проверить статус MailHog"
    echo "4) Выход"
    
    read -p "Введите выбор (1-4): " choice
    
    case $choice in
        1)
            echo "Выберите сценарий:"
            echo "1) Success"
            echo "2) Critical vulnerabilities"
            echo "3) Scan failure"
            echo "4) Normal scan"
            read -p "Сценарий (1-4): " scenario_choice
            
            case $scenario_choice in
                1) send_test_email "success" "success" ;;
                2) send_test_email "failure" "critical" ;;
                3) send_test_email "failure" "failure" ;;
                4) send_test_email "success" "normal" ;;
                *) echo "Неверный выбор" ;;
            esac
            ;;
        2)
            demo_email_scenarios
            ;;
        3)
            check_mailhog_status
            ;;
        4)
            echo "Выход..."
            exit 0
            ;;
        *)
            echo "Неверный выбор"
            ;;
    esac
    
    echo -e "${GREEN}✅ Email demo setup завершен${NC}"
}

# Запуск основной функции
main "$@"
