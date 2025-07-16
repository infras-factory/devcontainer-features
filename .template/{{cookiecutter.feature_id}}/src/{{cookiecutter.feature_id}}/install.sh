#!/bin/bash

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# ----------------------------------------
# Install Required Dependencies
# ----------------------------------------
log_info "Installing required dependencies..."

# Update package list
apt-get update || true

# Install essential dependencies
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    git \
    sudo \
    wget \
    ca-certificates \
    locales \
    tzdata || {
    log_error "Failed to install dependencies"
    exit 1
}

log_success "Dependencies installed successfully"

# ----------------------------------------
# Install {{ cookiecutter.feature_name }}
# ----------------------------------------
log_info "Installing {{ cookiecutter.feature_name }}..."

# TODO: Add your feature-specific installation steps here
# Example:
# curl -fsSL https://example.com/install.sh | bash
# apt-get install -y your-package
# git clone https://github.com/user/repo.git

log_success "{{ cookiecutter.feature_name }} installed successfully"

# ----------------------------------------
# Copy Feature Scripts and Configs
# ----------------------------------------
log_info "Setting up feature scripts and configurations..."

# Create directory structure
mkdir -p /usr/local/share/{{ cookiecutter.feature_id }}/{scripts,configs}

# Copy scripts
if [ -d ./scripts ]; then
    log_info "Copying lifecycle scripts..."
    cp -r ./scripts/* /usr/local/share/{{ cookiecutter.feature_id }}/scripts/
    chmod -R 755 /usr/local/share/{{ cookiecutter.feature_id }}/scripts
    log_success "Scripts copied successfully"
fi

# Copy configuration files
if [ -d ./configs ]; then
    # Check if there are files other than .gitkeep
    if [ "$(find ./configs -type f -not -name '.gitkeep' | wc -l)" -gt 0 ]; then
        log_info "Copying configuration files..."
        find ./configs -type f -not -name '.gitkeep' -exec cp {} /usr/local/share/{{ cookiecutter.feature_id }}/configs/ \;
        find /usr/local/share/{{ cookiecutter.feature_id }}/configs -type f -exec chmod 644 {} \;
        log_success "Configuration files copied successfully"
    else
        log_info "No configuration files to copy"
    fi
fi

# ----------------------------------------
# Cleanup
# ----------------------------------------
log_info "Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*

# ----------------------------------------
# Final Message
# ----------------------------------------
log_success "{{ cookiecutter.feature_name }} installation completed!"
log_info "Note: User-specific configuration will be done by lifecycle scripts"
