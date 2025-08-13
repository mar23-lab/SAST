#!/bin/bash

# ===================================================================
# SAST Platform - Manual Validation Script
# ===================================================================
# Simple step-by-step validation for debugging and verification
# Usage: ./scripts/manual-validation.sh

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 SAST Platform Manual Validation${NC}"
echo "====================================="

# Test 1: Basic file structure
echo -e "\n${BLUE}1. Checking basic file structure...${NC}"
echo "✓ Current directory: $(pwd)"

required_files=(
    "setup.sh"
    "docker-compose.yml" 
    "docker-compose-stable.yml"
    "Dockerfile.sast"
    "ci-config.yaml"
    "scripts/platform-validation.sh"
    "scripts/grafana-auto-setup.sh"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "✅ Found: $file"
    else
        echo -e "❌ Missing: $file"
    fi
done

# Test 2: Script permissions
echo -e "\n${BLUE}2. Checking script permissions...${NC}"
scripts=("setup.sh" "scripts/platform-validation.sh" "scripts/grafana-auto-setup.sh")

for script in "${scripts[@]}"; do
    if [[ -x "$script" ]]; then
        echo -e "✅ Executable: $script"
    else
        echo -e "❌ Not executable: $script"
    fi
done

# Test 3: Docker environment
echo -e "\n${BLUE}3. Checking Docker environment...${NC}"
if command -v docker >/dev/null 2>&1; then
    echo -e "✅ Docker installed: $(docker --version)"
else
    echo -e "❌ Docker not installed"
fi

if docker info >/dev/null 2>&1; then
    echo -e "✅ Docker daemon running"
else
    echo -e "❌ Docker daemon not running"
fi

# Test 4: Platform detection
echo -e "\n${BLUE}4. Testing platform detection...${NC}"
arch=$(uname -m)
echo -e "✅ Architecture: $arch"

case $arch in
    arm64|aarch64)
        echo -e "✅ ARM64 detected - will use docker-compose-stable.yml"
        ;;
    x86_64)
        echo -e "✅ x86_64 detected - will use docker-compose.yml"
        ;;
    *)
        echo -e "⚠️  Unknown architecture: $arch"
        ;;
esac

# Test 5: Docker Compose validation
echo -e "\n${BLUE}5. Validating Docker Compose files...${NC}"
compose_files=("docker-compose.yml" "docker-compose-stable.yml" "docker-compose-minimal.yml")

for compose_file in "${compose_files[@]}"; do
    if [[ -f "$compose_file" ]]; then
        if docker-compose -f "$compose_file" config >/dev/null 2>&1; then
            echo -e "✅ Valid: $compose_file"
        else
            echo -e "❌ Invalid: $compose_file"
        fi
    else
        echo -e "⚠️  Missing: $compose_file"
    fi
done

# Test 6: Configuration validation
echo -e "\n${BLUE}6. Validating configuration files...${NC}"
if command -v yq >/dev/null 2>&1; then
    if yq eval . ci-config.yaml >/dev/null 2>&1; then
        echo -e "✅ Valid: ci-config.yaml"
    else
        echo -e "❌ Invalid: ci-config.yaml"
    fi
else
    echo -e "⚠️  yq not available - skipping YAML validation"
fi

# Test 7: Port availability
echo -e "\n${BLUE}7. Checking port availability...${NC}"
required_ports=(3001 8087 9090 9091 8025 1025)
busy_ports=()

for port in "${required_ports[@]}"; do
    if lsof -i ":$port" >/dev/null 2>&1; then
        busy_ports+=($port)
        echo -e "⚠️  Port $port is in use"
    else
        echo -e "✅ Port $port available"
    fi
done

# Test 8: Grafana auto-setup validation
echo -e "\n${BLUE}8. Testing Grafana auto-setup script...${NC}"
if [[ -f "scripts/grafana-auto-setup.sh" ]]; then
    if bash -n scripts/grafana-auto-setup.sh; then
        echo -e "✅ Grafana auto-setup script syntax is valid"
    else
        echo -e "❌ Grafana auto-setup script has syntax errors"
    fi
else
    echo -e "❌ Grafana auto-setup script missing"
fi

# Summary
echo -e "\n${CYAN}📋 Validation Summary${NC}"
echo "====================="

if [[ ${#busy_ports[@]} -gt 0 ]]; then
    echo -e "⚠️  Some ports are in use: ${busy_ports[*]}"
    echo -e "   You may need to stop services or modify port mappings"
fi

echo -e "✅ Basic validation completed"
echo -e "📊 Platform: $(uname -s) $(uname -m)"
echo -e "🐳 Docker: $(docker --version 2>/dev/null || echo 'Not available')"

echo -e "\n${GREEN}🚀 Next steps:${NC}"
echo "1. Run: ./setup.sh --demo"
echo "2. Or: ./scripts/platform-validation.sh for detailed checks"
echo "3. Or: ./scripts/grafana-auto-setup.sh for Grafana setup only"

echo -e "\n${BLUE}Manual validation complete!${NC}"
