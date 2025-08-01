#!/bin/bash

# ----------------------------------------
# utils/layer-0/commands.sh - Command utility functions
# ----------------------------------------

# Function to check if a command exists
check_command() {
    local cmd=$1
    if command -v "$cmd" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to get version safely
get_version() {
    local cmd=$1
    local version_flag=${2:---version}
    local version=""

    if check_command "$cmd"; then
        version=$($cmd "$version_flag" 2>/dev/null | head -n 1 || echo "unknown")
        echo "$version"
    else
        echo "not installed"
    fi
}
