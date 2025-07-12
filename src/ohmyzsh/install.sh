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
    zsh \
    sudo \
    wget \
    ca-certificates \
    locales \
    tzdata || {
    log_error "Failed to install dependencies"
    exit 1
}

# Generate locale
locale-gen en_US.UTF-8 || true

log_success "Dependencies installed successfully"

# ----------------------------------------
# Copy Scripts to System Directory
# ----------------------------------------
# Copy scripts folder to /usr/local/share
if [ -d ./scripts ]; then
    log_info "Copying scripts to /usr/local/share..."

    # Create target directory if it doesn't exist
    if [ ! -d /usr/local/share ]; then
        mkdir -p /usr/local/share
        log_info "Created /usr/local/share directory"
    fi

    # Copy scripts folder
    cp -r ./scripts /usr/local/share/
    log_success "Scripts copied to /usr/local/share/scripts"

    # Set proper permissions
    chmod -R 755 /usr/local/share/scripts
    log_success "Set execute permissions on scripts"
else
    log_warning "Scripts folder not found at ./scripts"
fi

# Copy configs folder to /usr/local/share
if [ -d ./configs ]; then
    log_info "Copying configs to /usr/local/share..."

    # Copy configs folder
    cp -r ./configs /usr/local/share/
    log_success "Configs copied to /usr/local/share/configs"

    # Set proper permissions
    chmod 755 /usr/local/share/configs
    # Set permissions for all files including hidden files
    find /usr/local/share/configs -type f -exec chmod 644 {} \;
    log_success "Set proper permissions on configs"
else
    log_warning "Configs folder not found at ./configs"
fi

# ----------------------------------------
# Installation Complete
# ----------------------------------------
log_success "DevContainer feature installation completed!"
log_info "Scripts and configs have been copied to /usr/local/share/"
log_info "Oh My Zsh setup will be completed when container is created"
