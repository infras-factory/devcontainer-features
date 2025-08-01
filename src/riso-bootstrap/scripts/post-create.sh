#!/bin/bash

set -e

# ----------------------------------------
# Local Variables
# ----------------------------------------
FEATURE_TMP_DIR="/usr/local/share/riso-bootstrap"
# Files to import for install.sh usage (format: "path:description")
# shellcheck disable=SC2034
IMPORT_FILES=(
    "$FEATURE_TMP_DIR/utils/layer-0/logger.sh:Logger utilities"
    "$FEATURE_TMP_DIR/riso-bootstrap-options.env:Feature options"
)
TOTAL_STEPS=2

# ----------------------------------------
# Local Helper Functions
# ----------------------------------------
# Function to import (source) utility files
import_utility_files() {
    local -n files_array=$1

    for file_info in "${files_array[@]}"; do
        local file_path="${file_info%:*}"
        # shellcheck disable=SC2034
        local file_desc="${file_info#*:}"

        # shellcheck source=/dev/null disable=SC1091
        source "${file_path}"
    done

    return 0
}

# ----------------------------------------
# Validate and Import Required Utilities
# ----------------------------------------
import_utility_files IMPORT_FILES

# ----------------------------------------
# scripts/post-create.sh - Post-creation script for Riso Bootstrap
# ----------------------------------------
update_latest_libs() {
    local step_id=$1
    log_section "Executing: $step_id/$TOTAL_STEPS Updating latest libraries..."
    # Update command for the latest libraries
    npm install -g npm@latest
    log_section "Executing: $step_id/$TOTAL_STEPS Update completed"
}

# Function to setup Claude CLI tool
setup_claude() {
    local step_id=$1

    log_section "Executing: $step_id/$TOTAL_STEPS Installing Claude Code..."

    # Install Claude CLI globally
    npm install -g @anthropic-ai/claude-code

    log_section "Executing: $step_id/$TOTAL_STEPS Installation completed"
    return 0
}

main() {
    # Auto-detect project name if not provided
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(pwd)")
    fi

    update_latest_libs 1
    setup_claude 2
}

log_phase "RISO BOOTSTRAP POST-CREATE SCRIPT EXECUTION"

main "$@"
