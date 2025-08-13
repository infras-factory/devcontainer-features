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
TOTAL_STEPS=4

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
# scripts/post-create.sh - Post-creation script for Riso Bootstrap
# ----------------------------------------
update_latest_libs() {
    local step_id=$1
    log_section "Executing: $step_id/$TOTAL_STEPS Updating latest libraries..."
    # Update command for the latest libraries
    npm install -g npm@latest
    log_section "Executing: $step_id/$TOTAL_STEPS Update completed"
}

# Function to setup Claude CLI tool
setup_claude() {
    local step_id=$1

    log_section "Executing: $step_id/$TOTAL_STEPS Installing Claude Code..."

    # Install Claude CLI globally with specific version
    npm install -g @anthropic-ai/claude-code@1.0.67

    log_section "Executing: $step_id/$TOTAL_STEPS Installation completed"
    return 0
}

# Function to setup enhanced shell
setup_enhanced_shell() {
    local step_id=$1
    local enhancement_level="${SHELL_ENHANCEMENT_LEVEL:-standard}"

    log_section "Executing: $step_id/$TOTAL_STEPS Setting up enhanced shell ($enhancement_level)..."

    # Wait for Oh My Zsh to be ready
    local max_wait=30
    local wait_count=0
    while [ ! -d "$HOME/.oh-my-zsh" ] && [ $wait_count -lt $max_wait ]; do
        log_info "Waiting for Oh My Zsh installation..."
        sleep 1
        wait_count=$((wait_count + 1))
    done

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_error "Oh My Zsh not found. Skipping shell enhancements."
        return 1
    fi

    # Set ZSH_CUSTOM
    export ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

    # STEP 1: Install Powerlevel10k (mandatory for all levels)
    log_subsection "Installing Powerlevel10k theme..."
    if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
        log_success "Powerlevel10k installed"
    else
        log_info "Powerlevel10k already installed"
    fi

    # STEP 2: Install plugins based on level
    log_subsection "Installing plugins for $enhancement_level level..."

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
            log_info "$desc already installed"
        fi
    done

    # STEP 3: Configure .zshrc
    log_subsection "Configuring shell..."
    configure_enhanced_zshrc "$enhancement_level"

    # STEP 4: Copy Powerlevel10k configuration
    log_subsection "Setting up Powerlevel10k configuration..."
    if [ -f "$FEATURE_TMP_DIR/configs/.p10k.zsh" ]; then
        cp "$FEATURE_TMP_DIR/configs/.p10k.zsh" "$HOME/.p10k.zsh"
        log_success "Powerlevel10k configuration copied"
    else
        log_warning "Powerlevel10k config not found, user will need to run 'p10k configure'"
    fi

    # STEP 5: Install dependencies for plugins if needed
    if [ "$enhancement_level" = "poweruser" ]; then
        local pkg_manager
        pkg_manager=$(detect_package_manager_cached)
        log_info "Detected package manager: $pkg_manager"

        # Install bat for zsh-bat plugin
        if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
            log_info "Installing bat for zsh-bat plugin..."
            if install_package_smart "bat" "$pkg_manager"; then
                log_success "bat installed successfully"
            else
                log_warning "Failed to install bat, zsh-bat plugin may not work properly"
            fi
        fi
    fi

    log_section "Executing: $step_id/$TOTAL_STEPS Shell enhancement completed"
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
alias cc="claude 'MANDATORY: Follow ~/.claude/CLAUDE.md workflow EXACTLY:
  1. START with STEP 0: SESSION INITIALIZATION.
  2. ALWAYS use AI-Supervisor for task analysis (STEP 1)
  3. CONFIRM understanding before executing (STEP 2)
  4. Use AI-Supervisor for verification when needed (STEP 4)
  5. Complete with proper cleanup (STEP 5)
  CRITICAL: Never skip steps.'"
EOF
    fi
}

# Function to setup Serena coding agent toolkit
setup_serena() {
    local step_id=$1

    log_section "Executing: $step_id/$TOTAL_STEPS Setting up Serena coding agent..."

    # Install UV if not present
    if ! command -v uv &> /dev/null; then
        log_info "Installing UV package manager..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Generate mock files if in test mode and no source files exist
    if [ "$IS_TEST_MODE" = "true" ]; then
        # Check if workspace is empty or has no source files
        if [ -z "$(find . -maxdepth 1 -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.java' 2>/dev/null)" ]; then
            log_info "Test mode: Generating mock Python project for Serena..."
            # Import mock generator only when needed
            # shellcheck source=/dev/null
            source "$FEATURE_TMP_DIR/utils/layer-0/mock-generator.sh"
            generate_mock_python_project "."
        fi
    fi

    # Setup Serena for this project
    log_subsection "Initializing Serena for project..."
    uvx --from git+https://github.com/oraios/serena serena project generate-yml

    log_subsection "Indexing project for semantic analysis..."
    uvx --from git+https://github.com/oraios/serena serena project index

    # Add Serena MCP server to Claude Code
    log_subsection "Registering Serena with Claude Code..."
    if ! claude mcp add serena "uvx --from git+https://github.com/oraios/serena serena mcp --project $(pwd)"; then
        log_info "Warning: Failed to register Serena MCP server with Claude Code. This may be expected if already registered. Please check the output above for details."
    fi

    log_section "Executing: $step_id/$TOTAL_STEPS Serena setup completed"
    return 0
}

main() {
    # Auto-detect project name if not provided
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(pwd)")
    fi

    update_latest_libs 1
    setup_claude 2
    setup_enhanced_shell 3

    # Setup Serena if enabled
    if [ "$ENABLE_SERENA" = "true" ]; then
        setup_serena 4
    else
        log_section "Skipped: 4/$TOTAL_STEPS Serena setup (not enabled)"
    fi
}

log_phase "RISO BOOTSTRAP POST-CREATE SCRIPT EXECUTION"

main "$@"
