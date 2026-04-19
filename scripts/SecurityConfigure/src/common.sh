#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging helpers
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check root/sudo
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script requires root privileges. Please run with sudo."
        exit 1
    fi
}

# Parse CLI arguments
parse_args() {
    # Defaults
    SSH_PORT=${SSH_PORT:-22222}
    USERNAME=${USERNAME:-app}
    NON_INTERACTIVE=${NON_INTERACTIVE:-0}
    YES=${YES:-0}
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ssh-port)
                SSH_PORT="$2"
                shift 2
                ;;
            --username)
                USERNAME="$2"
                shift 2
                ;;
            --non-interactive)
                NON_INTERACTIVE=1
                shift 1
                ;;
            -y|--yes)
                YES=1
                shift 1
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validation
    if [[ ! $SSH_PORT =~ ^[0-9]+$ ]] || [[ $SSH_PORT -lt 1 ]] || [[ $SSH_PORT -gt 65535 ]]; then
        log_error "SSH port must be a number between 1 and 65535."
        exit 1
    fi
    
    if [[ ! $USERNAME =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "Username may contain lowercase letters, digits, underscores and hyphens, and must start with a letter or underscore."
        exit 1
    fi
}

# Help
show_help() {
    cat << EOF
Usage: \$0 [options]

Options:
    --ssh-port PORT     SSH port to use (default: 22222)
    --username NAME     Username to manage (default: app)
    --non-interactive   Run in non-interactive mode with safe defaults
    -y, --yes           Assume “yes” for prompts (overrides non-interactive)
    --help              Show this help message
EOF
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "Unable to detect operating system."
        exit 1
    fi
    
    log_info "Detected OS: $OS $VER"
    FAMILY="other"
    if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "alinux" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
        FAMILY="rhel"
    elif [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        FAMILY="debian"
    fi
}

# Install packages (per family)
install_packages() {
    local packages=("$@")
    
    if [[ "${FAMILY:-}" == "" ]]; then
        detect_os
    fi

    if [[ "$FAMILY" == "rhel" ]]; then
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y "${packages[@]}"
        else
            yum install -y "${packages[@]}"
        fi
    elif [[ "$FAMILY" == "debian" ]]; then
        if ! command -v apt >/dev/null 2>&1; then
            log_error "apt package manager not found."
            exit 1
        fi
        apt update
        DEBIAN_FRONTEND=noninteractive apt install -y "${packages[@]}"
    else
        log_error "Unsupported operating system: $OS"
        exit 1
    fi
}
