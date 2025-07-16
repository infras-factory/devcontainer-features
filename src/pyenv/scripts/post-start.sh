#!/bin/bash

# Post-start script for devcontainer
# This script runs every time the container starts

set -e

# Enable logging
LOG_FILE="/tmp/post-start.log"
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
echo -e "${PURPLE}     PYTHON VERSION MANAGEMENT (PYENV) POST-START SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}======================================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running as user: $CURRENT_USER"

# ----------------------------------------
# Setup Shell Configuration
# ----------------------------------------
log_info "Setting up shell configuration..."

# Function to add pyenv configuration to a shell rc file
add_pyenv_to_shell() {
    local RC_FILE="$1"
    local SHELL_NAME="$2"

    if [ -f "$RC_FILE" ]; then
        if ! grep -q "PYENV_ROOT" "$RC_FILE"; then
            log_info "Adding pyenv configuration to $SHELL_NAME..."
            cat >> "$RC_FILE" << 'EOF'

# Pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
EOF
            log_success "Pyenv configuration added to $SHELL_NAME"
        else
            log_info "Pyenv configuration already exists in $SHELL_NAME"
        fi
    fi
}

# Add to bash configuration
add_pyenv_to_shell "$USER_HOME/.bashrc" "bash"

# Add to zsh configuration if zsh is installed
if command -v zsh &> /dev/null; then
    add_pyenv_to_shell "$USER_HOME/.zshrc" "zsh"
fi

# ----------------------------------------
# Set correct ownership
# ----------------------------------------
log_info "Setting correct ownership for pyenv directory..."
PYENV_ROOT="$USER_HOME/.pyenv"
if [ -d "$PYENV_ROOT" ]; then
    chown -R "$CURRENT_USER:$CURRENT_USER" "$PYENV_ROOT"
    log_success "Ownership set for pyenv directory"
else
    log_warning "Pyenv directory not found at $PYENV_ROOT"
fi

# ----------------------------------------
# Start Services
# ----------------------------------------
log_info "Starting services..."

# TODO: Start any background services or daemons
# Example:
# if ! pgrep -f "service-name" > /dev/null; then
#     log_info "Starting service..."
#     service-name --daemon &
#     log_success "Service started"
# else
#     log_info "Service is already running"
# fi

log_success "Post-start script completed successfully"
