# 📋 Configuration Guide

This guide provides detailed explanations for every configuration option in `ci-config.yaml` and how to set up integrations properly.

## 📖 Table of Contents

- [General Settings](#-general-settings)
- [SAST Configuration](#-sast-configuration)
- [Notification Settings](#-notification-settings)
- [Integration Setup](#-integration-setup)
- [Pipeline Behavior](#-pipeline-behavior)
- [Security Settings](#-security-settings)
- [Reporting Configuration](#-reporting-configuration)
- [Demo Mode](#-demo-mode)
- [Environment Overrides](#-environment-overrides)
- [Secrets Management](#-secrets-management)

## 🎯 General Settings

### Project Configuration

```yaml
project:
  name: "CI-SAST-Boilerplate"          # Display name for your project
  version: "1.0.0"                     # Version for tracking changes
  environment: "production"            # Current environment (production|staging|development)
  team: "devops-security"              # Responsible team name
  contact_email: "devops@company.com"  # Contact for issues
```

**Usage Notes:**
- `name`: Used in notifications and dashboard titles
- `environment`: Determines which environment-specific overrides apply
- `team`: Included in notifications for @mentions
- `contact_email`: Used for fallback notifications

## 🔍 SAST Configuration

### Scanner Selection

```yaml
sast:
  scanners:
    - "codeql"    # GitHub's semantic analysis (recommended)
    - "semgrep"   # Fast pattern-based scanning
    - "bandit"    # Python security linter
    - "eslint"    # JavaScript/TypeScript security rules
```

**Available Scanners:**

| Scanner | Languages | Strengths | Best For |
|---------|-----------|-----------|----------|
| `codeql` | JS, TS, Python, Java, C#, Go | Deep semantic analysis | High-quality findings |
| `semgrep` | 30+ languages | Fast, customizable | Custom rules, speed |
| `bandit` | Python | Python-specific | Python projects |
| `eslint` | JavaScript, TypeScript | Front-end focused | Web applications |
| `sonarqube` | 25+ languages | Enterprise features | Large organizations |

### Language Configuration

```yaml
sast:
  languages:
    - "javascript"  # Include .js files
    - "typescript"  # Include .ts, .tsx files
    - "python"      # Include .py files
    - "go"          # Include .go files
    - "java"        # Include .java files
    - "csharp"      # Include .cs files
```

**Language-Scanner Matrix:**

| Language | CodeQL | Semgrep | Bandit | ESLint |
|----------|--------|---------|--------|--------|
| JavaScript | ✅ | ✅ | ❌ | ✅ |
| TypeScript | ✅ | ✅ | ❌ | ✅ |
| Python | ✅ | ✅ | ✅ | ❌ |
| Java | ✅ | ✅ | ❌ | ❌ |
| Go | ✅ | ✅ | ❌ | ❌ |
| C# | ✅ | ✅ | ❌ | ❌ |

### Severity and Thresholds

```yaml
sast:
  severity_threshold: "medium"        # Minimum severity to report
  max_critical_vulnerabilities: 0    # Pipeline fails if exceeded
  max_high_vulnerabilities: 5        # Pipeline fails if exceeded
```

**Severity Levels:**
- `critical`: Immediate action required (RCE, SQL injection)
- `high`: Serious security issue (XSS, authentication bypass)
- `medium`: Security concern (information disclosure)
- `low`: Minor issue (weak crypto, deprecated functions)
- `info`: Code quality suggestions

**Threshold Strategy:**
- **Strict**: `critical: 0, high: 0` - Zero tolerance
- **Balanced**: `critical: 0, high: 5` - Allow some high-severity findings
- **Permissive**: `critical: 2, high: 10` - More tolerant for legacy code

## 🔔 Notification Settings

### Basic Notification Configuration

```yaml
notifications:
  enabled: true                 # Master switch for all notifications
  trigger: "on_failure"         # When to send notifications
  channels:                     # Which channels to use
    email: true
    slack: true
    jira: true
    teams: false
```

**Trigger Options:**
- `always`: Send for both success and failure
- `on_failure`: Only send when scans fail or find issues
- `on_success`: Only send for successful scans
- `never`: Disable all notifications

### Email Configuration

```yaml
notifications:
  email:
    enabled: true
    smtp_server: "smtp.company.com"       # SMTP server hostname
    smtp_port: 587                        # SMTP port (587 for STARTTLS, 465 for SSL)
    sender_email: "ci-alerts@company.com" # From address
    sender_name: "CI/CD Security Alerts"  # From name
    recipients:                           # List of recipients
      - "security-team@company.com"
      - "devops-team@company.com"
    subject_prefix: "[SAST Alert]"        # Subject line prefix
    include_summary: true                 # Include vulnerability summary
    include_details: true                 # Include detailed findings
```

**SMTP Setup Examples:**

| Provider | SMTP Server | Port | Security |
|----------|-------------|------|----------|
| Gmail | smtp.gmail.com | 587 | STARTTLS |
| Outlook | smtp-mail.outlook.com | 587 | STARTTLS |
| AWS SES | email-smtp.region.amazonaws.com | 587 | STARTTLS |
| SendGrid | smtp.sendgrid.net | 587 | STARTTLS |

**Required Secret:** `EMAIL_SMTP_PASSWORD`

## 🔗 Integration Setup

### Slack Integration

```yaml
integrations:
  slack:
    enabled: true
    webhook_url: ""                    # Set via SLACK_WEBHOOK secret
    channel: "#security-alerts"       # Target channel
    username: "CI-Security-Bot"       # Bot display name
    icon_emoji: ":warning:"           # Bot icon
    mention_users:                    # Users to @mention
      - "@security-team"
      - "@devops-lead"
    message_format: "detailed"        # Message complexity
```

**Setup Steps:**
1. Go to Slack App settings
2. Create incoming webhook
3. Set `SLACK_WEBHOOK` secret to webhook URL
4. Test with demo mode

### Jira Integration

```yaml
integrations:
  jira:
    enabled: true
    server_url: "https://company.atlassian.net"  # Jira instance URL
    project_key: "SEC"                           # Project key for tickets
    issue_type: "Bug"                            # Issue type for vulnerabilities
    priority: "High"                             # Default priority
    assignee: "security-team"                    # Default assignee
    components:                                  # Components to assign
      - "Security"
      - "SAST"
    labels:                                      # Labels to apply
      - "security-vulnerability"
      - "sast-scan"
      - "auto-created"
    auto_assign: true                            # Auto-assign to default assignee
    create_on_severity:                          # When to create tickets
      - "critical"
      - "high"
```

**Setup Steps:**
1. Create Jira API token: Account Settings > Security > API Tokens
2. Set `JIRA_API_TOKEN` secret
3. Ensure bot user has project permissions
4. Create project and configure issue types

### Grafana Integration

```yaml
integrations:
  grafana:
    enabled: true
    server_url: "https://grafana.company.com"    # Grafana instance URL
    dashboard_uid: "sast-security-dashboard"     # Dashboard UID
    datasource: "prometheus"                     # Data source name
    organization_id: 1                           # Organization ID
    folder: "Security"                           # Dashboard folder
```

## 🔐 Secrets Management

### Required Secrets

Set these in GitHub Repository Settings > Secrets and Variables > Actions:

| Secret Name | Purpose | Example Value |
|-------------|---------|---------------|
| `SLACK_WEBHOOK` | Slack notifications | `https://hooks.slack.com/services/...` |
| `EMAIL_SMTP_PASSWORD` | Email notifications | `your-smtp-password` |
| `JIRA_API_TOKEN` | Jira integration | `your-jira-api-token` |
| `GRAFANA_API_KEY` | Grafana integration | `glsa_your-api-key` |
| `SEMGREP_APP_TOKEN` | Semgrep Pro features | `your-semgrep-token` |

### Secret Security Best Practices

1. **Rotate regularly**: Change secrets every 90 days
2. **Use least privilege**: Grant minimal required permissions
3. **Monitor usage**: Track secret access in audit logs
4. **Backup safely**: Store backup copies securely
5. **Document ownership**: Track who owns each secret

## 🧪 Demo Mode

### Demo Configuration

```yaml
demo_mode:
  enabled: false                      # Enable demo mode (set to true for testing)
  simulate_vulnerabilities: true     # Generate fake vulnerability data
  mock_scan_duration: 30              # Simulated scan time (seconds)
  
  demo_recipients:                    # Demo notification recipients
    - "demo@example.com"
  demo_slack_channel: "#demo-alerts" # Demo Slack channel
  demo_jira_project: "DEMO"          # Demo Jira project
  
  label_prefix: "[DEMO]"             # Prefix for demo items
  test_mode_indicator: "🧪 TEST MODE" # Visual indicator
```

## 🌍 Environment Overrides

### Environment-Specific Settings

```yaml
environments:
  development:                        # Development environment overrides
    sast:
      severity_threshold: "low"       # More permissive in dev
      max_critical_vulnerabilities: 10
    notifications:
      trigger: "never"                # No notifications in dev
    
  staging:                           # Staging environment overrides
    sast:
      severity_threshold: "medium"
      max_critical_vulnerabilities: 5
    notifications:
      trigger: "on_failure"           # Only failure notifications
    
  production:                        # Production environment overrides
    sast:
      severity_threshold: "medium"
      max_critical_vulnerabilities: 0  # Zero tolerance in prod
    notifications:
      trigger: "always"               # All notifications in prod
    pipeline:
      timeouts:
        total_pipeline: 120           # Longer timeouts for prod
        sast_scan: 60
```

## 🚨 Common Configuration Issues

### Invalid YAML Syntax

```bash
# Validate YAML syntax
yq eval ci-config.yaml > /dev/null
```

### Missing Required Fields

Ensure all required fields are present:
- `project.name`
- `sast.scanners` (at least one)
- `notifications.enabled`

### Network Connectivity

Test webhook URLs:
```bash
curl -I https://hooks.slack.com/services/your/webhook/url
```

### Permission Issues

Verify API permissions:
- Jira: Project access, issue creation
- Grafana: Dashboard read/write
- Slack: Incoming webhooks enabled

## 📝 Configuration Validation

### Automated Validation

The pipeline includes configuration validation:

```yaml
# Validates during pipeline execution
- name: Validate configuration
  run: |
    yq eval ci-config.yaml > /dev/null
    ./scripts/validate_config.sh
```

### Manual Testing

Test configuration with demo mode:

```bash
# Test all integrations
./run_demo.sh

# Test specific integration
./run_demo.sh --component slack
```

---

**🎯 Next Steps**: After configuring `ci-config.yaml`, run demo mode to test your setup: `./run_demo.sh`
