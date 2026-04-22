#!/usr/bin/env bash
#
# Phase: Create SpecKit configuration file
# Source this from the main script, don't run directly
#

# ============================================================
# Create SpecKit config
# ============================================================
phase_config() {
    local project_dir="$1"
    local lang="$2"
    local docs_lang="$3"
    local ai_agent="$4"
    local config_file="$project_dir/.specify/config.json"

    mkdir -p "$(dirname "$config_file")"

    cat > "$config_file" << EOF
{
  "version": "1.0",
  "ai": "$ai_agent",
  "language": {
    "programming": "$lang",
    "code_comments": "en",
    "documentation": "$docs_lang",
    "paths": "en"
  },
  "tdd": {
    "enabled": true,
    "strict_mode": true,
    "red_green_refactor": true
  }
}
EOF
    print_success "SpecKit configuration created"
}