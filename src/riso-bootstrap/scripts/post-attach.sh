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

    # Shell Enhancement Features
    log_subsection "Shell Enhancement ($SHELL_ENHANCEMENT_LEVEL)"

    # Get ZSH_CUSTOM path
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Check for Powerlevel10k theme (all levels)
    if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        log_section_info "✓ Powerlevel10k theme: installed"
        if [ -f "$HOME/.p10k.zsh" ]; then
            log_section_info "✓ P10k configuration: ready"
        fi
    else
        log_section_info "✗ Powerlevel10k theme not found"
    fi

    # Check for plugins based on enhancement level
    case "$SHELL_ENHANCEMENT_LEVEL" in
        "minimal")
            # Essential plugins
            if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
                log_section_info "✓ Autosuggestions: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/you-should-use" ]; then
                log_section_info "✓ Command hints: enabled"
            fi
            ;;
        "standard")
            # Standard plugins
            if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
                log_section_info "✓ Autosuggestions: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
                log_section_info "✓ Syntax highlighting: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/you-should-use" ]; then
                log_section_info "✓ Command hints: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
                log_section_info "✓ History search: enhanced"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/z" ]; then
                log_section_info "✓ Z directory jumper: enabled"
            fi
            ;;
        "poweruser")
            # All plugins
            if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
                log_section_info "✓ Autosuggestions: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
                log_section_info "✓ Syntax highlighting: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/you-should-use" ]; then
                log_section_info "✓ Command hints: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
                log_section_info "✓ History search: enhanced"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/z" ]; then
                log_section_info "✓ Z directory jumper: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/fzf-zsh-plugin" ]; then
                log_section_info "✓ FZF integration: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/git-extras" ]; then
                log_section_info "✓ Git extras: enabled"
            fi
            if [ -d "$ZSH_CUSTOM/plugins/zsh-vi-mode" ]; then
                log_section_info "✓ Vi mode: enabled"
            fi
            ;;
    esac

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

    # Gemini CLI
    log_subsection "AI Development Assistant"
    if check_command "gemini"; then
        log_section_info "✓ Gemini CLI: $(get_version gemini)"
        # Check if Gemini Oauth exists
        if [ -f "$HOME/.gemini/oauth_creds.json" ] || [ -d "$HOME/.gemini" ]; then
            log_section_info "  OAuth: mounted from host"
        else
            log_section_info "  OAuth: not found (run 'gemini login' to configure)"
        fi
    else
        log_section_info "✗ Gemini CLI not installed"
        log_section_info "  Run 'npm install -g @google/gemini-cli' to install"
    fi

    # Serena Coding Agent
    if [ "$ENABLE_SERENA" = "true" ]; then
        log_subsection "Serena Coding Agent"
        if check_command "uv"; then
            log_section_info "✓ UV package manager: installed"
            # Check if Serena project is configured
            if [ -f ".serena/project.yml" ]; then
                log_section_info "✓ Serena: configured for this project"
                log_section_info "  Project indexed and ready for semantic analysis"
                # Check MCP server registration
                if claude mcp list 2>/dev/null | grep -q "serena"; then
                    log_section_info "✓ MCP server: registered with Claude Code"
                else
                    log_section_info "  MCP server: not registered"
                fi
            else
                log_section_info "⚠ Serena: not configured for this project"
                log_section_info "  Run 'uvx --from git+https://github.com/oraios/serena serena project index'"
            fi
        else
            log_section_info "✗ UV not installed (required for Serena)"
        fi
    fi

    echo ""
    log_section "⚡ Quick Commands"
    log_section_info "• GitHub auth:     gh auth login"
    log_section_info "• Claude CLI:      claude --help"
    log_section_info "• Pre-commit:      pre-commit install"
    log_section_info "• Node version:    nvm list / nvm use"

    # Shell-specific commands based on enhancement level
    if [ "$SHELL_ENHANCEMENT_LEVEL" != "minimal" ]; then
        log_section_info "• Jump to dir:     z <partial-path>"
    fi
    if [ "$SHELL_ENHANCEMENT_LEVEL" = "poweruser" ]; then
        log_section_info "• Fuzzy search:    Ctrl+R (history), Ctrl+T (files)"
        log_section_info "• Vi mode:         Press ESC in terminal"
    fi

    if [ "$ENABLE_SERENA" = "true" ]; then
        log_section_info "• Serena help:     uvx --from git+https://github.com/oraios/serena serena --help"
        log_section_info "• Re-index code:   uvx --from git+https://github.com/oraios/serena serena project index"
    fi

    echo ""
    log_success "Happy coding! 🚀"
    echo ""
}

main() {
    set_workflow_context "post-attach.sh"
    log_workflow_start "Riso Bootstrap Post-Attach Status"

    log_step_start "Display feature status and welcome message" 1 1
    display_feature_status
    log_step_end "Status display" "success"

    log_workflow_end "Riso Bootstrap Post-Attach Status" "success"
}

main "$@"
