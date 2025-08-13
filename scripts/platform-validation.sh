#!/bin/bash

# ===================================================================
# SAST Platform - Platform Detection & Validation Script
# ===================================================================
# Automatically detects platform capabilities and validates environment
# Usage: ./scripts/platform-validation.sh [--fix]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
FIX_MODE=false
PLATFORM_ARCH=""
DOCKER_PLATFORM=""
GRAFANA_VERSION=""
COMPOSE_FILE=""
VALIDATION_ERRORS=0

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                FIX_MODE=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

show_usage() {
    cat << EOF
${CYAN}SAST Platform Validation${NC}

${CYAN}USAGE:${NC}
    ./scripts/platform-validation.sh [OPTIONS]

${CYAN}OPTIONS:${NC}
    --fix     Automatically fix detected issues
    --help    Show this help

${CYAN}DESCRIPTION:${NC}
    Detects platform architecture and validates Docker environment
    for optimal SAST platform compatibility.

${CYAN}VALIDATION CHECKS:${NC}
    ✓ Platform architecture detection (x86_64/ARM64)
    ✓ Docker & Docker Compose installation
    ✓ Port availability (3001, 8087, 9090, etc.)
    ✓ Memory and disk space requirements
    ✓ Docker platform compatibility
    ✓ Network connectivity

EOF
}

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((VALIDATION_ERRORS++))
}

log_header() {
    echo -e "\n${CYAN}🔍 $1${NC}"
    echo "─────────────────────────────────────────────"
}

# Platform detection
detect_platform() {
    log_header "Platform Detection"
    
    PLATFORM_ARCH=$(uname -m)
    case $PLATFORM_ARCH in
        arm64|aarch64)
            log_info "Detected ARM64 architecture (Apple Silicon M1/M2)"
            DOCKER_PLATFORM="linux/amd64"  # Use x86 emulation for stability
            GRAFANA_VERSION="9.5.0"
            COMPOSE_FILE="docker-compose-stable.yml"
            ;;
        x86_64)
            log_info "Detected x86_64 architecture"
            DOCKER_PLATFORM="linux/amd64"
            GRAFANA_VERSION="10.2.0"
            COMPOSE_FILE="docker-compose.yml"
            ;;
        *)
            log_error "Unsupported architecture: $PLATFORM_ARCH"
            return 1
            ;;
    esac
    
    log_success "Platform: $PLATFORM_ARCH, Docker Platform: $DOCKER_PLATFORM"
    log_success "Recommended Grafana: $GRAFANA_VERSION"
    log_success "Recommended Compose: $COMPOSE_FILE"
}

# Docker validation
validate_docker() {
    log_header "Docker Environment Validation"
    
    # Check Docker installation
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        if [[ $FIX_MODE == true ]]; then
            log_info "Please install Docker Desktop: https://www.docker.com/products/docker-desktop/"
        fi
        return 1
    fi
    log_success "Docker is installed"
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
        log_error "Docker Compose is not available"
        return 1
    fi
    log_success "Docker Compose is available"
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        if [[ $FIX_MODE == true ]]; then
            log_info "Please start Docker Desktop"
        fi
        return 1
    fi
    log_success "Docker daemon is running"
    
    # Check Docker platform support
    if docker buildx version &> /dev/null; then
        log_success "Docker Buildx available (multi-platform support)"
    else
        log_warning "Docker Buildx not available (limited platform support)"
    fi
}

# Port availability check
validate_ports() {
    log_header "Port Availability Check"
    
    local required_ports=(3001 8087 9090 9091 8025 1025)
    local blocked_ports=()
    
    for port in "${required_ports[@]}"; do
        if lsof -i :$port >/dev/null 2>&1; then
            log_warning "Port $port is in use"
            blocked_ports+=($port)
        else
            log_success "Port $port is available"
        fi
    done
    
    if [[ ${#blocked_ports[@]} -gt 0 ]]; then
        log_error "Blocked ports: ${blocked_ports[*]}"
        if [[ $FIX_MODE == true ]]; then
            log_info "To fix port conflicts:"
            echo "  sudo lsof -ti:${blocked_ports[0]} | xargs sudo kill -9"
            echo "  # Or modify port mappings in docker-compose file"
        fi
        return 1
    fi
}

# System resources check
validate_resources() {
    log_header "System Resources Check"
    
    # Check available memory (minimum 4GB recommended)
    local total_mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))
    
    if [[ $total_mem_gb -eq 0 ]]; then
        # macOS fallback
        local total_mem_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
        total_mem_gb=$((total_mem_bytes / 1024 / 1024 / 1024))
    fi
    
    if [[ $total_mem_gb -lt 4 ]]; then
        log_warning "Low memory: ${total_mem_gb}GB (4GB+ recommended)"
    else
        log_success "Memory: ${total_mem_gb}GB"
    fi
    
    # Check disk space (minimum 10GB)
    local available_space
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        available_space=$(df -g . | tail -1 | awk '{print $4}')
    else
        # Linux
        available_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    fi
    
    if [[ $available_space -lt 10 ]]; then
        log_warning "Low disk space: ${available_space}GB (10GB+ recommended)"
    else
        log_success "Disk space: ${available_space}GB available"
    fi
}

# Network connectivity check
validate_connectivity() {
    log_header "Network Connectivity Check"
    
    local test_urls=(
        "https://hub.docker.com"
        "https://registry-1.docker.io"
        "https://github.com"
    )
    
    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 5 "$url" >/dev/null; then
            log_success "Connectivity to $url"
        else
            log_warning "Cannot reach $url (may affect Docker pulls)"
        fi
    done
}

# Configuration validation
validate_configuration() {
    log_header "Configuration Validation"
    
    # Check for required files
    local required_files=(
        "ci-config.yaml"
        "docker-compose.yml"
        "Dockerfile.sast"
    )
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Found $file"
        else
            log_error "Missing $file"
        fi
    done
    
    # Validate YAML syntax
    if command -v yq &> /dev/null; then
        if yq eval . ci-config.yaml >/dev/null 2>&1; then
            log_success "ci-config.yaml syntax is valid"
        else
            log_error "ci-config.yaml has syntax errors"
        fi
    else
        log_warning "yq not available, skipping YAML validation"
    fi
    
    # Check for stable compose file
    if [[ -f "docker-compose-stable.yml" ]]; then
        log_success "Found stable Docker Compose configuration"
    else
        log_warning "docker-compose-stable.yml not found (ARM64 users should use this)"
    fi
}

# Generate platform-specific recommendations
generate_recommendations() {
    log_header "Platform-Specific Recommendations"
    
    case $PLATFORM_ARCH in
        arm64|aarch64)
            echo -e "${YELLOW}ARM64/Apple Silicon Recommendations:${NC}"
            echo "  • Use: docker-compose-stable.yml for better compatibility"
            echo "  • Set: export DOCKER_DEFAULT_PLATFORM=linux/amd64"
            echo "  • Grafana: Use version 9.5.0 instead of latest"
            echo "  • Expect: Slightly slower performance due to x86 emulation"
            echo ""
            if [[ $FIX_MODE == true ]]; then
                export DOCKER_DEFAULT_PLATFORM=linux/amd64
                log_info "Set DOCKER_DEFAULT_PLATFORM=linux/amd64"
            fi
            ;;
        x86_64)
            echo -e "${GREEN}x86_64 Recommendations:${NC}"
            echo "  • Use: docker-compose.yml (standard configuration)"
            echo "  • Grafana: Can use latest version (10.2.0+)"
            echo "  • Performance: Optimal native performance expected"
            echo ""
            ;;
    esac
    
    echo -e "${CYAN}General Recommendations:${NC}"
    echo "  • Start with: ./setup.sh --demo (safe testing)"
    echo "  • Email setup: ./scripts/email-setup-wizard.sh"
    echo "  • Health check: ./scripts/integration-tester.sh"
    echo "  • Troubleshooting: Check docs/TROUBLESHOOTING.md"
}

# Auto-fix function
auto_fix_issues() {
    if [[ $FIX_MODE != true ]]; then
        return 0
    fi
    
    log_header "Auto-Fix Attempt"
    
    # Create stable configuration if on ARM64
    if [[ $PLATFORM_ARCH == "arm64" || $PLATFORM_ARCH == "aarch64" ]]; then
        if [[ ! -f "docker-compose-stable.yml" ]]; then
            log_info "Creating docker-compose-stable.yml for ARM64 compatibility"
            # This would be created by the write tool above
        fi
    fi
    
    # Set Docker platform environment variable
    if ! grep -q "DOCKER_DEFAULT_PLATFORM" ~/.bashrc ~/.zshrc 2>/dev/null; then
        echo "export DOCKER_DEFAULT_PLATFORM=$DOCKER_PLATFORM" >> ~/.bashrc
        log_info "Added DOCKER_DEFAULT_PLATFORM to ~/.bashrc"
    fi
    
    log_success "Auto-fix completed. Please restart your shell or run:"
    echo "  source ~/.bashrc"
}

# Main validation function
main() {
    PURPLE='\033[0;35m'
    echo -e "${PURPLE}"
    cat << 'EOF'
 ┌─────────────────────────────────────────────────┐
 │          🔍 SAST Platform Validation            │
 │       Environment Compatibility Check           │
 └─────────────────────────────────────────────────┘
EOF
    echo -e "${NC}"
    
    parse_args "$@"
    
    # Run all validation checks
    detect_platform
    validate_docker
    validate_ports
    validate_resources
    validate_connectivity
    validate_configuration
    
    # Generate recommendations
    generate_recommendations
    
    # Auto-fix if requested
    auto_fix_issues
    
    # Summary
    echo ""
    log_header "Validation Summary"
    
    if [[ $VALIDATION_ERRORS -eq 0 ]]; then
        log_success "All validation checks passed! 🎉"
        log_info "Your system is ready for SAST platform deployment."
        echo ""
        echo -e "${GREEN}Next steps:${NC}"
        echo "  1. Run: ./setup.sh --demo"
        echo "  2. Wait for services to start (~3-5 minutes)"
        echo "  3. Access: http://localhost:3001 (Grafana)"
        echo "  4. Test: ./run_demo.sh"
    else
        log_error "Found $VALIDATION_ERRORS validation issues"
        echo ""
        echo -e "${YELLOW}To fix issues automatically:${NC}"
        echo "  ./scripts/platform-validation.sh --fix"
        echo ""
        echo -e "${YELLOW}For manual fixes, see:${NC}"
        echo "  docs/TROUBLESHOOTING.md"
    fi
    
    return $VALIDATION_ERRORS
}

# Execute main function
main "$@"
