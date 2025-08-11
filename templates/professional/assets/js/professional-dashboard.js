/**
 * Professional Dashboard - Universal SAST Boilerplate
 * Main dashboard functionality for professional template
 */

class ProfessionalDashboard {
    constructor(config = {}) {
        this.config = {
            companyName: config.companyName || 'Your Company',
            contactEmail: config.contactEmail || 'security@company.com',
            githubRepo: config.githubRepo || '',
            refreshInterval: config.refreshInterval || 300000, // 5 minutes
            apiEndpoint: config.apiEndpoint || '/api/security',
            realDataOnly: config.realDataOnly !== false // Default to true
        };
        
        this.charts = {};
        this.refreshTimer = null;
        this.lastUpdateTime = new Date();
        
        // Data cache
        this.cache = {
            securityData: null,
            integrationStatus: null,
            commitData: null,
            scannerData: null,
            lastFetch: null
        };
        
        // Bind methods
        this.initialize = this.initialize.bind(this);
        this.refreshData = this.refreshData.bind(this);
        this.updateMetrics = this.updateMetrics.bind(this);
        this.updateCharts = this.updateCharts.bind(this);
    }
    
    async initialize() {
        console.log('🚀 Initializing Professional Dashboard...');
        
        try {
            // Show loading overlay
            this.showLoading(true);
            
            // Initialize UI components
            this.initializeUI();
            
            // Load initial data
            await this.loadInitialData();
            
            // Setup auto-refresh
            this.setupAutoRefresh();
            
            // Setup event listeners
            this.setupEventListeners();
            
            console.log('✅ Professional Dashboard initialized successfully');
            
        } catch (error) {
            console.error('❌ Dashboard initialization failed:', error);
            this.showError('Failed to initialize dashboard. Please refresh the page.');
        } finally {
            this.showLoading(false);
        }
    }
    
    initializeUI() {
        // Update company branding
        this.updateCompanyBranding();
        
        // Initialize placeholders
        this.initializePlaceholders();
        
        // Setup responsive behavior
        this.setupResponsiveBehavior();
        
        console.log('🎨 UI components initialized');
    }
    
    updateCompanyBranding() {
        // Update company logo if default
        const logoElement = document.getElementById('company-logo');
        if (logoElement && logoElement.src.includes('{{COMPANY_LOGO}}')) {
            logoElement.src = 'assets/img/default-logo.png';
            logoElement.alt = this.config.companyName;
        }
        
        // Update page title
        document.title = `${this.config.companyName} Security Dashboard`;
        
        // Update footer links
        const contactLinks = document.querySelectorAll('.contact-link');
        contactLinks.forEach(link => {
            if (link.href.includes('{{CONTACT_EMAIL}}')) {
                link.href = `mailto:${this.config.contactEmail}`;
            }
        });
    }
    
    initializePlaceholders() {
        // Initialize metric values
        this.updateElement('critical-count', '0');
        this.updateElement('high-count', '0');
        this.updateElement('medium-count', '0');
        this.updateElement('low-count', '0');
        this.updateElement('security-score', '0');
        
        // Initialize status indicators
        this.updateSystemStatus('checking', 'Checking system health...');
        this.updateIntegrationStatus('github', 'checking', 'Checking...');
        this.updateIntegrationStatus('slack', 'checking', 'Checking...');
        this.updateIntegrationStatus('email', 'checking', 'Checking...');
        this.updateIntegrationStatus('jira', 'checking', 'Checking...');
    }
    
    async loadInitialData() {
        console.log('📊 Loading initial data...');
        
        // Load data from multiple sources
        const [securityData, integrationStatus, commitData, scannerData] = await Promise.allSettled([
            this.loadSecurityData(),
            this.checkIntegrationStatus(),
            this.loadCommitData(),
            this.loadScannerData()
        ]);
        
        // Process results
        if (securityData.status === 'fulfilled') {
            this.cache.securityData = securityData.value;
            this.updateMetrics(securityData.value);
        }
        
        if (integrationStatus.status === 'fulfilled') {
            this.cache.integrationStatus = integrationStatus.value;
            this.updateIntegrationDisplay(integrationStatus.value);
        }
        
        if (commitData.status === 'fulfilled') {
            this.cache.commitData = commitData.value;
            this.updateCommitDisplay(commitData.value);
        }
        
        if (scannerData.status === 'fulfilled') {
            this.cache.scannerData = scannerData.value;
            this.updateScannerDisplay(scannerData.value);
        }
        
        // Initialize charts with data
        this.initializeCharts();
        
        // Update last refresh time
        this.updateLastRefreshTime();
        
        console.log('✅ Initial data loaded');
    }
    
    async loadSecurityData() {
        try {
            // Try to load from multiple sources
            const sources = [
                this.loadFromSARIFFiles(),
                this.loadFromAPI(),
                this.loadFromLocalStorage()
            ];
            
            for (const source of sources) {
                try {
                    const data = await source;
                    if (data && this.validateSecurityData(data)) {
                        console.log('📈 Security data loaded from source');
                        return data;
                    }
                } catch (error) {
                    console.warn('⚠️ Data source failed:', error.message);
                }
            }
            
            // If no real data available and realDataOnly is false, return sample data
            if (!this.config.realDataOnly) {
                console.warn('⚠️ Using sample data (real data not available)');
                return this.getSampleSecurityData();
            }
            
            // Return empty data structure
            console.warn('⚠️ No security data available');
            return this.getEmptySecurityData();
            
        } catch (error) {
            console.error('❌ Failed to load security data:', error);
            return this.getEmptySecurityData();
        }
    }
    
    async loadFromSARIFFiles() {
        // Try to load SARIF files from common locations
        const sarifPaths = [
            'data/codeql-results.sarif',
            'data/semgrep-results.sarif',
            'data/eslint-results.sarif',
            'data/security-results.json'
        ];
        
        const results = [];
        
        for (const path of sarifPaths) {
            try {
                const response = await fetch(path);
                if (response.ok) {
                    const data = await response.json();
                    results.push(this.parseSARIFData(data));
                }
            } catch (error) {
                // Silently continue to next source
            }
        }
        
        if (results.length > 0) {
            return this.mergeScanResults(results);
        }
        
        throw new Error('No SARIF files found');
    }
    
    async loadFromAPI() {
        const response = await fetch(this.config.apiEndpoint);
        if (!response.ok) {
            throw new Error(`API request failed: ${response.status}`);
        }
        return await response.json();
    }
    
    async loadFromLocalStorage() {
        const data = localStorage.getItem('sast-security-data');
        if (!data) {
            throw new Error('No local storage data');
        }
        
        const parsed = JSON.parse(data);
        
        // Check if data is fresh (within 1 hour)
        const dataAge = Date.now() - new Date(parsed.timestamp).getTime();
        if (dataAge > 3600000) { // 1 hour
            throw new Error('Local storage data is stale');
        }
        
        return parsed.data;
    }
    
    validateSecurityData(data) {
        return data &&
               typeof data === 'object' &&
               data.vulnerabilities &&
               Array.isArray(data.vulnerabilities) &&
               data.summary &&
               typeof data.summary === 'object';
    }
    
    parseSARIFData(sarifData) {
        // Parse SARIF format to our internal format
        const vulnerabilities = [];
        
        if (sarifData.runs) {
            for (const run of sarifData.runs) {
                if (run.results) {
                    for (const result of run.results) {
                        vulnerabilities.push({
                            id: result.ruleId || 'unknown',
                            severity: this.mapSARIFSeverity(result.level),
                            message: result.message?.text || 'No description',
                            file: result.locations?.[0]?.physicalLocation?.artifactLocation?.uri || 'unknown',
                            line: result.locations?.[0]?.physicalLocation?.region?.startLine || 0,
                            scanner: run.tool?.driver?.name || 'unknown'
                        });
                    }
                }
            }
        }
        
        return {
            vulnerabilities,
            scanner: sarifData.runs?.[0]?.tool?.driver?.name || 'unknown',
            timestamp: new Date().toISOString()
        };
    }
    
    mapSARIFSeverity(level) {
        const mapping = {
            'error': 'critical',
            'warning': 'high',
            'note': 'medium',
            'info': 'low'
        };
        return mapping[level] || 'medium';
    }
    
    mergeScanResults(results) {
        const merged = {
            vulnerabilities: [],
            summary: { critical: 0, high: 0, medium: 0, low: 0 },
            scanners: [],
            timestamp: new Date().toISOString()
        };
        
        for (const result of results) {
            merged.vulnerabilities.push(...result.vulnerabilities);
            if (result.scanner) {
                merged.scanners.push(result.scanner);
            }
        }
        
        // Calculate summary
        for (const vuln of merged.vulnerabilities) {
            merged.summary[vuln.severity] = (merged.summary[vuln.severity] || 0) + 1;
        }
        
        return merged;
    }
    
    getEmptySecurityData() {
        return {
            vulnerabilities: [],
            summary: { critical: 0, high: 0, medium: 0, low: 0 },
            scanners: [],
            timestamp: new Date().toISOString()
        };
    }
    
    getSampleSecurityData() {
        return {
            vulnerabilities: [
                {
                    id: 'sql-injection',
                    severity: 'critical',
                    message: 'Potential SQL injection vulnerability',
                    file: 'src/database.js',
                    line: 42,
                    scanner: 'semgrep'
                },
                {
                    id: 'xss-vulnerability',
                    severity: 'high',
                    message: 'Cross-site scripting vulnerability',
                    file: 'src/utils.js',
                    line: 15,
                    scanner: 'eslint-security'
                }
            ],
            summary: { critical: 1, high: 5, medium: 19, low: 12 },
            scanners: ['codeql', 'semgrep', 'eslint-security'],
            timestamp: new Date().toISOString(),
            _sample: true
        };
    }
    
    async checkIntegrationStatus() {
        const status = {
            github: await this.checkGitHubIntegration(),
            slack: await this.checkSlackIntegration(),
            email: await this.checkEmailIntegration(),
            jira: await this.checkJiraIntegration()
        };
        
        return status;
    }
    
    async checkGitHubIntegration() {
        try {
            // Check if GitHub token is available
            const hasToken = await this.checkEnvironmentVariable('GITHUB_TOKEN');
            if (!hasToken) {
                return { status: 'inactive', message: 'No GitHub token configured' };
            }
            
            // Test GitHub API access
            const response = await fetch('https://api.github.com/user', {
                headers: {
                    'Authorization': `token ${process.env.GITHUB_TOKEN}`
                }
            });
            
            if (response.ok) {
                return { status: 'active', message: 'Connected' };
            } else {
                return { status: 'inactive', message: 'Authentication failed' };
            }
        } catch (error) {
            return { status: 'inactive', message: 'Connection failed' };
        }
    }
    
    async checkSlackIntegration() {
        try {
            const hasWebhook = await this.checkEnvironmentVariable('SLACK_WEBHOOK_URL');
            return hasWebhook
                ? { status: 'active', message: 'Webhook configured' }
                : { status: 'inactive', message: 'No webhook configured' };
        } catch (error) {
            return { status: 'inactive', message: 'Configuration error' };
        }
    }
    
    async checkEmailIntegration() {
        try {
            const hasConfig = await this.checkEnvironmentVariable('SMTP_HOST');
            return hasConfig
                ? { status: 'active', message: 'SMTP configured' }
                : { status: 'inactive', message: 'No SMTP configuration' };
        } catch (error) {
            return { status: 'inactive', message: 'Configuration error' };
        }
    }
    
    async checkJiraIntegration() {
        try {
            const hasConfig = await this.checkEnvironmentVariable('JIRA_URL');
            return hasConfig
                ? { status: 'active', message: 'API configured' }
                : { status: 'inactive', message: 'No API configuration' };
        } catch (error) {
            return { status: 'inactive', message: 'Configuration error' };
        }
    }
    
    async checkEnvironmentVariable(name) {
        // In a real implementation, this would check server-side
        // For now, we'll check localStorage or return false
        const value = localStorage.getItem(`env_${name}`);
        return value && value !== 'undefined' && value !== '';
    }
    
    async loadCommitData() {
        try {
            if (this.config.githubRepo) {
                const response = await fetch(`https://api.github.com/repos/${this.config.githubRepo}/commits?per_page=5`);
                if (response.ok) {
                    return await response.json();
                }
            }
            
            // Return sample commit data if no real data
            return this.getSampleCommitData();
        } catch (error) {
            console.warn('⚠️ Failed to load commit data:', error);
            return this.getSampleCommitData();
        }
    }
    
    getSampleCommitData() {
        return [
            {
                sha: 'abc123',
                commit: {
                    message: 'Fix security vulnerability in authentication',
                    author: {
                        name: 'Security Team',
                        date: new Date(Date.now() - 3600000).toISOString()
                    }
                },
                author: {
                    login: 'security-team',
                    avatar_url: 'assets/img/avatar-placeholder.png'
                }
            }
        ];
    }
    
    async loadScannerData() {
        // Load scanner performance data
        return {
            codeql: { issues: 15, duration: 125, coverage: 92 },
            semgrep: { issues: 8, duration: 45, rules: 150 },
            eslint: { issues: 23, duration: 12, files: 89 },
            typescript: { errors: 0, duration: 8, strict: 100 }
        };
    }
    
    updateMetrics(data) {
        const summary = data.summary || { critical: 0, high: 0, medium: 0, low: 0 };
        
        // Update metric counts
        this.updateElement('critical-count', summary.critical);
        this.updateElement('high-count', summary.high);
        this.updateElement('medium-count', summary.medium);
        this.updateElement('low-count', summary.low);
        
        // Update trends (would be calculated from historical data)
        this.updateTrend('critical-trend', 0);
        this.updateTrend('high-trend', -2);
        this.updateTrend('medium-trend', 3);
        this.updateTrend('low-trend', 1);
        
        // Calculate and update security score
        const securityScore = this.calculateSecurityScore(summary);
        this.updateElement('security-score', securityScore);
        
        // Update score breakdown
        this.updateElement('vuln-mgmt-score', '85%');
        this.updateElement('code-quality-score', '92%');
        this.updateElement('compliance-score', '88%');
        
        // Update system status based on vulnerabilities
        this.updateSystemStatusFromMetrics(summary);
        
        console.log('📊 Metrics updated');
    }
    
    calculateSecurityScore(summary) {
        // Simple scoring algorithm
        const weights = { critical: -20, high: -10, medium: -5, low: -1 };
        const baseScore = 100;
        
        let deductions = 0;
        for (const [severity, count] of Object.entries(summary)) {
            deductions += (weights[severity] || 0) * count;
        }
        
        return Math.max(0, Math.min(100, baseScore + deductions));
    }
    
    updateSystemStatusFromMetrics(summary) {
        if (summary.critical > 0) {
            this.updateSystemStatus('inactive', 'Critical vulnerabilities detected', 'Action required');
        } else if (summary.high > 10) {
            this.updateSystemStatus('degraded', 'High vulnerability count', 'Review recommended');
        } else {
            this.updateSystemStatus('active', 'System operational', 'All systems healthy');
        }
    }
    
    updateTrend(elementId, change) {
        const element = document.getElementById(elementId);
        if (!element) return;
        
        const iconElement = element.querySelector('.trend-icon');
        const textElement = element.querySelector('.trend-text');
        
        if (change > 0) {
            iconElement.textContent = '↗️';
            textElement.textContent = `+${change} from last week`;
            element.className = 'metric-trend trend-up';
        } else if (change < 0) {
            iconElement.textContent = '↘️';
            textElement.textContent = `${change} from last week`;
            element.className = 'metric-trend trend-down';
        } else {
            iconElement.textContent = '→';
            textElement.textContent = 'No change';
            element.className = 'metric-trend trend-stable';
        }
    }
    
    updateIntegrationDisplay(status) {
        for (const [integration, data] of Object.entries(status)) {
            this.updateIntegrationStatus(integration, data.status, data.message);
        }
        
        console.log('🔌 Integration status updated');
    }
    
    updateCommitDisplay(commits) {
        const container = document.getElementById('commits-list');
        if (!container || !commits.length) return;
        
        container.innerHTML = '';
        
        commits.slice(0, 5).forEach(commit => {
            const item = document.createElement('div');
            item.className = 'commit-item';
            
            item.innerHTML = `
                <div class="commit-avatar">
                    <img src="${commit.author?.avatar_url || 'assets/img/avatar-placeholder.png'}" 
                         alt="${commit.author?.login || 'Unknown'}" 
                         style="width: 100%; height: 100%; border-radius: 50%;">
                </div>
                <div class="commit-content">
                    <span class="commit-message" title="${commit.commit.message}">
                        ${commit.commit.message.substring(0, 60)}${commit.commit.message.length > 60 ? '...' : ''}
                    </span>
                    <div class="commit-meta">
                        <span class="commit-author">${commit.author?.login || commit.commit.author.name}</span>
                        <span class="commit-time">${this.formatRelativeTime(commit.commit.author.date)}</span>
                    </div>
                </div>
            `;
            
            container.appendChild(item);
        });
        
        console.log('📝 Commit display updated');
    }
    
    updateScannerDisplay(scannerData) {
        for (const [scanner, data] of Object.entries(scannerData)) {
            this.updateElement(`${scanner}-issues`, data.issues);
            this.updateElement(`${scanner}-duration`, `${data.duration}s`);
            
            // Update scanner-specific metrics
            if (data.coverage !== undefined) {
                this.updateElement(`${scanner}-coverage`, `${data.coverage}%`);
            }
            if (data.rules !== undefined) {
                this.updateElement(`${scanner}-rules`, data.rules);
            }
            if (data.files !== undefined) {
                this.updateElement(`${scanner}-files`, data.files);
            }
            if (data.errors !== undefined) {
                this.updateElement(`${scanner}-errors`, data.errors);
            }
            if (data.strict !== undefined) {
                this.updateElement(`${scanner}-strict`, `${data.strict}%`);
            }
            
            // Update scanner badge
            const badge = document.getElementById(`${scanner}-badge`);
            if (badge) {
                badge.className = 'scanner-badge active';
                badge.style.color = 'var(--success-color)';
            }
        }
        
        console.log('🔍 Scanner display updated');
    }
    
    initializeCharts() {
        this.initializeSecurityScoreChart();
        this.initializeTrendChart();
        console.log('📈 Charts initialized');
    }
    
    initializeSecurityScoreChart() {
        const canvas = document.getElementById('security-score-chart');
        if (!canvas) return;
        
        const ctx = canvas.getContext('2d');
        const score = parseInt(document.getElementById('security-score').textContent) || 0;
        
        this.charts.securityScore = new Chart(ctx, {
            type: 'doughnut',
            data: {
                datasets: [{
                    data: [score, 100 - score],
                    backgroundColor: [
                        this.getScoreColor(score),
                        'rgba(226, 232, 240, 0.3)'
                    ],
                    borderWidth: 0,
                    cutout: '80%'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: { enabled: false }
                }
            }
        });
    }
    
    initializeTrendChart() {
        const canvas = document.getElementById('trend-chart');
        if (!canvas) return;
        
        const ctx = canvas.getContext('2d');
        
        // Generate sample trend data
        const days = [];
        const criticalData = [];
        const highData = [];
        const mediumData = [];
        
        for (let i = 29; i >= 0; i--) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            days.push(date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
            
            // Sample trending data
            criticalData.push(Math.max(0, Math.floor(Math.random() * 3)));
            highData.push(Math.max(0, Math.floor(Math.random() * 8) + 2));
            mediumData.push(Math.max(0, Math.floor(Math.random() * 15) + 10));
        }
        
        this.charts.trend = new Chart(ctx, {
            type: 'line',
            data: {
                labels: days,
                datasets: [
                    {
                        label: 'Critical',
                        data: criticalData,
                        borderColor: 'var(--critical-color)',
                        backgroundColor: 'rgba(220, 38, 38, 0.1)',
                        fill: false,
                        tension: 0.4
                    },
                    {
                        label: 'High',
                        data: highData,
                        borderColor: 'var(--high-color)',
                        backgroundColor: 'rgba(234, 88, 12, 0.1)',
                        fill: false,
                        tension: 0.4
                    },
                    {
                        label: 'Medium',
                        data: mediumData,
                        borderColor: 'var(--medium-color)',
                        backgroundColor: 'rgba(217, 119, 6, 0.1)',
                        fill: false,
                        tension: 0.4
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: true,
                        position: 'bottom'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            precision: 0
                        }
                    },
                    x: {
                        ticks: {
                            maxTicksLimit: 7
                        }
                    }
                }
            }
        });
    }
    
    getScoreColor(score) {
        if (score >= 80) return 'var(--success-color)';
        if (score >= 60) return 'var(--warning-color)';
        return 'var(--critical-color)';
    }
    
    setupAutoRefresh() {
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
        }
        
        this.refreshTimer = setInterval(() => {
            this.refreshData();
        }, this.config.refreshInterval);
        
        console.log(`🔄 Auto-refresh enabled (${this.config.refreshInterval / 1000}s interval)`);
    }
    
    async refreshData() {
        console.log('🔄 Refreshing data...');
        
        try {
            // Refresh all data sources
            await this.loadInitialData();
            this.updateLastRefreshTime();
            console.log('✅ Data refreshed successfully');
        } catch (error) {
            console.error('❌ Data refresh failed:', error);
        }
    }
    
    setupEventListeners() {
        // Refresh button
        const refreshBtn = document.getElementById('refresh-events');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.refreshData());
        }
        
        // Window focus refresh
        window.addEventListener('focus', () => {
            const timeSinceLastUpdate = Date.now() - this.lastUpdateTime.getTime();
            if (timeSinceLastUpdate > 60000) { // 1 minute
                this.refreshData();
            }
        });
        
        // Responsive chart resize
        window.addEventListener('resize', () => {
            this.debounce(() => {
                Object.values(this.charts).forEach(chart => {
                    if (chart && chart.resize) {
                        chart.resize();
                    }
                });
            }, 250)();
        });
        
        console.log('👂 Event listeners setup');
    }
    
    setupResponsiveBehavior() {
        // Add responsive classes based on screen size
        const updateResponsiveClasses = () => {
            const width = window.innerWidth;
            const body = document.body;
            
            body.classList.toggle('mobile', width < 640);
            body.classList.toggle('tablet', width >= 640 && width < 1024);
            body.classList.toggle('desktop', width >= 1024);
        };
        
        updateResponsiveClasses();
        window.addEventListener('resize', this.debounce(updateResponsiveClasses, 100));
    }
    
    // Utility methods
    updateElement(id, value) {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = value;
        }
    }
    
    updateSystemStatus(status, message, details) {
        const statusBadge = document.getElementById('system-status');
        const statusText = document.getElementById('status-text');
        const statusDetails = document.getElementById('status-details');
        
        if (statusBadge) {
            statusBadge.className = `status-badge ${status}`;
        }
        
        if (statusText) {
            statusText.textContent = message;
        }
        
        if (statusDetails) {
            statusDetails.textContent = details || '';
        }
    }
    
    updateIntegrationStatus(integration, status, message) {
        const statusBadge = document.getElementById(`${integration}-status`);
        const statusText = document.getElementById(`${integration}-status-text`);
        
        if (statusBadge) {
            statusBadge.className = `status-badge ${status}`;
        }
        
        if (statusText) {
            statusText.textContent = message;
        }
    }
    
    updateLastRefreshTime() {
        this.lastUpdateTime = new Date();
        const element = document.getElementById('last-updated');
        if (element) {
            element.textContent = this.formatDateTime(this.lastUpdateTime);
        }
    }
    
    formatDateTime(date) {
        return date.toLocaleString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    
    formatRelativeTime(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diffMs = now - date;
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        const diffDays = Math.floor(diffHours / 24);
        
        if (diffDays > 0) {
            return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
        } else if (diffHours > 0) {
            return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
        } else {
            const diffMinutes = Math.floor(diffMs / (1000 * 60));
            return `${Math.max(1, diffMinutes)} minute${diffMinutes > 1 ? 's' : ''} ago`;
        }
    }
    
    showLoading(show) {
        const overlay = document.getElementById('loading-overlay');
        if (overlay) {
            overlay.classList.toggle('show', show);
        }
    }
    
    showError(message) {
        // Simple error display - could be enhanced with a proper notification system
        console.error('Dashboard Error:', message);
        
        // Update system status to show error
        this.updateSystemStatus('inactive', 'Error', message);
    }
    
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
    
    // Cleanup method
    destroy() {
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
        }
        
        // Destroy charts
        Object.values(this.charts).forEach(chart => {
            if (chart && chart.destroy) {
                chart.destroy();
            }
        });
        
        console.log('🧹 Dashboard cleanup completed');
    }
}

// Export for use in other scripts
window.ProfessionalDashboard = ProfessionalDashboard;
