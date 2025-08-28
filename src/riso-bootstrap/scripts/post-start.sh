#!/bin/bash

set -e

# ----------------------------------------
# Local Variables
# ----------------------------------------
FEATURE_TMP_DIR="/usr/local/share/riso-bootstrap"
HOME_DIR="/home/vscode"
# shellcheck disable=SC2034
REQUIRED_FILES=(
    "$HOME_DIR/.ssh/config:SSH config file"
    "$HOME_DIR/.ssh/id_rsa:SSH private key"
    "$HOME_DIR/.ssh/id_rsa.pub:SSH public key"
    "$HOME_DIR/.ssh/known_hosts:SSH known hosts file"
)
# Files to import (format: "path:description")
# shellcheck disable=SC2034
IMPORT_FILES=(
    "$FEATURE_TMP_DIR/utils/layer-0/logger.sh:Logger utilities"
    "$FEATURE_TMP_DIR/riso-bootstrap-options.env:Feature options"
)
# Calculate total steps dynamically
TOTAL_STEPS=0
BASE_STEPS=("grant_ssh_permissions")
# Optionally add conditional steps
if [ "$ENABLE_SERENA" = "true" ]; then
    BASE_STEPS+=("setup_serena_mcp")
fi
TOTAL_STEPS=${#BASE_STEPS[@]}

# ----------------------------------------
# Local Helper Functions
# ----------------------------------------
# Function to validate required files exist
validate_required_files() {
    local -n files_array=$1

    for file_info in "${files_array[@]}"; do
        local file_path="${file_info%:*}"
        local file_desc="${file_info#*:}"

        if [ ! -f "${file_path}" ]; then
            echo "ERROR: ${file_desc} not found at ${file_path}" >&2
            return 1
        fi
    done

    return 0
}

# Function to import (source) utility files
import_utility_files() {
    local -n files_array=$1

    for file_info in "${files_array[@]}"; do
        local file_path="${file_info%:*}"
        local file_desc="${file_info#*:}"

        # shellcheck source=/dev/null disable=SC1091
        source "${file_path}"
    done

    return 0
}

# ----------------------------------------
# Validate and Import Required Utilities
# ----------------------------------------
validate_required_files REQUIRED_FILES
import_utility_files IMPORT_FILES

# ----------------------------------------
# scripts/post-start.sh - Post-start script for Riso Bootstrap
# ----------------------------------------
grant_ssh_permissions() {
    # shellcheck disable=SC2034
    local step_id=$1
    # Note: step_id parameter kept for consistency but not used in new logging style
    set_step_context "grant_ssh_permissions"

    log_info "Granting SSH permissions..."

    if [ -d "$HOME_DIR/.ssh" ]; then
        chmod 700 "$HOME_DIR/.ssh"
        find "$HOME_DIR/.ssh" -type f -exec chmod 600 {} \;
        log_success "SSH permissions granted"
    else
        log_warning "No $HOME_DIR/.ssh directory found"
    fi
}

# Add Serena MCP server to Claude Code
setup_serena_mcp() {
    # shellcheck disable=SC2034
    local step_id=$1

    set_step_context "setup_serena_mcp"

    # Ensure UV is in PATH
    export PATH="$HOME/.local/bin:$PATH"

    # Check if UV is available
    if ! command -v uvx &> /dev/null; then
        log_error "uvx command not found. Please ensure UV is properly installed."
        return 1
    fi

    log_group_start "Setting up Serena MCP Server"

    # Check if server is already registered and working
    if claude mcp list | grep -q "serena.*✓ Connected"; then
        log_success "Serena MCP server already registered and connected"
        log_group_end "Setting up Serena MCP Server"
        return 0
    fi

    # Remove existing server if it exists but failed to connect
    if claude mcp list | grep -q "serena.*✗ Failed to connect"; then
        log_info "Removing failed Serena MCP server registration..."
        claude mcp remove serena --scope user || true
        log_info "Failed server registration removed"
    fi

    # Register Serena MCP server with Claude Code
    log_info "Registering Serena MCP server with Claude Code..."
    if claude mcp add serena --scope user -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project "$(pwd)"; then
        log_success "Serena MCP server registered with Claude Code"

        # Verify connection
        log_info "Verifying server connection..."
        sleep 2
        if claude mcp list | grep -q "serena.*✓ Connected"; then
            log_success "Serena MCP server connected successfully"
        else
            log_warning "Serena MCP server registered but connection verification failed"
        fi
    else
        log_error "Failed to register Serena MCP server with Claude Code"
        return 1
    fi

    log_group_end "Setting up Serena MCP Server"
}

main() {
    set_workflow_context "post-start.sh"
    log_workflow_start "Riso Bootstrap Post-Start Setup"

    local current_step=0

    # Step: Grant SSH permissions
    log_step_start "Grant SSH permissions" $((++current_step)) "$TOTAL_STEPS"
    grant_ssh_permissions $current_step
    log_step_end "Grant SSH permissions" "success"

    # Step: Setup Serena MCP (if enabled)
    if [ "$ENABLE_SERENA" = "true" ]; then
        log_step_start "Setup Serena MCP" $((++current_step)) "$TOTAL_STEPS"
        setup_serena_mcp "$current_step"
        log_step_end "Setup Serena MCP" "success"
    fi

    log_workflow_end "Riso Bootstrap Post-Start Setup" "success"
}

main "$@"
