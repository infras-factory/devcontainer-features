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

log_info "Testing global packages installation..."

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")

# Setup pyenv environment
export PYENV_ROOT="$USER_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv
if [ -f "$PYENV_ROOT/bin/pyenv" ]; then
    eval "$(pyenv init -)"
fi

# Test that pyenv is available
check "pyenv command available" command -v pyenv

# Test pip-tools installation
check "pip-tools is installed" pip show pip-tools

# Test black installation
check "black is installed" pip show black

# Test that pip-compile command is available
pyenv rehash
check "pip-compile command available" command -v pip-compile

# Test that black command is available
check "black command available" command -v black

# Report result
reportResults
