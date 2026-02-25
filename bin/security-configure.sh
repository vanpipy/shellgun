#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Single-file security configuration with subcommands:
#   user | ssh | firewall | cleanup | all (default)
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

show_subcommand_help() {
  cat << USAGE
Usage:
  $0 [subcommand] [options]

Subcommands:
  user        Run Phase 1 (user setup)
  ssh         Run Phase 2 (SSH hardening)
  firewall    Run Phase 3 (firewall & fail2ban)
  cleanup     Run Phase 4 (post checks & cleanup)
  all         Run all phases in order (default)

Options:
  --ssh-port PORT       SSH port to use (default: 22222)
  --username NAME       Username to manage (default: app)
  --non-interactive     Run in non-interactive mode
  -y, --yes             Assume “yes” for prompts
  --help                Show this help
USAGE
}

# ==== phase-cleanup.sh ====
# Phase 4: Cleanup


phase_cleanup() {
cat << "EOF"
╔════════════════════════════════════════╗
║           Phase 4: Cleanup             ║
╚════════════════════════════════════════╝
EOF

parse_args "$@"
check_root
detect_os

log_step "Run final checks and cleanup"

log_info "Check SSH configuration..."
if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
    log_warn "Warning: PasswordAuthentication is still enabled"
else
    log_info "✓ Password authentication is disabled"
fi

if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
    log_warn "Warning: PermitRootLogin is still enabled"
else
    log_info "✓ Root login is disabled"
fi

log_info "Check firewall status..."
if systemctl is-active firewalld >/dev/null 2>&1; then
    log_info "✓ firewalld is active"
    log_info "Open ports: $(firewall-cmd --list-ports)"
elif command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    log_info "✓ ufw is active"
    ufw status numbered || true
else
    log_warn "Warning: No active firewall service detected"
fi

log_info "Check Fail2ban status..."
if systemctl is-active fail2ban >/dev/null; then
    log_info "✓ fail2ban is running"
    fail2ban-client status sshd | grep "Status"
else
    log_warn "Warning: fail2ban is not running"
fi

if [[ "${NON_INTERACTIVE:-0}" -ne 1 || "${YES:-0}" -eq 1 ]]; then
    read -p "Lock 'admin' account (console-only access)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if id admin >/dev/null 2>&1; then
            passwd -l admin
            log_info "admin account locked"
        else
            log_warn "admin account does not exist"
        fi
    fi
fi

if [[ "${NON_INTERACTIVE:-0}" -ne 1 || "${YES:-0}" -eq 1 ]]; then
    read -p "Remove unnecessary packages? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$FAMILY" == "rhel" ]]; then
            if command -v dnf >/dev/null 2>&1; then
                dnf autoremove -y
            else
                yum autoremove -y || yum remove -y
            fi
        else
            apt autoremove -y
        fi
        log_info "Unnecessary packages removed"
    fi
fi

cat << EOF

${GREEN}╔════════════════════════════════════════╗
║       Server initialization complete!   ║
╚════════════════════════════════════════╝${NC}

${GREEN}Final configuration summary:${NC}
• Dedicated account: $USERNAME
• SSH port: $SSH_PORT
• Password authentication: Disabled
• Root login: Disabled
• Firewall: Configured
• Fail2ban: Running

${YELLOW}Login command:${NC}
ssh -p $SSH_PORT $USERNAME@<your_server_ip>

${BLUE}Next recommendations:${NC}
1. Keep system updated: sudo dnf update (or apt update && apt upgrade)
2. Monitor Fail2ban logs: sudo tail -f /var/log/fail2ban.log
3. Consider configuring automated backups
4. Proceed with your application deployment

EOF
}



# ==== phase-firewall.sh ====
# Phase 3: Configure Firewall and Fail2ban


phase_firewall() {
cat << "EOF"
╔════════════════════════════════════════╗
║    Phase 3: Firewall & Fail2ban Setup  ║
╚════════════════════════════════════════╝
EOF

detect_os

log_step "Install firewall and Fail2ban"
if [[ "$FAMILY" == "rhel" ]]; then
    install_packages firewalld fail2ban
else
    install_packages ufw fail2ban
fi

if [[ "$FAMILY" == "rhel" ]]; then
    log_step "Configure firewalld"

    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --permanent --add-port="$SSH_PORT/tcp"
    log_info "Allowed port $SSH_PORT/tcp"

    if [[ "${NON_INTERACTIVE:-0}" -ne 1 || "${YES:-0}" -eq 1 ]]; then
        read -p "Allow HTTP (80)? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            firewall-cmd --permanent --add-service=http
            log_info "HTTP allowed"
        fi
        read -p "Allow HTTPS (443)? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            firewall-cmd --permanent --add-service=https
            log_info "HTTPS allowed"
        fi
    fi

    firewall-cmd --reload
    log_info "Current firewall rules:"
    firewall-cmd --list-all

else
    log_step "Configure ufw"
    if ! systemctl is-active ufw >/dev/null 2>&1; then
        ufw --force enable >/dev/null 2>&1 || true
    fi
    ufw allow "$SSH_PORT"/tcp || true
    if [[ "${NON_INTERACTIVE:-0}" -ne 1 || "${YES:-0}" -eq 1 ]]; then
        read -p "Allow HTTP (80)? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ufw allow 80/tcp || true
        fi
        read -p "Allow HTTPS (443)? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ufw allow 443/tcp || true
        fi
    fi
    ufw status verbose || true
fi

log_step "Configure Fail2ban"

if [[ -f /etc/fail2ban/jail.local ]]; then
    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak.$(date +%Y%m%d%H%M%S)
fi
if [[ "$FAMILY" == "rhel" ]]; then
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ::1
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
logpath = /var/log/secure
EOF
else
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ::1
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
logpath = /var/log/auth.log
EOF
fi

systemctl start fail2ban
systemctl enable fail2ban

sleep 2
fail2ban-client status sshd

log_info "Phase 3 completed."
cat << EOF

${GREEN}Next:${NC}
Run Phase 4 (cleanup):
sudo ./lib/phase-cleanup.sh --ssh-port $SSH_PORT --username $USERNAME
EOF
}



# ==== phase-ssh.sh ====
# Phase 2: Configure SSH keys and hardening


phase_ssh() {
cat << "EOF"
╔════════════════════════════════════════╗
║    Phase 2: SSH Key Setup & Hardening  ║
╚════════════════════════════════════════╝
EOF

detect_os

log_step "Prepare for SSH port change"
if command -v firewall-cmd >/dev/null 2>&1; then
    if systemctl is-active firewalld >/devnull 2>&1; then
        firewall-cmd --add-port="$SSH_PORT/tcp" || true
    fi
elif command -v ufw >/dev/null 2>&1; then
    ufw allow "$SSH_PORT"/tcp >/dev/null 2>&1 || true
fi
if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce)" == "Enforcing" ]]; then
    log_step "Configure SELinux port policy"
    if ! command -v semanage >/dev/null 2>&1; then
        install_packages policycoreutils-python-utils policycoreutils-python || true
    fi
    if command -v semanage >/dev/null 2>&1; then
        semanage port -a -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || semanage port -m -t ssh_port_t -p tcp "$SSH_PORT" || true
    fi
fi

log_step "Check SSH key setup"

if ! id "$USERNAME" &>/dev/null; then
    log_error "User $USERNAME does not exist. Please run Phase 1 first."
    exit 1
fi

USER_HOME=$(eval echo ~$USERNAME)
AUTH_KEYS="$USER_HOME/.ssh/authorized_keys"

if [[ ! -f "$AUTH_KEYS" ]]; then
    log_error "Authorized key file for $USERNAME not found."
    cat << EOF
${YELLOW}Run on your local machine first:${NC}
ssh-copy-id -i ~/.ssh/id_ed25519.pub $USERNAME@<server_ip>

If you do not have an SSH key pair yet, generate one:
ssh-keygen -t ed25519 -C "your_email@example.com"
EOF
    exit 1
fi

log_step "Fix SSH directory permissions"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$AUTH_KEYS"
log_info "Permissions fixed"

log_step "Backup SSH configuration"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)
log_info "Configuration backed up"

log_step "Test SSH key login"
log_info "In another terminal, test: ssh -p $SSH_PORT $USERNAME@<server_ip>"
if [[ "${NON_INTERACTIVE:-0}" -ne 1 && "${YES:-0}" -ne 1 ]]; then
    read -p "Confirm passwordless login works? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Make sure key-based login works before proceeding."
        exit 1
    fi
fi

log_step "Harden SSH configuration"

sed -i.bak \
    -e "s/^#*Port .*/Port $SSH_PORT/" \
    -e "s/^#*PermitRootLogin .*/PermitRootLogin no/" \
    -e "s/^#*PasswordAuthentication .*/PasswordAuthentication no/" \
    -e "s/^#*PubkeyAuthentication .*/PubkeyAuthentication yes/" \
    -e "/^#*AllowUsers/d" \
    /etc/ssh/sshd_config

echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config

if [[ "${NON_INTERACTIVE:-0}" -eq 1 && "${YES:-0}" -ne 1 ]]; then
    :
else
    read -p "Deny SSH login for user 'admin'? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "DenyUsers admin" >> /etc/ssh/sshd_config
        log_info "SSH login for 'admin' has been denied"
    fi
fi

log_info "SSH configuration updated"

log_step "Restart SSH service"
if ! sshd -t 2>/dev/null; then
    log_error "SSHD configuration test failed. Backup kept at /etc/ssh/sshd_config.bak.*"
    exit 1
fi
if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "alinux" ]]; then
    systemctl restart sshd
else
    systemctl restart ssh
fi
log_info "SSH service restarted"

log_info "Phase 2 completed."
cat << EOF

${GREEN}Important:${NC}
1. ${YELLOW}Before closing this session, test the new configuration in a new terminal:${NC}
   ssh -p $SSH_PORT $USERNAME@<server_ip>

2. You can either:
   - Run the firewall phase directly:
     sudo ./lib/phase-firewall.sh --ssh-port $SSH_PORT --username $USERNAME
   - Or continue with the combined script:
     sudo ./security-configure.sh --ssh-port $SSH_PORT --username $USERNAME
EOF
}



# ==== phase-user.sh ====
# Phase 1: Configure User (Idempotent)


phase_user() {
cat << "EOF"
╔════════════════════════════════════════╗
║    Phase 1: Configure User (Idempotent)║
╚════════════════════════════════════════╝
EOF

log_step "Start configuring user: $USERNAME"

# Create or fix user
if id "$USERNAME" &>/dev/null; then
    log_info "User $USERNAME already exists"
    CURRENT_SHELL="$(getent passwd "$USERNAME" | cut -d: -f7 || echo "")"
    if [[ "$CURRENT_SHELL" != "/bin/bash" && -x /bin/bash ]]; then
        chsh -s /bin/bash "$USERNAME" || true
        log_info "Default shell for $USERNAME set to /bin/bash"
    fi
else
    useradd -m -s /bin/bash "$USERNAME"
    log_info "User $USERNAME created"
fi

# Set password (optional; skipped in non-interactive)
if [[ "${NON_INTERACTIVE:-0}" -ne 1 && "${YES:-0}" -ne 1 ]]; then
    log_step "Set user password"
    echo -e "${YELLOW}Please set a strong password for $USERNAME (password login is recommended to be disabled later).${NC}"
    passwd "$USERNAME"
else
    log_info "Non-interactive: skipping password setup"
fi

# Add to sudo/wheel group
log_step "Configure sudo privileges"
if [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "alinux" ]]; then
    usermod -aG wheel "$USERNAME"
    log_info "User added to wheel group"
else
    usermod -aG sudo "$USERNAME"
    log_info "User added to sudo group"
fi

# Configure whether sudo requires password
if [[ "${NON_INTERACTIVE:-0}" -ne 1 && "${YES:-0}" -ne 1 ]]; then
    read -p "Allow $USERNAME to run sudo without password? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$USERNAME"
        chmod 440 /etc/sudoers.d/"$USERNAME"
        log_info "NOPASSWD sudo configured"
    else
        log_info "sudo will require password"
    fi
else
    log_info "Non-interactive: keeping sudo password requirement"
fi

# Prepare SSH directory and permissions
USER_HOME=$(eval echo ~$USERNAME)
if [[ ! -d "$USER_HOME/.ssh" ]]; then
    mkdir -p "$USER_HOME/.ssh"
    chown "$USERNAME":"$USERNAME" "$USER_HOME/.ssh"
fi
chmod 700 "$USER_HOME/.ssh"

log_info "Phase 1 completed."
cat << EOF

${GREEN}Next steps:${NC}
1. On your local machine, copy your public key to the server:
   ssh-copy-id -i ~/.ssh/id_ed25519.pub $USERNAME@<server_ip>

2. You can either:
   - Run the SSH phase directly:
     sudo ./lib/phase-ssh.sh --ssh-port $SSH_PORT --username $USERNAME
   - Or use the combined script:
     sudo ./security-configure.sh --ssh-port $SSH_PORT --username $USERNAME
EOF
}


main() {
  # Determine subcommand if present (first arg not starting with '-')
  local cmd="all"
  if [[ $# -gt 0 && "$1" != --* ]]; then
    cmd="$1"
    shift
  fi

  # Early help without requiring root
  if [[ "$cmd" == "help" || "$cmd" == "--help" || "$cmd" == "-h" ]]; then
    show_subcommand_help
    exit 0
  fi

  # Parse global options into variables used by phases
  parse_args "$@"

  # Root and OS detection (user phase relies on OS variable)
  check_root
  detect_os

  case "$cmd" in
    user)       phase_user "$@";;
    ssh)        phase_ssh "$@";;
    firewall)   phase_firewall "$@";;
    cleanup)    phase_cleanup "$@";;
    all)        phase_user "$@"; phase_ssh "$@"; phase_firewall "$@"; phase_cleanup "$@";;
    *) echo "Unknown subcommand: $cmd"; show_subcommand_help; exit 1;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
