#!/bin/bash

# Post-create script for devcontainer
# This script runs once when the container is created

set -e

# Enable logging
LOG_FILE="/tmp/post-create.log"
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
echo -e "${PURPLE}     {{ cookiecutter.feature_name|upper }} POST-CREATE SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}======================================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# ----------------------------------------
# Setup {{ cookiecutter.feature_name }} for User
# ----------------------------------------
log_info "Setting up {{ cookiecutter.feature_name }} for user..."

# TODO: Add your user-specific setup here
# Example: Install user-level tools
# if [ ! -f "$USER_HOME/.local/bin/tool" ]; then
#     log_info "Installing user tool..."
#     mkdir -p "$USER_HOME/.local/bin"
#     curl -fsSL https://example.com/tool -o "$USER_HOME/.local/bin/tool"
#     chmod +x "$USER_HOME/.local/bin/tool"
#     log_success "Tool installed"
# fi

# ----------------------------------------
# Copy Configuration Files
# ----------------------------------------
CONFIG_SOURCE="/usr/local/share/{{ cookiecutter.feature_id }}/configs"
if [ -d "$CONFIG_SOURCE" ]; then
    log_info "Copying configuration files..."

    # TODO: Copy your specific config files
    # Example:
    # if [ -f "$CONFIG_SOURCE/.config-file" ]; then
    #     cp "$CONFIG_SOURCE/.config-file" "$USER_HOME/"
    #     log_success "Configuration file copied"
    # fi
fi

# ----------------------------------------
# Setup User Environment
# ----------------------------------------
log_info "Setting up user environment..."

# TODO: Add environment setup
# Example: Add to shell configuration
# if ! grep -q "{{ cookiecutter.feature_id }}" "$USER_HOME/.bashrc"; then
#     echo "" >> "$USER_HOME/.bashrc"
#     echo "# {{ cookiecutter.feature_name }} configuration" >> "$USER_HOME/.bashrc"
#     echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$USER_HOME/.bashrc"
#     log_success "Shell configuration updated"
# fi

# ----------------------------------------
# Final Setup and Validation
# ----------------------------------------
log_info "Performing final setup..."

# TODO: Add validation checks
# Example:
# if command -v your-tool &> /dev/null; then
#     log_success "{{ cookiecutter.feature_name }} is properly configured"
# else
#     log_error "{{ cookiecutter.feature_name }} setup failed"
#     exit 1
# fi

echo ""
log_success "Post-create script completed successfully!"
log_info "Log file saved to: $LOG_FILE"
echo ""
