#!/bin/bash

# 🏗️ Platform Detection Script for SAST Setup
# Automatically detects system architecture and chooses optimal Docker images

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Platform detection functions
detect_architecture() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "amd64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "arm"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_os() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$os" in
        linux)
            echo "linux"
            ;;
        darwin)
            echo "darwin"
            ;;
        mingw*|cygwin*|msys*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_docker_platform() {
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        # Get Docker's default platform
        local docker_arch=$(docker version --format '{{.Server.Arch}}' 2>/dev/null || echo "unknown")
        local docker_os=$(docker version --format '{{.Server.Os}}' 2>/dev/null || echo "unknown")
        echo "${docker_os}/${docker_arch}"
    else
        echo "docker-not-available"
    fi
}

get_email_service_image() {
    local arch="$1"
    local fallback_to_mailhog="${2:-false}"
    
    case "$arch" in
        arm64)
            if [[ "$fallback_to_mailhog" == "true" ]]; then
                echo "teawithfruit/mailhog:latest"
            else
                echo "axllent/mailpit:v1.19.0"
            fi
            ;;
        amd64)
            if [[ "$fallback_to_mailhog" == "true" ]]; then
                echo "mailhog/mailhog:v1.0.1"
            else
                echo "axllent/mailpit:v1.19.0"
            fi
            ;;
        *)
            echo "axllent/mailpit:v1.19.0"  # Default to modern solution
            ;;
    esac
}

get_docker_compose_file() {
    local arch="$1"
    case "$arch" in
        arm64)
            echo "docker-compose-universal.yml"
            ;;
        amd64)
            echo "docker-compose.yml"
            ;;
        *)
            echo "docker-compose-universal.yml"
            ;;
    esac
}

create_platform_env_file() {
    local arch="$1"
    local docker_platform="$2"
    
    cat > .env.platform << EOF
# Platform Detection Results - Generated $(date)
DETECTED_ARCH=$arch
DETECTED_OS=$(detect_os)
DOCKER_PLATFORM=$docker_platform
DOCKER_DEFAULT_PLATFORM=$docker_platform

# Email service selection based on platform
EMAIL_SERVICE_IMAGE=$(get_email_service_image "$arch")
EMAIL_SERVICE_NAME=$(if [[ "$(get_email_service_image "$arch")" == *"mailpit"* ]]; then echo "mailpit"; else echo "mailhog"; fi)

# Docker Compose file selection
DOCKER_COMPOSE_FILE=$(get_docker_compose_file "$arch")

# Platform-specific optimizations
EOF

    # Add platform-specific environment variables
    case "$arch" in
        arm64)
            cat >> .env.platform << EOF

# ARM64 specific settings
GRAFANA_IMAGE=grafana/grafana:11.1.0
PROMETHEUS_IMAGE=prom/prometheus:v2.53.0
INFLUXDB_IMAGE=influxdb:2.7
PUSHGATEWAY_IMAGE=prom/pushgateway:v1.9.0

# ARM64 optimized Grafana plugins (avoid problematic ones)
GRAFANA_PLUGINS=grafana-influxdb-datasource
EOF
            ;;
        amd64)
            cat >> .env.platform << EOF

# AMD64 specific settings (can use older stable versions)
GRAFANA_IMAGE=grafana/grafana:10.2.0
PROMETHEUS_IMAGE=prom/prometheus:v2.47.0
INFLUXDB_IMAGE=influxdb:2.7
PUSHGATEWAY_IMAGE=prom/pushgateway:v1.6.2

# AMD64 can use more plugins
GRAFANA_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource,grafana-influxdb-datasource
EOF
            ;;
    esac
    
    echo ".env.platform"
}

validate_docker_compatibility() {
    local arch="$1"
    
    echo -e "${BLUE}🔍 Validating Docker image compatibility...${NC}"
    
    local images_to_check=(
        "influxdb:2.7"
        "grafana/grafana:11.1.0"
        "prom/prometheus:v2.53.0"
        "$(get_email_service_image "$arch")"
    )
    
    local compatible_images=0
    local total_images=${#images_to_check[@]}
    
    for image in "${images_to_check[@]}"; do
        echo -n "  Checking $image for $arch... "
        if docker manifest inspect "$image" 2>/dev/null | jq -e ".manifests[] | select(.platform.architecture==\"$arch\")" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Compatible${NC}"
            ((compatible_images++))
        else
            echo -e "${YELLOW}⚠️  May need emulation${NC}"
        fi
    done
    
    echo ""
    echo -e "${CYAN}📊 Compatibility Summary:${NC}"
    echo "  Compatible images: $compatible_images/$total_images"
    
    if [[ $compatible_images -eq $total_images ]]; then
        echo -e "${GREEN}✅ Full native compatibility - optimal performance expected${NC}"
        return 0
    elif [[ $compatible_images -gt $((total_images / 2)) ]]; then
        echo -e "${YELLOW}⚠️  Partial compatibility - some images may use emulation${NC}"
        return 1
    else
        echo -e "${RED}❌ Poor compatibility - performance may be degraded${NC}"
        return 2
    fi
}

show_platform_summary() {
    local arch="$1"
    local docker_platform="$2"
    local env_file="$3"
    
    echo ""
    echo -e "${CYAN}🏗️  Platform Detection Summary${NC}"
    echo "────────────────────────────────────────────────"
    echo "• System Architecture: $arch"
    echo "• Operating System: $(detect_os)"
    echo "• Docker Platform: $docker_platform"
    echo "• Email Service: $(get_email_service_image "$arch")"
    echo "• Docker Compose: $(get_docker_compose_file "$arch")"
    echo "• Configuration File: $env_file"
    echo ""
    
    case "$arch" in
        arm64)
            echo -e "${GREEN}🚀 ARM64 Optimization Active${NC}"
            echo "• Using latest image versions for ARM64"
            echo "• Mailpit replaces MailHog for better compatibility"
            echo "• Grafana plugins optimized for ARM64"
            echo "• Full native performance expected"
            ;;
        amd64)
            echo -e "${BLUE}🔧 AMD64 Standard Configuration${NC}"
            echo "• Using stable tested image versions"
            echo "• All legacy plugins supported"
            echo "• Broad compatibility with existing setups"
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown Architecture Detected${NC}"
            echo "• Using universal compatibility mode"
            echo "• Performance may vary"
            echo "• Consider manual configuration"
            ;;
    esac
}

create_platform_specific_docker_compose() {
    local arch="$1"
    local env_file="$2"
    
    # Source the platform environment
    source "$env_file"
    
    local output_file="docker-compose-platform.yml"
    
    # Start with the universal template
    cp docker-compose-universal.yml "$output_file"
    
    # Apply platform-specific modifications
    case "$arch" in
        arm64)
            # Update image versions for ARM64
            sed -i.bak \
                -e "s|grafana/grafana:10.2.0|$GRAFANA_IMAGE|g" \
                -e "s|prom/prometheus:v2.47.0|$PROMETHEUS_IMAGE|g" \
                -e "s|prom/pushgateway:v1.6.2|$PUSHGATEWAY_IMAGE|g" \
                -e "s|influxdb:2.7|$INFLUXDB_IMAGE|g" \
                "$output_file"
            ;;
        amd64)
            # Keep backward compatibility
            sed -i.bak \
                -e "s|axllent/mailpit:v1.19.0|mailhog/mailhog:v1.0.1|g" \
                -e "s|email-server|mailhog|g" \
                "$output_file"
            ;;
    esac
    
    # Clean up backup file
    rm -f "${output_file}.bak"
    
    echo "$output_file"
}

# Main function
main() {
    echo -e "${CYAN}🏗️  SAST Platform Detection & Optimization${NC}"
    echo ""
    
    # Detect system architecture
    local arch=$(detect_architecture)
    local docker_platform=$(detect_docker_platform)
    
    echo -e "${BLUE}🔍 Detecting system platform...${NC}"
    echo "  Architecture: $arch"
    echo "  Docker Platform: $docker_platform"
    echo ""
    
    # Create platform-specific environment file
    local env_file=$(create_platform_env_file "$arch" "$docker_platform")
    echo -e "${GREEN}✅ Platform configuration created: $env_file${NC}"
    
    # Validate Docker compatibility
    if ! validate_docker_compatibility "$arch"; then
        echo -e "${YELLOW}⚠️  Some compatibility issues detected, but proceeding...${NC}"
    fi
    
    # Create platform-specific Docker Compose file
    local compose_file=$(create_platform_specific_docker_compose "$arch" "$env_file")
    echo -e "${GREEN}✅ Platform-optimized Docker Compose created: $compose_file${NC}"
    
    # Show summary
    show_platform_summary "$arch" "$docker_platform" "$env_file"
    
    # Output results for scripting
    echo ""
    echo "DETECTED_ARCH=$arch"
    echo "DOCKER_PLATFORM=$docker_platform"
    echo "ENV_FILE=$env_file"
    echo "COMPOSE_FILE=$compose_file"
    echo "EMAIL_SERVICE=$(get_email_service_image "$arch")"
}

# Handle command line arguments
case "${1:-detect}" in
    detect)
        main
        ;;
    arch)
        detect_architecture
        ;;
    docker)
        detect_docker_platform
        ;;
    email-image)
        get_email_service_image "$(detect_architecture)" "${2:-false}"
        ;;
    compose-file)
        get_docker_compose_file "$(detect_architecture)"
        ;;
    validate)
        validate_docker_compatibility "$(detect_architecture)"
        ;;
    help|--help|-h)
        echo "Usage: $0 [detect|arch|docker|email-image|compose-file|validate|help]"
        echo ""
        echo "Commands:"
        echo "  detect       - Full platform detection and optimization (default)"
        echo "  arch         - Show detected architecture"
        echo "  docker       - Show Docker platform"
        echo "  email-image  - Show recommended email service image"
        echo "  compose-file - Show recommended Docker Compose file"
        echo "  validate     - Validate Docker image compatibility"
        echo "  help         - Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
