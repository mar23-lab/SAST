# 🔒 Universal SAST Boilerplate

**Transform any repository into a secure, enterprise-ready project with automated SAST scanning, professional dashboards, and comprehensive DevSecOps integration.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/xlooop-ai/SAST/releases)
[![Status](https://img.shields.io/badge/status-Production%20Ready-green.svg)](https://github.com/xlooop-ai/SAST)

---

## 🎯 What This Boilerplate Provides

This Universal SAST Boilerplate transforms any repository into a secure, professionally managed project with:

### 🔍 **Multi-Scanner SAST Integration**
- **CodeQL** - GitHub's semantic code analysis
- **Semgrep** - Fast, customizable static analysis (30+ languages)
- **ESLint Security** - JavaScript/TypeScript security linting
- **Bandit** - Python-specific security analysis
- **Custom Rules** - Industry-specific security patterns

### 📊 **Professional Dashboards**
- **GitHub Pages** - Beautiful, responsive security dashboards
- **Real-time Metrics** - Live vulnerability tracking
- **Trend Analysis** - Historical security improvements
- **Executive Reports** - Management-ready summaries

### 🔄 **Enterprise DevSecOps**
- **Automated Workflows** - GitHub Actions integration
- **Quality Gates** - Configurable failure thresholds
- **Multi-Channel Notifications** - Slack, Email, Teams, Jira
- **Compliance Ready** - SARIF format, audit trails

### 🚀 **Universal Deployment**
- **One-Command Setup** - Automated onboarding wizard
- **Template Flexibility** - Basic, Professional, Enterprise options
- **Customer Customization** - Preserve local changes during updates
- **Version Management** - Semantic versioning with automated updates

---

## 🚀 Quick Start (60 seconds)

### For New Projects

```bash
# 1. Use this repository as a template
git clone https://github.com/xlooop-ai/SAST.git my-secure-project
cd my-secure-project

# 2. Run the onboarding wizard
./scripts/universal-onboarding.sh

# 3. Follow the prompts or use automation:
./scripts/universal-onboarding.sh \
  --project-name "My App" \
  --email "developer@company.com" \
  --template professional \
  --features "github_pages,notifications"

# 4. Push to trigger first scan
git add -A
git commit -m "feat: Add SAST security integration"
git push origin main
```

### For Existing Projects

```bash
# 1. Add as remote repository
git remote add sast-boilerplate https://github.com/xlooop-ai/SAST.git
git fetch sast-boilerplate

# 2. Copy onboarding script
git checkout sast-boilerplate/main -- scripts/universal-onboarding.sh
chmod +x scripts/universal-onboarding.sh

# 3. Run setup
./scripts/universal-onboarding.sh --interactive

# 4. Commit integration
git add -A
git commit -m "feat: Integrate Universal SAST Boilerplate"
git push origin main
```

---

## 🎨 Template Options

| Template | Features | Best For |
|----------|----------|----------|
| **Basic** | Core SAST + Notifications | Small teams, simple projects |
| **Professional** | Everything + GitHub Pages + Analytics | Most projects, client demos |
| **Enterprise** | Everything + Advanced reporting + Compliance | Large organizations, regulated industries |

### Basic Template
- ✅ Multi-scanner SAST
- ✅ Quality gates
- ✅ Basic notifications
- ✅ GitHub Security tab integration

### Professional Template (Recommended)
- ✅ Everything in Basic
- ✅ GitHub Pages dashboard
- ✅ Real-time metrics
- ✅ Trend analysis
- ✅ Professional reports

### Enterprise Template
- ✅ Everything in Professional
- ✅ Advanced analytics
- ✅ Compliance reporting
- ✅ Multi-tenant support
- ✅ Custom branding

---

## 📁 What Gets Added to Your Repository

After running the onboarding wizard, your repository will have:

```
your-repository/
├── 📄 customer-config.yml           # Your project-specific settings
├── 📄 .boilerplate-lock.json        # Version tracking
├── 📄 README_CUSTOMER.md            # Setup and usage guide
├── 
├── 🗂️ .github/workflows/
│   └── 📄 sast-security-scan.yml    # Automated security scanning
├── 
└── 🗂️ docs/                         # GitHub Pages dashboard
    └── 📄 index.html                 # Professional security dashboard
```

### customer-config.yml
```yaml
project:
  name: "Your Project"
  customer_email: "you@company.com"
  template: "professional"

sast:
  scanners:
    codeql: true
    semgrep: true
    eslint_security: true
  quality_gates:
    max_critical: 0
    max_high: 5

notifications:
  slack:
    enabled: true
    webhook_url: "your-webhook"
  email:
    enabled: true
    recipients: ["team@company.com"]
```

---

## 🔧 Advanced Configuration

### Custom Scanner Rules

Add custom security rules for your specific technology stack:

```yaml
# customer-config.yml
sast:
  custom_rules:
    - path: ".sast/custom-rules/"
    - pattern: "security-patterns/*.yml"
  scanner_config:
    semgrep:
      rules: ["p/security-audit", "p/secrets"]
    eslint:
      extends: ["@eslint/js", "plugin:security/recommended"]
```

### Multi-Environment Support

Configure different settings for different environments:

```yaml
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

### Integration with External Tools

```yaml
integrations:
  jira:
    enabled: true
    project_key: "SEC"
    auto_create_tickets: true
  
  grafana:
    enabled: true
    dashboard_url: "https://grafana.company.com/d/security"
  
  sonarqube:
    enabled: true
    project_key: "my-project"
```

---

## 🎯 Use Cases

### 🏢 **Enterprise Organizations**
- **Standardize security** across all repositories
- **Centralized management** of security policies
- **Compliance reporting** for audits
- **Real-time visibility** into security posture

### 👥 **Development Teams**
- **Shift-left security** in development process
- **Automated vulnerability detection** in CI/CD
- **Professional dashboards** for stakeholders
- **Reduced manual security review** overhead

### 🔒 **Security Teams**
- **Consistent security standards** across projects
- **Automated threat detection** at scale
- **Centralized vulnerability management**
- **Evidence collection** for compliance

### 📊 **DevOps Teams**
- **Integrated security** in existing workflows
- **Automated quality gates** for deployments
- **Performance metrics** and trend analysis
- **Incident response** automation

---

## 🔍 Supported Languages & Frameworks

| Language/Framework | CodeQL | Semgrep | ESLint | Bandit | Custom |
|-------------------|--------|---------|--------|--------|--------|
| **JavaScript/TypeScript** | ✅ | ✅ | ✅ | - | ✅ |
| **Python** | ✅ | ✅ | - | ✅ | ✅ |
| **Java** | ✅ | ✅ | - | - | ✅ |
| **C#/.NET** | ✅ | ✅ | - | - | ✅ |
| **Go** | ✅ | ✅ | - | - | ✅ |
| **Ruby** | ✅ | ✅ | - | - | ✅ |
| **PHP** | ✅ | ✅ | - | - | ✅ |
| **Swift** | ✅ | ✅ | - | - | ✅ |
| **Kotlin** | ✅ | ✅ | - | - | ✅ |
| **Rust** | - | ✅ | - | - | ✅ |

---

## 📊 Dashboard Features

### Real-Time Security Dashboard

![Dashboard Preview](https://via.placeholder.com/800x400?text=Security+Dashboard+Preview)

- **Live Vulnerability Counts** - Critical, High, Medium, Low
- **Trend Analysis** - Historical vulnerability tracking
- **Scan History** - Complete audit trail
- **Quality Metrics** - Code coverage, duplication, complexity
- **Compliance Status** - Policy adherence tracking

### GitHub Pages Integration

The professional template automatically creates a GitHub Pages dashboard at:
`https://[username].github.io/[repository-name]/`

Features:
- 📱 **Responsive Design** - Works on all devices
- 🔄 **Auto-Refresh** - Real-time data updates
- 🎨 **Professional Styling** - Ready for client presentations
- 📊 **Interactive Charts** - Drill-down capabilities
- 🔐 **Access Control** - Public or private repository support

---

## 🔔 Notification Channels

### Slack Integration
```yaml
notifications:
  slack:
    webhook_url: "https://hooks.slack.com/..."
    channels:
      - "#security"
      - "#development"
    mention_on: ["critical", "high"]
    format: "detailed"  # minimal | detailed | executive
```

### Email Notifications
```yaml
notifications:
  email:
    smtp_server: "smtp.company.com"
    recipients:
      - "security-team@company.com"
      - "dev-leads@company.com"
    templates:
      critical: "detailed_report"
      summary: "executive_summary"
```

### Microsoft Teams
```yaml
notifications:
  teams:
    webhook_url: "https://outlook.office.com/webhook/..."
    adaptive_cards: true
    mention_users: ["security@company.com"]
```

### Jira Integration
```yaml
notifications:
  jira:
    server_url: "https://company.atlassian.net"
    project_key: "SEC"
    issue_type: "Security Vulnerability"
    auto_assign: "security-team"
```

---

## 🚦 Quality Gates

Configure automated quality gates to prevent vulnerable code from being deployed:

### Basic Quality Gates
```yaml
quality_gates:
  vulnerability_thresholds:
    critical: 0    # Block deployment on any critical vulnerabilities
    high: 2        # Allow up to 2 high-severity vulnerabilities
    medium: 10     # Allow up to 10 medium-severity vulnerabilities
  
  code_quality:
    min_coverage: 80          # Require 80% test coverage
    max_duplication: 5        # Allow up to 5% code duplication
    max_complexity: 15        # Block functions with complexity > 15
```

### Advanced Quality Gates
```yaml
quality_gates:
  security_policies:
    - name: "No hardcoded secrets"
      scanner: "semgrep"
      rule: "secrets.hardcoded"
      severity: "critical"
      action: "block"
    
    - name: "SQL injection prevention"
      scanner: "codeql"
      rule: "sql-injection"
      severity: "high"
      action: "block"
  
  compliance_checks:
    - standard: "OWASP Top 10"
      required: true
    - standard: "CWE Top 25"
      required: true
```

---

## 🔄 Updates & Maintenance

### Automatic Updates

The boilerplate includes an automatic update system:

```yaml
# .boilerplate-lock.json
{
  "boilerplate_version": "1.0.0",
  "auto_update": true,
  "update_channel": "stable",  # stable | beta | latest
  "preserve_customizations": true
}
```

### Manual Updates

```bash
# Check for updates
./scripts/check-boilerplate-updates.sh

# Apply updates (preserves customizations)
./scripts/update-boilerplate.sh --version 1.1.0

# Review changes before applying
./scripts/update-boilerplate.sh --dry-run --version 1.1.0
```

### Customization Preservation

The update system automatically preserves:
- ✅ Your `customer-config.yml` settings
- ✅ Custom notification templates
- ✅ Additional workflow steps
- ✅ Custom dashboard styling
- ✅ Local security rules

---

## 📞 Support & Community

### 📖 Documentation
- **[Configuration Guide](CONFIG_GUIDE.md)** - Detailed setup instructions
- **[Best Practices](docs/BEST_PRACTICES.md)** - Security recommendations
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[API Reference](docs/API.md)** - Integration endpoints

### 🐛 Issues & Feature Requests
- **Bug Reports**: [GitHub Issues](https://github.com/xlooop-ai/SAST/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/xlooop-ai/SAST/discussions)
- **Security Issues**: security@xlooop.ai

### 🤝 Contributing
We welcome contributions from the community:
- **Custom Scanner Rules** - Share security patterns
- **Dashboard Templates** - New visualization options
- **Integration Modules** - Support for additional tools
- **Documentation** - Help improve guides and examples

### 💬 Community
- **Slack**: [Join our community](https://slack.xlooop.ai)
- **Discord**: [SAST Boilerplate server](https://discord.gg/sast-boilerplate)
- **LinkedIn**: [Follow for updates](https://linkedin.com/company/xlooop-ai)

---

## 📋 Requirements

### System Requirements
- **Git**: Version 2.0+
- **Node.js**: Version 16+ (for dashboard features)
- **GitHub Account**: For Actions and Pages
- **Operating System**: Linux, macOS, Windows (WSL)

### GitHub Permissions
- **Actions**: Read/Write (for workflow execution)
- **Security Events**: Write (for SARIF uploads)
- **Pages**: Write (for dashboard deployment)
- **Repository**: Admin (for initial setup)

### Optional Integrations
- **Slack**: Webhook URL for notifications
- **Email**: SMTP server access
- **Jira**: API token and project permissions
- **Grafana**: API key for dashboard integration

---

## 🏷️ Versioning & Releases

We use [Semantic Versioning](https://semver.org/) for releases:

- **MAJOR** version: Breaking changes to configuration or API
- **MINOR** version: New features, backward compatible
- **PATCH** version: Bug fixes, security updates

### Release Channels
- **Stable** (recommended): Thoroughly tested releases
- **Beta**: Early access to new features
- **Latest**: Cutting-edge updates (use with caution)

### Changelog
See [CHANGELOG.md](CHANGELOG.md) for detailed release notes.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Attribution

When using this boilerplate, please include attribution:

```markdown
Security powered by [Universal SAST Boilerplate](https://github.com/xlooop-ai/SAST)
```

---

## 🎯 Get Started Now

Ready to secure your repository? Choose your path:

### 🚀 **Quick Start** (Recommended)
```bash
./scripts/universal-onboarding.sh --template professional
```

### 🎛️ **Custom Setup**
```bash
./scripts/universal-onboarding.sh --interactive
```

### 📋 **Enterprise Deployment**
```bash
./scripts/universal-onboarding.sh --template enterprise \
  --features "all" \
  --compliance "soc2,hipaa"
```

---

**⭐ Star this repository** if you find it useful!

**🔗 Share with your team** and help improve security across your organization.

**📢 Follow us** for updates on new features and security best practices.

---

*Built with ❤️ by the [xlooop.ai](https://xlooop.ai) team*
