# Cloud Server Initial Security Hardening

This project provides an opinionated, idempotent 4‑phase hardening flow for generic Linux cloud servers. It now ships as a single executable with subcommands.

## Prerequisites
- Linux host with bash, sed, coreutils available.
- Root privileges (sudo) on the target server.
- Package manager:
  - RHEL family: dnf or yum, firewalld; optional semanage from policycoreutils(-python/-utils) when SELinux is enforcing.
  - Debian/Ubuntu family: apt, ufw.
- Network access to install packages (fail2ban, firewall tooling).

## Distribution
The repository provides a single entry script that embeds all phases:

- `./bin/security-configure.sh`

Subcommands:
- `user` – Phase 1: user setup
- `ssh` – Phase 2: SSH hardening
- `firewall` – Phase 3: firewall & fail2ban
- `cleanup` – Phase 4: post checks & cleanup
- `all` – Run all phases in sequence (default)

## Usage
- Show help (no root required):

```bash
./bin/security-configure.sh help
```

- Run all phases (recommended):

```bash
sudo ./bin/security-configure.sh all --ssh-port 22222 --username myapp
# or simply omit the subcommand (defaults to 'all')
sudo ./bin/security-configure.sh --ssh-port 22222 --username myapp
```

- Run a single phase:

```bash
sudo ./bin/security-configure.sh user --ssh-port 22222 --username myapp
sudo ./bin/security-configure.sh ssh --ssh-port 22222 --username myapp
sudo ./bin/security-configure.sh firewall --ssh-port 22222 --username myapp
sudo ./bin/security-configure.sh cleanup --ssh-port 22222 --username myapp
```

- Prepare an SSH key on your local machine if you don't have one:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

- Copy your public key to the server:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub myapp@<server_ip>
```

## Arguments and Modes
- `--ssh-port PORT`: SSH port to configure (default 22222)
- `--username NAME`: Target application user (default app)
- `--non-interactive`: Non‑interactive mode with safe defaults
- `-y, --yes`: Assume “yes” for prompts (overrides non‑interactive where applicable)

## OS Behavior
- Family detection: Debian/Ubuntu → ufw; RHEL/CentOS/Rocky/AlmaLinux/Alibaba Linux → firewalld.
- SELinux: When enforcing, configure ssh_port_t for the chosen SSH port (semanage port).

## Safety & Idempotence
- Scripts can be re‑run safely; they check existing state and only apply necessary changes.
- SSH changes sequence avoids lockout:
  - Temporarily allow the new SSH port in the firewall (+SELinux port if needed) before changing sshd_config.
  - Validate configuration with `sshd -t` before restart.
  - Test login on new port in a separate terminal before closing the current session.
- Backups:
  - SSH: `/etc/ssh/sshd_config.bak.<timestamp>`
  - Fail2ban: `/etc/fail2ban/jail.local.bak.<timestamp>`

## Troubleshooting
- SSHD restart fails: check `sshd -t` output and restore from the latest `/etc/ssh/sshd_config.bak.*`.
- Fail2ban log path:
  - Debian/Ubuntu: `/var/log/auth.log`
  - RHEL family: `/var/log/secure`
- Firewall not active:
  - ufw: `sudo ufw enable` then rerun the firewall subcommand
  - firewalld: `sudo systemctl enable --now firewalld`

## Notes for Development
- Phase logic source lives under `./src` for maintainability.
- The distributed single-file entry embeds the phase functions and dispatches via subcommands.
