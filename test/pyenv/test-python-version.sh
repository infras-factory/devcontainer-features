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
echo -e "${PURPLE}     PYENV DEFAULT PYTHON VERSION TEST${NC}"
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
# Test defaultPythonVersion Option
# ----------------------------------------
log_info "Testing defaultPythonVersion option..."

# Check that pyenv is available
check "pyenv command available" command -v pyenv

# Check Python 3.11.5 is installed (as specified in scenario)
check "Python 3.11.5 is installed" bash -c "pyenv versions | grep -q '3.11.5'"

# Check Python 3.11.5 is set as global version
check "Python 3.11.5 is global version" bash -c "pyenv global | grep -q '3.11.5'"

# Verify python command points to the correct version
check "python command works" command -v python
check "python version is 3.11.5" bash -c "python --version 2>&1 | grep -q '3.11.5'"

# Check pip is available
check "pip command available" command -v pip
check "pip works correctly" pip --version

# Test installing a simple package
log_info "Testing pip package installation..."
check "pip install requests works" pip install requests --quiet
check "requests module can be imported" python -c "import requests; print('requests imported successfully')"

# ----------------------------------------
# Final Summary
# ----------------------------------------
echo ""
echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}     TEST EXECUTION COMPLETE${NC}"
echo -e "${PURPLE}========================================${NC}"

# Report result
reportResults
