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
echo -e "${PURPLE}     PYTHON VERSION MANAGEMENT (PYENV) FEATURE TESTS${NC}"
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

# Check pyenv directory exists
check "pyenv directory exists" test -d "$USER_HOME/.pyenv"
check "pyenv bin directory exists" test -d "$USER_HOME/.pyenv/bin"
check "pyenv binary exists" test -f "$USER_HOME/.pyenv/bin/pyenv"

# Check pyenv plugins
check "pyenv-virtualenv plugin installed" test -d "$USER_HOME/.pyenv/plugins/pyenv-virtualenv"
check "pyenv-doctor plugin installed" test -d "$USER_HOME/.pyenv/plugins/pyenv-doctor"
check "pyenv-update plugin installed" test -d "$USER_HOME/.pyenv/plugins/pyenv-update"

# ----------------------------------------
# System Files Checks
# ----------------------------------------
log_info "Checking system files..."

check "feature directory exists" test -d "/usr/local/share/pyenv"
check "scripts directory exists" test -d "/usr/local/share/pyenv/scripts"
check "configs directory exists" test -d "/usr/local/share/pyenv/configs"
check "post-create script exists" test -f "/usr/local/share/pyenv/scripts/post-create.sh"
check "post-start script exists" test -f "/usr/local/share/pyenv/scripts/post-start.sh"
check "post-attach script exists" test -f "/usr/local/share/pyenv/scripts/post-attach.sh"

# ----------------------------------------
# Permissions Checks
# ----------------------------------------
log_info "Checking file permissions..."

check "post-create script executable" test -x "/usr/local/share/pyenv/scripts/post-create.sh"
check "post-start script executable" test -x "/usr/local/share/pyenv/scripts/post-start.sh"
check "post-attach script executable" test -x "/usr/local/share/pyenv/scripts/post-attach.sh"

# ----------------------------------------
# Configuration Checks
# ----------------------------------------
log_info "Checking configurations..."

# Check shell configuration
check "pyenv configured in .bashrc" bash -c "grep -q 'PYENV_ROOT' $USER_HOME/.bashrc"
check "pyenv PATH configured in .bashrc" bash -c "grep -q 'PYENV_ROOT/bin' $USER_HOME/.bashrc"
check "pyenv init configured in .bashrc" bash -c "grep -q 'pyenv init' $USER_HOME/.bashrc"
check "pyenv virtualenv-init configured in .bashrc" bash -c "grep -q 'pyenv virtualenv-init' $USER_HOME/.bashrc"

# Check for zsh configuration if zsh exists
if command -v zsh &> /dev/null && [ -f "$USER_HOME/.zshrc" ]; then
    check "pyenv configured in .zshrc" bash -c "grep -q 'PYENV_ROOT' $USER_HOME/.zshrc"
fi

# ----------------------------------------
# Functional Tests
# ----------------------------------------
log_info "Running functional tests..."

# Source bashrc to get pyenv in PATH
export PYENV_ROOT="$USER_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv
if [ -f "$PYENV_ROOT/bin/pyenv" ]; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
fi

# Check pyenv command works
check "pyenv command available" command -v pyenv
check "pyenv version command works" bash -c "export PYENV_ROOT='$USER_HOME/.pyenv' && export PATH='$PYENV_ROOT/bin:$PATH' && pyenv --version"

# Check pyenv plugins work
check "pyenv versions command works" bash -c "export PYENV_ROOT='$USER_HOME/.pyenv' && export PATH='$PYENV_ROOT/bin:$PATH' && eval \"\$(pyenv init -)\" && pyenv versions"
check "pyenv install --list works" bash -c "export PYENV_ROOT='$USER_HOME/.pyenv' && export PATH='$PYENV_ROOT/bin:$PATH' && pyenv install --list | head -n 5"

# Check pyenv virtualenv plugin
check "pyenv virtualenv help works" bash -c "export PYENV_ROOT='$USER_HOME/.pyenv' && export PATH='$PYENV_ROOT/bin:$PATH' && pyenv virtualenv --help &>/dev/null"

# Check ownership
check "pyenv directory owned by user" bash -c "[ \$(stat -c '%U' '$USER_HOME/.pyenv') = '$CURRENT_USER' ]"

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
