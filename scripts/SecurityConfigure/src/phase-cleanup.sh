#!/bin/bash
#
# Phase 4: Cleanup & Final Checks
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

phase_cleanup() {
    cat << "EOF"
╔════════════════════════════════════════╗
║           Phase 4: Cleanup             ║
╚════════════════════════════════════════╝
EOF

    log_step "Run final checks"

    log_info "Check SSH config..."
    grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config && log_warn "PasswordAuthentication still enabled" || log_info "Password auth disabled"
    grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config && log_warn "PermitRootLogin still enabled" || log_info "Root login disabled"

    log_info "Check firewall..."
    if systemctl is-active firewalld &>/dev/null; then
        log_info "firewalld active"
        firewall-cmd --list-ports 2>/dev/null || true
    elif command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
        log_info "ufw active"
    else
        log_warn "No active firewall"
    fi

    log_info "Check Fail2ban..."
    if systemctl is-active fail2ban &>/dev/null; then
        log_info "fail2ban running"
        fail2ban-client status sshd 2>/dev/null | grep Status || true
    else
        log_warn "fail2ban not running"
    fi

    if [[ "${NON_INTERACTIVE:-0}" -ne 1 && "${YES:-0}" -ne 1 ]]; then
        read -p "Lock 'admin' account? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] && id admin &>/dev/null; then
            passwd -l admin 2>/dev/null && log_info "admin locked"
        fi
        read -p "Remove unused packages? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            [[ "$FAMILY" == "rhel" ]] && (dnf autoremove -y 2>/dev/null || yum autoremove -y 2>/dev/null) || apt autoremove -y
            log_info "Cleanup done"
        fi
    fi

    cat << EFINAL

${GREEN}╔════════════════════════════════════════╗
║       Server initialization complete!   ║
╚════════════════════════════════════════╝${NC}

${GREEN}Summary:${NC}
• User: $USERNAME
• SSH port: $SSH_PORT
• Password auth: Disabled
• Root login: Disabled
• Firewall: Configured
• Fail2ban: Running

${YELLOW}Login:${NC} ssh -p $SSH_PORT $USERNAME@<server_ip>
EFINAL
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    phase_cleanup "$@"
fi
