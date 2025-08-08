// Vulnerable JavaScript code for SAST testing
// WARNING: This code contains intentional security vulnerabilities for testing purposes
// DO NOT use in production environments

// XSS Vulnerabilities
function vulnerableInnerHTML(userInput) {
    // VULNERABLE: Direct assignment to innerHTML
    document.getElementById('content').innerHTML = userInput;
}

function vulnerableDocumentWrite(userContent) {
    // VULNERABLE: document.write with user input
    document.write(userContent);
}

function vulnerableEval(userCode) {
    // VULNERABLE: eval() with user input
    eval(userCode);
}

function vulnerableSetAttribute(userUrl) {
    // VULNERABLE: Setting href attribute without validation
    const link = document.createElement('a');
    link.setAttribute('href', userUrl);
    document.body.appendChild(link);
}

// DOM-based XSS
function vulnerableDOMXSS() {
    // VULNERABLE: Using location.hash without sanitization
    const userInput = location.hash.substring(1);
    document.getElementById('welcome').innerHTML = `Hello ${userInput}!`;
}

// Reflected XSS simulation
function vulnerableReflectedXSS(searchTerm) {
    // VULNERABLE: Reflecting user input without escaping
    return `<div>Search results for: ${searchTerm}</div>`;
}

// jQuery XSS vulnerabilities
function vulnerablejQueryHTML(userInput) {
    // VULNERABLE: jQuery html() with user input
    $('#content').html(userInput);
}

function vulnerablejQueryAppend(userContent) {
    // VULNERABLE: jQuery append with unsanitized content
    $('body').append(userContent);
}

// Hardcoded API Keys and Secrets
const HARDCODED_API_KEY = "sk_live_abcdef123456789"; // VULNERABLE
const SECRET_TOKEN = "jwt_secret_key_production"; // VULNERABLE
const DATABASE_PASSWORD = "super_secret_db_pass"; // VULNERABLE

// Weak Cryptography
function weakHash(password) {
    // VULNERABLE: Using MD5 for password hashing
    return CryptoJS.MD5(password).toString();
}

function weakRandomToken() {
    // VULNERABLE: Math.random() for security purposes
    return Math.random().toString(36).substring(2);
}

// Command Injection (Node.js)
function vulnerableCommand(userInput) {
    const { exec } = require('child_process');
    
    // VULNERABLE: Command injection
    exec(`ls -la ${userInput}`, (error, stdout, stderr) => {
        console.log(stdout);
    });
}

// Path Traversal
function vulnerableFileRead(filename) {
    const fs = require('fs');
    
    // VULNERABLE: Path traversal
    const filePath = `./uploads/${filename}`;
    return fs.readFileSync(filePath, 'utf8');
}

// Insecure JSON Parsing
function vulnerableJSONParse(userInput) {
    // VULNERABLE: Parsing untrusted JSON (can lead to prototype pollution)
    return JSON.parse(userInput);
}

// Prototype Pollution
function vulnerableAssign(userObject) {
    const target = {};
    
    // VULNERABLE: Object.assign with user-controlled object
    return Object.assign(target, userObject);
}

// Insecure Regular Expressions (ReDoS)
function vulnerableRegex(userInput) {
    // VULNERABLE: ReDoS pattern
    const regex = /^(a+)+$/;
    return regex.test(userInput);
}

// CORS Misconfiguration
function vulnerableCORS() {
    // VULNERABLE: Wildcard CORS origin
    const headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Credentials': 'true'
    };
    return headers;
}

// Insecure HTTP Usage
function vulnerableHTTPRequest() {
    // VULNERABLE: HTTP instead of HTTPS
    fetch('http://api.example.com/sensitive-data')
        .then(response => response.json())
        .then(data => console.log(data));
}

// JWT Security Issues
function vulnerableJWTVerification(token) {
    const jwt = require('jsonwebtoken');
    
    // VULNERABLE: JWT verification disabled
    return jwt.verify(token, null, { verify: false });
}

// Debug Code in Production
const DEBUG_MODE = true; // VULNERABLE

function vulnerableLogging(username, password) {
    if (DEBUG_MODE) {
        // VULNERABLE: Logging sensitive information
        console.log(`Login attempt: ${username}:${password}`);
    }
}

// Information Disclosure
function vulnerableErrorHandling(userInput) {
    try {
        // Some operation that might fail
        return processUserData(userInput);
    } catch (error) {
        // VULNERABLE: Exposing internal error details
        console.error(`Internal error: ${error.stack}`);
        return { error: error.message, stack: error.stack };
    }
}

// Insecure Randomness
function vulnerableSessionId() {
    // VULNERABLE: Weak random for session IDs
    return Math.random().toString(16).substring(2);
}

// Client-side SQL Injection (for client-side databases)
function vulnerableClientSQL(userInput) {
    // VULNERABLE: SQL injection in client-side database
    const query = `SELECT * FROM users WHERE name = '${userInput}'`;
    return database.exec(query);
}

// PostMessage Security Issues
function vulnerablePostMessage() {
    // VULNERABLE: No origin validation
    window.addEventListener('message', function(event) {
        document.getElementById('content').innerHTML = event.data;
    });
}

// Clickjacking Vulnerability
function vulnerableFrameOptions() {
    // VULNERABLE: Missing X-Frame-Options
    const headers = {
        'Content-Type': 'text/html'
        // Missing: 'X-Frame-Options': 'DENY'
    };
    return headers;
}

// CSP Bypass
function vulnerableCSP() {
    // VULNERABLE: Weak Content Security Policy
    const csp = "default-src *; script-src 'unsafe-inline' 'unsafe-eval' *";
    return csp;
}

// Local Storage Security Issues
function vulnerableLocalStorage(sensitiveData) {
    // VULNERABLE: Storing sensitive data in localStorage
    localStorage.setItem('userToken', sensitiveData);
    localStorage.setItem('apiKey', HARDCODED_API_KEY);
}

// WebSocket Security Issues
function vulnerableWebSocket() {
    // VULNERABLE: No origin validation for WebSocket
    const ws = new WebSocket('ws://insecure-websocket.example.com');
    ws.onmessage = function(event) {
        document.body.innerHTML = event.data; // Also XSS vulnerable
    };
}

// Template Injection
function vulnerableTemplate(userInput) {
    // VULNERABLE: Server-side template injection
    const template = `Hello ${userInput}!`;
    return eval('`' + template + '`');
}

// LDAP Injection
function vulnerableLDAP(username) {
    // VULNERABLE: LDAP injection
    const filter = `(&(objectClass=person)(uid=${username}))`;
    return ldapClient.search(filter);
}

// XXE in JavaScript (rare but possible)
function vulnerableXMLParsing(xmlString) {
    const parser = new DOMParser();
    
    // VULNERABLE: Parsing XML without proper configuration
    return parser.parseFromString(xmlString, 'text/xml');
}

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        vulnerableInnerHTML,
        vulnerableDocumentWrite,
        vulnerableEval,
        vulnerableCommand,
        vulnerableFileRead,
        // ... other functions for testing
    };
}

// Example usage for scanner testing
if (typeof window !== 'undefined') {
    // Browser environment
    window.vulnerableFunctions = {
        runXSSTest: () => vulnerableInnerHTML('<script>alert("XSS")</script>'),
        runDOMXSS: vulnerableDOMXSS,
        logCredentials: () => vulnerableLogging('admin', 'password123')
    };
}
