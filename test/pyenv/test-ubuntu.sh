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
echo -e "${PURPLE}  PYTHON VERSION MANAGEMENT (PYENV) UBUNTU TESTS${NC}"
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

# Check pyenv installation
check "pyenv directory exists" test -d "$USER_HOME/.pyenv"
check "pyenv binary exists" test -f "$USER_HOME/.pyenv/bin/pyenv"

# Check required dependencies for building Python on Ubuntu
check "build-essential installed" dpkg -l | grep -q "build-essential"
check "libssl-dev installed" dpkg -l | grep -q "libssl-dev"
check "zlib1g-dev installed" dpkg -l | grep -q "zlib1g-dev"
check "libbz2-dev installed" dpkg -l | grep -q "libbz2-dev"
check "libreadline-dev installed" dpkg -l | grep -q "libreadline-dev"
check "libsqlite3-dev installed" dpkg -l | grep -q "libsqlite3-dev"
check "libncursesw5-dev installed" dpkg -l | grep -E "libncursesw?5-dev"
check "libffi-dev installed" dpkg -l | grep -q "libffi-dev"
check "liblzma-dev installed" dpkg -l | grep -q "liblzma-dev"

# ----------------------------------------
# System Files Checks
# ----------------------------------------
log_info "Checking system files..."

check "feature directory exists" test -d "/usr/local/share/pyenv"
check "scripts directory exists" test -d "/usr/local/share/pyenv/scripts"
check "configs directory exists" test -d "/usr/local/share/pyenv/configs"

# ----------------------------------------
# Permissions Checks
# ----------------------------------------
log_info "Checking file permissions..."

check "post-create script executable" test -x "/usr/local/share/pyenv/scripts/post-create.sh"
check "post-start script executable" test -x "/usr/local/share/pyenv/scripts/post-start.sh"
check "post-attach script executable" test -x "/usr/local/share/pyenv/scripts/post-attach.sh"

# ----------------------------------------
# User Setup Checks
# ----------------------------------------
log_info "Checking user setup..."

check "test user exists" id -u vscode

# ----------------------------------------
# Ubuntu-Specific Tests
# ----------------------------------------
log_info "Running Ubuntu-specific tests..."

# Source bashrc to get pyenv in PATH
export PYENV_ROOT="$USER_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Check pyenv functionality
check "pyenv works on Ubuntu" bash -c "export PYENV_ROOT='$USER_HOME/.pyenv' && export PATH='$PYENV_ROOT/bin:$PATH' && pyenv --version"
check "pyenv can list versions" bash -c "export PYENV_ROOT='$USER_HOME/.pyenv' && export PATH='$PYENV_ROOT/bin:$PATH' && pyenv install --list | grep -q '3.11'"

# Check shell configuration
check "pyenv configured in .bashrc" bash -c "grep -q 'PYENV_ROOT' $USER_HOME/.bashrc"

# Check pyenv plugins
check "pyenv virtualenv plugin works" bash -c "export PYENV_ROOT='$USER_HOME/.pyenv' && export PATH='$PYENV_ROOT/bin:$PATH' && pyenv virtualenv --help &>/dev/null"

# Ubuntu-specific: Check for additional development tools
check "python3-pip available" dpkg -l | grep -q "python3-pip" || true

# ----------------------------------------
# Final Summary
# ----------------------------------------
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}  UBUNTU TEST EXECUTION COMPLETE${NC}"
echo -e "${PURPLE}========================================${NC}"

# Report result
reportResults
