#!/bin/bash

# Post-attach script for devcontainer
# This script runs every time when attaching to the container

set -e

# Enable logging
LOG_FILE="/tmp/post-attach.log"
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
echo -e "${PURPLE}     PYTHON VERSION MANAGEMENT (PYENV) POST-ATTACH SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}======================================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# ----------------------------------------
# Verification
# ----------------------------------------
echo ""
log_info "Verifying pyenv installation and configuration..."

# Check if pyenv was installed by post-create
if [ -d "$USER_HOME/.pyenv" ]; then
    log_success "✓ Pyenv directory exists at $USER_HOME/.pyenv"

    # Check for pyenv binary
    if [ -f "$USER_HOME/.pyenv/bin/pyenv" ]; then
        log_success "✓ Pyenv binary found"
    else
        log_error "✗ Pyenv binary not found"
    fi

    # Verify plugins installed by post-create
    if [ -d "$USER_HOME/.pyenv/plugins/pyenv-virtualenv" ]; then
        log_success "✓ pyenv-virtualenv plugin installed"
    else
        log_error "✗ pyenv-virtualenv plugin missing"
    fi

    if [ -d "$USER_HOME/.pyenv/plugins/pyenv-doctor" ]; then
        log_success "✓ pyenv-doctor plugin installed"
    else
        log_warning "⚠ pyenv-doctor plugin missing (optional)"
    fi

    if [ -d "$USER_HOME/.pyenv/plugins/pyenv-update" ]; then
        log_success "✓ pyenv-update plugin installed"
    else
        log_warning "⚠ pyenv-update plugin missing (optional)"
    fi
else
    log_error "✗ Pyenv not found at expected location: $USER_HOME/.pyenv"
fi

# Verify shell configuration done by post-create
echo ""
log_info "Verifying shell configuration..."

if [ -f "$USER_HOME/.bashrc" ] && grep -q "PYENV_ROOT" "$USER_HOME/.bashrc"; then
    log_success "✓ Pyenv configured in .bashrc"
else
    log_error "✗ Pyenv not configured in .bashrc"
fi

if [ -f "$USER_HOME/.zshrc" ] && grep -q "PYENV_ROOT" "$USER_HOME/.zshrc"; then
    log_success "✓ Pyenv configured in .zshrc"
elif [ -f "$USER_HOME/.zshrc" ]; then
    log_warning "⚠ Pyenv not configured in .zshrc"
fi

# Check if pyenv is accessible in current shell
echo ""
log_info "Checking pyenv accessibility..."

# Source bashrc to get pyenv in PATH
if [ -f "$USER_HOME/.bashrc" ]; then
    # shellcheck source=/dev/null
    source "$USER_HOME/.bashrc"
fi

if command -v pyenv &> /dev/null; then
    PYENV_VERSION=$(pyenv --version 2>&1 || echo "Error getting version")
    log_success "✓ Pyenv is accessible: $PYENV_VERSION"

    # Show current Python version
    CURRENT_PYTHON=$(pyenv version-name 2>/dev/null || echo "none")
    log_info "Current Python version: $CURRENT_PYTHON"

    # Show installed Python versions
    log_info "Installed Python versions:"
    pyenv versions 2>&1 || log_warning "Unable to list versions"

    # ----------------------------------------
    # Validate Python Installation
    # ----------------------------------------
    echo ""
    log_info "Validating Python installation..."

    # Check if Python is properly installed
    if [ "$CURRENT_PYTHON" != "none" ] && [ "$CURRENT_PYTHON" != "system" ]; then
        log_success "✓ Python version is set: $CURRENT_PYTHON"

        # Verify Python executable
        if pyenv which python &> /dev/null; then
            PYTHON_PATH=$(pyenv which python)
            log_success "✓ Python executable found: $PYTHON_PATH"

            # Get Python version details
            if python --version &> /dev/null; then
                PYTHON_FULL_VERSION=$(python --version 2>&1)
                log_success "✓ Python is working: $PYTHON_FULL_VERSION"
            else
                log_error "✗ Python executable not working properly"
            fi

            # Check pip
            if pyenv which pip &> /dev/null; then
                PIP_VERSION=$(pip --version 2>&1 || echo "Error")
                log_success "✓ Pip is available: $PIP_VERSION"
            else
                log_warning "⚠ Pip not found - may need to install manually"
            fi
        else
            log_error "✗ Python executable not found for version: $CURRENT_PYTHON"
        fi
    else
        log_warning "⚠ No Python version set by pyenv (using system Python)"
    fi

    # Check for .python-version file
    echo ""
    log_info "Checking for .python-version file in workspace..."
    WORKSPACE_DIR="/workspaces"
    PYTHON_VERSION_FILE_FOUND=false

    if [ -d "$WORKSPACE_DIR" ]; then
        for dir in "$WORKSPACE_DIR"/*; do
            if [ -f "$dir/.python-version" ]; then
                PYTHON_VERSION_FILE_FOUND=true
                SPECIFIED_VERSION=$(tr -d '[:space:]' < "$dir/.python-version")
                log_info "Found .python-version file at: $dir/.python-version"
                log_info "Specified version: $SPECIFIED_VERSION"

                # Check if specified version matches current version
                if [ "$SPECIFIED_VERSION" = "$CURRENT_PYTHON" ]; then
                    log_success "✓ Current Python version matches .python-version file"
                else
                    log_warning "⚠ Current version ($CURRENT_PYTHON) differs from .python-version ($SPECIFIED_VERSION)"
                fi
                break
            fi
        done
    fi

    if [ "$PYTHON_VERSION_FILE_FOUND" = false ]; then
        log_info "No .python-version file found - using default Python version"
    fi

    # Run pyenv doctor for additional diagnostics
    echo ""
    log_info "Running pyenv doctor for diagnostics..."
    if command -v pyenv-doctor &> /dev/null; then
        pyenv doctor 2>&1 | head -20 || log_warning "pyenv doctor encountered issues"
    else
        log_info "pyenv-doctor not available - skipping diagnostics"
    fi

    # ----------------------------------------
    # Verify Global Packages
    # ----------------------------------------
    echo ""
    log_info "Checking global packages..."

    # Load feature options to check if globalPackages was specified
    FEATURE_OPTIONS_FILE="/usr/local/share/pyenv/configs/feature-options.env"
    if [ -f "$FEATURE_OPTIONS_FILE" ]; then
        # shellcheck disable=SC1090,SC1091
        source "$FEATURE_OPTIONS_FILE"

        if [ -n "$GLOBALPACKAGES" ]; then
            log_info "Expected global packages: $GLOBALPACKAGES"

            # Split packages by comma and verify each one
            IFS=',' read -ra PACKAGES <<< "$GLOBALPACKAGES"
            for package in "${PACKAGES[@]}"; do
                package=$(echo "$package" | xargs)  # Trim whitespace
                if [ -n "$package" ]; then
                    if pip show "$package" &> /dev/null; then
                        log_success "✓ $package is installed"
                    else
                        log_error "✗ $package is NOT installed"
                    fi
                fi
            done
        else
            log_info "No global packages specified"
        fi

        # ----------------------------------------
        # Verify Virtual Environment Packages
        # ----------------------------------------
        if [ "$AUTOCREATEVIRTUALENV" = "true" ] && [ -n "$VIRTUALENVPACKAGES" ]; then
            echo ""
            log_info "Checking virtual environment packages..."
            log_info "Expected virtualenv packages: $VIRTUALENVPACKAGES"

            # Check if we're in a virtualenv
            if echo "$CURRENT_PYTHON" | grep -q '/'; then
                log_info "Currently in virtualenv: $CURRENT_PYTHON"

                # Split packages by comma and verify each one
                IFS=',' read -ra VENV_PACKAGES <<< "$VIRTUALENVPACKAGES"
                for package in "${VENV_PACKAGES[@]}"; do
                    package=$(echo "$package" | xargs)  # Trim whitespace
                    if [ -n "$package" ]; then
                        if pip show "$package" &> /dev/null; then
                            log_success "✓ $package is installed in virtualenv"
                        else
                            log_error "✗ $package is NOT installed in virtualenv"
                        fi
                    fi
                done
            else
                log_warning "Not in a virtual environment, cannot verify virtualenv packages"
            fi
        fi
    fi
else
    log_error "✗ Pyenv command not found in PATH"
fi

# ----------------------------------------
# Display Welcome Message
# ----------------------------------------
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🐍 Welcome to your development container with pyenv!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📋 Status Report:${NC}"
echo -e "   • Feature: pyenv (Python Version Management)"
echo -e "   • Version: 1.0.0"
echo -e "   • User: $CURRENT_USER"
echo -e "   • Pyenv Root: $USER_HOME/.pyenv"
echo -e "   • Active Python: ${GREEN}$CURRENT_PYTHON${NC}"
if [ -n "$PYTHON_FULL_VERSION" ]; then
    echo -e "   • Python Version: ${GREEN}$PYTHON_FULL_VERSION${NC}"
fi
if [ "$PYTHON_VERSION_FILE_FOUND" = true ]; then
    echo -e "   • .python-version: ${YELLOW}$SPECIFIED_VERSION${NC}"
fi
echo ""
echo -e "${CYAN}🔧 Quick Commands:${NC}"
echo -e "   • ${YELLOW}pyenv install --list${NC}     # List available Python versions"
echo -e "   • ${YELLOW}pyenv install 3.11.5${NC}     # Install a specific Python version"
echo -e "   • ${YELLOW}pyenv global 3.11.5${NC}      # Set global Python version"
echo -e "   • ${YELLOW}pyenv local 3.11.5${NC}       # Set project-specific Python version"
echo -e "   • ${YELLOW}pyenv versions${NC}           # List installed Python versions"
echo -e "   • ${YELLOW}pyenv virtualenv 3.11.5 myenv${NC}  # Create a virtualenv"
echo -e "   • ${YELLOW}pyenv activate myenv${NC}     # Activate a virtualenv"
echo -e "   • ${YELLOW}pyenv doctor${NC}             # Run diagnostics"
echo -e "   • ${YELLOW}pyenv update${NC}             # Update pyenv and plugins"
echo ""
echo -e "${CYAN}📚 Resources:${NC}"
echo -e "   • Pyenv: https://github.com/pyenv/pyenv"
echo -e "   • Feature docs: https://github.com/infras-factory/devcontainer-features/tree/main/src/pyenv"
echo -e "   • Logs: $LOG_FILE"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_success "Post-attach script completed successfully"
