# Shellgun

> Shot every shelled problem with shelled bullet.

## Build

```bash
make security-configure
```

## Install

```bash
sudo make install
```

This installs:
- `bin/*` binaries to `/usr/local/bin/`
- `security-configure` to `/usr/local/bin/`
- Bash completion to `/usr/local/share/bash-completion/completions/`
- Zsh completion to `/usr/local/share/zsh/site-functions/`

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make security-configure` | Build `lib/security-configure` from source |
| `make install` | Install all to `/usr/local/bin/` (default) |
| `make uninstall` | Remove all installed files |
| `make clean` | Remove `lib/` build directory |

## Usage

```bash
# Show help (no root required)
security-configure help

# Run all phases (default)
sudo security-configure all --ssh-port 22222 --username myapp

# Run single phase
sudo security-configure user    --ssh-port 22222 --username myapp
sudo security-configure ssh     --ssh-port 22222 --username myapp
sudo security-configure firewall --ssh-port 22222 --username myapp
sudo security-configure cleanup --ssh-port 22222 --username myapp
```

### Subcommands

| Subcommand | Description |
|------------|-------------|
| `user` | Phase 1: user setup |
| `ssh` | Phase 2: SSH hardening |
| `firewall` | Phase 3: firewall & fail2ban |
| `cleanup` | Phase 4: post checks & cleanup |
| `all` | Run all phases in sequence (default) |

### Options

- `--ssh-port PORT` SSH port (default: 22222)
- `--username NAME` Target user (default: app)
- `--non-interactive` Non-interactive mode
- `-y, --yes` Assume yes for prompts

## Auto-Completion

**Bash** — add to `~/.bashrc`:
```bash
source /usr/local/share/bash-completion/completions/security-configure
```

**Zsh** — add to `~/.zshrc`:
```bash
fpath=(/usr/local/share/zsh/site-functions $fpath)
```

Then reload shell.

## Uninstall

```bash
sudo make uninstall
```

## Project Structure

```
bin/                           # Binaries (git-tracked)
scripts/SecurityConfigure/
  src/                         # Phase source scripts
  build.sh                     # Build script
lib/                           # Build output (temp, not tracked)
```
