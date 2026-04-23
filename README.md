# Shellgun

> Shot every shelled problem with shelled bullet.

## Binaries

| Command | Description |
|---------|-------------|
| `git-push-current-branch` | Push current branch to origin |
| `security-configure` | Server security hardening orchestrator |
| `speckit-configure` | Speckit configuration orchestrator |

## Install

```bash
sudo make install
```

This installs:
- `bin/*` binaries to `/usr/local/bin/`
- `security-configure` and `speckit-configure` to `/usr/local/bin/`
- Bash completion to `/usr/local/share/bash-completion/completions/`
- Zsh completion to `/usr/local/share/zsh/site-functions/`

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make security-configure` | Build `lib/security-configure` from source |
| `make install` | Install all to `/usr/local/bin/` (default) |
| `make uninstall` | Remove all installed files |
| `make clean` | Remove `lib/` build directory |

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
