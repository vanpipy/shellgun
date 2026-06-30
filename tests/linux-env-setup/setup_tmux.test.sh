#!/usr/bin/env bash
#
# tests/linux-env-setup/setup_tmux.test.sh
#
# TDD contract tests for setup_tmux in bin/linux-env-setup.
#
# Pinned behavior:
#   1. On first run, clones gpakosz/.tmux and symlinks ~/.tmux.conf.
#   2. Appends the shellgun custom tmux config (clipboard + mouse).
#   3. Re-running does NOT duplicate the custom config (idempotent).
#   4. Re-running preserves the ~/.tmux.conf symlink.
#
# Usage:  bash tests/linux-env-setup/setup_tmux.test.sh
#
set -euo pipefail

# Locate the script-under-test relative to this test file.
SCRIPT_UT="${SCRIPT_UT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../bin" && pwd)/linux-env-setup}"
[[ -f "$SCRIPT_UT" ]] || { echo "FATAL: cannot find linux-env-setup at $SCRIPT_UT" >&2; exit 2; }

# ── Sandbox HOME so the real ~/.tmux is never touched ─────────────────
SANDBOX=$(mktemp -d -t shellgun-tmux-test.XXXXXX)
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX"

# Source the script. The last line is `[[ BASH_SOURCE == $0 ]] && main "$@"`,
# which returns 1 when sourced (different $0), so we tolerate that exit code
# and instead verify the function was actually defined.
# shellcheck disable=SC1090
source "$SCRIPT_UT" || true
type setup_tmux &>/dev/null || { echo "FATAL: setup_tmux not defined after source" >&2; exit 2; }

# ── Tiny assertion helpers (top-level — no local needed) ───────────────
_fail() { echo "  ✗ FAIL: $*" >&2; exit 1; }
_pass() { echo "  ✓ $*"; }
_assert_file_exists()    { [[ -e "$1" ]] || _fail "expected file: $1"; }
_assert_symlink_to()     {
  [[ -L "$1" ]] || _fail "expected symlink: $1"
  local _target; _target=$(readlink "$1")
  [[ "$_target" == "$2" ]] || _fail "symlink $1 → '$_target', expected '$2'"
}
_assert_contains()       { grep -qF -- "$1" "$2" || _fail "expected '$1' in $2"; }

# ── Custom config contract (the 4 lines the user requested) ───────────
readonly CUSTOM_LINES=(
  'set -g set-clipboard on'
  'set -g mouse on'
  'bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "clip.exe"'
  'bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "clip.exe"'
)

# ────────────────────────────────────────────────────────────────────────
# Test 1 — clones gpakosz/.tmux and creates symlink on first run
# ────────────────────────────────────────────────────────────────────────
test_clones_gpakosz_and_symlinks() {
  echo "Test 1: clones gpakosz config and symlinks ~/.tmux.conf"
  setup_tmux
  _assert_file_exists "$HOME/.tmux"
  _assert_symlink_to  "$HOME/.tmux.conf" ".tmux/.tmux.conf"
  _pass "gpakosz config cloned and ~/.tmux.conf is a symlink"
}

# ────────────────────────────────────────────────────────────────────────
# Test 2 — appends the 4 custom shellgun lines to ~/.tmux.conf
# ────────────────────────────────────────────────────────────────────────
test_appends_custom_config() {
  echo "Test 2: appends custom shellgun tmux config"
  local line
  for line in "${CUSTOM_LINES[@]}"; do
    _assert_contains "$line" "$HOME/.tmux.conf"
  done
  _pass "all 4 custom lines present in ~/.tmux.conf"
}

# ────────────────────────────────────────────────────────────────────────
# Test 3 — idempotent: re-running setup_tmux does NOT duplicate lines
# ────────────────────────────────────────────────────────────────────────
test_idempotent() {
  echo "Test 3: idempotent (no duplicate appends on re-run)"
  local before after hits line
  before=$(wc -l < "$HOME/.tmux.conf" | tr -d ' ')
  setup_tmux   # second run — should be a no-op for the custom block
  after=$(wc -l < "$HOME/.tmux.conf" | tr -d ' ')
  [[ "$before" == "$after" ]] \
    || _fail "line count grew on re-run: $before → $after"

  for line in "${CUSTOM_LINES[@]}"; do
    hits=$(grep -cF -- "$line" "$HOME/.tmux.conf" || true)
    [[ "$hits" == "1" ]] || _fail "line '$line' appears $hits times, expected 1"
  done
  _pass "re-running setup_tmux is a no-op"
}

# ────────────────────────────────────────────────────────────────────────
# Test 4 — symlink survives re-run
# ────────────────────────────────────────────────────────────────────────
test_symlink_preserved() {
  echo "Test 4: ~/.tmux.conf symlink preserved on re-run"
  _assert_symlink_to "$HOME/.tmux.conf" ".tmux/.tmux.conf"
  _pass "symlink still points to ~/.tmux/.tmux.conf"
}

# ── Run all tests ──────────────────────────────────────────────────────
test_clones_gpakosz_and_symlinks
test_appends_custom_config
test_idempotent
test_symlink_preserved

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  All 4 tests passed ✓"
echo "═══════════════════════════════════════════════════════════"