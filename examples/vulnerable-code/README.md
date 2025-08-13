# ⚠️ Intentional Vulnerability Examples

**WARNING: This directory contains intentionally vulnerable code for SAST testing purposes.**

## 🚨 Security Notice

These files contain **real security vulnerabilities** that are:
- ✅ **Intentional** - Created for SAST platform testing
- ❌ **NOT for production** - Never use this code in real applications
- 🔍 **Testing purposes only** - Used to validate SAST scanner functionality

## 📁 Vulnerable Code Examples

### `sql_injection.py`
**Vulnerabilities included**:
- SQL injection via string concatenation
- Command injection with subprocess.call()
- Insecure pickle deserialization
- Hardcoded credentials
- Path traversal vulnerabilities
- Weak cryptographic functions

**SAST Findings Expected**:
- **HIGH**: Command injection (subprocess with shell=True)
- **MEDIUM**: SQL injection patterns
- **LOW**: Weak hash algorithms, subprocess module usage

## 🎯 Purpose

These examples serve to:
1. **Validate SAST functionality** - Ensure our scanners detect real vulnerabilities
2. **Test scanner accuracy** - Verify proper severity classification
3. **Benchmark detection** - Compare different SAST tools
4. **Demo capabilities** - Show customers what our platform detects

## 🔒 Security Measures

- ✅ Files clearly marked as vulnerable examples
- ✅ Warning comments in all vulnerable code
- ✅ Isolated in separate directory
- ✅ Documentation explains intentional nature
- ✅ Not included in production deployments

## 🧪 SAST Test Results

When scanned by our SAST platform, these files should produce:
- **20+ security findings** (Python vulnerabilities)
- **Proper severity classification** (Critical/High/Medium/Low)
- **Accurate vulnerability descriptions**
- **Clear remediation guidance**

## ⚠️ Important Reminders

1. **Never copy this code** into production applications
2. **These are teaching examples** of what NOT to do
3. **All vulnerabilities are intentional** and documented
4. **Use for SAST validation only**

---

*These examples demonstrate the types of vulnerabilities that our SAST platform successfully detects and helps prevent in real codebases.*
