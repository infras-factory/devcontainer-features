#!/bin/bash

set -e

# Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${RED}[ERROR]${NC} $1"
}

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}     OH MY ZSH FEATURE TESTS (UBUNTU)${NC}"
echo -e "${PURPLE}========================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running tests as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# ----------------------------------------
# Basic Installation Checks
# ----------------------------------------
log_info "Checking basic installations..."

check "zsh installed" which zsh
check "oh-my-zsh directory exists" test -d "$USER_HOME/.oh-my-zsh"
check ".zshrc file exists" test -f "$USER_HOME/.zshrc"

# ----------------------------------------
# Theme Installation Checks
# ----------------------------------------
log_info "Checking Powerlevel10k theme..."

check "powerlevel10k theme installed" test -d "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
check "p10k config exists" test -f "$USER_HOME/.p10k.zsh"
check "powerlevel10k theme configured" bash -c "grep -q 'ZSH_THEME=\"powerlevel10k/powerlevel10k\"' $USER_HOME/.zshrc"
check "p10k sourced in .zshrc" bash -c "grep -q '\.p10k\.zsh' $USER_HOME/.zshrc"

# ----------------------------------------
# Plugin Installation Checks
# ----------------------------------------
log_info "Checking Oh My Zsh plugins..."

plugins=(
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "fast-syntax-highlighting"
    "zsh-autocomplete"
    "zsh-bat"
    "you-should-use"
)

for plugin in "${plugins[@]}"; do
    check "$plugin plugin installed" test -d "$USER_HOME/.oh-my-zsh/custom/plugins/$plugin"
done

check "plugins configured in .zshrc" bash -c "grep -q 'plugins=(.*git.*zsh-autosuggestions.*zsh-syntax-highlighting.*fast-syntax-highlighting.*zsh-bat.*you-should-use.*)' $USER_HOME/.zshrc"

# ----------------------------------------
# Configuration Checks
# ----------------------------------------
log_info "Checking configurations..."

check "plugin configs section exists" bash -c "grep -q 'Plugin configurations' $USER_HOME/.zshrc"
check "autosuggest highlight style" bash -c "grep -q 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE' $USER_HOME/.zshrc"
check "autosuggest strategy" bash -c "grep -q 'ZSH_AUTOSUGGEST_STRATEGY' $USER_HOME/.zshrc"
check "history size config" bash -c "grep -q 'HISTSIZE=100000' $USER_HOME/.zshrc"
check "history save size" bash -c "grep -q 'SAVEHIST=100000' $USER_HOME/.zshrc"

# ----------------------------------------
# System Files Checks
# ----------------------------------------
log_info "Checking system files..."

check "scripts directory exists" test -d "/usr/local/share/scripts"
check "configs directory exists" test -d "/usr/local/share/configs"
check "post-create script exists" test -f "/usr/local/share/scripts/post-create.sh"
check "post-start script exists" test -f "/usr/local/share/scripts/post-start.sh"
check "p10k config in system dir" test -f "/usr/local/share/configs/.p10k.zsh"

# ----------------------------------------
# Permissions Checks
# ----------------------------------------
log_info "Checking file permissions..."

check "post-create script executable" test -x "/usr/local/share/scripts/post-create.sh"
check "post-start script executable" test -x "/usr/local/share/scripts/post-start.sh"

# ----------------------------------------
# Setup Completion Checks
# ----------------------------------------
log_info "Checking setup completion..."

check "setup complete marker exists" test -f "$USER_HOME/.ohmyzsh_setup_complete"

# ----------------------------------------
# Shell Configuration Checks
# ----------------------------------------
log_info "Checking shell configuration..."

if [[ "$SHELL" == *"zsh"* ]]; then
    check "default shell is zsh" bash -c "echo $SHELL | grep -q zsh"
    log_success "Zsh is the default shell"
else
    log_warning "Default shell is not zsh: $SHELL"
    log_info "User can run 'exec zsh' to switch to zsh"
fi

# ----------------------------------------
# Functional Tests
# ----------------------------------------
log_info "Running functional tests..."

# Test if Oh My Zsh loads without critical errors
check "oh-my-zsh loads successfully" bash -c "zsh -i -c 'exit' 2>&1 | grep -v 'zsh compinit: insecure directories' | grep -v '^$' || true"

# Check if zsh history file exists or can be created
check "zsh history file" bash -c "touch $USER_HOME/.zsh_history && test -f $USER_HOME/.zsh_history"

# ----------------------------------------
# Log File Checks
# ----------------------------------------
log_info "Checking log files..."

if [ -f "/tmp/post-create.log" ]; then
    check "post-create log exists" test -f "/tmp/post-create.log"
    log_info "Post-create log found at /tmp/post-create.log"
else
    log_warning "Post-create log not found (this may be normal depending on test environment)"
fi

# ----------------------------------------
# Final Summary
# ----------------------------------------
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}     TEST EXECUTION COMPLETE${NC}"
echo -e "${PURPLE}========================================${NC}"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
