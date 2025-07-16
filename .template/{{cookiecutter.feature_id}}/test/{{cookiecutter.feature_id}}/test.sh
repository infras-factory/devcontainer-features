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
echo -e "${PURPLE}     {{ cookiecutter.feature_name|upper }} FEATURE TESTS${NC}"
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

# TODO: Add your basic installation checks
# Example:
# check "tool installed" which your-tool
# check "config directory exists" test -d "$USER_HOME/.{{ cookiecutter.feature_id }}"
# check "config file exists" test -f "$USER_HOME/.{{ cookiecutter.feature_id }}/config"

# ----------------------------------------
# System Files Checks
# ----------------------------------------
log_info "Checking system files..."

check "feature directory exists" test -d "/usr/local/share/{{ cookiecutter.feature_id }}"
check "scripts directory exists" test -d "/usr/local/share/{{ cookiecutter.feature_id }}/scripts"
check "configs directory exists" test -d "/usr/local/share/{{ cookiecutter.feature_id }}/configs"
check "post-create script exists" test -f "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-create.sh"
check "post-start script exists" test -f "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-start.sh"
check "post-attach script exists" test -f "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-attach.sh"

# ----------------------------------------
# Permissions Checks
# ----------------------------------------
log_info "Checking file permissions..."

check "post-create script executable" test -x "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-create.sh"
check "post-start script executable" test -x "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-start.sh"
check "post-attach script executable" test -x "/usr/local/share/{{ cookiecutter.feature_id }}/scripts/post-attach.sh"

# ----------------------------------------
# Configuration Checks
# ----------------------------------------
log_info "Checking configurations..."

# TODO: Add your configuration checks
# Example:
# check "config value set" bash -c "grep -q 'SETTING_NAME' $USER_HOME/.bashrc"
# check "environment variable" bash -c "grep -q 'export {{ cookiecutter.feature_id|upper }}_HOME' $USER_HOME/.bashrc"

# ----------------------------------------
# Functional Tests
# ----------------------------------------
log_info "Running functional tests..."

# TODO: Add your functional tests
# Example:
# check "tool runs successfully" bash -c "your-tool --version"
# check "feature loads without errors" bash -c "your-tool test 2>&1"

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
