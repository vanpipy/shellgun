#!/usr/bin/env bash
#
# Common functions and variables for SpeckitConfigure
# This is sourced by bin/speckit-configure and individual phases
#

# ============================================================
# Color output
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================
# Default values
# ============================================================
PROJECT_DIR=""
PROJECT_NAME=""
PROGRAMMING_LANG="rust"
DOCS_LANG="en"
AI_AGENT="opencode"
FORCE_MODE=""
IGNORE_AGENT_TOOLS=""

# ============================================================
# Supported languages with their test frameworks
# ============================================================
declare -A LANG_CONFIG
LANG_CONFIG["rust"]="cargo-test|doc-test|miri"
LANG_CONFIG["python"]="pytest|doctest|mypy"
LANG_CONFIG["javascript"]="jest|vitest|eslint"
LANG_CONFIG["typescript"]="jest|vitest|tsc"
LANG_CONFIG["go"]="go-test|godoc|go-vet"
LANG_CONFIG["java"]="junit|maven|spotbugs"
LANG_CONFIG["csharp"]="xunit|dotnet-test|roslyn"
LANG_CONFIG["c"]="cmake|ctest|valgrind"
LANG_CONFIG["cpp"]="gtest|cmake|valgrind"
LANG_CONFIG["zig"]="zig-test|zig-doc"

# ============================================================
# Supported AI agents (Speckit supported)
# ============================================================
SUPPORTED_AI_AGENTS=("claude" "copilot" "gemini" "opencode" "cursor" "codex" "qwen" "qoder" "tabnine" "kiro" "pi" "forge" "goose" "mistral")

# ============================================================
# Helper functions
# ============================================================
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_help_header() { echo -e "${CYAN}$1${NC}"; }

show_lang_help() {
    echo ""
    print_help_header "╔═══════════════════════════════════════════════════════════════════╗"
    print_help_header "║         Supported Languages - Scaffolding Status                  ║"
    print_help_header "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Full Scaffolding (create_language_specific_config):"
    echo "  rust, python, go, javascript, typescript, java, csharp, c, cpp, zig"
    echo ""
    echo "Note: All languages support constitution and config creation."
    echo "      Languages marked above have additional project scaffolding."
    echo ""
}

show_help() {
    echo ""
    print_help_header "╔═══════════════════════════════════════════════════════════════════╗"
    print_help_header "║         SpecKit Initializer - Multi-Language Support            ║"
    print_help_header "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Usage:"
    echo "  ./speckit-configure [OPTIONS] <project-dir>"
    echo ""
    echo "Options:"
    echo "  -l, --lang <language>     Programming language (default: rust)"
    echo "  -d, --docs <en|zh>        Documentation language (default: en)"
    echo "  -a, --ai <agent>          AI coding agent for SpecKit (default: opencode)"
    echo "  -f, --force               Force init in non-empty directory"
    echo "  --ignore-agent-tools      Skip checking for AI agent tools"
    echo "  --lang-help               Show which languages have full scaffolding"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Supported Languages:"
    echo "  $(printf "%s  " "${!LANG_CONFIG[@]}" | sed 's/  $//')"
    echo ""
    echo "Supported AI Agents:"
    echo "  $(printf "%s  " "${SUPPORTED_AI_AGENTS[@]}" | sed 's/  $//')"
    echo ""
    echo "Examples:"
    echo "  ./speckit-configure my-project                              # Rust, en, opencode"
    echo "  ./speckit-configure -l python -d zh my-project              # Python with Chinese docs"
    echo "  ./speckit-configure -l go -a claude my-project             # Go with Claude AI"
    echo "  ./speckit-configure -l java -a copilot --force .            # Java in current dir with force"
    echo "  ./speckit-configure -l typescript -a cursor --ignore-agent-tools my-app"
    echo ""
    echo "Note: AI agent integration is handled by SpecKit directly."
    echo "      This script only passes the --ai parameter to 'specify init'."
    echo ""
}

# ============================================================
# Validation functions
# ============================================================
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check bash version (need 4.0+ for associative arrays)
    local major="${BASH_VERSION%%.*}"
    if [[ -z "$BASH_VERSION" ]] || [[ "$major" -lt 4 ]]; then
        print_error "Bash 4.0+ required, found version ${BASH_VERSION:-unknown}"
        exit 1
    fi

    if ! command -v uvx &> /dev/null; then
        print_error "uvx not found. Please install uv first:"
        echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi

    if ! command -v git &> /dev/null; then
        print_error "git not found. Please install git first."
        exit 1
    fi

    print_success "Prerequisites checked"
}

validate_language() {
    local lang="$1"
    if [[ -n "${LANG_CONFIG[$lang]}" ]]; then
        return 0
    fi
    return 1
}

validate_ai_agent() {
    local agent="$1"
    for supported in "${SUPPORTED_AI_AGENTS[@]}"; do
        if [[ "$supported" == "$agent" ]]; then
            return 0
        fi
    done
    return 1
}

validate_non_empty() {
    local value="$1"
    local name="$2"
    if [[ -z "$value" ]]; then
        print_error "$name requires a value"
        return 1
    fi
    if [[ "$value" == -* ]]; then
        print_error "$name value cannot start with '-': $value"
        return 1
    fi
    return 0
}

# ============================================================
# Argument parsing
# ============================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -l|--lang)
                if ! validate_non_empty "$2" "-l|--lang"; then
                    exit 1
                fi
                PROGRAMMING_LANG="$2"
                shift 2
                ;;
            -d|--docs)
                if ! validate_non_empty "$2" "-d|--docs"; then
                    exit 1
                fi
                DOCS_LANG="$2"
                shift 2
                ;;
            -a|--ai)
                if ! validate_non_empty "$2" "-a|--ai"; then
                    exit 1
                fi
                AI_AGENT="$2"
                shift 2
                ;;
            -f|--force)
                FORCE_MODE="--force"
                shift
                ;;
            --ignore-agent-tools)
                IGNORE_AGENT_TOOLS="--ignore-agent-tools"
                shift
                ;;
            --lang-help)
                show_lang_help
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$PROJECT_DIR" ]]; then
                    PROJECT_DIR="$1"
                else
                    print_error "Multiple project directories specified"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate project directory
    if [[ -z "$PROJECT_DIR" ]]; then
        print_error "Project directory is required"
        show_help
        exit 1
    fi

    # Extract project name from directory path
    PROJECT_NAME="$(basename "$PROJECT_DIR")"
}