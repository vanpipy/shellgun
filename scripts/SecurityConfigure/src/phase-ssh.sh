#!/bin/bash
#
# Phase 2: SSH Key Setup & Hardening
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

phase_ssh() {
    cat << "EOF"
╔════════════════════════════════════════╗
║    Phase 2: SSH Key Setup & Hardening  ║
╚════════════════════════════════════════╝
EOF

    detect_os

    log_step "Prepare for SSH port change"
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld &>/dev/null; then
        firewall-cmd --add-port="$SSH_PORT/tcp" 2>/dev/null || true
    elif command -v ufw >/dev/null 2>&1; then
        ufw allow "$SSH_PORT/tcp" 2>/dev/null || true
    fi
    if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce)" == "Enforcing" ]]; then
        log_step "Configure SELinux port policy"
        if command -v semanage >/dev/null 2>&1; then
            semanage port -a -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || \
                semanage port -m -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || true
        fi
    fi

    if ! id "$USERNAME" &>/dev/null; then
        log_error "User $USERNAME not found. Run Phase 1 first."
        exit 1
    fi

    user_home=$(eval echo ~"$USERNAME")
    auth_keys="$user_home/.ssh/authorized_keys"

    log_step "Ensure SSH directory exists"
    if [[ ! -d "$user_home/.ssh" ]]; then
        mkdir -p "$user_home/.ssh"
        chown "$USERNAME:$USERNAME" "$user_home/.ssh"
        chmod 700 "$user_home/.ssh"
    fi

    log_step "Fix SSH directory permissions"
    chmod 700 "$user_home/.ssh"
    [[ -f "$auth_keys" ]] && chmod 600 "$auth_keys"

    log_step "Backup SSH configuration"
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak."$(date +%Y%m%d%H%M%S)"

    has_keys=0
    [[ -f "$auth_keys" ]] && has_keys=1

    if [[ "$has_keys" -eq 0 ]]; then
        log_warn "No authorized_keys for $USERNAME; skipping hardening to avoid lockout."
        cat << EOUT
${YELLOW}Next: copy your key here, then re-run:${NC}
  ssh-copy-id -i ~/.ssh/id_ed25519.pub $USERNAME@<server_ip>
  sudo security-configure ssh --ssh-port $SSH_PORT --username $USERNAME
EOUT
        return 0
    fi

    log_info "Config backed up"

    log_step "Test SSH key login"
    log_info "In another terminal: ssh -p $SSH_PORT $USERNAME@<server_ip>"
    if [[ "${NON_INTERACTIVE:-0}" -ne 1 && "${YES:-0}" -ne 1 ]]; then
        read -p "Confirm passwordless login works? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "Key-based login must work before proceeding."
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

    if [[ "${NON_INTERACTIVE:-0}" -ne 1 && "${YES:-0}" -ne 1 ]]; then
        read -p "Deny SSH for 'admin'? (y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && echo "DenyUsers admin" >> /etc/ssh/sshd_config
    fi

    log_info "SSH config updated"

    log_step "Restart SSH service"
    if ! sshd -t 2>/dev/null; then
        log_error "sshd config test failed"
        exit 1
    fi
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    log_info "SSH service restarted"

    log_info "Phase 2 done"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_args "$@"
    check_root
    phase_ssh
fi
