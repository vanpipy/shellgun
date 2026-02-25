#!/bin/bash
# Phase 3: Configure Firewall and Fail2ban

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

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

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_args "$@"
    check_root
    phase_firewall
fi
