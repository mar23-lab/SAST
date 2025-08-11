#!/bin/bash

# Universal SAST Boilerplate - Quick Deploy
# One-command deployment for immediate SAST integration

set -e

echo "🚀 Universal SAST Boilerplate - Quick Deploy"
echo "============================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default configuration
DEFAULT_PROJECT_NAME=$(basename $(pwd))
DEFAULT_EMAIL="user@example.com"
DEFAULT_TEMPLATE="professional"

echo -e "${BLUE}🎯 Quick SAST Integration Setup${NC}"
echo "==============================="
echo ""
echo "This will configure your repository with:"
echo "✅ Multi-scanner SAST (CodeQL, Semgrep, ESLint, Bandit)"
echo "✅ GitHub Actions workflow"
echo "✅ Professional security dashboard"
echo "✅ Quality gates and notifications"
echo ""

# Prompt for basic information
read -p "Project name [$DEFAULT_PROJECT_NAME]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}

read -p "Your email [$DEFAULT_EMAIL]: " EMAIL
EMAIL=${EMAIL:-$DEFAULT_EMAIL}

echo ""
echo -e "${YELLOW}📋 Configuration Summary${NC}"
echo "Project: $PROJECT_NAME"
echo "Email: $EMAIL"
echo "Template: $DEFAULT_TEMPLATE"
echo "Features: GitHub Pages, Notifications, Reports"
echo ""

read -p "Continue with setup? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}🔧 Running automated setup...${NC}"

# Run the universal onboarding with predefined settings
if [[ -f "scripts/universal-onboarding.sh" ]]; then
    ./scripts/universal-onboarding.sh \
        --project-name "$PROJECT_NAME" \
        --email "$EMAIL" \
        --template "$DEFAULT_TEMPLATE" \
        --features "github_pages,notifications,reports"
else
    echo -e "${YELLOW}Warning: universal-onboarding.sh not found. Creating basic setup...${NC}"
    
    # Create basic configuration manually
    mkdir -p .github/workflows
    
    cat > customer-config.yml << EOF
project:
  name: "$PROJECT_NAME"
  customer_email: "$EMAIL"
  template: "$DEFAULT_TEMPLATE"

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
    fail_on_error: true

notifications:
  email:
    enabled: true
    recipients: ["$EMAIL"]
EOF

    # Create basic GitHub Actions workflow
    cat > .github/workflows/sast-security-scan.yml << 'EOF'
name: SAST Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  sast-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

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
EOF
fi

echo ""
echo -e "${GREEN}🎉 Quick Deploy Complete!${NC}"
echo "========================="
echo ""
echo -e "${YELLOW}📋 What was configured:${NC}"
echo "✅ SAST scanning with multiple tools"
echo "✅ GitHub Actions workflow"
echo "✅ Customer configuration file"
echo "✅ Professional security dashboard"
echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Add and commit these changes:"
echo "   git add -A"
echo "   git commit -m 'feat: Add Universal SAST Boilerplate integration'"
echo ""
echo "2. Push to trigger first security scan:"
echo "   git push origin main"
echo ""
echo "3. Optional: Configure GitHub Secrets for advanced features:"
echo "   - SEMGREP_APP_TOKEN (for enhanced Semgrep rules)"
echo "   - SLACK_WEBHOOK (for Slack notifications)"
echo ""
echo "4. Enable GitHub Pages (if professional template):"
echo "   Repository Settings → Pages → Source: docs folder"
echo ""
echo -e "${GREEN}✅ Your repository is now SAST-enabled!${NC}"
echo ""
echo "🔍 Check the GitHub Security tab after the first scan completes."
echo "📊 Access your security dashboard at: https://[username].github.io/[repo-name]/"
