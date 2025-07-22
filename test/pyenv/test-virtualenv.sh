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
echo -e "${PURPLE}     PYENV AUTO CREATE VIRTUALENV TEST${NC}"
echo -e "${PURPLE}========================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running tests as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# Setup pyenv environment
export PYENV_ROOT="$USER_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv
if [ -f "$PYENV_ROOT/bin/pyenv" ]; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
fi

# ----------------------------------------
# Test autoCreateVirtualenv Option
# ----------------------------------------
log_info "Testing autoCreateVirtualenv option..."

# Check that pyenv is available
check "pyenv command available" command -v pyenv

# Check pyenv-virtualenv plugin is installed
check "pyenv-virtualenv plugin exists" test -d "$USER_HOME/.pyenv/plugins/pyenv-virtualenv"

# Check virtualenv was created automatically
# The virtualenv name should be auto-generated based on project name and Python version
check "virtualenv list command works" bash -c "pyenv virtualenvs"

# Check if a virtualenv is active
log_info "Checking for active virtual environment..."

# Get the current Python version
PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
log_info "Current Python version: $PYTHON_VERSION"

# The virtualenv is created but set as local to workspace directory
# In test environment, we might not be in the workspace directory
# So we'll check if virtualenvs exist rather than if one is active
log_info "Checking for created virtual environments..."

# Test that we can create a new virtualenv manually
log_info "Testing manual virtualenv creation..."
check "create test virtualenv" bash -c "pyenv virtualenv test-env"
check "test virtualenv exists" bash -c "pyenv virtualenvs | grep -q 'test-env'"

# Test setting the virtualenv as local version
log_info "Testing virtualenv local activation..."
check "set test virtualenv as local" bash -c "pyenv local test-env"
check "verify local virtualenv is set" bash -c "pyenv version-name | grep -q 'test-env'"

# Reset to global version
check "unset local version" bash -c "pyenv local --unset || true"

# Cleanup test virtualenv
log_info "Cleaning up test virtualenv..."
bash -c "pyenv virtualenv-delete -f test-env" || true

# ----------------------------------------
# Test autoCreateVirtualenv feature
# ----------------------------------------
log_info "Testing autoCreateVirtualenv feature..."

# Check if auto-created virtualenv exists
# The feature should create a virtualenv with auto-generated name
# Format: projectname-py{version} or venv-py{version}
EXPECTED_PATTERN="py310"  # For Python 3.10.12 specified in scenario

check "auto-created virtualenv exists" bash -c "pyenv virtualenvs | grep -q '$EXPECTED_PATTERN'"

# Check feature options file
log_info "Checking feature configuration..."
if [ -f "/usr/local/share/pyenv/configs/feature-options.env" ]; then
    check "feature options file exists" test -f "/usr/local/share/pyenv/configs/feature-options.env"
    log_info "Feature options:"
    cat /usr/local/share/pyenv/configs/feature-options.env
fi

# ----------------------------------------
# Final Summary
# ----------------------------------------
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}     TEST EXECUTION COMPLETE${NC}"
echo -e "${PURPLE}========================================${NC}"

# Report result
reportResults
