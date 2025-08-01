#!/bin/bash

set -e

# ----------------------------------------
# Local Variables
# ----------------------------------------
FEATURE_TMP_DIR="/usr/local/share/riso-bootstrap"
# Files to import for install.sh usage (format: "path:description")
# shellcheck disable=SC2034
IMPORT_FILES=(
    "$FEATURE_TMP_DIR/utils/layer-0/logger.sh:Logger utilities"
    "$FEATURE_TMP_DIR/utils/layer-0/commands.sh:Command utilities"
    "$FEATURE_TMP_DIR/riso-bootstrap-options.env:Feature options"
)

# ----------------------------------------
# Local Helper Functions
# ----------------------------------------
# Function to import (source) utility files
import_utility_files() {
    local -n files_array=$1

    for file_info in "${files_array[@]}"; do
        local file_path="${file_info%:*}"
        # shellcheck disable=SC2034
        local file_desc="${file_info#*:}"

        # shellcheck source=/dev/null disable=SC1091
        source "${file_path}"
    done

    return 0
}

# ----------------------------------------
# Validate and Import Required Utilities
# ----------------------------------------
import_utility_files IMPORT_FILES

# ----------------------------------------
# scripts/post-attach.sh - Post-attach script for Riso Bootstrap
# ----------------------------------------
# Function to display welcome message and feature status
display_feature_status() {
    # Auto-detect project name if not provided
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(pwd)")
    fi

    # ----------------------------------------
    # Display Welcome Message
    # ----------------------------------------
    echo ""
    local welcome_msg="🚀 Welcome to Riso Bootstrap Development Environment!"
    display_bold_message "$welcome_msg"

    echo ""
    log_section "Installed Features and Tools"

    # Common Utils Feature
    log_subsection "Common Utilities"
    if check_command "zsh"; then
        log_section_info "✓ Zsh shell: $(get_version zsh)"
        if [ -d "$HOME/.oh-my-zsh" ]; then
            log_section_info "✓ Oh My Zsh: installed"
        fi
        if [ "$SHELL" = "$(which zsh)" ]; then
            log_section_info "✓ Default shell: Zsh"
        fi
    else
        log_section_info "✗ Zsh not found"
    fi

    # Git Feature
    log_subsection "Version Control"
    if check_command "git"; then
        log_section_info "✓ Git: $(get_version git)"
        # Check if current directory is a git repository
        if git rev-parse --git-dir &>/dev/null; then
            local branch
            branch=$(git branch --show-current 2>/dev/null || echo "unknown")
            log_section_info "  Current branch: $branch"
        fi
    else
        log_section_info "✗ Git not found"
    fi

    # GitHub CLI Feature
    if check_command "gh"; then
        log_section_info "✓ GitHub CLI: $(get_version gh)"
        # Check if authenticated
        if gh auth status &>/dev/null; then
            log_section_info "  GitHub CLI: authenticated"
        else
            log_section_info "  GitHub CLI: not authenticated (run 'gh auth login')"
        fi
    else
        log_section_info "✗ GitHub CLI not found"
    fi

    # Node.js Feature
    log_subsection "Node.js Development"
    if check_command "node"; then
        log_section_info "✓ Node.js: $(get_version node)"
    else
        log_section_info "✗ Node.js not found"
    fi

    if check_command "npm"; then
        log_section_info "✓ npm: $(get_version npm)"
    else
        log_section_info "✗ npm not found"
    fi

    if [ -d "/usr/local/share/nvm" ]; then
        log_section_info "✓ NVM: installed at /usr/local/share/nvm"
    else
        log_section_info "  NVM: not found"
    fi

    # Python Feature
    log_subsection "Python Development"
    if check_command "python"; then
        log_section_info "✓ Python: $(get_version python)"
    else
        log_section_info "✗ Python not found"
    fi

    if check_command "pip"; then
        log_section_info "✓ pip: $(get_version pip)"
    else
        log_section_info "✗ pip not found"
    fi

    if check_command "pre-commit"; then
        log_section_info "✓ pre-commit: $(get_version pre-commit)"
        # Check if pre-commit is configured in the current repo
        if [ -f ".pre-commit-config.yaml" ]; then
            log_section_info "  pre-commit config: found"
        fi
    else
        log_section_info "  pre-commit: not installed"
    fi

    # Claude CLI
    log_subsection "AI Development Assistant"
    if check_command "claude"; then
        log_section_info "✓ Claude CLI: $(get_version claude)"
        # Check if Claude configuration exists
        if [ -f "$HOME/.claude.json" ] || [ -d "$HOME/.claude" ]; then
            log_section_info "  Configuration: mounted from host"
        else
            log_section_info "  Configuration: not found (run 'claude login' to configure)"
        fi
    else
        log_section_info "✗ Claude CLI not installed"
        log_section_info "  Run 'npm install -g @anthropic-ai/claude-code' to install"
    fi

    echo ""
    log_section "⚡ Quick Commands"
    log_section_info "• GitHub auth:     gh auth login"
    log_section_info "• Claude CLI:      claude --help"
    log_section_info "• Pre-commit:      pre-commit install"
    log_section_info "• Node version:    nvm list / nvm use"

    echo ""
    log_success "Happy coding! 🚀"
    echo ""
}

main() {
    display_feature_status
}

main "$@"
