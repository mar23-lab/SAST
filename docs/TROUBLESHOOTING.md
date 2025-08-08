# 🔧 Troubleshooting Guide

This guide helps resolve common issues when setting up and using the CI/CD SAST Security Boilerplate.

## 🚨 Common Issues

### 1. Configuration Issues

#### YAML Syntax Errors

**Problem**: Pipeline fails with YAML parsing errors
```
Error: invalid YAML syntax in ci-config.yaml
```

**Solution**:
```bash
# Validate YAML syntax
yq eval ci-config.yaml > /dev/null

# Common issues:
# - Incorrect indentation (use spaces, not tabs)
# - Missing quotes around special characters
# - Unescaped special characters in strings
```

#### Missing Required Configuration

**Problem**: Pipeline fails due to missing required fields
```
Error: required field 'sast.scanners' not found
```

**Solution**:
```yaml
# Ensure all required fields are present
sast:
  scanners:
    - "codeql"  # At least one scanner required
```

### 2. GitHub Actions Issues

#### Workflow Permission Errors

**Problem**: 
```
Error: Resource not accessible by integration
```

**Solution**:
1. Go to Repository Settings > Actions > General
2. Set "Workflow permissions" to "Read and write permissions"
3. Enable "Allow GitHub Actions to create and approve pull requests"

#### Secret Not Found

**Problem**:
```
Error: Secret SLACK_WEBHOOK not found
```

**Solution**:
1. Go to Repository Settings > Secrets and Variables > Actions
2. Add required secrets:
   - `SLACK_WEBHOOK`
   - `EMAIL_SMTP_PASSWORD`
   - `JIRA_API_TOKEN`
   - `GRAFANA_API_KEY`

### 3. Scanner-Specific Issues

#### CodeQL Setup Failures

**Problem**:
```
Error: CodeQL could not analyze language: javascript
```

**Solution**:
```yaml
# Ensure language is supported and properly configured
sast:
  languages:
    - "javascript"  # Must match CodeQL supported languages
  codeql:
    query_suites:
      - "security-and-quality"
```

#### Semgrep Authentication

**Problem**:
```
Error: Semgrep authentication failed
```

**Solution**:
1. Get Semgrep App Token from https://semgrep.dev/manage/settings
2. Add as `SEMGREP_APP_TOKEN` secret
3. Or use community rules (remove token requirement):
```yaml
sast:
  semgrep:
    rules: "auto"  # Uses community rules
```

#### Bandit Python Path Issues

**Problem**:
```
Error: No Python files found for Bandit scan
```

**Solution**:
```yaml
# Check exclude paths in bandit.yaml
exclude_dirs:
  - '/tests'
  - '/venv'
  # Don't exclude your actual Python source directories
```

### 4. Integration Issues

#### Slack Webhook Failures

**Problem**:
```
Error: Slack webhook returned 404
```

**Solution**:
1. Verify webhook URL format: `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX`
2. Test webhook manually:
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test message"}' \
  YOUR_WEBHOOK_URL
```
3. Check webhook is active in Slack App settings

#### Email SMTP Issues

**Problem**:
```
Error: SMTP authentication failed
```

**Solution**:
1. Verify SMTP settings:
```yaml
email:
  smtp_server: "smtp.gmail.com"  # Correct SMTP server
  smtp_port: 587                 # Correct port (587 for STARTTLS)
```
2. Check email password/app password
3. For Gmail, use App Passwords (not regular password)

#### Jira API Issues

**Problem**:
```
Error: Jira API returned 401 Unauthorized
```

**Solution**:
1. Create API token: https://id.atlassian.com/manage-profile/security/api-tokens
2. Verify Jira URL format: `https://your-domain.atlassian.net`
3. Test API access:
```bash
curl -u your-email@domain.com:API_TOKEN \
  -X GET \
  -H "Content-Type: application/json" \
  https://your-domain.atlassian.net/rest/api/2/myself
```

#### Grafana Connection Issues

**Problem**:
```
Error: Grafana API key invalid
```

**Solution**:
1. Create API key in Grafana: Configuration > API Keys
2. Set appropriate permissions (Editor or Admin)
3. Test API key:
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://your-grafana.com/api/org
```

### 5. Demo Mode Issues

#### Demo Script Permission Denied

**Problem**:
```
bash: ./run_demo.sh: Permission denied
```

**Solution**:
```bash
chmod +x run_demo.sh
```

#### Missing Dependencies

**Problem**:
```
Error: jq: command not found
```

**Solution**:
```bash
# macOS
brew install jq yq

# Ubuntu/Debian
sudo apt-get install jq
sudo wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# CentOS/RHEL
sudo yum install jq
```

### 6. Performance Issues

#### Pipeline Timeout

**Problem**:
```
Error: The job running on runner GitHub Actions has exceeded the maximum execution time
```

**Solution**:
```yaml
# Increase timeouts in ci-config.yaml
pipeline:
  timeouts:
    total_pipeline: 120  # Increase from default 60 minutes
    sast_scan: 60        # Increase scan timeout
```

#### Large Repository Scans

**Problem**: Scans taking too long on large codebases

**Solution**:
1. Exclude unnecessary paths:
```yaml
sast:
  semgrep:
    exclude_paths:
      - "node_modules/"
      - "vendor/"
      - "build/"
      - "dist/"
```
2. Use incremental scanning where possible
3. Consider splitting into multiple jobs

### 7. Results and Reporting Issues

#### SARIF Upload Failures

**Problem**:
```
Error: Failed to upload SARIF file
```

**Solution**:
1. Check SARIF file format validity
2. Ensure proper GitHub permissions
3. Verify file size limits (10MB max)

#### Missing Vulnerability Data

**Problem**: No vulnerabilities found despite expecting some

**Solution**:
1. Check severity thresholds:
```yaml
sast:
  severity_threshold: "low"  # Lower threshold to see more findings
```
2. Verify scanner configuration
3. Check exclude paths aren't too broad

## 🔍 Debugging Steps

### 1. Enable Verbose Logging

```bash
# Run demo with verbose output
./run_demo.sh -v

# Check GitHub Actions logs for detailed output
```

### 2. Validate Configuration

```bash
# Check YAML syntax
yq eval ci-config.yaml

# Test individual components
./run_demo.sh -c slack
./run_demo.sh -c email
./run_demo.sh -c jira
```

### 3. Test Network Connectivity

```bash
# Test webhook endpoints
curl -I https://hooks.slack.com/services/your/webhook
curl -I https://your-jira.atlassian.net
curl -I https://your-grafana.com

# Test SMTP
telnet smtp.gmail.com 587
```

### 4. Check Scanner Dependencies

```bash
# Verify scanner requirements
npm list eslint  # For ESLint
pip list | grep bandit  # For Bandit
semgrep --version  # For Semgrep
```

## 📊 Monitoring and Maintenance

### Regular Health Checks

1. **Weekly**: Run demo mode to verify integrations
2. **Monthly**: Review and rotate API keys/tokens
3. **Quarterly**: Update scanner versions and rules

### Performance Monitoring

```bash
# Monitor pipeline execution times
# Check for timeout issues
# Review resource usage

# Example: Check recent workflow runs
gh api repos/:owner/:repo/actions/runs --jq '.workflow_runs[0:5] | .[] | {status, conclusion, created_at}'
```

### Security Maintenance

1. **Rotate secrets** every 90 days
2. **Update scanner rules** regularly
3. **Review threshold settings** quarterly
4. **Audit access permissions** monthly

## 🆘 Getting Additional Help

### Information to Gather

When seeking help, provide:
1. **Error message** (full text)
2. **Configuration** (sanitized ci-config.yaml)
3. **GitHub Actions logs** (relevant sections)
4. **Environment details** (repository size, languages, etc.)

### Useful Commands for Debugging

```bash
# Check repository structure
find . -name "*.py" -o -name "*.js" -o -name "*.ts" | wc -l

# Validate GitHub Actions workflow
act --list  # If using 'act' for local testing

# Check secret availability (in Actions)
echo "Secrets status: ${{ secrets.SLACK_WEBHOOK != '' }}"
```

### Log Analysis

Look for these patterns in GitHub Actions logs:
- `Error:` - Direct error messages
- `Warning:` - Potential issues
- `403` or `401` - Authentication problems
- `404` - Resource not found
- `timeout` - Performance issues

### Community Resources

- **GitHub Discussions**: Repository discussions for questions
- **Security Scanner Docs**: Official documentation for each scanner
- **GitHub Actions Community**: Actions marketplace and forums

---

**💡 Pro Tip**: Always test changes in demo mode before applying to production pipelines!
