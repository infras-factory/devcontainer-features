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
TOTAL_STEPS=3

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

# Function to setup Serena coding agent toolkit
setup_serena() {
    local step_id=$1

    log_section "Executing: $step_id/$TOTAL_STEPS Setting up Serena coding agent..."

    # Install UV if not present
    if ! command -v uv &> /dev/null; then
        log_info "Installing UV package manager..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Generate mock files if in test mode and no source files exist
    if [ "$IS_TEST_MODE" = "true" ]; then
        # Check if workspace is empty or has no source files
        if [ -z "$(find . -maxdepth 1 -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.java' 2>/dev/null)" ]; then
            log_info "Test mode: Generating mock Python project for Serena..."
            # Import mock generator only when needed
            # shellcheck source=/dev/null
            source "$FEATURE_TMP_DIR/utils/layer-0/mock-generator.sh"
            generate_mock_python_project "."
        fi
    fi

    # Setup Serena for this project
    log_subsection "Initializing Serena for project..."
    uvx --from git+https://github.com/oraios/serena serena project generate-yml

    log_subsection "Indexing project for semantic analysis..."
    uvx --from git+https://github.com/oraios/serena serena project index

    # Add Serena MCP server to Claude Code
    log_subsection "Registering Serena with Claude Code..."
    if ! claude mcp add serena "uvx --from git+https://github.com/oraios/serena serena mcp --project $(pwd)"; then
        log_info "Warning: Failed to register Serena MCP server with Claude Code. This may be expected if already registered. Please check the output above for details."
    fi

    log_section "Executing: $step_id/$TOTAL_STEPS Serena setup completed"
    return 0
}

main() {
    # Auto-detect project name if not provided
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(basename "$(pwd)")
    fi

    update_latest_libs 1
    setup_claude 2

    # Setup Serena if enabled
    if [ "$ENABLE_SERENA" = "true" ]; then
        setup_serena 3
    else
        log_section "Skipped: 3/$TOTAL_STEPS Serena setup (not enabled)"
    fi
}

log_phase "RISO BOOTSTRAP POST-CREATE SCRIPT EXECUTION"

main "$@"
