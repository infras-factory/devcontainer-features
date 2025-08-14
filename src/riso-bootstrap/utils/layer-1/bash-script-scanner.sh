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
# utils/layer-1/bash-script-scanner.sh - Simple bash script detector and analyzer
# ----------------------------------------

# ----------------------------------------
# Function 1: Detect if project has bash scripts
# Returns: 0 if found, 1 if not found
# ----------------------------------------
detect_bash_scripts() {
    local project_dir="${1:-.}"

    # Find any .sh files
    if find "$project_dir" -type f -name "*.sh" 2>/dev/null | head -1 | grep -q .; then
        log_success "Project uses bash scripts"
        return 0
    else
        log_warning "No bash scripts found"
        return 1
    fi
}

# ----------------------------------------
# Function 2: List locations containing scripts
# ----------------------------------------
list_script_locations() {
    local project_dir="${1:-.}"

    log_section "Script Locations"

    # Find directories containing .sh files
    find "$project_dir" -type f -name "*.sh" 2>/dev/null | \
        sed 's|/[^/]*$||' | \
        sort -u | \
        while read -r dir; do
            # Count scripts in each directory
            local count
            count=$(find "$dir" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | wc -l)
            local rel_dir="${dir#"$project_dir"/}"
            [ "$rel_dir" = "$dir" ] && rel_dir="."
            log_info "  → $rel_dir (${count} scripts)"
        done
}

# ----------------------------------------
# Function 3: Identify script purpose from header/name
# ----------------------------------------
identify_script_purpose() {
    local project_dir="${1:-.}"

    log_section "Key Scripts & Purpose"

    # Look for common entry point scripts
    local key_scripts=(
        "install.sh"
        "test.sh"
        "setup.sh"
        "build.sh"
        "run.sh"
        "deploy.sh"
        "main.sh"
        "post-create.sh"
        "post-start.sh"
        "post-attach.sh"
    )

    local found_any=false
    for script_name in "${key_scripts[@]}"; do
        local script_path
        script_path=$(find "$project_dir" -type f -name "$script_name" 2>/dev/null | head -1)
        if [ -n "$script_path" ]; then
            found_any=true
            local rel_path="${script_path#"$project_dir"/}"

            # Try to extract purpose from first comment block
            local purpose
            purpose=$(head -20 "$script_path" 2>/dev/null | \
                grep -E "^#\s+" | \
                grep -v "^#!/" | \
                grep -v "^#\s*-" | \
                head -1 | \
                sed 's/^#\s*//')

            if [ -n "$purpose" ]; then
                log_info "  • ${rel_path}"
                log_info "    Purpose: $purpose"
            else
                log_info "  • ${rel_path}"
            fi
        fi
    done

    if [ "$found_any" = false ]; then
        log_info "  No standard entry point scripts found"
    fi
}

# ----------------------------------------
# Function 4: Find entry points and usage
# ----------------------------------------
find_entry_points() {
    local project_dir="${1:-.}"

    log_section "How to Use"

    local found_any=false

    # Check for Makefile
    if [ -f "$project_dir/Makefile" ]; then
        found_any=true
        log_info "  • Makefile targets available:"
        grep -E "^[a-zA-Z0-9_-]+:" "$project_dir/Makefile" 2>/dev/null | \
            sed 's/:.*$//' | \
            grep -v "^\.PHONY" | \
            head -5 | \
            while read -r target; do
                log_info "    → make $target"
            done
    fi

    # Check for package.json scripts
    if [ -f "$project_dir/package.json" ]; then
        if grep -q '"scripts"' "$project_dir/package.json" 2>/dev/null; then
            found_any=true
            log_info "  • npm scripts available:"
            grep -E '^\s*"[^"]+"\s*:\s*"' "$project_dir/package.json" 2>/dev/null | \
                sed 's/.*"\([^"]*\)"\s*:\s*".*/\1/' | \
                grep -v "^$" | \
                head -5 | \
                while read -r script; do
                    log_info "    → npm run $script"
                done
        fi
    fi

    # Check for DevContainer feature
    if [ -f "$project_dir/devcontainer-feature.json" ] || \
       find "$project_dir" -name "devcontainer-feature.json" 2>/dev/null | head -1 | grep -q .; then
        found_any=true
        log_info "  • DevContainer feature detected"
        log_info "    → Use: devcontainer features test"
    fi

    # Direct executable scripts
    local exec_scripts
    exec_scripts=$(find "$project_dir" -maxdepth 2 -type f -name "*.sh" -executable 2>/dev/null | head -3)
    if [ -n "$exec_scripts" ]; then
        found_any=true
        log_info "  • Direct execution:"
        echo "$exec_scripts" | while read -r script; do
            local rel_path="${script#"$project_dir"/}"
            log_info "    → ./$rel_path"
        done
    fi

    if [ "$found_any" = false ]; then
        log_info "  No obvious entry points found"
        log_info "  Check documentation or look for *.sh files"
    fi
}

# ----------------------------------------
# Main scan function
# ----------------------------------------
scan_bash_project() {
    local project_dir="${1:-.}"

    log_phase "Bash Scripts Analysis"

    # Run all detection functions
    if detect_bash_scripts "$project_dir"; then
        list_script_locations "$project_dir"
        identify_script_purpose "$project_dir"
        find_entry_points "$project_dir"
    else
        log_warning "No bash scripts to analyze in this project"
        return 1
    fi

    log_info "Analysis complete"
}
