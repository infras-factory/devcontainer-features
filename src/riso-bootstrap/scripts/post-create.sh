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
    "$FEATURE_TMP_DIR/utils/layer-0/package-manager.sh:Package manager utilities"
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
# Calculate total steps dynamically (AFTER importing options)
# ----------------------------------------
BASE_STEPS=("update_latest_libs" "setup_claude" "setup_enhanced_shell")
# Optionally add conditional steps
if [ "$ENABLE_SERENA" = "true" ]; then
    BASE_STEPS+=("setup_serena")
fi
TOTAL_STEPS=${#BASE_STEPS[@]}

# ----------------------------------------
# scripts/post-create.sh - Post-creation script for Riso Bootstrap
# ----------------------------------------
update_latest_libs() {
    local step_id=$1
    set_step_context "update_latest_libs"

    log_info "Updating npm to latest version..."
    npm install -g npm@latest
    log_success "npm updated successfully"
}

# Function to setup Claude CLI tool
setup_claude() {
    local step_id=$1
    set_step_context "setup_claude"

    log_info "Installing Claude Code CLI tool..."

    # Install Claude CLI globally with specific version
    npm install -g @anthropic-ai/claude-code

    log_success "Claude Code installed successfully"
    return 0
}

# Function to setup enhanced shell
setup_enhanced_shell() {
    local step_id=$1
    local enhancement_level="${SHELL_ENHANCEMENT_LEVEL:-standard}"
    set_step_context "setup_enhanced_shell"

    log_info "Setting up enhanced shell (level: $enhancement_level)..."

    # Wait for Oh My Zsh to be ready
    log_group_start "Waiting for Oh My Zsh"
    local max_wait=30
    local wait_count=0
    while [ ! -d "$HOME/.oh-my-zsh" ] && [ $wait_count -lt $max_wait ]; do
        log_info "Waiting for Oh My Zsh installation... ($wait_count/$max_wait)"
        sleep 1
        wait_count=$((wait_count + 1))
    done

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_error "Oh My Zsh not found. Skipping shell enhancements."
        log_group_end "Waiting for Oh My Zsh"
        return 1
    fi
    log_success "Oh My Zsh found"
    log_group_end "Waiting for Oh My Zsh"

    # Set ZSH_CUSTOM
    export ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

    # STEP 1: Install Powerlevel10k
    log_group_start "Installing Powerlevel10k theme"
    if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
        log_success "Powerlevel10k installed"
    else
        log_notice "Powerlevel10k already installed"
    fi
    log_group_end "Installing Powerlevel10k theme"

    # STEP 2: Install plugins based on level
    log_group_start "Installing plugins for $enhancement_level level"

    # Define plugins for each level
    local plugins_minimal=(
        "zsh-users/zsh-autosuggestions|zsh-autosuggestions|Auto-suggestions"
        "MichaelAquilina/zsh-you-should-use|you-should-use|Alias reminder"
    )

    local plugins_standard=(
        "${plugins_minimal[@]}"
        "zsh-users/zsh-syntax-highlighting|zsh-syntax-highlighting|Syntax highlighting"
        "zsh-users/zsh-history-substring-search|zsh-history-substring-search|Better history search"
    )

    local plugins_poweruser=(
        "${plugins_standard[@]}"
        "marlonrichert/zsh-autocomplete|zsh-autocomplete|Auto-complete (PERFORMANCE IMPACT)"
        "fdellwing/zsh-bat|zsh-bat|Bat integration"
    )

    # Select plugins based on level
    local selected_plugins=()
    case "$enhancement_level" in
        minimal)
            selected_plugins=("${plugins_minimal[@]}")
            ;;
        standard)
            selected_plugins=("${plugins_standard[@]}")
            ;;
        poweruser)
            selected_plugins=("${plugins_poweruser[@]}")
            log_warning "Poweruser level may impact shell performance, especially zsh-autocomplete"
            ;;
    esac

    # Install selected plugins
    for plugin_info in "${selected_plugins[@]}"; do
        IFS='|' read -r repo name desc <<< "$plugin_info"
        if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
            if git clone --depth=1 "https://github.com/$repo" "$ZSH_CUSTOM/plugins/$name" 2>/dev/null; then
                log_success "$desc installed"
            else
                log_warning "Failed to install $desc"
            fi
        else
            log_notice "$desc already installed"
        fi
    done
    log_group_end "Installing plugins for $enhancement_level level"

    # STEP 3: Configure .zshrc
    log_group_start "Configuring shell"
    configure_enhanced_zshrc "$enhancement_level"
    log_group_end "Configuring shell"

    # STEP 4: Copy Powerlevel10k configuration
    log_group_start "Setting up Powerlevel10k configuration"
    if [ -f "$FEATURE_TMP_DIR/configs/.p10k.zsh" ]; then
        cp "$FEATURE_TMP_DIR/configs/.p10k.zsh" "$HOME/.p10k.zsh"
        log_success "Powerlevel10k configuration copied"
    else
        log_warning "Powerlevel10k config not found, user will need to run 'p10k configure'"
    fi
    log_group_end "Setting up Powerlevel10k configuration"

    # STEP 5: Install dependencies for plugins if needed
    if [ "$enhancement_level" = "poweruser" ]; then
        log_group_start "Installing plugin dependencies"
        local pkg_manager
        pkg_manager=$(detect_package_manager_cached)
        log_debug "Detected package manager: $pkg_manager"

        # Install bat for zsh-bat plugin
        if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
            log_info "Installing bat for zsh-bat plugin..."
            if install_package_smart "bat" "$pkg_manager"; then
                log_success "bat installed successfully"
            else
                log_warning "Failed to install bat, zsh-bat plugin may not work properly"
            fi
        else
            log_notice "bat already available"
        fi
        log_group_end "Installing plugin dependencies"
    fi

    log_success "Shell enhancement completed successfully"
    return 0
}

# Function to configure .zshrc
configure_enhanced_zshrc() {
    local level=$1

    # Backup existing .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    fi

    # Update theme
    if grep -q "^ZSH_THEME=" "$HOME/.zshrc"; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
    fi

    # Build plugin list
    local plugin_list="git"
    case "$level" in
        minimal)
            plugin_list="$plugin_list zsh-autosuggestions you-should-use"
            ;;
        standard)
            plugin_list="$plugin_list zsh-autosuggestions you-should-use zsh-syntax-highlighting zsh-history-substring-search"
            ;;
        poweruser)
            plugin_list="$plugin_list zsh-autosuggestions you-should-use zsh-syntax-highlighting zsh-history-substring-search zsh-autocomplete zsh-bat"
            ;;
    esac

    # Update plugins
    if grep -q "^plugins=" "$HOME/.zshrc"; then
        sed -i "s/^plugins=.*/plugins=($plugin_list)/" "$HOME/.zshrc"
    else
        echo "plugins=($plugin_list)" >> "$HOME/.zshrc"
    fi

    # Add configurations
    if ! grep -q "# Riso Bootstrap Shell Enhancements" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" << 'EOF'

# Riso Bootstrap Shell Enhancements
# Plugin configurations
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export YSU_MESSAGE_POSITION="after"
export YSU_MODE=ALL

# Better history
export HISTSIZE=100000
export SAVEHIST=100000
export HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Key bindings for history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Claude Code alias with workflow enforcement
alias cc="claude 'MANDATORY: Follow ~/.claude/CLAUDE.md enhanced workflow:
    1. INIT: Load .context/ + ~/.claude/risotech-standards/ modular system
    2. ROUTE: New features → SDD (/spec-*) | Quick fixes → AI-Supervisor
    3. EXECUTE: With constitutional compliance (9 articles)
    4. VERIFY: AI-Supervisor loads Core→UserPatterns→HighPriority→Flexible
    5. TDD: Enforce test-first, track with TodoWrite
    CRITICAL: SDD for features, modular standards for quality, no exceptions on 100% items.
    THEN RETURN Context Loaded'"
EOF
    fi
}

# Function to setup Serena coding agent toolkit
setup_serena() {
    # shellcheck disable=SC2034
    local step_id=$1
    # Note: step_id parameter kept for consistency but not used in new logging style
    set_step_context "setup_serena"

    # Check if Serena is already setup in this project
    if [ -d ".serena" ]; then
        log_notice "Serena already configured for this project (found .serena directory)"
        log_info "Skipping Serena setup..."
        return 0
    fi

    log_info "Setting up Serena coding agent..."

    # Install UV if not present
    log_group_start "Installing UV package manager"
    if ! command -v uv &> /dev/null; then
        log_info "Installing UV package manager..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        log_success "UV package manager installed"
    else
        log_notice "UV package manager already available"
    fi
    log_group_end "Installing UV package manager"

    # Setup Serena for this project
    log_group_start "Initializing Serena"
    log_info "Generating Serena configuration for project..."
    uvx --from git+https://github.com/oraios/serena serena project generate-yml
    log_success "Serena configuration generated"
    log_group_end "Initializing Serena"

    log_group_start "Indexing project"
    log_info "Indexing project for semantic analysis..."
    uvx --from git+https://github.com/oraios/serena serena project index
    log_success "Project indexed successfully"
    log_group_end "Indexing project"

    log_success "Serena setup completed successfully"
    return 0
}

generate_mock_projects_for_testing() {
    local test_dir="/tmp/riso-test-projects"
    export DEBUG="true"
    # shellcheck source=/dev/null
    source "$FEATURE_TMP_DIR/utils/layer-0/mock-generator.sh"

    log_group_start "Mock Projects Generation for Testing"

    local current_workspace
    current_workspace=$(pwd)
    if [[ "$current_workspace" == /workspaces/* ]]; then
        log_info "Generating mock projects in root directory"
        log_info "  • Creating mock Python project in current devcontainer test workspace: $current_workspace"
        generate_mock_project "python" "flask" "$current_workspace" ""
    fi

    # Remove existing test directory if it exists
    if [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
        log_info "Cleaned existing test directory"
    fi

    # Create test directory
    mkdir -p "$test_dir"
    log_info "Created test directory: $test_dir"

    # Generate mock projects in test directory
    log_info "Generating mock projects in test directory"
    log_info "  • DevContainer Feature project"
    generate_mock_project "bash" "devcontainer" "$test_dir/devcontainer-feature" ""

    log_info "  • Python Flask project"
    generate_mock_project "python" "flask" "$test_dir/python-flask" ""

    log_info "  • Node.js Express project"
    generate_mock_project "nodejs" "express" "$test_dir/nodejs-express" ""

    log_info "  • Multi-tech combo project"
    generate_mock_project "combo" "all-tech" "$test_dir/combo-project" ""

    log_info "  • Bash Scripts project"
    generate_mock_project "bash" "scripts" "$test_dir/bash-scripts" ""

    log_info "  • Template project"
    generate_mock_project "template" "cookiecutter" "$test_dir/template-project" ""

    log_group_end "Mock Projects Generation for Testing"
}

main() {
    # Auto-detect project name if not provided
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(pwd)")
    fi

    # Optional: Generate mock projects for testing if in test mode
    if [ "$IS_TEST_MODE" = "true" ]; then
        log_step_start "Generate mock projects for testing" 0 0
        generate_mock_projects_for_testing
        log_step_end "Mock projects generation" "success"
    fi

    set_workflow_context "post-create.sh"
    log_workflow_start "Riso Bootstrap Post-Create Setup"

    local current_step=0

    # Step 1: Update libraries
    log_step_start "Update latest libraries" $((++current_step)) "$TOTAL_STEPS"
    log_group_start "Package management"
    update_latest_libs $current_step
    log_group_end "Package management"
    log_step_end "Update latest libraries" "success"

    # Step 2: Setup Claude
    log_step_start "Install Claude Code" $((++current_step)) "$TOTAL_STEPS"
    log_group_start "Claude CLI installation"
    setup_claude $current_step
    log_group_end "Claude CLI installation"
    log_step_end "Claude Code installation" "success"

    # Step 3: Setup enhanced shell
    log_step_start "Setup enhanced shell ($SHELL_ENHANCEMENT_LEVEL)" $((++current_step)) "$TOTAL_STEPS"
    setup_enhanced_shell $current_step
    log_step_end "Shell enhancement" "success"

    # Conditional Step: Setup Serena
    if [ "$ENABLE_SERENA" = "true" ]; then
        log_step_start "Setup Serena coding agent" $((++current_step)) "$TOTAL_STEPS"
        setup_serena $current_step
        log_step_end "Serena setup" "success"
    else
        log_notice "Serena setup skipped (not enabled)"
    fi

    log_workflow_end "Riso Bootstrap Post-Create Setup" "success"
}

main "$@"
