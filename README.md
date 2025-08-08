# 🔒 CI/CD SAST Security Boilerplate

A comprehensive, production-ready CI/CD boilerplate for Static Application Security Testing (SAST) with centralized configuration, multi-channel notifications, and demo mode capabilities.

## 🎯 Overview

This repository provides a complete CI/CD solution for implementing security scanning workflows with:
- **Multi-scanner SAST integration** (CodeQL, Semgrep, Bandit, ESLint)
- **Centralized configuration management**
- **Multi-channel notifications** (Slack, Email, Jira, Teams)
- **Grafana dashboard integration**
- **Demo/test mode** for safe evaluation
- **Production-ready workflows**

## 🚀 Quick Start

### 1. Clone and Configure

```bash
# Clone this boilerplate repository
git clone <this-repo-url> my-security-pipeline
cd my-security-pipeline

# Copy and customize the configuration
cp ci-config.yaml ci-config.yaml.local
# Edit ci-config.yaml.local with your settings
```

### 2. Set Required Secrets

Configure the following secrets in your GitHub repository:

```bash
# GitHub Repository Settings > Secrets and Variables > Actions

# Required secrets:
SLACK_WEBHOOK=https://hooks.slack.com/services/...
EMAIL_SMTP_PASSWORD=your-smtp-password
JIRA_API_TOKEN=your-jira-token
GRAFANA_API_KEY=your-grafana-key
SEMGREP_APP_TOKEN=your-semgrep-token  # Optional
```

### 3. Test with Demo Mode

```bash
# Enable demo mode for safe testing
./run_demo.sh

# Or run individual components
./scripts/send_notifications.sh success "Demo Pipeline" "Test notification"
```

### 4. Deploy to Production

1. Update `ci-config.yaml` with your production settings
2. Push to your main branch
3. Workflows will automatically trigger on configured events

## 📁 Repository Structure

```
ci-sast-boilerplate/
├── 📄 ci-config.yaml              # Central configuration file
├── 📄 README.md                   # This file
├── 📄 CONFIG_GUIDE.md             # Detailed configuration guide
├── 📄 run_demo.sh                 # Demo mode execution script
├── 
├── 🗂️  .github/workflows/
│   ├── 📄 sast-security-scan.yml  # Main SAST scanning workflow
│   └── 📄 ci-pipeline.yml         # Complete CI/CD pipeline
├── 
├── 🗂️  scripts/
│   ├── 📄 process_results.sh      # SAST results processing
│   ├── 📄 send_notifications.sh   # Multi-channel notifications
│   └── 📄 update_grafana.sh       # Grafana dashboard updates
├── 
├── 🗂️  configs/
│   ├── 📄 .eslintrc.security.json # ESLint security rules
│   ├── 📄 bandit.yaml            # Bandit configuration
│   └── 📄 semgrep-rules.yaml     # Custom Semgrep rules
├── 
├── 🗂️  docs/
│   ├── 📄 ARCHITECTURE.md        # System architecture
│   ├── 📄 TROUBLESHOOTING.md     # Common issues and solutions
│   └── 📄 EXAMPLES.md            # Usage examples
└── 
└── 🗂️  examples/
    ├── 📄 vulnerable-code/        # Sample code for testing
    └── 📄 pipeline-templates/     # Additional workflow templates
```

## ⚙️ Key Features

### 🔍 Multi-Scanner SAST Support

| Scanner | Languages | Purpose |
|---------|-----------|---------|
| **CodeQL** | JavaScript, TypeScript, Python, Java, C#, Go | GitHub's semantic code analysis |
| **Semgrep** | 30+ languages | Fast, customizable static analysis |
| **Bandit** | Python | Python-specific security linter |
| **ESLint** | JavaScript, TypeScript | Security-focused linting rules |

### 📊 Centralized Configuration

All settings managed through `ci-config.yaml`:
- SAST scanner configuration
- Notification settings
- Integration endpoints
- Environment-specific overrides
- Quality gates and thresholds

### 🔔 Multi-Channel Notifications

| Channel | Features | Use Case |
|---------|----------|----------|
| **Slack** | Rich formatting, @mentions | Real-time team alerts |
| **Email** | SMTP support, HTML formatting | Formal notifications |
| **Jira** | Auto-ticket creation | Issue tracking |
| **Teams** | Adaptive cards | Microsoft ecosystem |

### 📈 Dashboard Integration

- **Grafana** dashboards with security metrics
- **Prometheus** metrics collection
- **Historical trending** and analysis
- **Custom annotations** for scan events

## 🧪 Demo Mode

Demo mode allows safe testing of all integrations without affecting production systems:

```bash
# Run complete demo pipeline
./run_demo.sh

# Test specific components
./run_demo.sh --component slack
./run_demo.sh --component email
./run_demo.sh --component jira

# Simulate different scenarios
./run_demo.sh --scenario critical-vulnerabilities
./run_demo.sh --scenario scan-failure
```

Demo mode features:
- ✅ Sends test notifications to demo channels
- ✅ Uses dummy vulnerability data
- ✅ Creates test Jira tickets in demo project
- ✅ Populates demo Grafana dashboard
- ✅ Clearly labeled as "TEST MODE"

## 🔧 Configuration

### Basic Setup

1. **Edit `ci-config.yaml`** - See [CONFIG_GUIDE.md](CONFIG_GUIDE.md) for detailed explanations
2. **Set GitHub Secrets** - Configure integration tokens and passwords
3. **Customize workflows** - Modify `.github/workflows/` files if needed
4. **Test configuration** - Run demo mode to verify setup

### Environment-Specific Settings

```yaml
# ci-config.yaml
environments:
  development:
    sast:
      severity_threshold: "low"
    notifications:
      trigger: "never"
  
  production:
    sast:
      severity_threshold: "medium" 
      max_critical_vulnerabilities: 0
    notifications:
      trigger: "always"
```

### Workflow Triggers

| Trigger | When | Purpose |
|---------|------|---------|
| **Push** | `main`, `develop` branches | Production security scans |
| **Pull Request** | To `main` branch | Pre-merge validation |
| **Schedule** | Daily at 2 AM UTC | Regular security audits |
| **Manual** | Workflow dispatch | On-demand scanning |

## 🚦 Usage Examples

### Standard Security Scan

```bash
# Triggered automatically on push to main
git push origin main

# Manual trigger with options
gh workflow run sast-security-scan.yml -f scan_type=critical-only
```

### Custom Integration

```yaml
# In your application repository workflow
jobs:
  security-scan:
    uses: your-org/ci-sast-boilerplate/.github/workflows/sast-security-scan.yml@main
    with:
      config-file: custom-security-config.yaml
    secrets:
      SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
      JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
```

### Local Development

```bash
# Run security scans locally
./scripts/process_results.sh semgrep full

# Test notifications
export CONFIG_JSON='{"notifications":{"enabled":true}}'
./scripts/send_notifications.sh failure "Local Test"
```

## 📋 Requirements

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+ recommended)
- **Git**: Version 2.0+
- **curl**: For API integrations
- **jq**: For JSON processing
- **yq**: For YAML processing

### GitHub Permissions

- **Actions**: Read/Write (for workflow execution)
- **Security events**: Write (for SARIF uploads)
- **Repository**: Read (for code access)

### Integration Requirements

| Integration | Requirements |
|-------------|--------------|
| **Slack** | Incoming webhook URL |
| **Email** | SMTP server access + credentials |
| **Jira** | API token + project permissions |
| **Grafana** | API key + dashboard permissions |
| **Semgrep** | App token (optional, uses community rules otherwise) |

## 🔒 Security Considerations

### Secrets Management

- ✅ Use GitHub Secrets for sensitive data
- ✅ Never commit API keys or passwords
- ✅ Rotate tokens regularly
- ✅ Use least-privilege access

### Network Security

- ✅ Webhook URLs use HTTPS
- ✅ API endpoints are authenticated
- ✅ Results are transmitted securely
- ✅ Scan data is encrypted at rest

### Compliance

- ✅ SARIF format for standardized reporting
- ✅ Audit trail through workflow logs
- ✅ Configurable retention policies
- ✅ Access controls on sensitive operations

## 📞 Support

### Documentation

- 📖 [CONFIG_GUIDE.md](CONFIG_GUIDE.md) - Detailed configuration reference
- 🏗️ [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System architecture overview
- 🔧 [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Common issues and solutions
- 💡 [EXAMPLES.md](docs/EXAMPLES.md) - Advanced usage examples

### Getting Help

1. **Check the documentation** - Most questions are covered in the guides
2. **Run demo mode** - Test your configuration safely
3. **Review workflow logs** - GitHub Actions provides detailed execution logs
4. **Check integration endpoints** - Verify API connectivity

### Contributing

This is a boilerplate repository designed to be forked and customized for your needs. Key areas for customization:

- **Scanner configuration** - Add/remove security scanners
- **Notification formats** - Customize message templates
- **Quality gates** - Adjust failure thresholds
- **Workflow triggers** - Modify when scans run

## 📄 License

This boilerplate is provided under the MIT License. See LICENSE file for details.

## 🏷️ Version

Current version: **1.0.0**

---

**📚 Next Steps**: Read the [CONFIG_GUIDE.md](CONFIG_GUIDE.md) for detailed configuration instructions and start with demo mode to test your setup safely.
