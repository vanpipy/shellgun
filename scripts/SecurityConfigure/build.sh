#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
PROJECT_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"
OUT_FILE="$PROJECT_ROOT/lib/security-configure"
OUT_STANDALONE="$PROJECT_ROOT/lib/security-configure"
COMMON_SRC="$SRC_DIR/common.sh"

# Completion file paths
BASH_COMP="$PROJECT_ROOT/lib/security-configure.bash"
ZSH_COMP="$PROJECT_ROOT/lib/_security-configure"

if [[ ! -f "$COMMON_SRC" ]]; then
  echo "common.sh not found at $COMMON_SRC" >&2
  exit 1
fi

mkdir -p "$PROJECT_ROOT/lib"

# Clean old multi-file outputs if any (non-backward compatible single file output)
rm -f "$PROJECT_ROOT/lib/phase-user.sh" \
      "$PROJECT_ROOT/lib/phase-ssh.sh" \
      "$PROJECT_ROOT/lib/phase-firewall.sh" \
      "$PROJECT_ROOT/lib/phase-cleanup.sh"
rm -rf "$PROJECT_ROOT/lib/SecurityConfigure" || true

echo "[BUILD] Generating dispatcher: $OUT_STANDALONE"
python3 -c "
import sys
root = '$PROJECT_ROOT'
with open('$PROJECT_ROOT/bin/security-configure') as f:
    content = f.read()
content = content.replace(
    'SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]}\")\" && pwd)\"',
    'PROJECT_ROOT=\"' + root + '\"; SCRIPT_DIR=\"' + root + '/bin\"'
)
content = content.replace(
    'CONF_DIR=\"\$SCRIPT_DIR/scripts/SecurityConfigure\"',
    'CONF_DIR=\"' + root + '/scripts/SecurityConfigure\"'
)
with open('$OUT_STANDALONE', 'w') as f:
    f.write(content)
"
chmod +x "$OUT_STANDALONE"

echo "[BUILD] Generating bash completion: $BASH_COMP"
cat > "$BASH_COMP" << 'EOF'
# bash completion for security-configure
_security-configure() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"

    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=($(compgen -W "user ssh firewall cleanup all help" -- "$cur"))
        return
    fi

    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--ssh-port --username --non-interactive --yes --help" -- "$cur"))
    fi
}
complete -F _security-configure security-configure
EOF

echo "[BUILD] Generating zsh completion: $ZSH_COMP"
cat > "$ZSH_COMP" << 'EOF'
#compdef security-configure
_security-configure() {
    local -a cmds=(user ssh firewall cleanup all)
    _describe 'subcommand' cmds
    _arguments \
        '--ssh-port[SSH port]:port:' \
        '--username[username]:name:' \
        '--non-interactive[non-interactive mode]' \
        '-y[assume yes]' \
        '--help[show help]'
}
_security-configure "$@"
EOF

echo "[BUILD] Generating single-file dispatcher: $OUT_FILE"

# Prepare common body (strip shebang if present)
COMMON_BODY_FILE="$(mktemp)"
trap 'rm -f "$COMMON_BODY_FILE"' EXIT
if head -n1 "$COMMON_SRC" | grep -q '^#!/bin/bash'; then
  tail -n +2 "$COMMON_SRC" > "$COMMON_BODY_FILE"
else
  cat "$COMMON_SRC" > "$COMMON_BODY_FILE"
fi

# Helper to extract only the function body from a phase script
extract_phase_fn() {
  local phase_file="$1"
  local tmp="$(mktemp)"
  # Drop shebang
  tail -n +2 "$phase_file" > "$tmp"
  # Remove SCRIPT_DIR assignment and source common.sh
  sed -Ei \
    -e '/^[[:space:]]*SCRIPT_DIR=.*BASH_SOURCE\[0\].*$/d' \
    -e '/^[[:space:]]*source[[:space:]]+"?\$SCRIPT_DIR\/common\.sh"?[[:space:]]*$/d' \
    "$tmp"
  # Remove standalone main guard block: if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then ... fi
  # Use a conservative range delete
  sed -E -i '/^\s*if \[\[ "\$\{BASH_SOURCE\[0\]\}" == "\$0" \]\]; then/,/^\s*fi\s*$/d' "$tmp"
  cat "$tmp"
  rm -f "$tmp"
}

# Start writing the single output
cat > "$OUT_FILE" << 'HEADER'
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Single-file security configuration with subcommands:
#   user | ssh | firewall | cleanup | all (default)
HEADER

# Inject common library
cat "$COMMON_BODY_FILE" >> "$OUT_FILE"
echo >> "$OUT_FILE"

# Add subcommand-specific help
cat >> "$OUT_FILE" << 'EOF'
show_subcommand_help() {
  cat << USAGE
Usage:
  $0 [subcommand] [options]

Subcommands:
  user        Run Phase 1 (user setup)
  ssh         Run Phase 2 (SSH hardening)
  firewall    Run Phase 3 (firewall & fail2ban)
  cleanup     Run Phase 4 (post checks & cleanup)
  all         Run all phases in order (default)

Options:
  --ssh-port PORT       SSH port to use (default: 22222)
  --username NAME       Username to manage (default: app)
  --non-interactive     Run in non-interactive mode
  -y, --yes             Assume “yes” for prompts
  --help                Show this help
USAGE
}
EOF

# Inject phase functions
for pf in "$SRC_DIR"/phase-*.sh; do
  echo >> "$OUT_FILE"
  echo "# ==== $(basename "$pf") ====" >> "$OUT_FILE"
  extract_phase_fn "$pf" >> "$OUT_FILE"
  echo >> "$OUT_FILE"
done

# Add dispatcher (main)
cat >> "$OUT_FILE" << 'EOF'
main() {
  # Determine subcommand if present (first arg not starting with '-')
  local cmd="all"
  if [[ $# -gt 0 && "$1" != --* ]]; then
    cmd="$1"
    shift
  fi

  # Early help without requiring root
  if [[ "$cmd" == "help" || "$cmd" == "--help" || "$cmd" == "-h" ]]; then
    show_subcommand_help
    exit 0
  fi

  # Parse global options into variables used by phases
  parse_args "$@"

  # Root and OS detection (user phase relies on OS variable)
  check_root
  detect_os

  case "$cmd" in
    user)       phase_user "$@";;
    ssh)        phase_ssh "$@";;
    firewall)   phase_firewall "$@";;
    cleanup)    phase_cleanup "$@";;
    all)        phase_user "$@"; phase_ssh "$@"; phase_firewall "$@"; phase_cleanup "$@";;
    *) echo "Unknown subcommand: $cmd"; show_subcommand_help; exit 1;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
EOF

chmod +x "$OUT_FILE"
echo "[BUILD] Done."
