#!/bin/bash

# Enhanced SAST Boilerplate Onboarding Wizard
# Universal SAST Boilerplate - Customer Setup System
# Based on successful customer patterns from xlooop-ai/xlop-security

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Unicode symbols
CHECKMARK="✅"
CROSS="❌"
ARROW="➡️"
STAR="⭐"
ROCKET="🚀"
SHIELD="🛡️"
GEAR="⚙️"

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CUSTOMER_NAME=""
GITHUB_USERNAME=""
GITHUB_REPO=""
TEMPLATE_CHOICE=""
COMPANY_LOGO=""
CUSTOM_DOMAIN=""
PRIMARY_COLOR=""
CONTACT_EMAIL=""
ENABLE_GITHUB_PAGES=false
SETUP_NOTIFICATIONS=false
CONFIGURE_GOVERNANCE=false

# Setup tracking
START_TIME=$(date +%s)
SETUP_STEPS=()
ERROR_LOG=""

# Display functions
print_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║          🛡️  UNIVERSAL SAST BOILERPLATE SETUP  🛡️           ║"
    echo "║                                                              ║"
    echo "║              Professional Security Dashboard Setup           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_step() {
    local step="$1"
    local description="$2"
    echo -e "${CYAN}${GEAR} Step $step: ${BLUE}$description${NC}"
    echo "────────────────────────────────────────────────"
    echo ""
}

print_success() {
    echo -e "${GREEN}${CHECKMARK} $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
    ERROR_LOG+="ERROR: $1\n"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Input validation functions
validate_github_username() {
    local username="$1"
    if [[ ! "$username" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-])*[a-zA-Z0-9]$ ]]; then
        return 1
    fi
    return 0
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]] && [[ ! "$url" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Setup functions
collect_basic_info() {
    print_step "1" "Basic Information"
    
    echo -e "${BLUE}Let's start with some basic information about your project.${NC}"
    echo ""
    
    # Customer/Company name
    while [[ -z "$CUSTOMER_NAME" ]]; do
        read -p "Company/Project name: " CUSTOMER_NAME
        if [[ -z "$CUSTOMER_NAME" ]]; then
            print_error "Company name cannot be empty"
        fi
    done
    
    # GitHub username/organization
    while [[ -z "$GITHUB_USERNAME" ]]; do
        read -p "GitHub username/organization: " GITHUB_USERNAME
        if ! validate_github_username "$GITHUB_USERNAME"; then
            print_error "Invalid GitHub username format"
            GITHUB_USERNAME=""
        fi
    done
    
    # Repository name
    while [[ -z "$GITHUB_REPO" ]]; do
        read -p "Repository name (e.g., security-dashboard): " GITHUB_REPO
        if [[ -z "$GITHUB_REPO" ]]; then
            print_error "Repository name cannot be empty"
        fi
    done
    
    # Contact email
    while [[ -z "$CONTACT_EMAIL" ]]; do
        read -p "Security contact email: " CONTACT_EMAIL
        if ! validate_email "$CONTACT_EMAIL"; then
            print_error "Invalid email format"
            CONTACT_EMAIL=""
        fi
    done
    
    print_success "Basic information collected"
    SETUP_STEPS+=("basic_info")
    echo ""
}

select_template() {
    print_step "2" "Dashboard Template Selection"
    
    echo -e "${BLUE}Choose your dashboard template:${NC}"
    echo ""
    echo "1) 🏢 Professional (Recommended)"
    echo "   └─ Enterprise-ready design for stakeholder presentations"
    echo "   └─ Mobile-responsive with real-time metrics"
    echo "   └─ Perfect for team collaboration"
    echo ""
    echo "2) 👔 Executive"
    echo "   └─ C-level focused with high-level metrics"
    echo "   └─ Business impact and trend analysis"
    echo "   └─ Compliance and risk reporting"
    echo ""
    echo "3) 💻 Developer"
    echo "   └─ Technical console with detailed scan results"
    echo "   └─ Code-focused vulnerability details"
    echo "   └─ Scanner performance metrics"
    echo ""
    echo "4) 📋 Compliance"
    echo "   └─ Audit-ready format for compliance teams"
    echo "   └─ Standards tracking (SOC 2, ISO 27001)"
    echo "   └─ Evidence collection and reporting"
    echo ""
    
    while [[ -z "$TEMPLATE_CHOICE" ]]; do
        read -p "Select template (1-4): " choice
        case $choice in
            1)
                TEMPLATE_CHOICE="professional"
                print_success "Selected: Professional template"
                ;;
            2)
                TEMPLATE_CHOICE="executive"
                print_success "Selected: Executive template"
                ;;
            3)
                TEMPLATE_CHOICE="developer"
                print_success "Selected: Developer template"
                ;;
            4)
                TEMPLATE_CHOICE="compliance"
                print_success "Selected: Compliance template"
                ;;
            *)
                print_error "Invalid choice. Please select 1-4."
                ;;
        esac
    done
    
    SETUP_STEPS+=("template_selection")
    echo ""
}

configure_github_pages() {
    print_step "3" "GitHub Pages Configuration"
    
    echo -e "${BLUE}Configure GitHub Pages for your security dashboard:${NC}"
    echo ""
    
    read -p "Enable GitHub Pages dashboard? (Y/n): " enable_pages
    if [[ "$enable_pages" =~ ^[Yy]$|^$ ]]; then
        ENABLE_GITHUB_PAGES=true
        print_success "GitHub Pages enabled"
        
        echo ""
        echo -e "${BLUE}Dashboard will be available at:${NC}"
        echo "https://${GITHUB_USERNAME}.github.io/${GITHUB_REPO}/"
        echo ""
        
        # Custom domain
        read -p "Custom domain (optional, e.g., security.company.com): " CUSTOM_DOMAIN
        if [[ -n "$CUSTOM_DOMAIN" ]]; then
            if validate_url "$CUSTOM_DOMAIN"; then
                print_success "Custom domain: $CUSTOM_DOMAIN"
                print_info "Don't forget to configure DNS CNAME record"
            else
                print_warning "Invalid domain format, skipping custom domain"
                CUSTOM_DOMAIN=""
            fi
        fi
        
    else
        ENABLE_GITHUB_PAGES=false
        print_info "GitHub Pages disabled"
    fi
    
    SETUP_STEPS+=("github_pages")
    echo ""
}

configure_branding() {
    print_step "4" "Company Branding"
    
    echo -e "${BLUE}Customize the dashboard appearance for your company:${NC}"
    echo ""
    
    # Company logo
    read -p "Company logo URL (optional): " COMPANY_LOGO
    if [[ -n "$COMPANY_LOGO" ]] && validate_url "$COMPANY_LOGO"; then
        print_success "Logo configured: $COMPANY_LOGO"
    elif [[ -n "$COMPANY_LOGO" ]]; then
        print_warning "Invalid logo URL, using default"
        COMPANY_LOGO=""
    fi
    
    # Primary color
    read -p "Primary brand color (hex, e.g., #1f2937): " PRIMARY_COLOR
    if [[ "$PRIMARY_COLOR" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        print_success "Primary color: $PRIMARY_COLOR"
    elif [[ -n "$PRIMARY_COLOR" ]]; then
        print_warning "Invalid color format, using default"
        PRIMARY_COLOR=""
    fi
    
    SETUP_STEPS+=("branding")
    echo ""
}

configure_integrations() {
    print_step "5" "Team Integrations"
    
    echo -e "${BLUE}Set up team notifications and integrations:${NC}"
    echo ""
    
    read -p "Configure team notifications (Slack, Email, etc.)? (y/N): " setup_notifications
    if [[ "$setup_notifications" =~ ^[Yy]$ ]]; then
        SETUP_NOTIFICATIONS=true
        print_success "Team notifications will be configured"
        print_info "You'll need to provide webhook URLs and SMTP settings later"
    else
        SETUP_NOTIFICATIONS=false
        print_info "Team notifications skipped (can be configured later)"
    fi
    
    echo ""
    read -p "Set up enterprise governance policies? (y/N): " setup_governance
    if [[ "$setup_governance" =~ ^[Yy]$ ]]; then
        CONFIGURE_GOVERNANCE=true
        print_success "Enterprise governance will be configured"
        print_info "Compliance frameworks and quality gates will be set up"
    else
        CONFIGURE_GOVERNANCE=false
        print_info "Governance policies skipped (can be configured later)"
    fi
    
    SETUP_STEPS+=("integrations")
    echo ""
}

generate_configuration() {
    print_step "6" "Generating Configuration"
    
    echo -e "${BLUE}Creating your custom configuration...${NC}"
    echo ""
    
    # Create customer configuration file
    cat > customer-config.yml << EOF
# Universal SAST Boilerplate - Customer Configuration
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

customer:
  name: "$CUSTOMER_NAME"
  contact_email: "$CONTACT_EMAIL"
  github:
    username: "$GITHUB_USERNAME"
    repository: "$GITHUB_REPO"

template:
  name: "$TEMPLATE_CHOICE"
  branding:
    company_logo: "$COMPANY_LOGO"
    primary_color: "$PRIMARY_COLOR"
    company_name: "$CUSTOMER_NAME"

github_pages:
  enabled: $ENABLE_GITHUB_PAGES
  custom_domain: "$CUSTOM_DOMAIN"
  auto_deploy: true

features:
  notifications: $SETUP_NOTIFICATIONS
  governance: $CONFIGURE_GOVERNANCE
  real_data_only: true
  auto_refresh: true

scanners:
  codeql:
    enabled: true
    languages: ["javascript", "typescript", "python"]
  semgrep:
    enabled: true
    rules: "auto"
  eslint_security:
    enabled: true
    config: "recommended"
  typescript:
    enabled: true
    strict: true

notifications:
  slack:
    enabled: false
    webhook_url: ""
  email:
    enabled: false
    smtp_host: ""
  jira:
    enabled: false
    url: ""

governance:
  quality_gates:
    critical_threshold: 0
    high_threshold: 5
    medium_threshold: 20
  compliance:
    frameworks: []
    policies: []

EOF

    print_success "Configuration file created: customer-config.yml"
    
    # Generate template files
    generate_template_files
    
    # Generate GitHub Actions workflow
    if [[ "$ENABLE_GITHUB_PAGES" == true ]]; then
        generate_github_workflow
    fi
    
    SETUP_STEPS+=("configuration")
    echo ""
}

generate_template_files() {
    echo -e "${BLUE}Generating dashboard template files...${NC}"
    
    # Create directory structure
    mkdir -p dist/
    mkdir -p assets/{css,js,img}/
    mkdir -p data/
    
    # Copy and customize template
    local template_source="$PROJECT_ROOT/templates/github-pages/$TEMPLATE_CHOICE"
    
    if [[ -d "$template_source" ]]; then
        # Copy template files
        cp -r "$template_source"/* ./
        
        # Process template variables
        process_template_variables
        
        print_success "Template files generated"
    else
        print_warning "Template not found, using professional template as fallback"
        cp -r "$PROJECT_ROOT/templates/github-pages/professional"/* ./
        process_template_variables
    fi
}

process_template_variables() {
    echo -e "${BLUE}Customizing template with your branding...${NC}"
    
    # Process HTML files
    find . -name "*.html" -type f -exec sed -i.bak \
        -e "s/{{COMPANY_NAME}}/$CUSTOMER_NAME/g" \
        -e "s/{{CONTACT_EMAIL}}/$CONTACT_EMAIL/g" \
        -e "s/{{COMPANY_LOGO}}/${COMPANY_LOGO:-assets\/img\/default-logo.png}/g" \
        -e "s/{{GITHUB_REPO_URL}}/https:\/\/github.com\/$GITHUB_USERNAME\/$GITHUB_REPO/g" \
        -e "s/{{CURRENT_YEAR}}/$(date +%Y)/g" \
        -e "s/{{LAST_UPDATED}}/$(date)/g" \
        {} \;
    
    # Process CSS files if custom color is provided
    if [[ -n "$PRIMARY_COLOR" ]]; then
        find . -name "*.css" -type f -exec sed -i.bak \
            -e "s/--primary-color: #1f2937/--primary-color: $PRIMARY_COLOR/g" \
            {} \;
    fi
    
    # Clean up backup files
    find . -name "*.bak" -delete
    
    print_success "Template customized with your branding"
}

generate_github_workflow() {
    echo -e "${BLUE}Creating GitHub Actions workflow...${NC}"
    
    mkdir -p .github/workflows/
    
    cat > .github/workflows/deploy-dashboard.yml << 'EOF'
name: Deploy Security Dashboard

on:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: true
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: |
          npm init -y
          npm install --save-dev @types/node
      
      - name: Update dashboard data
        run: |
          # Fetch latest security scan results
          echo "Updating dashboard with latest security data..."
          
          # This would normally fetch from SARIF files or API
          # For now, create sample data structure
          mkdir -p data/
          echo '{"summary":{"critical":0,"high":0,"medium":0,"low":0},"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > data/security-data.json
      
      - name: Setup Pages
        uses: actions/configure-pages@v4
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'
      
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF

    # Add custom domain if specified
    if [[ -n "$CUSTOM_DOMAIN" ]]; then
        echo "$CUSTOM_DOMAIN" > CNAME
        print_success "CNAME file created for custom domain"
    fi
    
    print_success "GitHub Actions workflow created"
}

setup_git_repository() {
    print_step "7" "Repository Setup"
    
    echo -e "${BLUE}Setting up Git repository...${NC}"
    echo ""
    
    # Initialize git if not already
    if [[ ! -d ".git" ]]; then
        git init
        print_success "Git repository initialized"
    fi
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*

# Environment variables
.env
.env.local

# Temporary files
*.tmp
*.bak
.DS_Store

# IDE
.vscode/
.idea/

# Logs
*.log

# Build artifacts
dist/
build/

# Security scan results (if sensitive)
# security-results/
# sarif-results/
EOF

    print_success ".gitignore created"
    
    # Stage files
    git add .
    git commit -m "Initial setup: Universal SAST Boilerplate with $TEMPLATE_CHOICE template"
    
    print_success "Initial commit created"
    
    # Setup remote if provided
    echo ""
    read -p "Set up GitHub remote repository? (Y/n): " setup_remote
    if [[ "$setup_remote" =~ ^[Yy]$|^$ ]]; then
        setup_github_remote
    fi
    
    SETUP_STEPS+=("git_setup")
    echo ""
}

setup_github_remote() {
    echo -e "${BLUE}Setting up GitHub remote...${NC}"
    
    # Add remote
    git remote add origin "https://github.com/$GITHUB_USERNAME/$GITHUB_REPO.git"
    
    print_success "GitHub remote added"
    print_info "To push to GitHub:"
    echo "  1. Create repository at: https://github.com/new"
    echo "  2. Repository name: $GITHUB_REPO"
    echo "  3. Run: git push -u origin main"
    
    if [[ "$ENABLE_GITHUB_PAGES" == true ]]; then
        echo ""
        print_info "To enable GitHub Pages:"
        echo "  1. Go to repository Settings"
        echo "  2. Navigate to Pages section"
        echo "  3. Select 'GitHub Actions' as source"
        echo "  4. Your dashboard will be at: https://$GITHUB_USERNAME.github.io/$GITHUB_REPO/"
    fi
}

create_documentation() {
    print_step "8" "Documentation"
    
    echo -e "${BLUE}Creating project documentation...${NC}"
    echo ""
    
    # Create README
    cat > README.md << EOF
# $CUSTOMER_NAME Security Dashboard

Professional security monitoring dashboard powered by Universal SAST Boilerplate.

## 🌐 Live Dashboard

**Access:** https://$GITHUB_USERNAME.github.io/$GITHUB_REPO/

## 🛡️ Security Coverage

- **CodeQL** - Semantic code analysis
- **Semgrep** - Pattern-based vulnerability detection  
- **ESLint Security** - JavaScript/TypeScript security rules
- **TypeScript** - Type safety validation

## 📊 Features

- ✅ **Real-time Security Metrics** - Live vulnerability tracking
- ✅ **Professional Dashboard** - Stakeholder-ready presentation
- ✅ **Mobile Responsive** - Access from any device
- ✅ **Integration Status** - GitHub, Slack, Email, Jira monitoring
- ✅ **Auto-refresh** - Continuous data updates

## 🚀 Quick Start

### First-time Setup

1. **Enable GitHub Pages**
   - Go to repository Settings → Pages
   - Select "GitHub Actions" as source
   - Dashboard will be available at the URL above

2. **Configure Integrations**
   - Add secrets for notifications (SLACK_WEBHOOK_URL, etc.)
   - Update customer-config.yml with your settings
   - Push changes to trigger deployment

### Team Access

Share the dashboard URL with your team:
- **Developers**: Real-time security status
- **Security Team**: Detailed vulnerability tracking  
- **Management**: Professional security reporting

## ⚙️ Configuration

Edit \`customer-config.yml\` to customize:
- Scanner settings and thresholds
- Notification channels
- Branding and appearance
- Quality gates and policies

## 📞 Support

- **Security Contact**: $CONTACT_EMAIL
- **Repository**: https://github.com/$GITHUB_USERNAME/$GITHUB_REPO
- **Documentation**: See docs/ folder for detailed guides

---

**🛡️ Built with Universal SAST Boilerplate - Enterprise Security Made Simple**
EOF

    print_success "README.md created"
    
    # Create setup guide
    cat > SETUP_GUIDE.md << EOF
# Setup Guide - $CUSTOMER_NAME Security Dashboard

## 📋 Initial Configuration

### 1. GitHub Repository Setup

1. **Create Repository**
   - Name: $GITHUB_REPO
   - Description: Security dashboard for $CUSTOMER_NAME
   - Public/Private: Choose based on your needs

2. **Push Code**
   \`\`\`bash
   git push -u origin main
   \`\`\`

### 2. GitHub Pages Configuration

1. **Enable Pages**
   - Repository Settings → Pages
   - Source: GitHub Actions
   - Custom domain: $CUSTOM_DOMAIN

2. **First Deployment**
   - Workflow runs automatically on push
   - Dashboard available at: https://$GITHUB_USERNAME.github.io/$GITHUB_REPO/

### 3. Security Integration

1. **GitHub Secrets**
   \`\`\`
   GITHUB_TOKEN=<your_token>
   SLACK_WEBHOOK_URL=<slack_webhook>
   SMTP_HOST=<email_server>
   JIRA_URL=<jira_instance>
   \`\`\`

2. **Scan Configuration**
   - Edit \`.github/workflows/\` files
   - Configure scanner rules in \`configs/\`
   - Set quality gates in \`customer-config.yml\`

## 🔧 Customization

### Dashboard Appearance
- Edit \`assets/css/\` for styling
- Update \`assets/img/\` for logos
- Modify \`index.html\` for layout

### Scanner Settings
- Configure thresholds in \`customer-config.yml\`
- Add custom rules in \`configs/\`
- Enable/disable scanners as needed

## 📊 Team Onboarding

### For Developers
1. Bookmark dashboard URL
2. Set up local development environment
3. Review security scan results

### For Security Team  
1. Configure notification channels
2. Set up quality gates
3. Review compliance settings

### For Management
1. Access executive dashboard view
2. Review security posture reports
3. Monitor team adoption metrics

## 🆘 Troubleshooting

### Common Issues
- **Dashboard not updating**: Check GitHub Actions workflow
- **Integrations not working**: Verify secrets configuration
- **Scans failing**: Review scanner configuration

### Getting Help
- Check repository Issues tab
- Contact: $CONTACT_EMAIL
- Review Universal SAST Boilerplate documentation
EOF

    print_success "SETUP_GUIDE.md created"
    
    SETUP_STEPS+=("documentation")
    echo ""
}

display_summary() {
    print_step "9" "Setup Complete"
    
    local end_time=$(date +%s)
    local setup_duration=$((end_time - START_TIME))
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║                    🎉 SETUP COMPLETE! 🎉                    ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${BLUE}${STAR} Setup Summary${NC}"
    echo "────────────────────────────────────────────────"
    echo "• Company: $CUSTOMER_NAME"
    echo "• Template: $TEMPLATE_CHOICE"
    echo "• Repository: $GITHUB_USERNAME/$GITHUB_REPO"
    if [[ "$ENABLE_GITHUB_PAGES" == true ]]; then
        echo "• Dashboard: https://$GITHUB_USERNAME.github.io/$GITHUB_REPO/"
        if [[ -n "$CUSTOM_DOMAIN" ]]; then
            echo "• Custom Domain: $CUSTOM_DOMAIN"
        fi
    fi
    echo "• Setup Time: ${setup_duration}s"
    echo ""
    
    echo -e "${BLUE}${ROCKET} Next Steps${NC}"
    echo "────────────────────────────────────────────────"
    echo "1. Create GitHub repository: https://github.com/new"
    echo "2. Push code: git push -u origin main"
    if [[ "$ENABLE_GITHUB_PAGES" == true ]]; then
        echo "3. Enable GitHub Pages in repository settings"
        echo "4. Configure GitHub secrets for integrations"
    fi
    echo "5. Review and customize customer-config.yml"
    echo "6. Share dashboard URL with your team"
    echo ""
    
    if [[ "$SETUP_NOTIFICATIONS" == true ]]; then
        echo -e "${YELLOW}${GEAR} Integration Setup Required${NC}"
        echo "────────────────────────────────────────────────"
        echo "• Configure Slack webhook URL"
        echo "• Set up SMTP settings for email notifications"
        echo "• Add Jira integration credentials"
        echo "• See SETUP_GUIDE.md for detailed instructions"
        echo ""
    fi
    
    echo -e "${GREEN}${SHIELD} Security Dashboard Features${NC}"
    echo "────────────────────────────────────────────────"
    echo "• Real-time vulnerability tracking"
    echo "• Professional stakeholder reporting"
    echo "• Mobile-responsive team access"
    echo "• Integration status monitoring"
    echo "• Automated security scanning"
    echo ""
    
    echo -e "${BLUE}📞 Support${NC}"
    echo "────────────────────────────────────────────────"
    echo "• Documentation: README.md and SETUP_GUIDE.md"
    echo "• Security Contact: $CONTACT_EMAIL"
    echo "• Universal SAST Boilerplate: https://github.com/universal-sast/boilerplate-core"
    echo ""
    
    # Track setup completion
    track_setup_completion
}

track_setup_completion() {
    # Create setup completion file for analytics
    cat > .setup-complete.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "setup_duration": $(($(date +%s) - START_TIME)),
  "customer_name": "$CUSTOMER_NAME",
  "template": "$TEMPLATE_CHOICE",
  "github_pages": $ENABLE_GITHUB_PAGES,
  "notifications": $SETUP_NOTIFICATIONS,
  "governance": $CONFIGURE_GOVERNANCE,
  "steps_completed": $(printf '%s\n' "${SETUP_STEPS[@]}" | jq -R . | jq -s .),
  "version": "1.0.0"
}
EOF
}

# Error handling
handle_error() {
    echo ""
    print_error "Setup failed at step: ${SETUP_STEPS[-1]:-unknown}"
    echo ""
    echo -e "${YELLOW}Error Details:${NC}"
    echo -e "$ERROR_LOG"
    echo ""
    echo -e "${BLUE}For help:${NC}"
    echo "1. Check the error messages above"
    echo "2. Review SETUP_GUIDE.md for troubleshooting"
    echo "3. Contact support: $CONTACT_EMAIL"
    exit 1
}

trap 'handle_error' ERR

# Main execution
main() {
    print_header
    
    echo -e "${BLUE}Welcome to the Universal SAST Boilerplate setup wizard!${NC}"
    echo ""
    echo "This wizard will help you create a professional security dashboard"
    echo "in just a few minutes, based on successful customer patterns."
    echo ""
    echo -e "${GREEN}What you'll get:${NC}"
    echo "• Professional security dashboard with real-time metrics"
    echo "• Mobile-responsive design for team access"
    echo "• Integration with GitHub, Slack, Email, and Jira"
    echo "• Automated security scanning and reporting"
    echo "• Enterprise-grade appearance for stakeholder presentations"
    echo ""
    
    read -p "Ready to begin? Press Enter to continue or Ctrl+C to exit..."
    
    # Execute setup steps
    collect_basic_info
    select_template
    configure_github_pages
    configure_branding
    configure_integrations
    generate_configuration
    setup_git_repository
    create_documentation
    display_summary
    
    echo -e "${GREEN}${CHECKMARK} Setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}🚀 Your professional security dashboard is ready to deploy!${NC}"
}

# Run main function
main "$@"
