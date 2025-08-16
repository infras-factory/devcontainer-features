#!/bin/bash

set -e

# ----------------------------------------
# Local Variables
# ----------------------------------------
FEATURE_TMP_DIR="/usr/local/share/riso-bootstrap"
# Files required for system to work (format: "path:description")
# shellcheck disable=SC2034
REQUIRED_FILES=(
    "./utils/layer-0/logger.sh:Logger utilities"
    "./utils/layer-1/file-ops.sh:File operation utilities"
    "./utils/layer-1/validator.sh:Validation utilities"
)
# Files to import for install.sh usage (format: "path:description")
# shellcheck disable=SC2034
IMPORT_FILES=(
    "./utils/layer-0/logger.sh:Logger utilities"
    "./utils/layer-1/file-ops.sh:File operation utilities"
)

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
# Local Helper Functions for Installation
# ----------------------------------------
# Function to copy scripts and utils to system directory
copy_feature_files() {
    mkdir -p "${FEATURE_TMP_DIR}"/{scripts,utils,configs}

    # Copy utils folder
    copy_directory "./utils" "${FEATURE_TMP_DIR}/utils" "utils"

    # Copy scripts folder
    copy_directory "./scripts" "${FEATURE_TMP_DIR}/scripts" "scripts"

    # Copy configs folder
    copy_directory "./configs" "${FEATURE_TMP_DIR}/configs" "configs"
}

# Function to create feature options environment file
create_options_file() {
    cat > ${FEATURE_TMP_DIR}/riso-bootstrap-options.env << EOF
# Riso Bootstrap Feature Options
PROJECT_NAME="${PROJECTNAME:-""}"
ENABLE_SERENA="${ENABLESERENA:-false}"
SHELL_ENHANCEMENT_LEVEL="${SHELLENHANCEMENTLEVEL:-standard}"
IS_TEST_MODE="${ISTESTMODE:-false}"
# Constant variables
FEATURE_TMP_DIR="${FEATURE_TMP_DIR}"
EOF
}

# ----------------------------------------
# install.sh - Installation script for Riso Bootstrap
# ----------------------------------------
main() {
    set_workflow_context "install.sh"
    log_workflow_start "Riso Bootstrap Installation"

    local total_steps=2
    local current_step=0

    # Step 1: Copy feature files
    log_step_start "Copy feature files to system directory" $((++current_step)) $total_steps
    log_group_start "File operations"
    copy_feature_files
    log_group_end "File operations"
    log_step_end "Copy feature files to system directory" "success"

    # Step 2: Create options file
    log_step_start "Create feature options environment file" $((++current_step)) $total_steps
    log_group_start "Configuration setup"
    create_options_file
    log_group_end "Configuration setup"
    log_step_end "Create feature options environment file" "success"

    log_workflow_end "Riso Bootstrap Installation" "success"
}

main "$@"
