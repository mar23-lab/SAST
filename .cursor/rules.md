# 🔧 CURSOR DEVELOPMENT RULES - SAST Platform
## Code Generation and Modification Guidelines

## 🎯 CORE PRINCIPLES

### 1. Developer Experience First
- **Convention over Configuration**: Smart defaults that work for 80% of use cases
- **Progressive Enhancement**: Basic functionality first, advanced features opt-in
- **Clear Error Messages**: Every error should include actionable next steps
- **Zero-Configuration Success**: Target 60% success rate without any configuration

### 2. Security by Design
- **Secure Defaults**: Fail-safe, conservative thresholds
- **Input Validation**: Sanitize all user inputs
- **Secrets Management**: Environment variables only, never hardcode
- **Audit Trails**: Log all security-relevant operations

### 3. Enterprise Quality
- **Backward Compatibility**: Never break existing configurations
- **Comprehensive Testing**: Demo mode for all new features
- **Documentation**: Code should be self-documenting with examples
- **Error Handling**: Graceful degradation, never silent failures

## 📋 CODE GENERATION STANDARDS

### Shell Script Requirements
```bash
#!/bin/bash
# ALWAYS include this header pattern:

# ===================================================================
# SCRIPT_NAME - Brief Description
# ===================================================================
# Purpose: Detailed purpose and usage
# Usage: ./script_name.sh [options]
# Example: ./script_name.sh --demo --verbose

set -euo pipefail  # MANDATORY: Strict error handling

# REQUIRED: Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'  
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# REQUIRED: Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# REQUIRED: Help function
show_help() {
    cat << EOF
USAGE: $0 [options]

OPTIONS:
    -h, --help      Show this help message
    --demo          Run in demo mode
    --verbose       Enable verbose logging

EXAMPLES:
    $0 --demo       # Safe testing mode
    $0 --verbose    # Detailed output

EOF
}

# REQUIRED: Cleanup function
cleanup_on_error() {
    log_error "Operation failed. Cleaning up..."
    # Add cleanup logic here
    exit 1
}

trap cleanup_on_error ERR
```

### Python Script Requirements
```python
#!/usr/bin/env python3
"""
Script Name - Brief Description

Purpose: Detailed purpose and functionality
Usage: python script_name.py [options]
Example: python script_name.py --config ci-config.yaml --demo
"""

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Dict, List, Optional, Union

# REQUIRED: Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main() -> int:
    """Main entry point with proper error handling."""
    try:
        # Implementation here
        return 0
    except KeyboardInterrupt:
        logger.error("Operation cancelled by user")
        return 130
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

## 🔧 SPECIFIC FILE MODIFICATION RULES

### ci-config.yaml (CRITICAL FILE)
```yaml
# RULES for modifying ci-config.yaml:
# 1. ALWAYS maintain backward compatibility
# 2. Add comprehensive comments for new parameters
# 3. Include example values and valid ranges
# 4. Update CONFIG_GUIDE.md simultaneously
# 5. Test with existing configurations

# EXAMPLE of proper parameter addition:
new_feature:
  enabled: true  # Enable new feature (default: true)
  # Valid values: true, false
  # Example: true for production, false for development
  
  timeout_minutes: 30  # Timeout in minutes (default: 30)
  # Valid range: 5-120 minutes
  # Recommended: 30 for normal repos, 60 for large repos
```

### Docker Compose Files
```yaml
# RULES for Docker Compose modifications:
# 1. Maintain compatibility with existing volume mounts
# 2. Use environment variables for configuration
# 3. Include health checks for all services
# 4. Add resource limits for production use
# 5. Test with all deployment modes (demo, minimal, production)

services:
  new-service:
    image: service:latest
    environment:
      - CONFIG_VAR=${CONFIG_VAR:-default_value}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
```

### GitHub Actions Workflows
```yaml
# RULES for workflow modifications:
# 1. Include timeout and retry logic
# 2. Use matrix builds for multi-platform support
# 3. Store artifacts for debugging
# 4. Add conditional execution based on file changes
# 5. Test with different repository types

name: Enhanced SAST Workflow
on:
  push:
    paths:
      - 'src/**'
      - 'scripts/**'
      - 'ci-config.yaml'

jobs:
  sast-scan:
    runs-on: ubuntu-latest
    timeout-minutes: 60
    strategy:
      fail-fast: false
      matrix:
        language: [javascript, python, go]
    
    steps:
      - uses: actions/checkout@v4
      - name: Run SAST Scan
        id: sast
        continue-on-error: true
        run: |
          ./scripts/process_results.sh ${{ matrix.language }}
      
      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: sast-results-${{ matrix.language }}
          path: results/
```

## 🎯 FEATURE DEVELOPMENT PATTERNS

### Adding New Scanner Support
```bash
# 1. Create scanner configuration
cat > configs/new-scanner.yaml << EOF
scanner:
  name: "new-scanner"
  version: "latest"
  languages: ["java", "kotlin"]
  command: "new-scanner scan"
  output_format: "sarif"
  
rules:
  severity_levels: ["critical", "high", "medium", "low"]
  exclude_patterns:
    - "test/**"
    - "*.test.java"
EOF

# 2. Add to process_results.sh
add_scanner_support() {
    case "$scanner" in
        "new-scanner")
            log_info "Running new-scanner analysis..."
            run_new_scanner_scan "$target_dir"
            ;;
    esac
}

# 3. Update ci-config.yaml
# Add scanner to available options with documentation

# 4. Create demo mode support
# Add test cases in run_demo.sh

# 5. Update documentation
# Add scanner details to CONFIG_GUIDE.md
```

### Adding New Integration
```bash
# 1. Create integration script
cat > scripts/integrate_new_service.sh << 'EOF'
#!/bin/bash
set -euo pipefail

integrate_new_service() {
    local config_file="$1"
    local results_file="$2"
    
    # Read configuration
    SERVICE_URL=$(yq eval '.integrations.new_service.url // ""' "$config_file")
    SERVICE_TOKEN=$(yq eval '.integrations.new_service.token // ""' "$config_file")
    
    if [[ -z "$SERVICE_URL" ]]; then
        log_warning "New service URL not configured, skipping integration"
        return 0
    fi
    
    # Send results
    curl -s -X POST "$SERVICE_URL/api/results" \
        -H "Authorization: Bearer $SERVICE_TOKEN" \
        -H "Content-Type: application/json" \
        -d @"$results_file" || {
        log_error "Failed to send results to new service"
        return 1
    }
    
    log_success "Results sent to new service successfully"
}
EOF

# 2. Add to send_notifications.sh
# Include new integration in notification flow

# 3. Update ci-config.yaml
# Add configuration section with examples

# 4. Create demo mode
# Add mock integration testing
```

## 📊 TESTING REQUIREMENTS

### Demo Mode Implementation
```bash
# EVERY new feature MUST include demo mode support
run_demo_new_feature() {
    log_info "Running new feature demo..."
    
    # Create mock data
    create_mock_data() {
        cat > /tmp/demo_data.json << EOF
{
    "feature": "new_feature",
    "status": "success",
    "results": {
        "items_processed": 42,
        "success_rate": "95%"
    }
}
EOF
    }
    
    # Test the feature with mock data
    create_mock_data
    test_new_feature "/tmp/demo_data.json"
    
    # Validate results
    if [[ $? -eq 0 ]]; then
        log_success "New feature demo completed successfully"
    else
        log_error "New feature demo failed"
        return 1
    fi
}
```

### Configuration Validation
```python
def validate_config(config_data: Dict) -> List[str]:
    """Validate configuration with detailed error messages."""
    errors = []
    
    # Check required fields
    required_fields = ['project.name', 'sast.scanners']
    for field in required_fields:
        if not get_nested_value(config_data, field):
            errors.append(f"Missing required field: {field}")
    
    # Validate scanner configuration
    scanners = config_data.get('sast', {}).get('scanners', [])
    valid_scanners = ['codeql', 'semgrep', 'bandit', 'eslint']
    
    for scanner in scanners:
        if scanner not in valid_scanners:
            errors.append(f"Invalid scanner: {scanner}. Valid options: {valid_scanners}")
    
    return errors
```

## 🔄 INTEGRATION PATTERNS

### Service Health Checks
```bash
# Standard pattern for service health validation
validate_service_health() {
    local service_name="$1"
    local health_endpoint="$2"
    local expected_status="${3:-200}"
    
    log_info "Checking $service_name health..."
    
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$health_endpoint" || echo "000")
    
    if [[ "$response_code" == "$expected_status" ]]; then
        log_success "$service_name is healthy (HTTP $response_code)"
        return 0
    else
        log_error "$service_name health check failed (HTTP $response_code)"
        log_info "Expected: $expected_status, Got: $response_code"
        return 1
    fi
}
```

### Configuration File Processing
```bash
# Standard pattern for YAML configuration processing
process_config_section() {
    local config_file="$1"
    local section="$2"
    
    # Validate file exists
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Extract section with default fallback
    local section_data
    section_data=$(yq eval ".$section // {}" "$config_file" 2>/dev/null) || {
        log_error "Failed to parse configuration section: $section"
        return 1
    }
    
    # Validate section is not empty
    if [[ "$section_data" == "{}" ]]; then
        log_warning "Configuration section '$section' is empty or missing"
        return 0
    fi
    
    echo "$section_data"
}
```

## 🚨 ERROR HANDLING REQUIREMENTS

### Graceful Degradation
```bash
# Pattern for handling optional features
try_optional_feature() {
    local feature_name="$1"
    shift
    local feature_command=("$@")
    
    log_info "Attempting optional feature: $feature_name"
    
    if "${feature_command[@]}" 2>/dev/null; then
        log_success "Optional feature '$feature_name' succeeded"
        return 0
    else
        log_warning "Optional feature '$feature_name' failed, continuing without it"
        return 0  # Don't fail the entire process for optional features
    fi
}
```

### User-Friendly Error Messages
```bash
# Pattern for actionable error messages
report_actionable_error() {
    local error_message="$1"
    local suggested_action="$2"
    local help_url="${3:-}"
    
    log_error "$error_message"
    echo ""
    echo -e "${YELLOW}💡 Suggested Action:${NC}"
    echo "   $suggested_action"
    
    if [[ -n "$help_url" ]]; then
        echo ""
        echo -e "${BLUE}📖 More Help:${NC}"
        echo "   $help_url"
    fi
    echo ""
}

# Example usage:
# report_actionable_error \
#     "Email configuration failed" \
#     "Run './scripts/email_setup_wizard.sh' to configure email settings" \
#     "https://github.com/mar23-lab/SAST/blob/main/docs/TROUBLESHOOTING.md#email-setup"
```

## 🎯 COMPETITIVE DEVELOPMENT FOCUS

### DefectDojo Feature Parity
```yaml
# When implementing features, consider DefectDojo comparison:
DefectDojo_Feature_Analysis:
  Vulnerability_Management:
    DefectDojo: "Complex Django admin interface"
    Our_Approach: "Simple YAML configuration + CLI"
    
  Multi_Tenant:
    DefectDojo: "Database-driven with complex setup"
    Our_Approach: "File-based with simple organization structure"
    
  API_Access:
    DefectDojo: "Full REST API with authentication"
    Our_Approach: "Configuration-driven with optional API layer"
    
  Integration_Ecosystem:
    DefectDojo: "120+ parsers, complex architecture"
    Our_Approach: "Essential scanners, simple addition process"
```

### Development Speed Optimization
```bash
# Optimize for 10x faster setup than competitors
optimize_for_speed() {
    # 1. Automate configuration detection
    auto_detect_project_settings
    
    # 2. Provide intelligent defaults
    generate_smart_defaults
    
    # 3. Validate early and often
    validate_configuration_early
    
    # 4. Parallel processing where possible
    run_tasks_in_parallel
    
    # 5. Cache results for faster subsequent runs
    implement_intelligent_caching
}
```

---

**Remember**: Every line of code should contribute to our goal of "DefectDojo-grade enterprise capabilities with 10x superior developer experience." Always ask: "Does this make the developer's life easier or harder?"
