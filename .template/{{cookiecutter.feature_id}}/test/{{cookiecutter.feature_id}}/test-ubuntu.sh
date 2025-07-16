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
echo -e "${PURPLE}  {{ cookiecutter.feature_name|upper }} UBUNTU TESTS${NC}"
echo -e "${PURPLE}========================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running tests as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# ----------------------------------------
# OS Verification
# ----------------------------------------
log_info "Verifying OS..."

check "os is ubuntu" grep -q "ubuntu" /etc/os-release
log_success "Running on Ubuntu"

# ----------------------------------------
# Basic Installation Checks
# ----------------------------------------
log_info "Checking basic installations..."

# TODO: Add Ubuntu-specific installation checks
# Example:
# check "ubuntu package installed" dpkg -l | grep -q "package-name"

# ----------------------------------------
# System Files Checks
# ----------------------------------------
log_info "Checking system files..."

check "feature directory exists" test -d "/usr/local/share/{{ cookiecutter.feature_id }}"
check "scripts directory exists" test -d "/usr/local/share/{{ cookiecutter.feature_id }}/scripts"
check "configs directory exists" test -d "/usr/local/share/{{ cookiecutter.feature_id }}/configs"

# ----------------------------------------
# Permissions Checks
# ----------------------------------------
log_info "Checking file permissions..."

check "post-create script executable" test -x "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-create.sh"
check "post-start script executable" test -x "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-start.sh"
check "post-attach script executable" test -x "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-attach.sh"

# ----------------------------------------
# User Setup Checks
# ----------------------------------------
log_info "Checking user setup..."

check "test user exists" id -u vscode

# ----------------------------------------
# Ubuntu-Specific Tests
# ----------------------------------------
log_info "Running Ubuntu-specific tests..."

# TODO: Add tests specific to Ubuntu
# Example:
# check "ubuntu tool works" bash -c "ubuntu-specific-tool --version"

# ----------------------------------------
# Final Summary
# ----------------------------------------
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}  UBUNTU TEST EXECUTION COMPLETE${NC}"
echo -e "${PURPLE}========================================${NC}"

# Report result
reportResults
