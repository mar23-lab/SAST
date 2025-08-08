#!/bin/bash

# ===================================================================
# Notification Sending Script
# ===================================================================
# This script sends notifications via email, Slack, Jira, and Teams
# Usage: ./send_notifications.sh <status> [pipeline_type] [custom_message]

set -euo pipefail

STATUS="${1:-unknown}"
PIPELINE_TYPE="${2:-SAST Scan}"
CUSTOM_MESSAGE="${3:-}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RESULTS_DIR="./sast-results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load configuration from environment variable or file
if [ -n "${CONFIG_JSON:-}" ]; then
    CONFIG="$CONFIG_JSON"
elif [ -f "ci-config.yaml" ] && command -v yq >/dev/null 2>&1; then
    CONFIG=$(yq -o=json ci-config.yaml)
else
    echo -e "${RED}❌ No configuration available${NC}"
    exit 1
fi

echo -e "${BLUE}📨 Sending notifications for $PIPELINE_TYPE...${NC}"

# Extract configuration values
NOTIFICATIONS_ENABLED=$(echo "$CONFIG" | jq -r '.notifications.enabled // true')
NOTIFICATION_TRIGGER=$(echo "$CONFIG" | jq -r '.notifications.trigger // "on_failure"')

# Check if notifications should be sent based on trigger settings
should_send_notification() {
    case "$NOTIFICATION_TRIGGER" in
        "always")
            return 0
            ;;
        "on_failure")
            [ "$STATUS" = "failure" ] && return 0 || return 1
            ;;
        "on_success")
            [ "$STATUS" = "success" ] && return 0 || return 1
            ;;
        "never")
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Generate message content
generate_message_content() {
    local format="$1"
    
    # Load summary data if available
    local total_critical=0
    local total_high=0
    local total_medium=0
    local total_low=0
    local total_findings=0
    
    if [ -f "$RESULTS_DIR/overall-summary.json" ] && command -v jq >/dev/null 2>&1; then
        total_critical=$(jq '.total_vulnerabilities.critical // 0' "$RESULTS_DIR/overall-summary.json")
        total_high=$(jq '.total_vulnerabilities.high // 0' "$RESULTS_DIR/overall-summary.json")
        total_medium=$(jq '.total_vulnerabilities.medium // 0' "$RESULTS_DIR/overall-summary.json")
        total_low=$(jq '.total_vulnerabilities.low // 0' "$RESULTS_DIR/overall-summary.json")
        total_findings=$(jq '.total_findings // 0' "$RESULTS_DIR/overall-summary.json")
    fi
    
    # Status emoji
    local status_emoji="🔍"
    case "$STATUS" in
        "success") status_emoji="✅" ;;
        "failure") status_emoji="❌" ;;
        "warning") status_emoji="⚠️" ;;
    esac
    
    case "$format" in
        "slack")
            cat << EOF
{
  "text": "$status_emoji $PIPELINE_TYPE Status: ${STATUS^^}",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "$status_emoji $PIPELINE_TYPE Status: ${STATUS^^}"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Repository:*\n\${GITHUB_REPOSITORY:-Unknown}"
        },
        {
          "type": "mrkdwn",
          "text": "*Branch:*\n\${GITHUB_REF_NAME:-Unknown}"
        },
        {
          "type": "mrkdwn",
          "text": "*Commit:*\n\${GITHUB_SHA:-Unknown}"
        },
        {
          "type": "mrkdwn",
          "text": "*Timestamp:*\n$TIMESTAMP"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Vulnerability Summary:*\n🔴 Critical: $total_critical\n🟠 High: $total_high\n🟡 Medium: $total_medium\n🔵 Low: $total_low\n\n*Total Findings:* $total_findings"
      }
    }
EOF
            if [ -n "$CUSTOM_MESSAGE" ]; then
                cat << EOF
    ,
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Additional Information:*\n$CUSTOM_MESSAGE"
      }
    }
EOF
            fi
            cat << EOF
  ]
}
EOF
            ;;
        "email")
            cat << EOF
Subject: [$PIPELINE_TYPE] ${STATUS^^} - \${GITHUB_REPOSITORY:-Repository}

$status_emoji $PIPELINE_TYPE Status: ${STATUS^^}

Repository: \${GITHUB_REPOSITORY:-Unknown}
Branch: \${GITHUB_REF_NAME:-Unknown}
Commit: \${GITHUB_SHA:-Unknown}
Timestamp: $TIMESTAMP

Vulnerability Summary:
🔴 Critical: $total_critical
🟠 High: $total_high
🟡 Medium: $total_medium
🔵 Low: $total_low

Total Findings: $total_findings

EOF
            if [ -n "$CUSTOM_MESSAGE" ]; then
                echo "Additional Information:"
                echo "$CUSTOM_MESSAGE"
                echo ""
            fi
            
            echo "View full results: \${GITHUB_SERVER_URL:-https://github.com}/\${GITHUB_REPOSITORY:-repo}/actions/runs/\${GITHUB_RUN_ID:-run}"
            ;;
        "teams")
            cat << EOF
{
  "@type": "MessageCard",
  "@context": "http://schema.org/extensions",
  "themeColor": "$([ "$STATUS" = "success" ] && echo "00FF00" || echo "FF0000")",
  "summary": "$PIPELINE_TYPE Status: ${STATUS^^}",
  "sections": [
    {
      "activityTitle": "$status_emoji $PIPELINE_TYPE Status: ${STATUS^^}",
      "activitySubtitle": "Repository: \${GITHUB_REPOSITORY:-Unknown}",
      "facts": [
        {
          "name": "Branch",
          "value": "\${GITHUB_REF_NAME:-Unknown}"
        },
        {
          "name": "Commit",
          "value": "\${GITHUB_SHA:-Unknown}"
        },
        {
          "name": "Total Findings",
          "value": "$total_findings"
        },
        {
          "name": "Critical",
          "value": "$total_critical"
        },
        {
          "name": "High",
          "value": "$total_high"
        }
      ]
    }
  ]
}
EOF
            ;;
    esac
}

# Send Slack notification
send_slack_notification() {
    local slack_enabled=$(echo "$CONFIG" | jq -r '.integrations.slack.enabled // false')
    local webhook_url="${SLACK_WEBHOOK:-$(echo "$CONFIG" | jq -r '.integrations.slack.webhook_url // ""')}"
    
    if [ "$slack_enabled" = "true" ] && [ -n "$webhook_url" ]; then
        echo -e "${BLUE}📱 Sending Slack notification...${NC}"
        
        local message_content
        message_content=$(generate_message_content "slack")
        
        if curl -s -X POST -H 'Content-type: application/json' \
           --data "$message_content" \
           "$webhook_url" > /dev/null; then
            echo -e "${GREEN}✅ Slack notification sent successfully${NC}"
        else
            echo -e "${RED}❌ Failed to send Slack notification${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Slack notifications disabled or webhook not configured${NC}"
    fi
}

# Send email notification
send_email_notification() {
    local email_enabled=$(echo "$CONFIG" | jq -r '.notifications.email.enabled // false')
    local smtp_server=$(echo "$CONFIG" | jq -r '.notifications.email.smtp_server // ""')
    local smtp_port=$(echo "$CONFIG" | jq -r '.notifications.email.smtp_port // 587')
    local sender_email=$(echo "$CONFIG" | jq -r '.notifications.email.sender_email // ""')
    local recipients=$(echo "$CONFIG" | jq -r '.notifications.email.recipients[]' | tr '\n' ',')
    
    if [ "$email_enabled" = "true" ] && [ -n "$smtp_server" ] && [ -n "$sender_email" ]; then
        echo -e "${BLUE}📧 Sending email notification...${NC}"
        
        local message_content
        message_content=$(generate_message_content "email")
        
        # Create temporary email file
        local email_file
        email_file=$(mktemp)
        echo "$message_content" > "$email_file"
        
        # Send email using curl (SMTP)
        if command -v curl >/dev/null 2>&1 && [ -n "${EMAIL_SMTP_PASSWORD:-}" ]; then
            for recipient in ${recipients//,/ }; do
                if curl -s --url "smtp://$smtp_server:$smtp_port" \
                   --ssl-reqd \
                   --mail-from "$sender_email" \
                   --mail-rcpt "$recipient" \
                   --upload-file "$email_file" \
                   --user "$sender_email:$EMAIL_SMTP_PASSWORD" > /dev/null; then
                    echo -e "${GREEN}✅ Email sent to $recipient${NC}"
                else
                    echo -e "${RED}❌ Failed to send email to $recipient${NC}"
                fi
            done
        else
            echo -e "${YELLOW}⚠️  Email sending requires curl and EMAIL_SMTP_PASSWORD${NC}"
        fi
        
        rm -f "$email_file"
    else
        echo -e "${YELLOW}⚠️  Email notifications disabled or not configured${NC}"
    fi
}

# Send Teams notification
send_teams_notification() {
    local teams_enabled=$(echo "$CONFIG" | jq -r '.integrations.teams.enabled // false')
    local webhook_url=$(echo "$CONFIG" | jq -r '.integrations.teams.webhook_url // ""')
    
    if [ "$teams_enabled" = "true" ] && [ -n "$webhook_url" ]; then
        echo -e "${BLUE}🔗 Sending Teams notification...${NC}"
        
        local message_content
        message_content=$(generate_message_content "teams")
        
        if curl -s -X POST -H 'Content-Type: application/json' \
           --data "$message_content" \
           "$webhook_url" > /dev/null; then
            echo -e "${GREEN}✅ Teams notification sent successfully${NC}"
        else
            echo -e "${RED}❌ Failed to send Teams notification${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Teams notifications disabled or webhook not configured${NC}"
    fi
}

# Create Jira ticket
create_jira_ticket() {
    local jira_enabled=$(echo "$CONFIG" | jq -r '.integrations.jira.enabled // false')
    local jira_url=$(echo "$CONFIG" | jq -r '.integrations.jira.server_url // ""')
    local project_key=$(echo "$CONFIG" | jq -r '.integrations.jira.project_key // ""')
    local issue_type=$(echo "$CONFIG" | jq -r '.integrations.jira.issue_type // "Bug"')
    
    # Only create tickets for critical/high severity findings and failures
    local should_create_ticket=false
    if [ "$STATUS" = "failure" ]; then
        should_create_ticket=true
    elif [ -f "$RESULTS_DIR/overall-summary.json" ] && command -v jq >/dev/null 2>&1; then
        local critical_count=$(jq '.total_vulnerabilities.critical // 0' "$RESULTS_DIR/overall-summary.json")
        local high_count=$(jq '.total_vulnerabilities.high // 0' "$RESULTS_DIR/overall-summary.json")
        [ "$critical_count" -gt 0 ] || [ "$high_count" -gt 0 ] && should_create_ticket=true
    fi
    
    if [ "$jira_enabled" = "true" ] && [ -n "$jira_url" ] && [ -n "$project_key" ] && [ "$should_create_ticket" = "true" ]; then
        echo -e "${BLUE}🎫 Creating Jira ticket...${NC}"
        
        local summary="$PIPELINE_TYPE ${STATUS^^} - \${GITHUB_REPOSITORY:-Repository}"
        local description
        description=$(generate_message_content "email" | sed 's/"/\\"/g')
        
        local jira_payload
        jira_payload=$(cat << EOF
{
  "fields": {
    "project": {
      "key": "$project_key"
    },
    "summary": "$summary",
    "description": "$description",
    "issuetype": {
      "name": "$issue_type"
    },
    "priority": {
      "name": "High"
    },
    "labels": ["security-vulnerability", "sast-scan", "auto-created"]
  }
}
EOF
)
        
        if [ -n "${JIRA_API_TOKEN:-}" ] && command -v curl >/dev/null 2>&1; then
            local jira_user=$(echo "$CONFIG" | jq -r '.integrations.jira.assignee // "admin"')
            
            if curl -s -X POST \
               -H "Content-Type: application/json" \
               -H "Authorization: Basic $(echo -n "$jira_user:$JIRA_API_TOKEN" | base64)" \
               --data "$jira_payload" \
               "$jira_url/rest/api/2/issue" > /dev/null; then
                echo -e "${GREEN}✅ Jira ticket created successfully${NC}"
            else
                echo -e "${RED}❌ Failed to create Jira ticket${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Jira ticket creation requires JIRA_API_TOKEN${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Jira integration disabled or no ticket needed${NC}"
    fi
}

# Update Grafana metrics
update_grafana_metrics() {
    local grafana_enabled=$(echo "$CONFIG" | jq -r '.integrations.grafana.enabled // false')
    
    if [ "$grafana_enabled" = "true" ] && [ -n "${GRAFANA_API_KEY:-}" ]; then
        echo -e "${BLUE}📊 Updating Grafana metrics...${NC}"
        
        # This would typically push metrics to Prometheus or directly to Grafana
        # For demo purposes, we'll just log the action
        echo -e "${GREEN}✅ Grafana metrics would be updated here${NC}"
        
        # Example metrics that would be pushed:
        # - sast_vulnerabilities_total{severity="critical"} $total_critical
        # - sast_vulnerabilities_total{severity="high"} $total_high
        # - sast_scan_status{pipeline="$PIPELINE_TYPE"} $([ "$STATUS" = "success" ] && echo 1 || echo 0)
    else
        echo -e "${YELLOW}⚠️  Grafana integration disabled or API key not configured${NC}"
    fi
}

# Main execution
main() {
    if [ "$NOTIFICATIONS_ENABLED" != "true" ]; then
        echo -e "${YELLOW}⚠️  Notifications are disabled${NC}"
        exit 0
    fi
    
    if ! should_send_notification; then
        echo -e "${YELLOW}⚠️  Notification not triggered based on current settings (trigger: $NOTIFICATION_TRIGGER, status: $STATUS)${NC}"
        exit 0
    fi
    
    echo -e "${GREEN}📨 Sending notifications for $PIPELINE_TYPE with status: $STATUS${NC}"
    
    # Send notifications in parallel for better performance
    {
        send_slack_notification &
        send_email_notification &
        send_teams_notification &
        create_jira_ticket &
        update_grafana_metrics &
        wait
    }
    
    echo -e "${GREEN}✅ All notifications processed${NC}"
}

# Execute main function
main "$@"
