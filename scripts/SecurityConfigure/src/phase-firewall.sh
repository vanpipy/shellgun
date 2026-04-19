#!/bin/bash
#
# Phase 3: Firewall & Fail2ban Setup
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

phase_firewall() {
    cat << "EOF"
╔════════════════════════════════════════╗
║    Phase 3: Firewall & Fail2ban Setup  ║
╚════════════════════════════════════════╝
EOF

    detect_os

    log_step "Install firewall and Fail2ban"
    [[ "$FAMILY" == "rhel" ]] && install_packages firewalld fail2ban || install_packages ufw fail2ban

    if [[ "$FAMILY" == "rhel" ]]; then
        log_step "Configure firewalld"
        systemctl start firewalld
        systemctl enable firewalld
        firewall-cmd --permanent --add-port="$SSH_PORT/tcp"
        log_info "Allowed port $SSH_PORT/tcp"

        if [[ "${NON_INTERACTIVE:-0}" -ne 1 || "${YES:-0}" -eq 1 ]]; then
            read -p "Allow HTTP (80)? (y/n): " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]] && firewall-cmd --permanent --add-service=http
            read -p "Allow HTTPS (443)? (y/n): " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]] && firewall-cmd --permanent --add-service=https
        fi
        firewall-cmd --reload
        log_info "Firewall rules:"
        firewall-cmd --list-all
    else
        log_step "Configure ufw"
        ufw --force enable 2>/dev/null || true
        ufw allow "$SSH_PORT/tcp" 2>/dev/null || true
        if [[ "${NON_INTERACTIVE:-0}" -ne 1 || "${YES:-0}" -eq 1 ]]; then
            read -p "Allow HTTP (80)? (y/n): " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]] && ufw allow 80/tcp
            read -p "Allow HTTPS (443)? (y/n): " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]] && ufw allow 443/tcp
        fi
        ufw status verbose 2>/dev/null || true
    fi

    log_step "Configure Fail2ban"
    [[ -f /etc/fail2ban/jail.local ]] && cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak."$(date +%Y%m%d%H%M%S)"

    logpath="/var/log/auth.log"
    [[ "$FAMILY" == "rhel" ]] && logpath="/var/log/secure"

    cat > /etc/fail2ban/jail.local << ECONF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ::1
backend = systemd

[sshd]
enabled = true
port = $SSH_PORT
logpath = $logpath
ECONF

    systemctl start fail2ban
    systemctl enable fail2ban
    sleep 2
    fail2ban-client status sshd

    log_info "Phase 3 done"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_args "$@"
    check_root
    phase_firewall
fi
