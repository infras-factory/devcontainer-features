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
echo -e "${PURPLE}  {{ cookiecutter.feature_name|upper }} DEBIAN TESTS${NC}"
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

check "os is debian" grep -q "debian" /etc/os-release
log_success "Running on Debian"

# ----------------------------------------
# Basic Installation Checks
# ----------------------------------------
log_info "Checking basic installations..."

# TODO: Add Debian-specific installation checks
# Example:
# check "debian package installed" dpkg -l | grep -q "package-name"

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
# Debian-Specific Tests
# ----------------------------------------
log_info "Running Debian-specific tests..."

# TODO: Add tests specific to Debian
# Example:
# check "debian tool works" bash -c "debian-specific-tool --version"

# ----------------------------------------
# Final Summary
# ----------------------------------------
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}  DEBIAN TEST EXECUTION COMPLETE${NC}"
echo -e "${PURPLE}========================================${NC}"

# Report result
reportResults
