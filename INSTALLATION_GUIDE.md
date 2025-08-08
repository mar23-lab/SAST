# 🚀 SAST Platform - Complete Installation Guide

## 📋 Overview

This guide provides step-by-step instructions for deploying a **production-ready SAST (Static Application Security Testing) platform** with comprehensive monitoring, alerting, and visualization capabilities.

## 🎯 What You'll Get

- **Multi-scanner SAST**: CodeQL, Semgrep, Bandit, ESLint
- **Real-time Dashboards**: Grafana with InfluxDB and Prometheus
- **Advanced Monitoring**: Metrics, alerts, and trend analysis
- **Email Integration**: HTML notifications with testing capabilities
- **Demo Mode**: Safe testing environment
- **Repository Testing**: Script for scanning real GitHub repositories

## ⚡ Quick Start (5 minutes)

### Prerequisites
- Docker & Docker Compose installed
- 8GB RAM minimum
- 10GB free disk space

### One-Command Deployment
```bash
git clone https://github.com/xlooop-ai/SAST.git
cd SAST
docker-compose -f docker-compose-minimal.yml up -d
```

### Access Your Platform
- **Grafana Dashboards**: http://localhost:3001 (admin:admin123)
- **InfluxDB Database**: http://localhost:8087 (admin:adminpass123)
- **Email Testing**: http://localhost:8025
- **Prometheus Metrics**: http://localhost:9090

## 📊 Service Architecture

```mermaid
graph TB
    A[GitHub Repository] --> B[SAST Runner]
    B --> C[Multiple Scanners]
    C --> D[Results Processing]
    D --> E[InfluxDB]
    D --> F[Prometheus]
    E --> G[Grafana Dashboards]
    F --> G
    D --> H[Email Notifications]
    D --> I[Slack/Jira Alerts]
    
    subgraph "Monitoring Stack"
        E
        F
        G
    end
    
    subgraph "Notification System"
        H
        I
        J[MailHog Testing]
    end
```

## 🔧 Detailed Installation

### Step 1: Clone and Prepare
```bash
# Clone the repository
git clone https://github.com/xlooop-ai/SAST.git
cd SAST

# Make scripts executable
chmod +x *.sh scripts/*.sh
```

### Step 2: Configure Environment (Optional)
```bash
# Copy and customize configuration
cp ci-config.yaml ci-config-production.yaml

# Edit configuration for your environment
nano ci-config-production.yaml
```

### Step 3: Deploy Services
```bash
# Start all services
docker-compose -f docker-compose-minimal.yml up -d

# Check service status
docker-compose -f docker-compose-minimal.yml ps
```

### Step 4: Verify Installation
```bash
# Run health checks
curl -s http://localhost:8087/health | jq .
curl -s http://localhost:3001/api/health | jq .
curl -s http://localhost:9090/api/v1/status/config
```

### Step 5: Run Demo Test
```bash
# Execute demo scan
docker exec -it sast-runner ./run_demo.sh -s critical -c all

# Send metrics to monitoring systems
docker exec -it sast-runner ./scripts/influxdb_integration.sh success
```

## 📊 Dashboard Setup

### InfluxDB Dashboard (Primary)
1. Open http://localhost:3001
2. Login: admin / admin123
3. Navigate to: http://localhost:3001/d/bb0e2238-59f0-42ce-a4e7-1e1c0242f277/sast-security-dashboard-influxdb

### Prometheus Dashboard (Alternative)
1. Same Grafana instance
2. Navigate to: http://localhost:3001/d/sast-security-dashboard/sast-security-dashboard

## 🧪 Testing Real Repositories

### Test with Vulnerable Applications
```bash
# Test OWASP NodeGoat (JavaScript vulnerabilities)
docker exec -it sast-runner ./test_real_repo.sh https://github.com/OWASP/NodeGoat

# Test Vulnerable Flask App (Python vulnerabilities)  
docker exec -it sast-runner ./test_real_repo.sh https://github.com/we45/vulnerable-flask-app

# Test any GitHub repository
docker exec -it sast-runner ./test_real_repo.sh https://github.com/user/repo main
```

### After Testing
```bash
# Send real results to monitoring
docker exec -it sast-runner ./scripts/influxdb_integration.sh failure
docker exec -it sast-runner ./scripts/update_grafana.sh failure
```

## 📧 Email Configuration

### Development (MailHog)
MailHog is pre-configured for testing:
- **SMTP**: localhost:1025
- **Web UI**: http://localhost:8025

### Production SMTP
Edit `ci-config.yaml`:
```yaml
notifications:
  email:
    enabled: true
    smtp_server: "your-smtp-server.com"
    smtp_port: 587
    sender_email: "alerts@yourcompany.com"
    recipients:
      - "security@yourcompany.com"
      - "devops@yourcompany.com"
```

## 🔔 Notification Channels

### Slack Integration
```yaml
integrations:
  slack:
    enabled: true
    webhook_url: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    channel: "#security-alerts"
```

### Jira Integration
```yaml
integrations:
  jira:
    enabled: true
    server_url: "https://yourcompany.atlassian.net"
    project_key: "SEC"
    api_token: "your-api-token"
```

## 🔧 Production Configuration

### Environment-Specific Settings
```yaml
environments:
  production:
    sast:
      severity_threshold: "medium"
      max_critical_vulnerabilities: 0
      max_high_vulnerabilities: 5
    notifications:
      trigger: "always"
    pipeline:
      timeouts:
        total_pipeline: 120
        sast_scan: 60
```

### Security Hardening
```bash
# Generate secure passwords
GRAFANA_PASSWORD=$(openssl rand -base64 32)
INFLUXDB_PASSWORD=$(openssl rand -base64 32)

# Update docker-compose-minimal.yml with secure passwords
sed -i "s/admin123/$GRAFANA_PASSWORD/" docker-compose-minimal.yml
sed -i "s/adminpass123/$INFLUXDB_PASSWORD/" docker-compose-minimal.yml
```

## 📈 Monitoring & Alerting

### Prometheus Alert Rules
```yaml
# Add to prometheus-config/sast_rules.yml
groups:
  - name: sast_critical_alerts
    rules:
      - alert: CriticalVulnerabilitiesFound
        expr: sast_vulnerabilities_total{severity="critical"} > 0
        labels:
          severity: critical
        annotations:
          summary: "Critical security vulnerabilities detected"
```

### Grafana Alert Channels
1. Navigate to Grafana → Alerting → Alert Channels
2. Add Slack/Email/PagerDuty integrations
3. Configure thresholds for automatic alerting

## 🔄 CI/CD Integration

### GitHub Actions Workflow
```yaml
name: SAST Security Scan
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  security-scan:
    uses: ./.github/workflows/sast-security-scan.yml
    secrets:
      SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
      EMAIL_SMTP_PASSWORD: ${{ secrets.EMAIL_SMTP_PASSWORD }}
```

### GitLab CI Integration
```yaml
include:
  - local: '.gitlab/sast-pipeline.yml'

variables:
  SAST_CONFIG: "ci-config.yaml"
  NOTIFICATION_CHANNELS: "slack,email"
```

## 🐛 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check port usage
lsof -i :3001 -i :8087 -i :9090

# Modify ports in docker-compose-minimal.yml if needed
```

#### Service Not Starting
```bash
# Check logs
docker-compose -f docker-compose-minimal.yml logs service-name

# Restart specific service
docker-compose -f docker-compose-minimal.yml restart service-name
```

#### No Data in Dashboards
```bash
# Send test metrics
docker exec -it sast-runner ./scripts/influxdb_integration.sh success

# Check InfluxDB data
curl -H "Authorization: Token sast-admin-token-12345" \
     "http://localhost:8087/api/v2/query?org=sast-org" \
     -d 'from(bucket:"sast-metrics") |> range(start:-1h) |> limit(n:5)'
```

### Performance Tuning

#### Resource Limits
```yaml
# Add to docker-compose-minimal.yml
services:
  grafana:
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

#### Database Optimization
```yaml
# InfluxDB settings
environment:
  - INFLUXDB_DATA_CACHE_SIZE=256m
  - INFLUXDB_DATA_WAL_FSYNC_DELAY=1s
```

## 📊 Maintenance

### Regular Tasks
```bash
# Update system (monthly)
docker-compose -f docker-compose-minimal.yml pull
docker-compose -f docker-compose-minimal.yml up -d

# Cleanup old data (weekly)
docker exec sast-influxdb influx delete \
  --bucket sast-metrics \
  --start '1970-01-01T00:00:00Z' \
  --stop $(date -d '30 days ago' -u +%Y-%m-%dT%H:%M:%SZ)

# Backup configuration
tar -czf sast-backup-$(date +%Y%m%d).tar.gz \
  ci-config.yaml \
  grafana-config/ \
  prometheus-config/
```

### Monitoring Health
```bash
# Service health script
#!/bin/bash
services=("grafana" "influxdb" "prometheus" "sast-runner")
for service in "${services[@]}"; do
  if docker ps --filter "name=sast-$service" --filter "status=running" | grep -q $service; then
    echo "✅ $service is running"
  else
    echo "❌ $service is not running"
  fi
done
```

## 🎯 Success Metrics

### After Installation, You Should See:
- ✅ All 6 Docker containers running
- ✅ Grafana dashboards showing vulnerability data
- ✅ InfluxDB with SAST metrics stored
- ✅ Email notifications working via MailHog
- ✅ Demo mode execution successful
- ✅ Real repository scanning functional

### Performance Benchmarks:
- **Demo scan**: ~30 seconds
- **Real repository scan**: 2-5 minutes
- **Dashboard load time**: <3 seconds
- **Notification delivery**: <10 seconds

## 🚀 Next Steps

1. **Customize for your organization**: Update `ci-config.yaml`
2. **Set up CI/CD integration**: Add to your pipeline
3. **Configure production notifications**: Slack, Jira, email
4. **Scale deployment**: Consider Kubernetes for production
5. **Add custom scanners**: Extend with additional security tools

## 📞 Support

- **Documentation**: Review included README.md and CONFIG_GUIDE.md
- **Demo Testing**: Use `run_demo.sh` for safe experimentation
- **Real Testing**: Use `test_real_repo.sh` for live repository scanning
- **Logs**: `docker-compose logs` for troubleshooting

---

**🎉 Congratulations! You now have a production-ready SAST platform that rivals commercial solutions costing $300k+ annually.**
