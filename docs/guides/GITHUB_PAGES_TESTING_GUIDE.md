# 🧪 GitHub Pages Testing Guide

Complete guide for testing your SAST security dashboard before deploying to GitHub Pages.

## 🚀 Quick Testing Methods

### Method 1: Automated Testing Script (Recommended)

```bash
# Start the test dashboard
./test-github-pages.sh

# Custom configuration
./test-github-pages.sh --company "Your Company" --email "security@yourcompany.com"

# Use different port
./test-github-pages.sh --port 9000

# Stop the test server
./test-github-pages.sh --stop
```

### Method 2: Manual Local Testing

```bash
# 1. Copy and customize template
cp -r templates/professional local-test
cd local-test

# 2. Replace template variables
sed -i 's/{{COMPANY_NAME}}/Your Company/g' index.html
sed -i 's/{{CONTACT_EMAIL}}/security@yourcompany.com/g' index.html
sed -i 's|{{GITHUB_REPO_URL}}|https://github.com/your-user/your-repo|g' index.html

# 3. Start local server
python3 -m http.server 8080

# 4. Open in browser
open http://localhost:8080
```

### Method 3: Using Your One-Command Setup

```bash
# Use the sast-init.sh with GitHub Pages feature
./sast-init.sh --interactive
# Select "github_pages" when prompted for features

# Or directly:
./sast-init.sh --project "Test Project" --features "github_pages"
```

## 🌐 Testing the Live Dashboard

### What to Test

1. **📊 Visual Elements**
   - [ ] Dashboard loads without errors
   - [ ] All metrics cards display correctly
   - [ ] Charts render properly (requires Chart.js)
   - [ ] Responsive design works on mobile

2. **🔧 Functionality**
   - [ ] Real-time data updates
   - [ ] Interactive charts and graphs
   - [ ] Navigation and links work
   - [ ] Integration status indicators

3. **🎨 Customization**
   - [ ] Company name appears correctly
   - [ ] Contact email is displayed
   - [ ] Repository links are functional
   - [ ] Branding matches your organization

4. **📱 Cross-Platform Testing**
   - [ ] Desktop browsers (Chrome, Firefox, Safari)
   - [ ] Mobile devices (iOS, Android)
   - [ ] Tablet devices
   - [ ] Different screen resolutions

## 🚀 GitHub Pages Deployment Testing

### Step 1: Enable GitHub Pages

1. Go to your repository on GitHub
2. Navigate to **Settings** > **Pages**
3. Source: **GitHub Actions**
4. Save the configuration

### Step 2: Deploy Workflow

```yaml
# Copy this to .github/workflows/deploy-pages.yml
name: Deploy Security Dashboard

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/configure-pages@v4
    
    - name: Build Dashboard
      run: |
        mkdir -p _site
        cp -r templates/professional/* _site/
        # Customize with your data
        cd _site
        sed -i 's/{{COMPANY_NAME}}/Your Company/g' index.html
        sed -i 's|{{GITHUB_REPO_URL}}|https://github.com/${{ github.repository }}|g' index.html
    
    - uses: actions/upload-pages-artifact@v3
    - uses: actions/deploy-pages@v4
      id: deployment
```

### Step 3: Test Live Deployment

1. **Push changes** to trigger deployment
2. **Wait for workflow** to complete (usually 2-5 minutes)
3. **Access your dashboard** at: `https://[username].github.io/[repository]`

### Step 4: Verify Functionality

```bash
# Test the live URL
curl -I https://your-username.github.io/your-repo

# Check for common issues
curl -s https://your-username.github.io/your-repo | grep -i "error\|404\|500"
```

## 🔧 Troubleshooting Common Issues

### Issue 1: Dashboard Not Loading

**Symptoms**: Blank page or 404 error
**Solutions**:
```bash
# Check if index.html exists in the right location
ls -la templates/professional/index.html

# Verify GitHub Pages is enabled
# Go to Settings > Pages in your repository

# Check workflow logs
# Go to Actions tab in your repository
```

### Issue 2: Styles Not Loading

**Symptoms**: Unstyled HTML content
**Solutions**:
```bash
# Check CSS file paths in index.html
grep -n "\.css" templates/professional/index.html

# Verify CSS files exist
ls -la templates/professional/assets/css/

# Test locally first
./test-github-pages.sh
```

### Issue 3: JavaScript Not Working

**Symptoms**: Static dashboard, no interactivity
**Solutions**:
```bash
# Check browser console for errors
# Open Developer Tools > Console

# Verify JavaScript files exist
ls -la templates/professional/assets/js/

# Test Chart.js loading
curl -I https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.min.js
```

### Issue 4: Template Variables Not Replaced

**Symptoms**: Seeing {{COMPANY_NAME}} instead of actual values
**Solutions**:
```bash
# Check your deployment script replaces variables
grep -n "{{" templates/professional/index.html

# Use the automated testing script
./test-github-pages.sh --company "Your Company"

# Manually replace in deployment
sed -i 's/{{COMPANY_NAME}}/Your Company/g' index.html
```

## 📊 Performance Testing

### Load Time Testing

```bash
# Test page load speed
curl -w "@curl-format.txt" -o /dev/null -s https://your-username.github.io/your-repo

# Create curl-format.txt:
echo "     time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
   time_pretransfer:  %{time_pretransfer}\n
      time_redirect:  %{time_redirect}\n
 time_starttransfer:  %{time_starttransfer}\n
                    ----------\n
         time_total:  %{time_total}\n" > curl-format.txt
```

### Security Testing

```bash
# Check HTTPS configuration
curl -I https://your-username.github.io/your-repo

# Verify security headers
curl -I https://your-username.github.io/your-repo | grep -i "x-frame-options\|content-security-policy"
```

## 🎯 Best Practices

### 1. Test Locally First
Always test your dashboard locally before deploying to GitHub Pages.

### 2. Use Version Control
Commit your changes and test in a separate branch before merging to main.

### 3. Monitor Deployment
Watch the GitHub Actions workflow to catch deployment issues early.

### 4. Mobile Testing
Test on multiple devices to ensure responsive design works correctly.

### 5. Performance Optimization
- Minimize external dependencies
- Optimize images and assets
- Use CDNs for libraries like Chart.js

## 📞 Getting Help

### Common Resources

- **GitHub Pages Documentation**: https://docs.github.com/en/pages
- **GitHub Actions Workflow Logs**: Repository > Actions tab
- **Browser Developer Tools**: F12 for debugging
- **SAST Testing Script**: `./test-github-pages.sh --help`

### Testing Checklist

Before deploying to production:

- [ ] Local testing completed successfully
- [ ] All template variables replaced
- [ ] CSS and JavaScript loading correctly
- [ ] Charts and interactivity working
- [ ] Mobile responsive design tested
- [ ] Performance is acceptable
- [ ] Security headers are present
- [ ] All links are functional

## 🎉 Success Criteria

Your GitHub Pages dashboard is ready when:

1. ✅ **Loads quickly** (< 3 seconds)
2. ✅ **Displays all metrics** correctly
3. ✅ **Charts are interactive** and functional
4. ✅ **Mobile responsive** on all devices
5. ✅ **Company branding** is consistent
6. ✅ **Links work** and navigate correctly
7. ✅ **Updates automatically** with new data
8. ✅ **Professional appearance** suitable for stakeholders

---

**🚀 Ready to deploy?** Your SAST security dashboard will provide real-time visibility into your security posture and impress stakeholders with its professional presentation!

*Generated by Universal SAST Boilerplate Testing Suite*
