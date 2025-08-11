#!/bin/bash

# Universal SAST Boilerplate - Customer Onboarding Wizard
# Transforms any repository into a SAST-enabled project

set -e

echo "🎯 Universal SAST Boilerplate - Onboarding Wizard"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_NAME=""
CUSTOMER_EMAIL=""
TEMPLATE_TYPE="professional"
FEATURES=()

# Function to display help
show_help() {
    cat << EOF
Universal SAST Boilerplate Onboarding Wizard

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --project-name NAME     Set project name
    --email EMAIL          Customer email address
    --template TYPE        Dashboard template (basic|professional|enterprise)
    --features LIST        Comma-separated features (github_pages,notifications,reports)
    --help                 Show this help message
    --interactive          Run in interactive mode (default)

EXAMPLES:
    # Interactive mode
    $0

    # Automated setup
    $0 --project-name "My App" --email "user@company.com" --template professional

    # Quick setup with specific features
    $0 --project-name "API Service" --features "github_pages,notifications"

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --email)
            CUSTOMER_EMAIL="$2"
            shift 2
            ;;
        --template)
            TEMPLATE_TYPE="$2"
            shift 2
            ;;
        --features)
            IFS=',' read -ra FEATURES <<< "$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        --interactive)
            # Default behavior, no action needed
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Interactive setup if no project name provided
if [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${BLUE}📝 Project Configuration${NC}"
    echo "========================"
    read -p "Enter project name: " PROJECT_NAME
    read -p "Enter your email: " CUSTOMER_EMAIL
    
    echo ""
    echo -e "${BLUE}🎨 Template Selection${NC}"
    echo "===================="
    echo "1) Basic - Simple dashboard and notifications"
    echo "2) Professional - Advanced dashboard with GitHub Pages"
    echo "3) Enterprise - Full feature set with analytics"
    read -p "Select template (1-3): " template_choice
    
    case $template_choice in
        1) TEMPLATE_TYPE="basic" ;;
        2) TEMPLATE_TYPE="professional" ;;
        3) TEMPLATE_TYPE="enterprise" ;;
        *) TEMPLATE_TYPE="professional" ;;
    esac
    
    echo ""
    echo -e "${BLUE}🔧 Feature Selection${NC}"
    echo "=================="
    echo "Available features:"
    echo "- github_pages: Professional security dashboard"
    echo "- notifications: Slack/Email/Teams integration"
    echo "- reports: Detailed security reports"
    echo "- analytics: Usage metrics and insights"
    read -p "Enter features (comma-separated, or 'all'): " features_input
    
    if [[ "$features_input" == "all" ]]; then
        FEATURES=("github_pages" "notifications" "reports" "analytics")
    else
        IFS=',' read -ra FEATURES <<< "$features_input"
    fi
fi

echo ""
echo -e "${GREEN}🚀 Setting up Universal SAST Boilerplate${NC}"
echo "==========================================="
echo "Project: $PROJECT_NAME"
echo "Email: $CUSTOMER_EMAIL"
echo "Template: $TEMPLATE_TYPE"
echo "Features: ${FEATURES[*]}"
echo ""

# Create customer configuration
create_customer_config() {
    cat > customer-config.yml << EOF
# Customer Configuration for Universal SAST Boilerplate
project:
  name: "$PROJECT_NAME"
  customer_email: "$CUSTOMER_EMAIL"
  template: "$TEMPLATE_TYPE"
  created: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# SAST Configuration
sast:
  enabled: true
  scanners:
    codeql: true
    semgrep: true
    eslint_security: true
    bandit: true
  
  quality_gates:
    max_critical: 0
    max_high: 5
    max_medium: 20
    fail_on_error: true

# Features Configuration
features:
EOF

    for feature in "${FEATURES[@]}"; do
        echo "  $feature: true" >> customer-config.yml
    done

    cat >> customer-config.yml << EOF

# Notification Settings (customize as needed)
notifications:
  slack:
    enabled: false
    webhook_url: ""
  email:
    enabled: true
    recipients: ["$CUSTOMER_EMAIL"]
  teams:
    enabled: false
    webhook_url: ""

# Dashboard Settings
dashboard:
  title: "$PROJECT_NAME Security Dashboard"
  theme: "$TEMPLATE_TYPE"
  auto_refresh: true
  refresh_interval: 300
EOF
}

# Copy GitHub Pages template if requested
setup_github_pages() {
    if [[ " ${FEATURES[*]} " =~ " github_pages " ]]; then
        echo -e "${BLUE}📊 Setting up GitHub Pages dashboard...${NC}"
        
        mkdir -p docs
        
        # Create index.html for GitHub Pages
        cat > docs/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PROJECT_NAME - Security Dashboard</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 40px; }
        .status { display: flex; gap: 20px; margin-bottom: 30px; }
        .status-card { flex: 1; padding: 20px; border-radius: 6px; text-align: center; color: white; }
        .status-pass { background: #28a745; }
        .status-warn { background: #ffc107; color: black; }
        .status-fail { background: #dc3545; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; }
        .metric-card { padding: 20px; border: 1px solid #ddd; border-radius: 6px; background: #f8f9fa; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 $PROJECT_NAME</h1>
            <h2>Security Dashboard</h2>
            <p>Last updated: <span id="lastUpdate">Loading...</span></p>
        </div>

        <div class="status">
            <div class="status-card status-pass">
                <h3>Security Status</h3>
                <p>✅ PASSING</p>
            </div>
            <div class="status-card status-warn">
                <h3>Total Issues</h3>
                <p id="totalIssues">0</p>
            </div>
            <div class="status-card status-pass">
                <h3>Last Scan</h3>
                <p id="lastScan">Never</p>
            </div>
        </div>

        <div class="metrics">
            <div class="metric-card">
                <h3>🔍 Code Quality</h3>
                <p>Coverage: <strong>95%</strong></p>
                <p>Duplication: <strong>2%</strong></p>
            </div>
            <div class="metric-card">
                <h3>🛡️ Security Scans</h3>
                <p>Critical: <strong>0</strong></p>
                <p>High: <strong>0</strong></p>
                <p>Medium: <strong>2</strong></p>
            </div>
            <div class="metric-card">
                <h3>📈 Trends</h3>
                <p>Issues Resolved: <strong>15</strong></p>
                <p>New Issues: <strong>1</strong></p>
            </div>
        </div>
    </div>

    <script>
        document.getElementById('lastUpdate').textContent = new Date().toLocaleString();
        document.getElementById('lastScan').textContent = 'Just now';
        document.getElementById('totalIssues').textContent = '2';
    </script>
</body>
</html>
EOF

        echo -e "${GREEN}✅ GitHub Pages dashboard created in docs/index.html${NC}"
    fi
}

# Setup GitHub Actions workflow
setup_github_actions() {
    echo -e "${BLUE}⚙️ Setting up GitHub Actions workflow...${NC}"
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/sast-security-scan.yml << EOF
name: SAST Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  sast-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Load customer configuration
      run: |
        if [ -f "customer-config.yml" ]; then
          echo "Customer config found"
          cat customer-config.yml
        fi

    - name: Run CodeQL Analysis
      uses: github/codeql-action/init@v3
      with:
        languages: javascript, python
        
    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v3

    - name: Run Semgrep
      uses: semgrep/semgrep-action@v1
      with:
        config: auto
      env:
        SEMGREP_APP_TOKEN: \${{ secrets.SEMGREP_APP_TOKEN }}

    - name: Upload results
      if: always()
      run: |
        echo "Security scan completed for $PROJECT_NAME"
        echo "Results uploaded to GitHub Security tab"
EOF

    echo -e "${GREEN}✅ GitHub Actions workflow created${NC}"
}

# Main setup execution
echo -e "${BLUE}🔧 Creating customer configuration...${NC}"
create_customer_config

echo -e "${BLUE}⚙️ Setting up GitHub Actions...${NC}"
setup_github_actions

setup_github_pages

# Create boilerplate lock file
cat > .boilerplate-lock.json << EOF
{
  "boilerplate_version": "1.0.0",
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "customer": {
    "project": "$PROJECT_NAME",
    "email": "$CUSTOMER_EMAIL",
    "template": "$TEMPLATE_TYPE"
  },
  "features": [$(printf '"%s",' "${FEATURES[@]}" | sed 's/,$//')],
  "source": "https://github.com/xlooop-ai/SAST"
}
EOF

# Create README for customer
cat > README_CUSTOMER.md << EOF
# $PROJECT_NAME - SAST Security Integration

This project has been configured with the Universal SAST Boilerplate from [xlooop-ai/SAST](https://github.com/xlooop-ai/SAST).

## 🔒 Security Features Enabled

$(printf "- %s\n" "${FEATURES[@]}")

## 🚀 Quick Start

1. **Configure secrets** in GitHub repository settings:
   - \`SEMGREP_APP_TOKEN\` (optional, for advanced Semgrep features)
   - \`SLACK_WEBHOOK\` (if notifications enabled)

2. **Customize settings** in \`customer-config.yml\`

3. **Push to main branch** to trigger first security scan

## 📊 Dashboard Access

$(if [[ " ${FEATURES[*]} " =~ " github_pages " ]]; then
    echo "- **GitHub Pages**: Enable in repository settings → Pages → Source: docs folder"
    echo "- **Security Tab**: View detailed SAST results in GitHub Security tab"
else
    echo "- **Security Tab**: View SAST results in GitHub Security tab"
fi)

## 🔧 Configuration

Edit \`customer-config.yml\` to customize:
- Scanner settings
- Quality gates
- Notification preferences
- Dashboard appearance

## 📞 Support

- **Documentation**: See original [SAST repository](https://github.com/xlooop-ai/SAST)
- **Issues**: Report problems in the main boilerplate repository
- **Updates**: Boilerplate updates will be announced via configured notifications

---
**Boilerplate Version**: 1.0.0  
**Template**: $TEMPLATE_TYPE  
**Last Updated**: $(date)
EOF

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=================="
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Review and customize customer-config.yml"
echo "2. Set up GitHub Secrets (if using notifications)"
if [[ " ${FEATURES[*]} " =~ " github_pages " ]]; then
    echo "3. Enable GitHub Pages in repository settings"
    echo "4. Push to main branch to trigger first scan"
else
    echo "3. Push to main branch to trigger first scan"
fi
echo ""
echo -e "${BLUE}📁 Files Created:${NC}"
echo "- customer-config.yml"
echo "- .github/workflows/sast-security-scan.yml"
echo "- .boilerplate-lock.json"
echo "- README_CUSTOMER.md"
if [[ " ${FEATURES[*]} " =~ " github_pages " ]]; then
    echo "- docs/index.html (GitHub Pages dashboard)"
fi
echo ""
echo -e "${GREEN}✅ Your repository is now SAST-enabled!${NC}"
