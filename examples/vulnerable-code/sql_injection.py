#!/usr/bin/env python3
"""
Sample vulnerable Python code for SAST testing
WARNING: This code contains intentional security vulnerabilities for testing purposes
DO NOT use in production environments
"""

import sqlite3
import os
import subprocess
import pickle
import hashlib

# SQL Injection Vulnerabilities
def vulnerable_user_lookup(user_id):
    """Example of SQL injection vulnerability"""
    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()
    
    # VULNERABLE: Direct string concatenation
    query = "SELECT * FROM users WHERE id = '" + user_id + "'"
    cursor.execute(query)
    
    result = cursor.fetchone()
    conn.close()
    return result

def vulnerable_search(search_term):
    """Another SQL injection example"""
    conn = sqlite3.connect('products.db')
    cursor = conn.cursor()
    
    # VULNERABLE: String formatting
    query = f"SELECT * FROM products WHERE name LIKE '%{search_term}%'"
    cursor.execute(query)
    
    results = cursor.fetchall()
    conn.close()
    return results

# Command Injection Vulnerabilities
def vulnerable_ping(hostname):
    """Example of command injection vulnerability"""
    # VULNERABLE: User input directly in system command
    command = f"ping -c 4 {hostname}"
    result = os.system(command)
    return result

def vulnerable_file_listing(directory):
    """Another command injection example"""
    # VULNERABLE: subprocess with shell=True and user input
    command = f"ls -la {directory}"
    result = subprocess.call(command, shell=True)
    return result

# Path Traversal Vulnerabilities
def vulnerable_file_read(filename):
    """Example of path traversal vulnerability"""
    # VULNERABLE: Direct file access without validation
    file_path = f"/var/www/uploads/{filename}"
    try:
        with open(file_path, 'r') as file:
            content = file.read()
        return content
    except FileNotFoundError:
        return None

# Hardcoded Credentials
class DatabaseConfig:
    """Example of hardcoded credentials"""
    # VULNERABLE: Hardcoded credentials
    DB_PASSWORD = "super_secret_password_123"
    API_KEY = "sk_live_abcdef123456789"
    SECRET_TOKEN = "jwt_secret_key_dont_share"

# Weak Cryptography
def vulnerable_password_hash(password):
    """Example of weak cryptographic hash"""
    # VULNERABLE: Using MD5 for password hashing
    return hashlib.md5(password.encode()).hexdigest()

def vulnerable_session_token():
    """Example of weak random generation"""
    import random
    # VULNERABLE: Using weak random for security purposes
    return str(random.randint(1000000, 9999999))

# Insecure Deserialization
def vulnerable_deserialize(data):
    """Example of insecure deserialization"""
    # VULNERABLE: Unpickling untrusted data
    return pickle.loads(data)

# Information Disclosure
def vulnerable_error_handling(user_id):
    """Example of information disclosure through error messages"""
    try:
        user = vulnerable_user_lookup(user_id)
        return user
    except Exception as e:
        # VULNERABLE: Exposing internal errors
        print(f"Database error: {e}")
        print(f"Failed query for user: {user_id}")
        return None

# Debug Code Left in Production
DEBUG = True  # VULNERABLE: Debug flag in production

def vulnerable_logging(username, password):
    """Example of sensitive data in logs"""
    if DEBUG:
        # VULNERABLE: Logging sensitive information
        print(f"Login attempt: username={username}, password={password}")
    
    # Authentication logic would go here
    return True

# XML External Entity (XXE) Vulnerability
def vulnerable_xml_parsing(xml_content):
    """Example of XXE vulnerability"""
    import xml.etree.ElementTree as ET
    
    # VULNERABLE: Parsing XML without disabling external entities
    try:
        root = ET.fromstring(xml_content)
        return root
    except ET.ParseError:
        return None

# Weak SSL/TLS Configuration
def vulnerable_https_request(url):
    """Example of weak SSL configuration"""
    import requests
    import urllib3
    
    # VULNERABLE: Disabling SSL verification
    urllib3.disable_warnings()
    response = requests.get(url, verify=False)
    return response.text

# Additional Security Issues
class VulnerableClass:
    """Class with multiple security issues"""
    
    def __init__(self):
        # VULNERABLE: Hardcoded secret
        self.api_secret = "hardcoded_api_secret_123"
    
    def process_user_input(self, user_data):
        """Multiple vulnerabilities in one method"""
        # VULNERABLE: eval() with user input
        result = eval(user_data)
        
        # VULNERABLE: exec() with user input
        exec(f"value = {user_data}")
        
        return result
    
    def unsafe_file_operation(self, filename, content):
        """Unsafe file operations"""
        # VULNERABLE: Path traversal
        full_path = f"./uploads/{filename}"
        
        with open(full_path, 'w') as f:
            f.write(content)
    
    def weak_random_token(self):
        """Weak random token generation"""
        import random
        import string
        
        # VULNERABLE: Weak random for security token
        return ''.join(random.choices(string.ascii_letters, k=32))

# YAML Loading Vulnerability
def vulnerable_yaml_load(yaml_content):
    """Example of unsafe YAML loading"""
    import yaml
    
    # VULNERABLE: yaml.load without safe loader
    return yaml.load(yaml_content)

if __name__ == "__main__":
    # Example usage (for testing scanners)
    print("This is vulnerable code for security testing purposes")
    
    # These would trigger various security scanners
    user = vulnerable_user_lookup("1' OR '1'='1")
    result = vulnerable_ping("localhost; rm -rf /")
    content = vulnerable_file_read("../../../etc/passwd")
    
    print("Vulnerable operations completed")
