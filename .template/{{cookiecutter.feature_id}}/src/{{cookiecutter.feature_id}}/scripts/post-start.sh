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
echo -e "${PURPLE}     {{ cookiecutter.feature_name|upper }} POST-START SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}======================================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running as user: $CURRENT_USER"

# ----------------------------------------
# Environment Setup
# ----------------------------------------
log_info "Setting up environment..."

# TODO: Add environment setup that needs to run on every start
# Example: Export environment variables
# export PATH="$USER_HOME/.local/bin:$PATH"

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

echo ""
log_success "Post-start script completed successfully!"
log_info "Log file saved to: $LOG_FILE"
echo ""
