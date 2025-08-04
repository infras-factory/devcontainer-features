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
# shellcheck disable=SC2034
IMPORT_FILES=(
    "$FEATURE_TMP_DIR/utils/layer-0/logger.sh:Logger utilities"
    "$FEATURE_TMP_DIR/riso-bootstrap-options.env:Feature options"
)
TOTAL_STEPS=1

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
    local step_id=$1
    log_section "Executing: $step_id/$TOTAL_STEPS Grant SSH permission..."

    if [ -d "$HOME_DIR/.ssh" ]; then
        chmod 700 "$HOME_DIR/.ssh"
        find "$HOME_DIR/.ssh" -type f -exec chmod 600 {} \;
    else
        log_warning "No $HOME_DIR/.ssh directory found"
    fi

    log_section "Executing: $step_id/$TOTAL_STEPS Grant SSH permission completed"
}

main() {
    grant_ssh_permissions 1
}

log_phase "RISO BOOTSTRAP POST-START SCRIPT EXECUTION"

main "$@"
