#!/bin/bash
#
# Phase 1: Configure User (Idempotent)
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

phase_user() {
    cat << "EOF"
╔════════════════════════════════════════╗
║    Phase 1: Configure User (Idempotent)║
╚════════════════════════════════════════╝
EOF

    log_step "Configure user: $USERNAME"

    if id "$USERNAME" &>/dev/null; then
        log_info "User exists"
        shell=$(getent passwd "$USERNAME" | cut -d: -f7)
        if [[ "$shell" != "/bin/bash" && -x /bin/bash ]]; then
            chsh -s /bin/bash "$USERNAME" 2>/dev/null || true
            log_info "Shell set to /bin/bash"
        fi
    else
        useradd -m -s /bin/bash "$USERNAME"
        log_info "User created"
    fi

    if [[ "${NON_INTERACTIVE:-0}" -ne 1 && "${YES:-0}" -ne 1 ]]; then
        log_step "Set password"
        passwd "$USERNAME"
    else
        log_info "Skipping password"
    fi

    log_step "Add to sudo/wheel"
    case "$OS" in
        centos|rhel|alinux) usermod -aG wheel "$USERNAME" ;;
        *) usermod -aG sudo "$USERNAME" ;;
    esac
    log_info "Added to $([[ "$OS" == "rhel" ]] && echo "wheel" || echo "sudo") group"

    if [[ "${NON_INTERACTIVE:-0}" -ne 1 && "${YES:-0}" -ne 1 ]]; then
        read -p "NOPASSWD sudo for $USERNAME? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$USERNAME"
            chmod 440 /etc/sudoers.d/"$USERNAME"
            log_info "NOPASSWD enabled"
        fi
    fi

    user_home=$(eval echo ~"$USERNAME")
    if [[ ! -d "$user_home/.ssh" ]]; then
        mkdir -p "$user_home/.ssh"
        chown "$USERNAME:$USERNAME" "$user_home/.ssh"
    fi
    chmod 700 "$user_home/.ssh"

    log_info "Phase 1 done"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_args "$@"
    check_root
    detect_os
    phase_user
fi
