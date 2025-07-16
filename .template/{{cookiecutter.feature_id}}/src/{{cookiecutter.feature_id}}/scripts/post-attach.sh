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
echo -e "${PURPLE}     {{ cookiecutter.feature_name|upper }} POST-ATTACH SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}======================================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# ----------------------------------------
# Final Verification
# ----------------------------------------
echo ""
log_info "Performing {{ cookiecutter.feature_name }} setup verification..."

# TODO: Add your verification checks here
# Example: Verify installation
# if [ -d "$USER_HOME/.{{ cookiecutter.feature_id }}" ]; then
#     log_success "{{ cookiecutter.feature_name }}: Installed"
# else
#     log_error "{{ cookiecutter.feature_name }}: Not found"
# fi

# Example: Verify tools
# if command -v your-tool &> /dev/null; then
#     VERSION=$(your-tool --version)
#     log_success "Tool: Installed (version: $VERSION)"
# else
#     log_error "Tool: Not found"
# fi

# ----------------------------------------
# Display Welcome Message
# ----------------------------------------
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🚀 Welcome to your development container with {{ cookiecutter.feature_name }}!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📋 Status Report:${NC}"
echo -e "   • Feature: {{ cookiecutter.feature_name }}"
echo -e "   • Version: {{ cookiecutter.feature_version }}"
echo -e "   • User: $CURRENT_USER"
echo -e "   • Home: $USER_HOME"
echo ""
echo -e "${CYAN}🔧 Quick Commands:${NC}"
echo -e "   TODO: Add helpful commands here"
echo ""
echo -e "${CYAN}📚 Resources:${NC}"
echo -e "   • Documentation: {{ cookiecutter.documentation_url }}"
echo -e "   • Logs: $LOG_FILE"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
