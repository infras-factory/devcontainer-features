#!/bin/bash

# Post-create script for devcontainer
# This script runs once when the container is created

set -e

# Enable logging
LOG_FILE="/tmp/post-create.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

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

echo -e "${PURPLE}======================================================${NC}"
echo -e "${PURPLE}     PYTHON VERSION MANAGEMENT (PYENV) POST-CREATE SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}======================================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# ----------------------------------------
# Install pyenv for User
# ----------------------------------------
log_info "Installing pyenv for user: $CURRENT_USER"

# Set pyenv environment variables
export PYENV_ROOT="$USER_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Clone pyenv repository
if [ ! -d "$PYENV_ROOT" ]; then
    log_info "Cloning pyenv repository..."
    git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT" || {
        log_error "Failed to clone pyenv repository"
        exit 1
    }
    log_success "Pyenv repository cloned successfully"
else
    log_info "Pyenv already exists, updating..."
    cd "$PYENV_ROOT" && git pull
fi

# ----------------------------------------
# Install pyenv plugins
# ----------------------------------------
log_info "Installing pyenv plugins..."

# Install pyenv-virtualenv plugin
VIRTUALENV_PLUGIN="$PYENV_ROOT/plugins/pyenv-virtualenv"
if [ ! -d "$VIRTUALENV_PLUGIN" ]; then
    log_info "Installing pyenv-virtualenv plugin..."
    git clone https://github.com/pyenv/pyenv-virtualenv.git "$VIRTUALENV_PLUGIN" || {
        log_error "Failed to install pyenv-virtualenv plugin"
        exit 1
    }
    log_success "pyenv-virtualenv plugin installed successfully"
else
    log_info "pyenv-virtualenv already exists, updating..."
    cd "$VIRTUALENV_PLUGIN" && git pull
fi

# Install pyenv-doctor plugin (for diagnostics)
DOCTOR_PLUGIN="$PYENV_ROOT/plugins/pyenv-doctor"
if [ ! -d "$DOCTOR_PLUGIN" ]; then
    log_info "Installing pyenv-doctor plugin..."
    git clone https://github.com/pyenv/pyenv-doctor.git "$DOCTOR_PLUGIN" || {
        log_warning "Failed to install pyenv-doctor plugin (optional)"
    }
    log_success "pyenv-doctor plugin installed successfully"
else
    log_info "pyenv-doctor already exists, updating..."
    cd "$DOCTOR_PLUGIN" && git pull
fi

# Install pyenv-update plugin (for easy updates)
UPDATE_PLUGIN="$PYENV_ROOT/plugins/pyenv-update"
if [ ! -d "$UPDATE_PLUGIN" ]; then
    log_info "Installing pyenv-update plugin..."
    git clone https://github.com/pyenv/pyenv-update.git "$UPDATE_PLUGIN" || {
        log_warning "Failed to install pyenv-update plugin (optional)"
    }
    log_success "pyenv-update plugin installed successfully"
else
    log_info "pyenv-update already exists, updating..."
    cd "$UPDATE_PLUGIN" && git pull
fi

# ----------------------------------------
# Load Feature Configuration
# ----------------------------------------
log_info "Loading feature configuration..."

FEATURE_OPTIONS_FILE="/usr/local/share/pyenv/configs/feature-options.env"
if [ -f "$FEATURE_OPTIONS_FILE" ]; then
    # shellcheck disable=SC1090,SC1091
    source "$FEATURE_OPTIONS_FILE"
    log_info "Feature options loaded from: $FEATURE_OPTIONS_FILE"
    log_info "  - DEFAULTPYTHONVERSION: ${DEFAULTPYTHONVERSION:-'(not set)'}"
else
    log_warning "Feature options file not found: $FEATURE_OPTIONS_FILE"
    DEFAULTPYTHONVERSION=""
fi

# ----------------------------------------
# Install Default Python Version
# ----------------------------------------
log_info "Setting up default Python version..."

# Initialize pyenv for this session
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)" 2>/dev/null || true

# Check for .python-version file in the workspace
WORKSPACE_DIR="/workspaces"
PYTHON_VERSION_FILE=""
PYTHON_VERSION=""

# Priority 1: Look for .python-version file in workspace directories
if [ -d "$WORKSPACE_DIR" ]; then
    for dir in "$WORKSPACE_DIR"/*; do
        if [ -f "$dir/.python-version" ]; then
            PYTHON_VERSION_FILE="$dir/.python-version"
            PYTHON_VERSION=$(tr -d '[:space:]' < "$PYTHON_VERSION_FILE")
            log_info "Found .python-version file at: $PYTHON_VERSION_FILE"
            log_info "Python version specified: $PYTHON_VERSION"
            log_info "Priority: Using .python-version file"
            break
        fi
    done
fi

# Priority 2: Use defaultPythonVersion option if no .python-version file found
if [ -z "$PYTHON_VERSION" ] && [ -n "$DEFAULTPYTHONVERSION" ]; then
    PYTHON_VERSION="$DEFAULTPYTHONVERSION"
    log_info "Using defaultPythonVersion option: $PYTHON_VERSION"
    log_info "Priority: Using defaultPythonVersion feature option"
fi

# Priority 3: Use latest LTS if neither .python-version nor defaultPythonVersion are set
if [ -z "$PYTHON_VERSION" ]; then
    log_info "No .python-version file or defaultPythonVersion option found, determining latest LTS Python version..."
    # Get the latest stable Python version (excluding pre-releases, dev, and rc versions)
    PYTHON_VERSION=$(pyenv install --list | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | xargs)
    log_info "Latest LTS Python version: $PYTHON_VERSION"
    log_info "Priority: Using latest LTS version"
fi

# Install the Python version if not already installed
if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
    log_info "Installing Python $PYTHON_VERSION..."
    pyenv install "$PYTHON_VERSION" || {
        log_error "Failed to install Python $PYTHON_VERSION"
        exit 1
    }
    log_success "Python $PYTHON_VERSION installed successfully"
else
    log_info "Python $PYTHON_VERSION is already installed"
fi

# Set as global default
log_info "Setting Python $PYTHON_VERSION as global default..."
pyenv global "$PYTHON_VERSION"
log_success "Python $PYTHON_VERSION set as global default"

# Verify installation
CURRENT_PYTHON=$(pyenv version-name)
log_info "Current Python version: $CURRENT_PYTHON"

echo ""
log_success "Post-create script completed!"
log_info "Log file saved to: $LOG_FILE"
log_info "Run post-attach script for verification"
echo ""
