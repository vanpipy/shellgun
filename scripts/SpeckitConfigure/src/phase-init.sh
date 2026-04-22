#!/usr/bin/env bash
#
# Phase: Run SpecKit initialization
# Source this from the main script, don't run directly
#

# ============================================================
# Run SpecKit init
# ============================================================
phase_init() {
    local project_dir="$1"
    local ai_agent="$2"
    local force_mode="$3"
    local ignore_agent_tools="$4"

    print_info "Running SpecKit initialization with AI: $ai_agent..."

    # Save current directory
    local saved_dir="$(pwd)"

    cd "$project_dir"

    # Build the specify init command using array
    local -a cmd=("uvx" "--from" "git+https://github.com/github/spec-kit.git" "specify" "init" "." "--ai" "$ai_agent")

    if [[ -n "$force_mode" ]]; then
        cmd+=("--force")
    fi

    if [[ -n "$ignore_agent_tools" ]]; then
        cmd+=("--ignore-agent-tools")
    fi

    print_info "Executing: ${cmd[*]}"
    "${cmd[@]}"

    # Return to original directory
    cd "$saved_dir"

    print_success "SpecKit initialization complete"
}