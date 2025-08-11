# 🔒 SAST Platform - Cursor AI Instructions
## Developer-First Security Scanning Platform

You are working on a **production-ready SAST (Static Application Security Testing) platform** designed to provide enterprise-grade security scanning with exceptional developer experience.

## 🎯 PROJECT MISSION

Transform security scanning from a developer burden into a delightful experience by delivering DefectDojo-grade enterprise capabilities with 10x superior developer UX.

**Competitive Position**: "DefectDojo for Developers" - Enterprise security that developers actually want to use.

## 🏗️ TECHNICAL ARCHITECTURE

### Core Technology Stack
- **Backend**: Shell scripts + Python (lightweight vs DefectDojo's Django)
- **Scanners**: CodeQL, Semgrep, Bandit, ESLint (multi-scanner approach)
- **Monitoring**: InfluxDB, Grafana, Prometheus (enterprise observability)
- **Deployment**: Docker Compose (container-native)
- **CI/CD**: GitHub Actions, Bitbucket Pipelines, GitLab CI

### Repository Structure
```
SAST/
├── 📄 ci-config.yaml              # Central configuration (CRITICAL FILE)
├── 🗂️ .github/workflows/          # CI/CD automation
├── 🗂️ scripts/                   # Core processing logic
├── 🗂️ configs/                   # Scanner configurations
├── 🗂️ docker-compose files       # Infrastructure
├── 🗂️ monitoring configs         # Grafana, Prometheus, InfluxDB
└── 📄 CURSOR_CONTRIBUTOR_DOCUMENTATION.md  # YOUR MAIN REFERENCE
```

## 🎯 CURRENT DEVELOPMENT PRIORITIES

### **Phase 1: Competitive Advantage Acceleration** (Week 2 - CURRENT)
**Target**: Achieve setup time parity with DefectDojo (30 min) then surpass (15 min)

#### Week 2 Focus (CURRENT PRIORITY):
```bash
PRIMARY OBJECTIVES:
- Implement ./sast init --repo [URL] command
- Auto-detect languages and recommend scanners  
- Test all integrations before completion

SUCCESS METRICS:
- Setup time: 2.5h → 30 min (vs DefectDojo 2-8h)
- Setup success rate: 30% → 70% (vs DefectDojo ~60%)
- Zero-configuration success: 0% → 60% (unique market position)

DELIVERABLES:
- sast-init.sh (main onboarding script)
- language-detector.py (auto-detect project languages)
- integration-tester.sh (validate all connections)
- Quick-start templates for common project types
```

## 🔧 DEVELOPMENT GUIDELINES

### Code Quality Standards
```yaml
Shell Scripts:
  - Use bash with set -euo pipefail for error handling
  - Include comprehensive logging (log_info, log_error functions)
  - Color-coded output for user experience
  - Validate all dependencies before execution
  - Provide --help and usage examples

Python Scripts:
  - Type hints for all function parameters
  - Comprehensive error handling with try/catch
  - JSON/YAML processing with proper validation
  - CLI interfaces using argparse
  - Unit tests for critical functions

Configuration:
  - YAML format with clear commenting
  - Environment variable support
  - Validation schemas where possible
  - Example configurations for common scenarios
```

### Architecture Principles
```yaml
Developer Experience First:
  - Convention over configuration
  - Zero-configuration defaults that work for 80% of cases
  - Progressive enhancement (basic → advanced features)
  - Clear error messages with actionable solutions

Security by Design:
  - Secure defaults (fail-safe, conservative thresholds)
  - Secrets management via environment variables
  - HTTPS/TLS for all external communications
  - Input validation and sanitization

Observability:
  - Comprehensive logging at all levels
  - Metrics collection for performance monitoring
  - Health checks for all services
  - Audit trails for security events
```

## 📋 STANDARD DEVELOPMENT PATTERNS

### Configuration Management Pattern
```bash
# Standard pattern for reading configuration
CONFIG_FILE="${CONFIG_FILE:-ci-config.yaml}"
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found: $CONFIG_FILE"
    echo "Run: cp ci-config.yaml.example ci-config.yaml"
    exit 1
fi

# Use yq for YAML processing
SETTING=$(yq eval '.section.parameter // "default_value"' "$CONFIG_FILE")
```

### Service Health Check Pattern
```bash
# Standard health check with retries
check_service_health() {
    local service_name="$1"
    local health_url="$2"
    local max_retries="${3:-30}"
    
    for ((i=1; i<=max_retries; i++)); do
        if curl -s "$health_url" >/dev/null 2>&1; then
            log_success "$service_name is ready"
            return 0
        fi
        log_info "Waiting for $service_name... ($i/$max_retries)"
        sleep 2
    done
    
    log_error "$service_name failed to start after $max_retries attempts"
    return 1
}
```

### Error Handling Pattern
```bash
# Comprehensive error handling with cleanup
set -euo pipefail

cleanup_on_error() {
    log_error "Operation failed. Cleaning up..."
    docker-compose down >/dev/null 2>&1 || true
    exit 1
}

trap cleanup_on_error ERR
```

## 🏆 COMPETITIVE CONTEXT

### DefectDojo Analysis (Primary Competitor)
```yaml
DefectDojo Strengths (Learn From):
  - 4,146⭐ stars, proven enterprise adoption
  - 120+ scanner integrations (parser ecosystem)
  - Multi-tenant architecture with RBAC
  - Comprehensive vulnerability management
  - Fortune 500 deployments

DefectDojo Weaknesses (Our Advantage):
  - Complex setup (2-8 hours vs our 15-minute target)
  - Django complexity vs our lightweight approach
  - Database-driven config vs our file-based config
  - Standalone tool vs our CI/CD native integration
```

### SonarQube Analysis (Secondary Reference)
```yaml
SonarQube Strengths:
  - 9,791⭐ stars, market leader position
  - Enterprise adoption across Fortune 500
  - Comprehensive language support (30+)
  - IDE integrations and developer tools

SonarQube Weaknesses (Our Opportunity):
  - Expensive enterprise licensing vs our open source
  - Complex setup vs our automation
  - Limited platform integration vs our multi-platform
```

## 🎯 WHEN TO USE WHICH APPROACH

### Code Generation Strategy
```yaml
Always Include:
  - Comprehensive header comment with purpose
  - Usage examples and parameter documentation
  - Error handling with graceful degradation
  - Logging at appropriate levels
  - Input validation and sanitization

For Configuration Changes:
  - Backward compatibility preservation
  - Default values that work out-of-box
  - Clear documentation with examples
  - Validation and error messages
  - Migration path from previous versions

For New Features:
  - Demo mode support for testing
  - Both positive and negative test cases
  - Clear success/failure indicators
  - Realistic test data for demonstrations
```

### File Modification Guidelines
```yaml
ci-config.yaml (CRITICAL):
  - Maintain backward compatibility
  - Add comprehensive comments for new parameters
  - Include example values and valid ranges
  - Update CONFIG_GUIDE.md simultaneously

setup.sh:
  - Preserve existing error handling patterns
  - Add new dependencies to prerequisites check
  - Update banner and usage information
  - Test all deployment modes (demo, production, minimal)

Workflow Files:
  - Ensure GitHub Actions compatibility
  - Add appropriate timeout and retry logic
  - Include artifact storage for results
  - Support matrix builds for multiple platforms
```

## 📊 SUCCESS METRICS TO TRACK

### Competitive Benchmarks
```yaml
Current Targets (Week 2):
  - Setup Time: 30 minutes (DefectDojo parity)
  - Setup Success Rate: 70% (vs DefectDojo ~60%)
  - Email Delivery: 95% (vs DefectDojo manual)
  - Platform Support: GitHub + Bitbucket foundation

Week 4 Goals:
  - Setup Time: 15 minutes (market leadership)
  - Setup Success Rate: 90% (clear advantage)
  - Zero-Configuration: 60% success rate
  - Multi-Platform: GitHub + Bitbucket functional
```

## 🚨 CRITICAL FILES TO UNDERSTAND

### Essential Reading Order
1. **CURSOR_CONTRIBUTOR_DOCUMENTATION.md** - Complete technical reference
2. **COMPETITIVE_ANALYSIS_SUMMARY.md** - Market positioning strategy
3. **UPDATED_ACTION_PLAN.md** - Current development priorities
4. **ci-config.yaml** - Master configuration (all settings)
5. **setup.sh** - Automated deployment script

### Key Implementation Files
```yaml
Core Logic:
  - scripts/process_results.sh: SAST results processing
  - scripts/send_notifications.sh: Multi-channel notifications
  - run_demo.sh: Interactive demonstration mode
  - test_real_repo.sh: Live repository testing

Configuration:
  - configs/bandit.yaml: Python scanner config
  - configs/.eslintrc.security.json: JS/TS scanner config
  - configs/semgrep-rules.yaml: Custom security rules

Infrastructure:
  - docker-compose-minimal.yml: Essential services
  - grafana-config/: Pre-built security dashboards
  - prometheus-config/: Alerting rules and metrics
```

## 💡 DEVELOPMENT PHILOSOPHY

### "Developer Delight Through Security Excellence"
Every change should ask: "Does this make security easier or harder for developers?" If it makes it harder, find a different approach.

### Progressive Enhancement Approach
1. **Basic functionality first** - Works out of the box for 80% of cases
2. **Advanced features optional** - Power users can customize
3. **Clear upgrade path** - Simple → Advanced configuration
4. **Graceful degradation** - Partial failures don't break everything

### Competitive Advantage Focus
```yaml
Speed: 10-30x faster setup than any competitor
Cost: 90-95% cost reduction vs enterprise solutions
Platform: Only multi-platform native Git integration
UX: Only developer-first enterprise security platform
```

## 🎯 IMMEDIATE NEXT STEPS

### This Week Priority
1. **Email wizard completion** - scripts/email_setup_wizard.sh
2. **One-command setup** - sast-init.sh development
3. **Language detection** - language-detector.py implementation
4. **Integration testing** - integration-tester.sh framework

### Success Definition
**The project succeeds when a developer can run `./sast init --repo [URL]` and have a fully functional, enterprise-grade security scanning platform operational in under 15 minutes with 90%+ success rate.**

---

**Remember**: We're building the "DefectDojo for Developers" - enterprise-grade security orchestration with 10x superior developer experience. Focus on Phase 1 priorities and always optimize for developer delight while maintaining enterprise capabilities.
