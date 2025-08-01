#!/bin/bash

set -e

# ----------------------------------------
# Local Variables
# ----------------------------------------
LAYER_ZERO_DIR="./utils/layer-0/"

# ----------------------------------------
# Import Utilities
# ----------------------------------------
# shellcheck source=../layer-0/logger.sh disable=SC1091
source "${LAYER_ZERO_DIR}logger.sh"

# ----------------------------------------
# utils/validator.sh - Setup validation functions
# ----------------------------------------
# Function to validate project name
validate_project_name() {
    local name="$1"

    if [ -z "$name" ]; then
        log_error "Project name cannot be empty"
        return 1
    fi

    if [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_success "Project name '$name' is valid"
        return 0
    else
        log_error "Project name '$name' contains invalid characters"
        return 1
    fi
}
