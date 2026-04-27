#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/src"
PROJECT_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"
OUT_FILE="$PROJECT_ROOT/lib/speckit-configure"
COMMON_SRC="$SRC_DIR/common.sh"

if [[ ! -f "$COMMON_SRC" ]]; then
  echo "common.sh not found at $COMMON_SRC" >&2
  exit 1
fi

mkdir -p "$PROJECT_ROOT/lib"

echo "[BUILD] Generating single-file dispatcher: $OUT_FILE"

COMMON_BODY_FILE="$(mktemp)"
trap 'rm -f "$COMMON_BODY_FILE"' EXIT
if head -n1 "$COMMON_SRC" | grep -q '^#!'; then
  tail -n +2 "$COMMON_SRC" > "$COMMON_BODY_FILE"
else
  cat "$COMMON_SRC" > "$COMMON_BODY_FILE"
fi

extract_phase_fn() {
  local phase_file="$1"
  local tmp="$(mktemp)"
  tail -n +2 "$phase_file" > "$tmp"
  sed -Ei \
    -e '/^[[:space:]]*SCRIPT_DIR=.*BASH_SOURCE\[0\].*$/d' \
    -e '/^[[:space:]]*source[[:space:]]+"?\$SCRIPT_DIR\/common\.sh"?[[:space:]]*$/d' \
    "$tmp"
  sed -E -i '/^\s*if \[\[ "\$\{BASH_SOURCE\[0\]\}" == "\$0" \]\]; then/,/^\s*fi\s*$/d' "$tmp"
  cat "$tmp"
  rm -f "$tmp"
}

cat > "$OUT_FILE" << 'HEADER'
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Single-file SpecKit initializer
HEADER

cat "$COMMON_BODY_FILE" >> "$OUT_FILE"
echo >> "$OUT_FILE"

cat >> "$OUT_FILE" << 'PHASE_SUMMARY'
phase_summary() {
    local project_dir="$1"
    local lang="$2"
    local docs_lang="$3"
    local ai_agent="$4"

    echo ""
    echo "=========================================="
    print_success "Setup Complete!"
    echo "=========================================="
    echo "Project Directory: $project_dir"
    echo "Programming Language: $lang"
    echo "Documentation Language: $docs_lang"
    echo "AI Agent: $ai_agent"
    echo ""
    echo "Next steps:"
    echo "  cd $project_dir"
    echo "  # Use your AI agent with SpecKit commands:"
    echo "  /speckit.constitution  # Review the constitution"
    echo "  /speckit.specify       # Start your first feature"
    echo "  /speckit.plan          # Create implementation plan"
    echo "  /speckit.tasks         # Break down into tasks"
    echo "  /speckit.implement     # Execute implementation"
    echo ""
    echo "TDD is enabled: Always write tests first!"
    echo "=========================================="
}
PHASE_SUMMARY

for pf in "$SRC_DIR"/phase-*.sh; do
  echo >> "$OUT_FILE"
  echo "# ==== $(basename "$pf") ====" >> "$OUT_FILE"
  extract_phase_fn "$pf" >> "$OUT_FILE"
  echo >> "$OUT_FILE"
done

cat >> "$OUT_FILE" << 'MAIN'
main() {
    parse_args "$@"

    echo ""
    echo "=========================================="
    echo "       SpecKit Initializer v1.0"
    echo "  Multi-Language Support with TDD"
    echo "=========================================="
    echo ""

    if ! validate_language "$PROGRAMMING_LANG"; then
        print_error "Unsupported language: $PROGRAMMING_LANG"
        echo "Supported languages: ${!LANG_CONFIG[*]}"
        exit 1
    fi

    if [[ "$DOCS_LANG" != "en" ]] && [[ "$DOCS_LANG" != "zh" ]]; then
        print_error "Documentation language must be 'en' or 'zh'"
        exit 1
    fi

    if ! validate_ai_agent "$AI_AGENT"; then
        print_warning "AI agent '$AI_AGENT' may not be supported by SpecKit"
        echo "Supported agents according to SpecKit: ${SUPPORTED_AI_AGENTS[*]}"
        echo "Continuing anyway - Speckit will validate..."
        echo ""
    fi

    if [[ "$PROJECT_DIR" != "." ]]; then
        mkdir -p "$PROJECT_DIR"
        print_info "Created directory: $PROJECT_DIR"
    fi

    check_prerequisites
    phase_constitution "$PROJECT_DIR" "$PROGRAMMING_LANG" "$DOCS_LANG"
    phase_scaffold "$PROJECT_DIR" "$PROGRAMMING_LANG"
    phase_config "$PROJECT_DIR" "$PROGRAMMING_LANG" "$DOCS_LANG" "$AI_AGENT"
    phase_init "$PROJECT_DIR" "$AI_AGENT" "$FORCE_MODE" "$IGNORE_AGENT_TOOLS"
    phase_summary "$PROJECT_DIR" "$PROGRAMMING_LANG" "$DOCS_LANG" "$AI_AGENT"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
MAIN

chmod +x "$OUT_FILE"
echo "[BUILD] Done."
