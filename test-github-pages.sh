#!/bin/bash

# 🧪 GitHub Pages Testing Script
# Test your SAST security dashboard locally and prepare for GitHub Pages deployment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TEST_PORT=8080
TEST_DIR="github-pages-test"
COMPANY_NAME="Test Company"
CONTACT_EMAIL="security@test-company.com"
GITHUB_REPO="https://github.com/test-user/test-repo"

show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🧪 GITHUB PAGES TESTING SUITE                  ║"
    echo "║          Test Your SAST Dashboard Before Deployment         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${PURPLE}🔧 $1${NC}"; }

cleanup() {
    log_step "Cleaning up test environment..."
    pkill -f "python3 -m http.server $TEST_PORT" 2>/dev/null || true
    rm -rf "$TEST_DIR" 2>/dev/null || true
    log_success "Cleanup completed"
}

prepare_test_dashboard() {
    log_step "Preparing test dashboard..."
    
    # Clean up any existing test
    cleanup
    
    # Copy professional template
    if [[ -d "templates/professional" ]]; then
        cp -r templates/professional "$TEST_DIR"
        log_success "Professional template copied"
    else
        log_error "Professional template not found"
        return 1
    fi
    
    cd "$TEST_DIR"
    
    # Customize template variables
    log_step "Customizing dashboard with test data..."
    
    # Replace template variables
    sed -i '' "s/{{COMPANY_NAME}}/$COMPANY_NAME/g" index.html 2>/dev/null || \
    sed -i "s/{{COMPANY_NAME}}/$COMPANY_NAME/g" index.html
    
    sed -i '' "s/{{CONTACT_EMAIL}}/$CONTACT_EMAIL/g" index.html 2>/dev/null || \
    sed -i "s/{{CONTACT_EMAIL}}/$CONTACT_EMAIL/g" index.html
    
    sed -i '' "s|{{GITHUB_REPO_URL}}|$GITHUB_REPO|g" index.html 2>/dev/null || \
    sed -i "s|{{GITHUB_REPO_URL}}|$GITHUB_REPO|g" index.html
    
    sed -i '' "s/{{CURRENT_YEAR}}/$(date +%Y)/g" index.html 2>/dev/null || \
    sed -i "s/{{CURRENT_YEAR}}/$(date +%Y)/g" index.html
    
    sed -i '' "s/{{LAST_UPDATED}}/$(date)/g" index.html 2>/dev/null || \
    sed -i "s/{{LAST_UPDATED}}/$(date)/g" index.html
    
    # Handle company logo placeholder
    sed -i '' 's|{{COMPANY_LOGO}}|data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTE2IDNMMTkuMDkgMTAuMjZMMjcgMTBMMjEgMTZMMjcgMjJMMTkuMDkgMjEuNzRMMTYgMjlMMTIuOTEgMjEuNzRMNSAyMkwxMSAxNkw1IDEwTDEyLjkxIDEwLjI2TDE2IDNaIiBmaWxsPSIjMzMzNiI+CjwvcGF0aD4KPC9zdmc+|g' index.html 2>/dev/null || \
    sed -i 's|{{COMPANY_LOGO}}|data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTE2IDNMMTkuMDkgMTAuMjZMMjcgMTBMMjEgMTZMMjcgMjJMMTkuMDkgMjEuNzRMMTYgMjlMMTIuOTEgMjEuNzRMNSAyMkwxMSAxNkw1IDEwTDEyLjkxIDEwLjI2TDE2IDNaIiBmaWxsPSIjMzMzNiI+CjwvcGF0aD4KPC9zdmc+|g' index.html
    
    log_success "Dashboard customized with test data"
    cd ..
}

start_local_server() {
    log_step "Starting local web server..."
    
    cd "$TEST_DIR"
    
    # Check if port is available
    if lsof -Pi :$TEST_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "Port $TEST_PORT is already in use. Stopping existing server..."
        pkill -f "python3 -m http.server $TEST_PORT" 2>/dev/null || true
        sleep 2
    fi
    
    # Start web server
    python3 -m http.server $TEST_PORT > /dev/null 2>&1 &
    local server_pid=$!
    
    # Wait for server to start
    sleep 3
    
    # Verify server is running
    if curl -s http://localhost:$TEST_PORT >/dev/null 2>&1; then
        log_success "Local web server started on port $TEST_PORT (PID: $server_pid)"
        echo "$server_pid" > .server_pid
        cd ..
        return 0
    else
        log_error "Failed to start web server"
        cd ..
        return 1
    fi
}

test_dashboard_functionality() {
    log_step "Testing dashboard functionality..."
    
    # Test basic connectivity
    if curl -s -f http://localhost:$TEST_PORT >/dev/null; then
        log_success "Dashboard is accessible"
    else
        log_error "Dashboard is not accessible"
        return 1
    fi
    
    # Test HTML content
    local html_content
    html_content=$(curl -s http://localhost:$TEST_PORT)
    
    if echo "$html_content" | grep -q "Security Dashboard"; then
        log_success "Dashboard title found"
    else
        log_warning "Dashboard title not found in HTML"
    fi
    
    if echo "$html_content" | grep -q "$COMPANY_NAME"; then
        log_success "Company name customization working"
    else
        log_warning "Company name not found in HTML"
    fi
    
    if echo "$html_content" | grep -q "Chart.js"; then
        log_success "Chart.js library loaded"
    else
        log_warning "Chart.js library not found"
    fi
    
    # Test CSS loading
    if echo "$html_content" | grep -q "professional.css"; then
        log_success "CSS stylesheet linked"
    else
        log_warning "CSS stylesheet not found"
    fi
    
    # Test JavaScript loading
    if echo "$html_content" | grep -q "professional-dashboard.js"; then
        log_success "Dashboard JavaScript linked"
    else
        log_warning "Dashboard JavaScript not found"
    fi
    
    log_success "Dashboard functionality test completed"
}

generate_github_pages_files() {
    log_step "Generating GitHub Pages deployment files..."
    
    # Create GitHub Pages workflow
    mkdir -p "$TEST_DIR/.github/workflows"
    
    cat > "$TEST_DIR/.github/workflows/deploy-pages.yml" << 'EOF'
name: 📊 Deploy Security Dashboard to GitHub Pages

on:
  push:
    branches: [ main, master ]
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Pages
      uses: actions/configure-pages@v4

    - name: Build Dashboard
      run: |
        mkdir -p _site
        if [ -d "templates/professional" ]; then
          cp -r templates/professional/* _site/
        else
          echo "<h1>Dashboard not found</h1>" > _site/index.html
        fi
        
        # Customize with repository info
        cd _site
        find . -name "*.html" -exec sed -i 's/{{COMPANY_NAME}}/${{ github.repository_owner }}/g' {} \;
        find . -name "*.html" -exec sed -i 's/{{GITHUB_REPO_URL}}/https:\/\/github.com\/${{ github.repository }}/g' {} \;
        find . -name "*.html" -exec sed -i 's/{{CURRENT_YEAR}}/'$(date +%Y)'/g' {} \;
        find . -name "*.html" -exec sed -i 's/{{LAST_UPDATED}}/'$(date)'/g' {} \;

    - name: Upload artifact
      uses: actions/upload-pages-artifact@v3

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
    - name: Deploy to GitHub Pages
      id: deployment
      uses: actions/deploy-pages@v4
EOF
    
    # Create README for GitHub Pages
    cat > "$TEST_DIR/README-GITHUB-PAGES.md" << EOF
# 📊 GitHub Pages Security Dashboard

This directory contains your SAST security dashboard ready for GitHub Pages deployment.

## 🚀 Quick Setup

1. **Enable GitHub Pages** in your repository:
   - Go to Settings > Pages
   - Source: GitHub Actions
   - Save settings

2. **Push to your repository**:
   \`\`\`bash
   git add .
   git commit -m "Add GitHub Pages security dashboard"
   git push origin main
   \`\`\`

3. **Access your dashboard**:
   - URL: \`https://[username].github.io/[repository]\`
   - Updates automatically on every push

## 📋 Features

- ✅ Real-time security metrics
- ✅ Interactive charts and graphs  
- ✅ Scanner performance monitoring
- ✅ Professional responsive design
- ✅ Automatic updates via GitHub Actions

## 🔧 Customization

Edit the following files to customize:
- \`index.html\` - Main dashboard content
- \`assets/css/professional.css\` - Styling
- \`assets/js/professional-dashboard.js\` - Functionality

Generated by SAST Testing Suite on $(date)
EOF
    
    log_success "GitHub Pages files generated"
}

show_test_results() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 TESTING COMPLETE!                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🌐 Your dashboard is running at:${NC}"
    echo -e "${YELLOW}   http://localhost:$TEST_PORT${NC}"
    echo ""
    echo -e "${CYAN}📁 Test files location:${NC}"
    echo -e "${YELLOW}   ./$TEST_DIR/${NC}"
    echo ""
    echo -e "${CYAN}🚀 Next steps:${NC}"
    echo "1. Open http://localhost:$TEST_PORT in your browser"
    echo "2. Test all dashboard features and interactions"
    echo "3. Copy files to your repository for GitHub Pages"
    echo "4. Enable GitHub Pages in repository settings"
    echo ""
    echo -e "${CYAN}🔧 GitHub Pages deployment:${NC}"
    echo "1. Copy .github/workflows/deploy-pages.yml to your repo"
    echo "2. Copy dashboard files to your repository root"
    echo "3. Push to GitHub and enable Pages in Settings"
    echo ""
    echo -e "${CYAN}⏹️  Stop the test server:${NC}"
    echo -e "${YELLOW}   ./test-github-pages.sh --stop${NC}"
    echo ""
}

stop_server() {
    log_step "Stopping test server..."
    
    if [[ -f "$TEST_DIR/.server_pid" ]]; then
        local pid
        pid=$(cat "$TEST_DIR/.server_pid")
        if kill "$pid" 2>/dev/null; then
            log_success "Server stopped (PID: $pid)"
        else
            log_warning "Server process not found"
        fi
        rm -f "$TEST_DIR/.server_pid"
    else
        pkill -f "python3 -m http.server $TEST_PORT" 2>/dev/null || true
        log_success "Server processes stopped"
    fi
}

show_help() {
    cat << EOF
🧪 GitHub Pages Testing Suite

USAGE:
    ./test-github-pages.sh [OPTIONS]

OPTIONS:
    --start         Start the test dashboard (default)
    --stop          Stop the test server
    --port PORT     Use custom port (default: $TEST_PORT)
    --company NAME  Set company name
    --email EMAIL   Set contact email
    --repo URL      Set GitHub repository URL
    --clean         Clean up test files and exit
    --help          Show this help

EXAMPLES:
    ./test-github-pages.sh                              # Start with defaults
    ./test-github-pages.sh --port 9000                  # Use port 9000
    ./test-github-pages.sh --company "My Company"       # Custom company name
    ./test-github-pages.sh --stop                       # Stop the server
    ./test-github-pages.sh --clean                      # Clean up files

TESTING WORKFLOW:
1. Run script to start local dashboard
2. Open http://localhost:$TEST_PORT in browser
3. Test all features and functionality
4. Copy generated files to your repository
5. Enable GitHub Pages in repository settings

EOF
}

main() {
    local action="start"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --start)
                action="start"
                shift
                ;;
            --stop)
                action="stop"
                shift
                ;;
            --port)
                TEST_PORT="$2"
                shift 2
                ;;
            --company)
                COMPANY_NAME="$2"
                shift 2
                ;;
            --email)
                CONTACT_EMAIL="$2"
                shift 2
                ;;
            --repo)
                GITHUB_REPO="$2"
                shift 2
                ;;
            --clean)
                action="clean"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    case $action in
        start)
            show_banner
            prepare_test_dashboard
            generate_github_pages_files
            start_local_server
            test_dashboard_functionality
            show_test_results
            ;;
        stop)
            stop_server
            ;;
        clean)
            cleanup
            log_success "Test environment cleaned"
            ;;
    esac
}

# Trap for cleanup on exit
trap cleanup EXIT

main "$@"
