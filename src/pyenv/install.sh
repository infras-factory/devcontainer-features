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
# Feature Options
# ----------------------------------------
DEFAULTPYTHONVERSION="${DEFAULTPYTHONVERSION:-}"
AUTOCREATEVIRTUALENV="${AUTOCREATEVIRTUALENV:-false}"
VIRTUALENVNAME="${VIRTUALENVNAME:-}"
GLOBALPACKAGES="${GLOBALPACKAGES:-}"

log_info "Feature options:"
log_info "  - defaultPythonVersion: ${DEFAULTPYTHONVERSION:-'(empty - priority: .python-version → defaultPythonVersion → latest LTS)'}"
log_info "  - autoCreateVirtualenv: ${AUTOCREATEVIRTUALENV}"
log_info "  - virtualenvName: ${VIRTUALENVNAME:-'(empty - will auto-generate)'}"
log_info "  - globalPackages: ${GLOBALPACKAGES:-'(empty)'}"

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
    log_error "Failed to install basic dependencies"
    exit 1
}

log_success "Basic dependencies installed successfully"

# ----------------------------------------
# Install pyenv Build Dependencies
# ----------------------------------------
log_info "Installing pyenv build dependencies for compiling Python..."

# Install dependencies required to build Python from source
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev || {
    log_error "Failed to install pyenv build dependencies"
    exit 1
}

log_success "Pyenv build dependencies installed successfully"

# ----------------------------------------
# Note about pyenv installation
# ----------------------------------------
log_info "Note: pyenv itself will be installed per-user in post-create script"
log_info "This ensures proper permissions and user-specific configuration"

# ----------------------------------------
# Store Feature Configuration
# ----------------------------------------
log_info "Storing feature configuration..."

mkdir -p /usr/local/share/pyenv/configs
{
    echo "DEFAULTPYTHONVERSION=${DEFAULTPYTHONVERSION}"
    echo "AUTOCREATEVIRTUALENV=${AUTOCREATEVIRTUALENV}"
    echo "VIRTUALENVNAME=${VIRTUALENVNAME}"
    echo "GLOBALPACKAGES=${GLOBALPACKAGES}"
} > /usr/local/share/pyenv/configs/feature-options.env

log_success "Feature configuration stored successfully"

# ----------------------------------------
# Copy Feature Scripts and Configs
# ----------------------------------------
log_info "Setting up feature scripts and configurations..."

# Create directory structure
mkdir -p /usr/local/share/pyenv/{scripts,configs}

# Copy scripts
if [ -d ./scripts ]; then
    log_info "Copying lifecycle scripts..."
    cp -r ./scripts/* /usr/local/share/pyenv/scripts/
    chmod -R 755 /usr/local/share/pyenv/scripts
    log_success "Scripts copied successfully"
fi

# Copy configuration files
if [ -d ./configs ]; then
    # Check if there are files other than .gitkeep
    if [ "$(find ./configs -type f -not -name '.gitkeep' | wc -l)" -gt 0 ]; then
        log_info "Copying configuration files..."
        find ./configs -type f -not -name '.gitkeep' -exec cp {} /usr/local/share/pyenv/configs/ \;
        find /usr/local/share/pyenv/configs -type f -exec chmod 644 {} \;
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
log_success "Python Version Management (pyenv) installation completed!"
log_info "Note: User-specific configuration will be done by lifecycle scripts"
