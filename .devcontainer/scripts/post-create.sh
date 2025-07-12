#!/bin/bash

# Post-create script for devcontainer
# This script runs once when the container is first created

set -e

# Color codes for output
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
echo -e "${PURPLE}     POST-CREATE SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}========================================${NC}"

# ========================================
# SYSTEM PACKAGES INSTALLATION
# ========================================

# Update package lists
log_info "Updating package lists..."
sudo apt-get update

# ----------------------------------------
# Node.js Tools
# ----------------------------------------
# Update npm
log_info "Updating npm to the latest version..."
if command -v npm &> /dev/null; then
    npm install -g npm@latest
    log_success "npm updated successfully"
else
    log_warning "npm not found, skipping npm update"
fi

# Install Claude Code globally if npm is available
if command -v npm &> /dev/null; then
    log_info "Installing Claude Code globally..."
    npm install -g @anthropic-ai/claude-code
    log_success "Claude Code installed globally"

    log_info "Installing DevContainers CLI globally..."
    npm install -g @devcontainers/cli
    log_success "DevContainers CLI installed globally"
fi

# ========================================
# CLEANUP
# ========================================

# Clean up apt cache to reduce image size
log_info "Cleaning up package cache..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo -e "${PURPLE}========================================${NC}"
echo -e "${GREEN}Post-create script completed!${NC}"
echo -e "${PURPLE}========================================${NC}"
