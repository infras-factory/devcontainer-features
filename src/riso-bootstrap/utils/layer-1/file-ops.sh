#!/bin/bash

set -e

# ----------------------------------------
# Local Variables
# ----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LAYER_ZERO_DIR="${BASE_DIR}/layer-0"

# ----------------------------------------
# Import Utilities
# ----------------------------------------
# shellcheck source=../layer-0/logger.sh disable=SC1091
source "${LAYER_ZERO_DIR}/logger.sh"

# ----------------------------------------
# utils/file-ops.sh - File operations utilities for Riso Bootstrap
# ----------------------------------------
# Function to copy a directory with proper logging and permissions
copy_directory() {
    local source_dir="$1"
    local dest_dir="$2"
    local dir_name="$3"

    if [ -z "$source_dir" ] || [ -z "$dest_dir" ] || [ -z "$dir_name" ]; then
        log_error "copy_directory requires 3 parameters: source_dir, dest_dir, dir_name"
        return 1
    fi

    if [ -d "$source_dir" ]; then
        log_info "Copying $dir_name to $dest_dir..."

        # Copy entire directory structure preserving hierarchy and hidden files
        # Use (cd && cp) to ensure all files including hidden ones are copied
        (cd "$source_dir" && cp -r . "$dest_dir/")

        # Check if any files were copied
        if [ "$(ls -A "$dest_dir" 2>/dev/null)" ]; then
            log_success "$dir_name copied to $dest_dir"
            chmod -R 755 "$dest_dir"
            log_success "Set execute permissions on $dir_name"
            return 0
        else
            log_warning "No $dir_name were copied"
            return 1
        fi
    else
        log_warning "$dir_name folder not found at $source_dir"
        return 1
    fi
}
