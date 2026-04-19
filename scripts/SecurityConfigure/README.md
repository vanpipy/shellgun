# Cloud Server Initial Security Hardening

This project provides an opinionated, idempotent 4‑phase hardening flow for generic Linux cloud servers. Built as a single executable with subcommands.

## security-configure

Server security hardening orchestrator that runs 4 phases in sequence or individually.

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `user` | Phase 1: Create application user, configure shell, set up sudo permissions and SSH directory |
| `ssh` | Phase 2: Harden SSH daemon — custom port, key-only auth, root login disabled |
| `firewall` | Phase 3: Configure firewall (ufw/firewalld) and install fail2ban |
| `cleanup` | Phase 4: Post-configuration checks and cleanup |
| `all` | Run all phases in sequence (default) |

### Usage

Show help (no root required):
```bash
security-configure help
```

Run all phases (recommended for fresh servers):
```bash
sudo security-configure all --ssh-port 22222 --username myapp
```

Run a single phase:
```bash
sudo security-configure user      --ssh-port 22222 --username myapp
sudo security-configure ssh       --ssh-port 22222 --username myapp
sudo security-configure firewall  --ssh-port 22222 --username myapp
sudo security-configure cleanup    --ssh-port 22222 --username myapp
```

### Options

| Option | Description |
|--------|-------------|
| `--ssh-port PORT` | SSH port to configure (default: 22222) |
| `--username NAME` | Target application user (default: app) |
| `--non-interactive` | Non-interactive mode with safe defaults |
| `-y, --yes` | Assume "yes" for prompts |

### Prerequisites

- Linux host with bash, sed, coreutils available
- Root privileges (sudo) on the target server
- Package manager:
  - RHEL family: dnf/yum, firewalld; optional semanage from policycoreutils when SELinux enforcing
  - Debian/Ubuntu family: apt, ufw
- Network access to install packages (fail2ban, firewall tooling)

### OS Behavior

- **Debian/Ubuntu** → ufw
- **RHEL/CentOS/Rocky/AlmaLinux/Alibaba Linux** → firewalld
- **SELinux**: When enforcing, configure `ssh_port_t` for the chosen SSH port via `semanage port`

### Safety & Idempotence

- Scripts are re‑run safe; they check existing state and only apply necessary changes
- SSH lockout prevention sequence:
  1. Temporarily allow new SSH port in firewall (+ SELinux port if needed)
  2. Validate configuration with `sshd -t` before restart
  3. Test login on new port in a separate terminal before closing current session
- Automatic backups:
  - SSH: `/etc/ssh/sshd_config.bak.<timestamp>`
  - Fail2ban: `/etc/fail2ban/jail.local.bak.<timestamp>`

### Troubleshooting

| Issue | Solution |
|-------|----------|
| SSHD restart fails | Check `sshd -t` output; restore from `/etc/ssh/sshd_config.bak.*` |
| Fail2ban not working | Log path: Debian/Ubuntu → `/var/log/auth.log`, RHEL → `/var/log/secure` |
| Firewall not active | ufw: `sudo ufw enable`; firewalld: `sudo systemctl enable --now firewalld` |

## Phase Details

### Phase 1: User (`user`)

- Create or update application user with `/bin/bash` shell
- Add user to `sudo` (Debian) or `wheel` (RHEL) group
- Optionally enable NOPASSWD sudo for the user
- Create `~/.ssh/` with mode 700 and proper ownership
- Prompt for password unless `--non-interactive` or `-y` is set

### Phase 2: SSH (`ssh`)

- Backup existing sshd_config
- Configure sshd:
  - Custom port (`--ssh-port`)
  - PubkeyAuthentication yes
  - PasswordAuthentication no
  - PermitRootLogin no
  - AllowUsers only the specified username
  - MaxAuthTries 3
- Validate with `sshd -t` before reloading sshd
- Restart sshd service

### Phase 3: Firewall (`firewall`)

- Install and enable firewalld or ufw based on OS family
- Open custom SSH port
- Install and configure fail2ban with sshd jail
- Configure ban time, find time, max retry via jail.local

### Phase 4: Cleanup (`cleanup`)

- Verify SSH configuration
- Check firewall rules
- Display hardening summary
- Remove temporary files

## Development

- Phase logic source lives under `./src/` for maintainability
- Build output goes to `lib/` (temporary, not tracked in git)
- `bin/security-configure` is the source dispatcher; `lib/security-configure` is the built artifact
- Bash and zsh auto-completion files generated during build
