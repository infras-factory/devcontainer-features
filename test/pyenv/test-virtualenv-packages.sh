#!/bin/bash

set -e

# Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Color codes
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${CYAN}[INFO]${NC} $1"
}

log_info "Testing virtual environment packages installation..."

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")

# Setup pyenv environment
export PYENV_ROOT="$USER_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv
if [ -f "$PYENV_ROOT/bin/pyenv" ]; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
fi

# Test that pyenv is available
check "pyenv command available" command -v pyenv

# Check that a virtualenv was created (autoCreateVirtualenv should be true)
check "virtualenv exists" bash -c "pyenv virtualenvs | grep -q py"

# Get the virtualenv name
VENV_NAME=$(pyenv virtualenvs --bare | grep py | head -1)
log_info "Found virtualenv: $VENV_NAME"

# The virtualenv should already be active (set as global or local)
CURRENT_VERSION=$(pyenv version-name)
log_info "Current Python version: $CURRENT_VERSION"

# Test requests installation
check "requests is installed in virtualenv" pip show requests

# Test pytest installation
check "pytest is installed in virtualenv" pip show pytest
check "pytest command available" command -v pytest

# Report result
reportResults
