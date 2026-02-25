#!/bin/bash
# Phase 2: Configure SSH keys and hardening

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

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

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_args "$@"
    check_root
    phase_ssh
fi
