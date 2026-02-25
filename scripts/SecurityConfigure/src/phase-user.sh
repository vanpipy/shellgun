#!/bin/bash
# Phase 1: Configure User (Idempotent)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

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

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_args "$@"
    check_root
    detect_os
    phase_user
fi
