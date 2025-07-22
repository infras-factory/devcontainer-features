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
echo -e "${PURPLE}     PYENV CUSTOM VIRTUALENV NAME TEST${NC}"
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
# Test virtualenvName Option
# ----------------------------------------
log_info "Testing virtualenvName option with custom name 'myproject-dev'..."

# Check that pyenv is available
check "pyenv command available" command -v pyenv

# Check pyenv-virtualenv plugin is installed
check "pyenv-virtualenv plugin exists" test -d "$USER_HOME/.pyenv/plugins/pyenv-virtualenv"

# Expected virtualenv name from the scenario
EXPECTED_VENV_NAME="myproject-dev"

# Check feature configuration first
log_info "Checking feature configuration..."
if [ -f "/usr/local/share/pyenv/configs/feature-options.env" ]; then
    log_info "Feature options:"
    cat /usr/local/share/pyenv/configs/feature-options.env
fi

# Check if the custom named virtualenv exists
check "custom virtualenv 'myproject-dev' exists" bash -c "pyenv virtualenvs | grep -q '$EXPECTED_VENV_NAME'"

# The virtualenv might be set as local to workspace directory
# So we check if it exists first
log_info "Checking custom virtualenv in workspace context..."

# Check workspace directory for local python version
WORKSPACE_DIR="/workspaces"
if [ -d "$WORKSPACE_DIR" ]; then
    for dir in "$WORKSPACE_DIR"/*; do
        if [ -d "$dir" ] && [ -f "$dir/.python-version" ]; then
            LOCAL_VERSION=$(cat "$dir/.python-version")
            log_info "Found local Python version in $dir: $LOCAL_VERSION"
            if [ "$LOCAL_VERSION" = "$EXPECTED_VENV_NAME" ]; then
                log_success "Custom virtualenv is set as local version in workspace"
            fi
        fi
    done
fi

# Test activating the custom virtualenv manually
log_info "Testing manual activation of custom virtualenv..."
check "set custom virtualenv as local" bash -c "pyenv local $EXPECTED_VENV_NAME"
check "verify custom virtualenv is active" bash -c "pyenv version-name | grep -q '$EXPECTED_VENV_NAME'"

# Now test pip in the activated virtualenv
check "pip command available" command -v pip
check "pip works in virtualenv" pip --version

# Install a test package to verify virtualenv isolation
check "install test package in custom virtualenv" pip install wheel --quiet
check "wheel module can be imported" python -c "import wheel; print('wheel imported from custom virtualenv')"

# Verify the Python version in the virtualenv
log_info "Verifying Python version in custom virtualenv..."
PYTHON_VERSION=$(python --version 2>&1)
log_info "Python version in virtualenv: $PYTHON_VERSION"
check "python version check" python --version

# Clean up - unset local version
check "unset local version" bash -c "pyenv local --unset || true"

# ----------------------------------------
# Final Summary
# ----------------------------------------
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}     TEST EXECUTION COMPLETE${NC}"
echo -e "${PURPLE}========================================${NC}"

# Report result
reportResults
