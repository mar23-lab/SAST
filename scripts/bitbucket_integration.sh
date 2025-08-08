#!/bin/bash

# ===================================================================
# Bitbucket Integration Script for SAST Security Scanning
# ===================================================================
# This script provides Bitbucket-specific integration features:
# - PR comments with vulnerability summaries
# - Build status updates
# - Repository variables management
# - Webhook configuration

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../ci-config.yaml"
RESULTS_DIR="./sast-results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Bitbucket API configuration
BITBUCKET_API_URL="https://api.bitbucket.org/2.0"
WORKSPACE="${BITBUCKET_WORKSPACE:-}"
REPO_SLUG="${BITBUCKET_REPO_SLUG:-}"
PR_ID="${BITBUCKET_PR_ID:-}"
BUILD_NUMBER="${BITBUCKET_BUILD_NUMBER:-}"

# Display usage information
show_usage() {
    cat << EOF
🔧 Bitbucket Integration for SAST Security Scanning

USAGE:
    ./bitbucket_integration.sh [COMMAND] [OPTIONS]

COMMANDS:
    pr-comment          Add vulnerability summary comment to PR
    build-status        Update build status with scan results
    setup-variables     Configure repository variables for SAST
    setup-webhooks      Configure webhooks for notifications
    test-integration    Test Bitbucket API connectivity

OPTIONS:
    --pr-id ID          Specify PR ID (default: from environment)
    --workspace NAME    Specify workspace (default: from environment)
    --repo SLUG         Specify repository slug (default: from environment)
    --dry-run           Show what would be done without executing
    --verbose           Enable verbose output

EXAMPLES:
    ./bitbucket_integration.sh pr-comment --pr-id 123
    ./bitbucket_integration.sh build-status
    ./bitbucket_integration.sh setup-variables
    ./bitbucket_integration.sh test-integration --verbose

EOF
}

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

log_verbose() {
    if [ "${VERBOSE:-false}" = "true" ]; then
        echo -e "${BLUE}🔍 $1${NC}"
    fi
}

# Check Bitbucket API credentials
check_credentials() {
    if [ -z "${BITBUCKET_APP_PASSWORD:-}" ]; then
        log_error "BITBUCKET_APP_PASSWORD environment variable not set"
        log_info "Create an app password at: https://bitbucket.org/account/settings/app-passwords/"
        return 1
    fi
    
    if [ -z "${BITBUCKET_USERNAME:-}" ]; then
        log_error "BITBUCKET_USERNAME environment variable not set"
        return 1
    fi
    
    return 0
}

# Make authenticated API request to Bitbucket
bitbucket_api_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    
    local url="${BITBUCKET_API_URL}${endpoint}"
    local auth="${BITBUCKET_USERNAME}:${BITBUCKET_APP_PASSWORD}"
    
    log_verbose "Making $method request to: $url"
    
    if [ -n "$data" ]; then
        curl -s -X "$method" \
             -u "$auth" \
             -H "Content-Type: application/json" \
             -d "$data" \
             "$url"
    else
        curl -s -X "$method" \
             -u "$auth" \
             -H "Content-Type: application/json" \
             "$url"
    fi
}

# Load scan results
load_scan_results() {
    local results_file="$RESULTS_DIR/overall-summary.json"
    
    if [ ! -f "$results_file" ]; then
        log_error "Scan results not found: $results_file"
        return 1
    fi
    
    # Export results as environment variables
    export SCAN_STATUS=$(jq -r '.status' "$results_file")
    export TOTAL_CRITICAL=$(jq '.total_vulnerabilities.critical' "$results_file")
    export TOTAL_HIGH=$(jq '.total_vulnerabilities.high' "$results_file")
    export TOTAL_MEDIUM=$(jq '.total_vulnerabilities.medium' "$results_file")
    export TOTAL_LOW=$(jq '.total_vulnerabilities.low' "$results_file")
    export TOTAL_FINDINGS=$(jq '.total_findings' "$results_file")
    
    log_verbose "Loaded scan results: $TOTAL_FINDINGS total findings"
    return 0
}

# Generate PR comment content
generate_pr_comment() {
    local comment_file="$RESULTS_DIR/pr-comment.md"
    
    cat > "$comment_file" << EOF
## 🔒 SAST Security Scan Results

**Scan Status**: $([ "$SCAN_STATUS" = "success" ] && echo "✅ PASSED" || echo "❌ FAILED")  
**Build**: #${BUILD_NUMBER}  
**Timestamp**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

### 📊 Vulnerability Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | $TOTAL_CRITICAL |
| 🟠 High | $TOTAL_HIGH |
| 🟡 Medium | $TOTAL_MEDIUM |
| 🔵 Low | $TOTAL_LOW |
| **📊 Total** | **$TOTAL_FINDINGS** |

### 🔧 Scanners Used

$(jq -r '.scanners_run[]' "$RESULTS_DIR/overall-summary.json" | sed 's/^/- /')

### 📋 Next Steps

EOF

    if [ "$SCAN_STATUS" = "failure" ]; then
        cat >> "$comment_file" << EOF
❌ **Action Required**: This PR introduces security vulnerabilities that need to be addressed.

- Review the detailed scan results
- Fix critical and high severity issues
- Consider suppressing false positives if applicable

📄 **Detailed Results**: Check the pipeline artifacts for complete SARIF reports.
EOF
    else
        cat >> "$comment_file" << EOF
✅ **Good to go**: No critical security issues found in this PR.

- All security scans passed
- Ready for review and merge

📄 **Detailed Results**: Available in pipeline artifacts.
EOF
    fi
    
    cat >> "$comment_file" << EOF

---
*🤖 Automated security scan powered by [SAST Boilerplate](https://github.com/xlooop-ai/SAST)*
EOF
    
    echo "$comment_file"
}

# Add comment to PR
add_pr_comment() {
    if [ -z "$PR_ID" ]; then
        log_error "PR_ID not specified"
        return 1
    fi
    
    log_info "Adding security scan comment to PR #$PR_ID"
    
    # Load scan results
    if ! load_scan_results; then
        return 1
    fi
    
    # Generate comment content
    local comment_file
    comment_file=$(generate_pr_comment)
    local comment_content
    comment_content=$(cat "$comment_file")
    
    # Prepare API request
    local endpoint="/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$PR_ID/comments"
    local payload
    payload=$(jq -n --arg content "$comment_content" '{
        content: {
            raw: $content
        }
    }')
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "DRY RUN: Would add comment to PR #$PR_ID"
        log_verbose "Comment content: $comment_content"
        return 0
    fi
    
    # Make API request
    local response
    response=$(bitbucket_api_request "POST" "$endpoint" "$payload")
    
    if echo "$response" | jq -e '.id' > /dev/null; then
        log_success "Comment added to PR #$PR_ID"
        return 0
    else
        log_error "Failed to add comment to PR #$PR_ID"
        log_verbose "Response: $response"
        return 1
    fi
}

# Update build status
update_build_status() {
    log_info "Updating build status for commit"
    
    # Load scan results
    if ! load_scan_results; then
        return 1
    fi
    
    # Determine build status
    local state
    local description
    
    if [ "$SCAN_STATUS" = "success" ]; then
        state="SUCCESSFUL"
        description="✅ Security scan passed - $TOTAL_FINDINGS findings"
    else
        state="FAILED"
        description="❌ Security scan failed - $TOTAL_CRITICAL critical, $TOTAL_HIGH high"
    fi
    
    # Get commit hash
    local commit_hash="${BITBUCKET_COMMIT:-$(git rev-parse HEAD)}"
    
    # Prepare API request
    local endpoint="/repositories/$WORKSPACE/$REPO_SLUG/commit/$commit_hash/statuses/build"
    local payload
    payload=$(jq -n \
        --arg state "$state" \
        --arg key "sast-security-scan" \
        --arg name "SAST Security Scan" \
        --arg description "$description" \
        --arg url "${BITBUCKET_BUILD_URL:-}" \
        '{
            state: $state,
            key: $key,
            name: $name,
            description: $description,
            url: $url
        }')
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "DRY RUN: Would update build status to $state"
        log_verbose "Description: $description"
        return 0
    fi
    
    # Make API request
    local response
    response=$(bitbucket_api_request "POST" "$endpoint" "$payload")
    
    if echo "$response" | jq -e '.uuid' > /dev/null; then
        log_success "Build status updated: $state"
        return 0
    else
        log_error "Failed to update build status"
        log_verbose "Response: $response"
        return 1
    fi
}

# Setup repository variables for SAST
setup_repository_variables() {
    log_info "Setting up repository variables for SAST integration"
    
    local variables=(
        "SLACK_WEBHOOK:Repository webhook URL for Slack notifications"
        "EMAIL_SMTP_PASSWORD:SMTP password for email notifications"
        "JIRA_API_TOKEN:API token for Jira integration"
        "GRAFANA_API_KEY:API key for Grafana dashboard updates"
        "SAST_CONFIG_URL:URL to custom SAST configuration file"
    )
    
    log_info "Required repository variables:"
    for var in "${variables[@]}"; do
        local name="${var%%:*}"
        local description="${var#*:}"
        echo "  - $name: $description"
    done
    
    echo
    log_info "To set these variables:"
    echo "1. Go to Repository Settings > Repository variables"
    echo "2. Add each variable with appropriate values"
    echo "3. Mark sensitive variables as 'Secured'"
    echo
    log_info "Bitbucket Repository Variables URL:"
    echo "https://bitbucket.org/$WORKSPACE/$REPO_SLUG/admin/addon/admin/bitbucket-pipelines/repository-variables"
}

# Setup webhooks for notifications
setup_webhooks() {
    log_info "Setting up webhooks for SAST notifications"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "DRY RUN: Would create webhooks"
        return 0
    fi
    
    # Create webhook for pull request events
    local pr_webhook_payload
    pr_webhook_payload=$(jq -n '{
        description: "SAST Security Scan - PR Events",
        url: "https://your-webhook-endpoint.com/bitbucket/pr",
        active: true,
        events: [
            "pullrequest:created",
            "pullrequest:updated"
        ]
    }')
    
    local endpoint="/repositories/$WORKSPACE/$REPO_SLUG/hooks"
    local response
    response=$(bitbucket_api_request "POST" "$endpoint" "$pr_webhook_payload")
    
    if echo "$response" | jq -e '.uuid' > /dev/null; then
        log_success "PR webhook created"
    else
        log_warning "Failed to create PR webhook"
        log_verbose "Response: $response"
    fi
    
    # Create webhook for push events
    local push_webhook_payload
    push_webhook_payload=$(jq -n '{
        description: "SAST Security Scan - Push Events",
        url: "https://your-webhook-endpoint.com/bitbucket/push",
        active: true,
        events: [
            "repo:push"
        ]
    }')
    
    response=$(bitbucket_api_request "POST" "$endpoint" "$push_webhook_payload")
    
    if echo "$response" | jq -e '.uuid' > /dev/null; then
        log_success "Push webhook created"
    else
        log_warning "Failed to create push webhook"
        log_verbose "Response: $response"
    fi
}

# Test Bitbucket API integration
test_integration() {
    log_info "Testing Bitbucket API integration"
    
    # Test API connectivity
    log_info "Testing API connectivity..."
    local response
    response=$(bitbucket_api_request "GET" "/user")
    
    if echo "$response" | jq -e '.username' > /dev/null; then
        local username
        username=$(echo "$response" | jq -r '.username')
        log_success "API connectivity OK - authenticated as: $username"
    else
        log_error "API connectivity failed"
        log_verbose "Response: $response"
        return 1
    fi
    
    # Test repository access
    if [ -n "$WORKSPACE" ] && [ -n "$REPO_SLUG" ]; then
        log_info "Testing repository access..."
        response=$(bitbucket_api_request "GET" "/repositories/$WORKSPACE/$REPO_SLUG")
        
        if echo "$response" | jq -e '.name' > /dev/null; then
            local repo_name
            repo_name=$(echo "$response" | jq -r '.name')
            log_success "Repository access OK: $repo_name"
        else
            log_error "Repository access failed"
            log_verbose "Response: $response"
            return 1
        fi
    else
        log_warning "Workspace or repository slug not set - skipping repository test"
    fi
    
    log_success "Bitbucket integration test completed"
    return 0
}

# Main execution
main() {
    local command="${1:-}"
    shift || true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pr-id)
                PR_ID="$2"
                shift 2
                ;;
            --workspace)
                WORKSPACE="$2"
                shift 2
                ;;
            --repo)
                REPO_SLUG="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required but not installed"
        exit 1
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl is required but not installed"
        exit 1
    fi
    
    # Execute command
    case "$command" in
        pr-comment)
            check_credentials || exit 1
            add_pr_comment
            ;;
        build-status)
            check_credentials || exit 1
            update_build_status
            ;;
        setup-variables)
            setup_repository_variables
            ;;
        setup-webhooks)
            check_credentials || exit 1
            setup_webhooks
            ;;
        test-integration)
            check_credentials || exit 1
            test_integration
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
