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

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}     POST-START SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}========================================${NC}"

# ----------------------------------------
# Powerlevel10k Setup
# ----------------------------------------
# Source Powerlevel10k instant prompt if available
if [ -f ~/.p10k.zsh ] && [ ! -f ~/.p10k-instant-prompt-"${USER}".zsh ]; then
    log_info "Enabling Powerlevel10k instant prompt..."
    # This ensures instant prompt works on subsequent shells
    touch ~/.p10k-instant-prompt-"${USER}".zsh
fi

echo ""
log_success "Post-start script completed successfully!"
log_info "Log file saved to: $LOG_FILE"
echo ""
