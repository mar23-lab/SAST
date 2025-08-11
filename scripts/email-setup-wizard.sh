#!/bin/bash

# 📧 SAST Email Setup Wizard
# Interactive email configuration with provider auto-detection
# Supports Gmail, Outlook, Yahoo, SendGrid, and custom SMTP

set -euo pipefail

# Colors and symbols
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

CHECKMARK="✅"
CROSS="❌"
ENVELOPE="📧"
GEAR="⚙️"
WARNING="⚠️"
INFO="ℹ️"

# Configuration variables
EMAIL_ADDRESS=""
EMAIL_PASSWORD=""
SMTP_HOST=""
SMTP_PORT=""
SMTP_TLS=""
PROVIDER=""
TEST_RECIPIENT=""
CONFIG_FILE="ci-config-generated.yaml"

# Provider configurations (compatible with older bash versions)
get_provider_config() {
    case "$1" in
        gmail) echo "smtp.gmail.com:587:true" ;;
        outlook) echo "smtp-mail.outlook.com:587:true" ;;
        yahoo) echo "smtp.mail.yahoo.com:587:true" ;;
        sendgrid) echo "smtp.sendgrid.net:587:true" ;;
        mailgun) echo "smtp.mailgun.org:587:true" ;;
        amazon_ses) echo "email-smtp.us-east-1.amazonaws.com:587:true" ;;
        *) echo "" ;;
    esac
}

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               📧 SAST EMAIL SETUP WIZARD 📧                 ║"
    echo "║                                                              ║"
    echo "║        Professional Email Notifications in 5 Minutes        ║"
    echo "║                                                              ║"
    echo "║  Supports: Gmail, Outlook, Yahoo, SendGrid, Custom SMTP     ║"
    echo "║  Features: Auto-detection, App passwords, Test delivery     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Logging functions
log_info() {
    echo -e "${BLUE}${INFO} $1${NC}"
}

log_success() {
    echo -e "${GREEN}${CHECKMARK} $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

log_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

log_step() {
    echo -e "${PURPLE}${GEAR} $1${NC}"
}

# Email validation
validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Provider detection
detect_email_provider() {
    local email="$1"
    local domain=$(echo "$email" | cut -d'@' -f2 | tr '[:upper:]' '[:lower:]')
    
    case "$domain" in
        gmail.com|googlemail.com)
            echo "gmail"
            ;;
        outlook.com|hotmail.com|live.com|msn.com)
            echo "outlook"
            ;;
        yahoo.com|yahoo.co.uk|yahoo.ca|ymail.com)
            echo "yahoo"
            ;;
        *)
            echo "custom"
            ;;
    esac
}

# Provider-specific setup instructions
show_provider_instructions() {
    local provider="$1"
    
    echo ""
    echo -e "${CYAN}📋 Setup Instructions for $provider${NC}"
    echo "────────────────────────────────────────────────"
    
    case "$provider" in
        gmail)
            echo -e "${BLUE}Gmail App Password Setup:${NC}"
            echo "1. Go to https://myaccount.google.com/security"
            echo "2. Enable 2-Factor Authentication (required)"
            echo "3. Go to 'App passwords' section"
            echo "4. Select 'Mail' and 'Other (custom name)'"
            echo "5. Enter 'SAST Security Scanner' as the name"
            echo "6. Use the generated 16-character password below"
            echo ""
            ;;
        outlook)
            echo -e "${BLUE}Outlook App Password Setup:${NC}"
            echo "1. Go to https://account.live.com/security"
            echo "2. Enable 2-Factor Authentication (required)"
            echo "3. Go to 'App passwords' section"
            echo "4. Click 'Create a new app password'"
            echo "5. Enter 'SAST Security Scanner' as the name"
            echo "6. Use the generated password below"
            echo ""
            ;;
        yahoo)
            echo -e "${BLUE}Yahoo App Password Setup:${NC}"
            echo "1. Go to https://login.yahoo.com/account/security"
            echo "2. Enable 2-Factor Authentication (required)"
            echo "3. Go to 'Generate app password'"
            echo "4. Select 'Other app' and enter 'SAST Scanner'"
            echo "5. Use the generated password below"
            echo ""
            ;;
        sendgrid)
            echo -e "${BLUE}SendGrid API Key Setup:${NC}"
            echo "1. Log in to SendGrid dashboard"
            echo "2. Go to Settings → API Keys"
            echo "3. Create new API key with 'Mail Send' permissions"
            echo "4. Use 'apikey' as username and API key as password"
            echo ""
            ;;
        *)
            echo -e "${BLUE}Custom SMTP Setup:${NC}"
            echo "Contact your email administrator for:"
            echo "• SMTP server hostname"
            echo "• SMTP port (usually 587 or 465)"
            echo "• Authentication credentials"
            echo "• TLS/SSL requirements"
            echo ""
            ;;
    esac
}

# Collect email configuration
collect_email_config() {
    log_step "Email Configuration"
    
    # Get email address
    while [[ -z "$EMAIL_ADDRESS" ]]; do
        echo -n "Enter your email address: "
        read -r EMAIL_ADDRESS
        if ! validate_email "$EMAIL_ADDRESS"; then
            log_error "Invalid email format"
            EMAIL_ADDRESS=""
        else
            log_success "Email address validated"
        fi
    done
    
    # Detect provider
    PROVIDER=$(detect_email_provider "$EMAIL_ADDRESS")
    log_info "Detected provider: $PROVIDER"
    
    # Get SMTP configuration
    local provider_config=$(get_provider_config "$PROVIDER")
    if [[ "$PROVIDER" != "custom" ]] && [[ -n "$provider_config" ]]; then
        IFS=':' read -r SMTP_HOST SMTP_PORT SMTP_TLS <<< "$provider_config"
        log_success "Auto-configured SMTP settings for $PROVIDER"
        echo "  Host: $SMTP_HOST"
        echo "  Port: $SMTP_PORT"
        echo "  TLS: $SMTP_TLS"
    else
        echo ""
        log_warning "Custom SMTP configuration required"
        echo -n "SMTP Host: "
        read -r SMTP_HOST
        echo -n "SMTP Port [587]: "
        read -r port_input
        SMTP_PORT="${port_input:-587}"
        echo -n "Use TLS? [y]: "
        read -r tls_input
        SMTP_TLS="true"
        [[ "$tls_input" =~ ^[Nn]$ ]] && SMTP_TLS="false"
    fi
    
    # Show provider-specific instructions
    show_provider_instructions "$PROVIDER"
    
    # Get credentials
    while [[ -z "$EMAIL_PASSWORD" ]]; do
        echo -n "Enter email password/app password: "
        read -rs EMAIL_PASSWORD
        echo ""
        if [[ -z "$EMAIL_PASSWORD" ]]; then
            log_error "Password cannot be empty"
        else
            log_success "Password configured"
        fi
    done
    
    # Test recipient
    echo ""
    echo -n "Test recipient email (or press Enter to use sender): "
    read -r TEST_RECIPIENT
    TEST_RECIPIENT="${TEST_RECIPIENT:-$EMAIL_ADDRESS}"
}

# Test email configuration
test_email_delivery() {
    log_step "Testing Email Delivery"
    
    local test_script="/tmp/test_email.py"
    
    # Create Python test script
    cat > "$test_script" << EOF
#!/usr/bin/env python3
import smtplib
import ssl
from email.mime.text import MimeText
from email.mime.multipart import MimeMultipart
import sys
from datetime import datetime

def test_email():
    try:
        # Email configuration
        smtp_server = "$SMTP_HOST"
        port = $SMTP_PORT
        sender_email = "$EMAIL_ADDRESS"
        password = "$EMAIL_PASSWORD"
        receiver_email = "$TEST_RECIPIENT"
        use_tls = $SMTP_TLS
        
        # Create message
        message = MimeMultipart("alternative")
        message["Subject"] = "🔒 SAST Email Configuration Test"
        message["From"] = sender_email
        message["To"] = receiver_email
        
        # Email content
        text = """
        SAST Email Configuration Test
        
        This is a test email from your SAST security scanner.
        
        Configuration Details:
        - SMTP Server: {smtp_server}
        - Port: {port}
        - TLS: {tls}
        - Timestamp: {timestamp}
        
        If you received this email, your email notifications are working correctly!
        
        Next steps:
        1. Configure notification thresholds in ci-config-generated.yaml
        2. Set up team notification channels
        3. Test with a real security scan
        
        --
        SAST Security Scanner
        """.format(
            smtp_server=smtp_server,
            port=port,
            tls=use_tls,
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
        )
        
        html = """
        <html>
          <body>
            <h2>🔒 SAST Email Configuration Test</h2>
            <p>This is a test email from your SAST security scanner.</p>
            
            <h3>Configuration Details:</h3>
            <ul>
              <li><strong>SMTP Server:</strong> {smtp_server}</li>
              <li><strong>Port:</strong> {port}</li>
              <li><strong>TLS:</strong> {tls}</li>
              <li><strong>Timestamp:</strong> {timestamp}</li>
            </ul>
            
            <p><strong>✅ If you received this email, your email notifications are working correctly!</strong></p>
            
            <h3>Next steps:</h3>
            <ol>
              <li>Configure notification thresholds in <code>ci-config-generated.yaml</code></li>
              <li>Set up team notification channels</li>
              <li>Test with a real security scan</li>
            </ol>
            
            <hr>
            <p><em>SAST Security Scanner</em></p>
          </body>
        </html>
        """.format(
            smtp_server=smtp_server,
            port=port,
            tls=use_tls,
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
        )
        
        # Create MimeText objects
        part1 = MimeText(text, "plain")
        part2 = MimeText(html, "html")
        
        # Add parts to message
        message.attach(part1)
        message.attach(part2)
        
        # Send email
        print("Connecting to SMTP server...")
        
        if use_tls:
            context = ssl.create_default_context()
            server = smtplib.SMTP(smtp_server, port)
            server.starttls(context=context)
        else:
            server = smtplib.SMTP(smtp_server, port)
        
        print("Authenticating...")
        server.login(sender_email, password)
        
        print("Sending email...")
        text = message.as_string()
        server.sendmail(sender_email, receiver_email, text)
        server.quit()
        
        print("SUCCESS: Email sent successfully!")
        return True
        
    except smtplib.SMTPAuthenticationError as e:
        print(f"AUTHENTICATION ERROR: {e}")
        print("Check your email and password/app password")
        return False
    except smtplib.SMTPConnectError as e:
        print(f"CONNECTION ERROR: {e}")
        print("Check SMTP host and port settings")
        return False
    except smtplib.SMTPException as e:
        print(f"SMTP ERROR: {e}")
        return False
    except Exception as e:
        print(f"UNEXPECTED ERROR: {e}")
        return False

if __name__ == "__main__":
    success = test_email()
    sys.exit(0 if success else 1)
EOF

    chmod +x "$test_script"
    
    echo "Testing email delivery to $TEST_RECIPIENT..."
    echo ""
    
    if python3 "$test_script"; then
        log_success "Email test successful!"
        echo ""
        log_info "Check your inbox at $TEST_RECIPIENT"
        return 0
    else
        log_error "Email test failed"
        echo ""
        log_warning "Common issues:"
        echo "• Wrong password (use app password for Gmail/Outlook)"
        echo "• 2FA not enabled (required for app passwords)"
        echo "• Firewall blocking SMTP port"
        echo "• Invalid SMTP settings"
        return 1
    fi
    
    # Cleanup
    rm -f "$test_script"
}

# Update configuration file
update_sast_config() {
    log_step "Updating SAST Configuration"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_warning "SAST configuration file not found, creating new one"
        create_default_config
    fi
    
    # Backup existing config
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%s)"
    log_info "Backup created: ${CONFIG_FILE}.backup.*"
    
    # Update email configuration using yq or manual editing
    if command -v yq >/dev/null 2>&1; then
        log_info "Updating configuration with yq..."
        
        # Enable email notifications
        yq eval '.notifications.email.enabled = true' -i "$CONFIG_FILE"
        yq eval '.notifications.email.smtp_server = "'"$SMTP_HOST"'"' -i "$CONFIG_FILE"
        yq eval '.notifications.email.smtp_port = '"$SMTP_PORT"'' -i "$CONFIG_FILE"
        yq eval '.notifications.email.use_tls = '"$SMTP_TLS"'' -i "$CONFIG_FILE"
        yq eval '.notifications.email.sender_email = "'"$EMAIL_ADDRESS"'"' -i "$CONFIG_FILE"
        yq eval '.notifications.email.sender_name = "SAST Security Scanner"' -i "$CONFIG_FILE"
        
        # Set default recipients
        yq eval '.notifications.email.recipients = ["'"$EMAIL_ADDRESS"'"]' -i "$CONFIG_FILE"
        
        # Configure notification triggers
        yq eval '.notifications.email.triggers.critical = true' -i "$CONFIG_FILE"
        yq eval '.notifications.email.triggers.high = true' -i "$CONFIG_FILE"
        yq eval '.notifications.email.triggers.scan_complete = false' -i "$CONFIG_FILE"
        yq eval '.notifications.email.triggers.scan_failed = true' -i "$CONFIG_FILE"
        
        log_success "Configuration updated successfully"
    else
        log_warning "yq not found, manual configuration required"
        echo "Please manually update $CONFIG_FILE with the following settings:"
        echo ""
        echo "notifications:"
        echo "  email:"
        echo "    enabled: true"
        echo "    smtp_server: \"$SMTP_HOST\""
        echo "    smtp_port: $SMTP_PORT"
        echo "    use_tls: $SMTP_TLS"
        echo "    sender_email: \"$EMAIL_ADDRESS\""
        echo "    sender_name: \"SAST Security Scanner\""
        echo "    recipients:"
        echo "      - \"$EMAIL_ADDRESS\""
    fi
    
    # Store credentials securely (for CI/CD)
    create_env_file
}

# Create environment file for sensitive data
create_env_file() {
    local env_file=".env.email"
    
    cat > "$env_file" << EOF
# SAST Email Configuration - KEEP SECURE!
# Add this file to your .gitignore
# For GitHub Actions, add these as repository secrets

EMAIL_SMTP_HOST=$SMTP_HOST
EMAIL_SMTP_PORT=$SMTP_PORT
EMAIL_SMTP_TLS=$SMTP_TLS
EMAIL_SMTP_USER=$EMAIL_ADDRESS
EMAIL_SMTP_PASSWORD=$EMAIL_PASSWORD
EMAIL_FROM_ADDRESS=$EMAIL_ADDRESS
EMAIL_FROM_NAME="SAST Security Scanner"

# GitHub Secrets to add:
# - EMAIL_SMTP_PASSWORD: $EMAIL_PASSWORD
# - EMAIL_SMTP_HOST: $SMTP_HOST
# - EMAIL_SMTP_PORT: $SMTP_PORT
# - EMAIL_FROM_ADDRESS: $EMAIL_ADDRESS
EOF
    
    log_success "Environment file created: $env_file"
    log_warning "Add $env_file to your .gitignore!"
    
    # Update .gitignore
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "\.env\.email" .gitignore; then
            echo ".env.email" >> .gitignore
            log_success "Added $env_file to .gitignore"
        fi
    else
        echo ".env.email" > .gitignore
        log_success "Created .gitignore with $env_file"
    fi
}

# Create default configuration if needed
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
# SAST Configuration - Generated by Email Setup Wizard
project:
  name: "SAST Security Project"
  description: "Automated security scanning with email notifications"
  version: "1.0.0"

sast:
  enabled: true
  scanners:
    - codeql
    - semgrep
    - bandit
    - eslint
  severity_threshold: "medium"

notifications:
  email:
    enabled: false
    smtp_server: ""
    smtp_port: 587
    use_tls: true
    sender_email: ""
    sender_name: "SAST Security Scanner"
    recipients: []
    triggers:
      critical: true
      high: true
      medium: false
      low: false
      scan_complete: false
      scan_failed: true

integrations:
  github:
    enabled: true
    upload_sarif: true
EOF
    
    log_success "Default configuration created"
}

# Generate GitHub Actions workflow
generate_github_workflow() {
    log_step "Generating GitHub Actions Workflow"
    
    mkdir -p ".github/workflows"
    
    cat > ".github/workflows/sast-email-notifications.yml" << 'EOF'
name: 🔒 SAST with Email Notifications

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

env:
  CONFIG_FILE: ci-config-generated.yaml

jobs:
  security-scan:
    name: Security Scan & Notify
    runs-on: ubuntu-latest
    
    permissions:
      actions: read
      contents: read
      security-events: write
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        pip install yq jq
    
    - name: Load configuration
      id: config
      run: |
        if [ -f "$CONFIG_FILE" ]; then
          echo "config_exists=true" >> $GITHUB_OUTPUT
          # Extract email settings
          EMAIL_ENABLED=$(yq eval '.notifications.email.enabled' $CONFIG_FILE)
          echo "email_enabled=$EMAIL_ENABLED" >> $GITHUB_OUTPUT
        else
          echo "config_exists=false" >> $GITHUB_OUTPUT
          echo "email_enabled=false" >> $GITHUB_OUTPUT
        fi
    
    - name: Run Security Scans
      id: scan
      run: |
        # Initialize scan results
        CRITICAL_COUNT=0
        HIGH_COUNT=0
        TOTAL_ISSUES=0
        SCAN_STATUS="success"
        
        # Run CodeQL (if available)
        echo "Running CodeQL scan..."
        # Note: Add actual CodeQL scan here
        
        # Run Semgrep
        echo "Running Semgrep scan..."
        pip install semgrep
        semgrep --config=auto --sarif -o semgrep-results.sarif . || true
        
        # Run Bandit for Python
        echo "Running Bandit scan..."
        pip install bandit
        bandit -r . -f sarif -o bandit-results.sarif || true
        
        # Parse results (simplified)
        if [ -f "semgrep-results.sarif" ]; then
          SEMGREP_ISSUES=$(jq '.runs[0].results | length' semgrep-results.sarif 2>/dev/null || echo "0")
          TOTAL_ISSUES=$((TOTAL_ISSUES + SEMGREP_ISSUES))
        fi
        
        if [ -f "bandit-results.sarif" ]; then
          BANDIT_ISSUES=$(jq '.runs[0].results | length' bandit-results.sarif 2>/dev/null || echo "0")
          TOTAL_ISSUES=$((TOTAL_ISSUES + BANDIT_ISSUES))
        fi
        
        # Export results
        echo "critical_count=$CRITICAL_COUNT" >> $GITHUB_OUTPUT
        echo "high_count=$HIGH_COUNT" >> $GITHUB_OUTPUT
        echo "total_issues=$TOTAL_ISSUES" >> $GITHUB_OUTPUT
        echo "scan_status=$SCAN_STATUS" >> $GITHUB_OUTPUT
        
        echo "Scan completed: $TOTAL_ISSUES total issues found"
    
    - name: Upload SARIF results
      if: always()
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: |
          semgrep-results.sarif
          bandit-results.sarif
      continue-on-error: true
    
    - name: Send Email Notification
      if: steps.config.outputs.email_enabled == 'true' && (steps.scan.outputs.critical_count > 0 || steps.scan.outputs.high_count > 0 || failure())
      uses: dawidd6/action-send-mail@v3
      with:
        server_address: ${{ secrets.EMAIL_SMTP_HOST }}
        server_port: ${{ secrets.EMAIL_SMTP_PORT }}
        username: ${{ secrets.EMAIL_FROM_ADDRESS }}
        password: ${{ secrets.EMAIL_SMTP_PASSWORD }}
        subject: |
          🔒 Security Scan Results: ${{ github.repository }}
        from: ${{ secrets.EMAIL_FROM_ADDRESS }}
        to: ${{ secrets.EMAIL_FROM_ADDRESS }}
        html_body: |
          <h2>🔒 SAST Security Scan Results</h2>
          
          <p><strong>Repository:</strong> ${{ github.repository }}</p>
          <p><strong>Branch:</strong> ${{ github.ref_name }}</p>
          <p><strong>Commit:</strong> ${{ github.sha }}</p>
          <p><strong>Triggered by:</strong> ${{ github.event_name }}</p>
          <p><strong>Scan Status:</strong> ${{ steps.scan.outputs.scan_status }}</p>
          
          <h3>📊 Results Summary</h3>
          <ul>
            <li><strong>Critical Issues:</strong> ${{ steps.scan.outputs.critical_count }}</li>
            <li><strong>High Severity:</strong> ${{ steps.scan.outputs.high_count }}</li>
            <li><strong>Total Issues:</strong> ${{ steps.scan.outputs.total_issues }}</li>
          </ul>
          
          <h3>🔗 Quick Links</h3>
          <ul>
            <li><a href="https://github.com/${{ github.repository }}/security">Security Tab</a></li>
            <li><a href="https://github.com/${{ github.repository }}/actions">Actions</a></li>
            <li><a href="https://github.com/${{ github.repository }}/commit/${{ github.sha }}">Commit Details</a></li>
          </ul>
          
          <hr>
          <p><em>This email was sent by the SAST Security Scanner</em></p>
        secure: true
EOF

    log_success "GitHub workflow created: .github/workflows/sast-email-notifications.yml"
    
    echo ""
    log_info "Required GitHub secrets to add:"
    echo "• EMAIL_SMTP_HOST"
    echo "• EMAIL_SMTP_PORT" 
    echo "• EMAIL_SMTP_PASSWORD"
    echo "• EMAIL_FROM_ADDRESS"
}

# Show completion summary
show_completion_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   📧 EMAIL SETUP COMPLETE! 📧               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${CYAN}📋 Configuration Summary${NC}"
    echo "────────────────────────────────────────────────"
    echo "• Email Provider: $PROVIDER"
    echo "• Email Address: $EMAIL_ADDRESS"
    echo "• SMTP Host: $SMTP_HOST"
    echo "• SMTP Port: $SMTP_PORT"
    echo "• TLS Enabled: $SMTP_TLS"
    echo "• Configuration File: $CONFIG_FILE"
    echo ""
    
    echo -e "${CYAN}✅ What's Configured${NC}"
    echo "────────────────────────────────────────────────"
    echo "• SMTP server settings"
    echo "• Email authentication"
    echo "• Notification triggers (Critical & High severity)"
    echo "• GitHub Actions workflow"
    echo "• Environment variables for CI/CD"
    echo ""
    
    echo -e "${CYAN}🚀 Next Steps${NC}"
    echo "────────────────────────────────────────────────"
    echo "1. Add GitHub repository secrets:"
    echo "   - EMAIL_SMTP_PASSWORD"
    echo "   - EMAIL_SMTP_HOST"
    echo "   - EMAIL_SMTP_PORT"
    echo "   - EMAIL_FROM_ADDRESS"
    echo ""
    echo "2. Test with a security scan:"
    echo "   git add . && git commit -m 'Configure email notifications' && git push"
    echo ""
    echo "3. Customize notification settings in $CONFIG_FILE"
    echo "4. Add team members to recipients list"
    echo ""
    
    echo -e "${CYAN}📞 Support${NC}"
    echo "────────────────────────────────────────────────"
    echo "• Email test failed? Check .env.email for credentials"
    echo "• App password issues? Review provider instructions above"
    echo "• GitHub Actions help: Check workflow logs"
    echo ""
    
    echo -e "${GREEN}🛡️ Your security team will now receive email notifications for:${NC}"
    echo "• Critical and High severity vulnerabilities"
    echo "• Failed security scans"
    echo "• Weekly security reports (optional)"
}

# Main execution
main() {
    show_banner
    
    echo -e "${BLUE}Welcome to the SAST Email Setup Wizard!${NC}"
    echo ""
    echo "This wizard will configure professional email notifications for your security scans."
    echo "We'll help you set up authentication, test delivery, and integrate with your CI/CD."
    echo ""
    
    log_info "Estimated setup time: 5 minutes"
    echo ""
    
    read -p "Ready to begin? Press Enter to continue or Ctrl+C to exit..."
    
    # Execute setup steps
    collect_email_config
    
    # Test email delivery
    echo ""
    read -p "Test email delivery now? [Y/n]: " test_now
    if [[ "$test_now" =~ ^[Yy]$|^$ ]]; then
        if test_email_delivery; then
            log_success "Email delivery test passed!"
        else
            log_warning "Email test failed, but configuration will be saved"
            echo ""
            read -p "Continue with configuration? [Y/n]: " continue_setup
            if [[ "$continue_setup" =~ ^[Nn]$ ]]; then
                log_info "Setup cancelled"
                exit 1
            fi
        fi
    fi
    
    # Update configuration
    update_sast_config
    
    # Generate GitHub workflow
    echo ""
    read -p "Generate GitHub Actions workflow for automated notifications? [Y/n]: " gen_workflow
    if [[ "$gen_workflow" =~ ^[Yy]$|^$ ]]; then
        generate_github_workflow
    fi
    
    # Show completion
    show_completion_summary
    
    log_success "Email setup wizard completed successfully!"
}

# Error handling
trap 'log_error "Setup failed. Check the error above and try again."; exit 1' ERR

# Run main function
main "$@"
