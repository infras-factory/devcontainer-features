#!/bin/bash

# Post-attach script for devcontainer
# This script runs every time when attaching to the container

set -e

# Enable logging
LOG_FILE="/tmp/post-attach.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

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

echo -e "${PURPLE}======================================================${NC}"
echo -e "${PURPLE}     RISO OH MY ZSH POST-ATTACH SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}======================================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# Set ZSH_CUSTOM path
export ZSH_CUSTOM=${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}

# ----------------------------------------
# Final Verification
# ----------------------------------------
echo ""
log_info "Performing Oh My Zsh setup verification..."

# Verify Oh My Zsh
if [ -d "$USER_HOME/.oh-my-zsh" ]; then
    log_success "Oh My Zsh: Installed"
else
    log_error "Oh My Zsh: Not found"
fi

# Verify theme
if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    log_success "Powerlevel10k theme: Installed"
else
    log_error "Powerlevel10k theme: Not found"
fi

# Verify plugins
echo ""
log_info "Verifying plugins:"
plugins=(
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "fast-syntax-highlighting"
    "zsh-autocomplete"
    "zsh-bat"
    "you-should-use"
)

for plugin_name in "${plugins[@]}"; do
    if [ -d "$ZSH_CUSTOM/plugins/$plugin_name" ]; then
        log_success "  $plugin_name: Installed"
    else
        log_error "  $plugin_name: Not found"
    fi
done

# Verify tools
echo ""
log_info "Verifying tools:"
if command -v bat &> /dev/null || command -v batcat &> /dev/null; then
    log_success "bat: Installed"
else
    log_warning "bat: Not found"
fi

# Check if setup was completed
if [ -f "$USER_HOME/.ohmyzsh_setup_complete" ]; then
    log_success "Initial setup was completed successfully"
else
    log_warning "Initial setup marker not found"
fi

# Check current shell
echo ""
log_info "Current shell: $SHELL"
if [[ "$SHELL" == *"zsh"* ]]; then
    log_success "Zsh is the default shell"
else
    log_warning "Zsh is not the default shell"
    log_info "You can switch to zsh by running: exec zsh"
fi

# ----------------------------------------
# Display Welcome Message
# ----------------------------------------
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Welcome to your development container with Oh My ZSH!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📋 Status Report:${NC}"
echo -e "   • Feature: Oh My ZSH"
echo -e "   • Version: 1.0.0"
echo -e "   • User: $CURRENT_USER"
echo -e "   • Home: $USER_HOME"
echo ""
# Only show reminder if not already in zsh
if [[ "$SHELL" != *"zsh"* ]]; then
echo -e "${CYAN}🔧 Quick Commands:${NC}"
echo -e "   ${CYAN}Run 'exec zsh' to start using Oh My Zsh${NC}"
echo ""
fi
echo -e "${CYAN}📚 Resources:${NC}"
echo -e "   • Documentation: https://github.com/infras-factory/devcontainer-features/tree/main/src/ohmyzsh"
echo -e "   • Logs: $LOG_FILE"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
