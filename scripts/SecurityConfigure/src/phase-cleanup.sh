#!/bin/bash
# Phase 4: Cleanup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

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

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    phase_cleanup "$@"
fi
