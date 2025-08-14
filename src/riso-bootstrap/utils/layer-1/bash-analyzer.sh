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
# utils/layer-1/bash-analyzer.sh - Deep analyzer for bash scripts
# ----------------------------------------

# ----------------------------------------
# Analyze script purpose from comments and structure
# ----------------------------------------
analyze_script_purpose() {
    local script_path="$1"

    if [ ! -f "$script_path" ]; then
        log_warning "File not found: $script_path"
        return 1
    fi

    local script_name
    script_name=$(basename "$script_path")
    log_subsection "Analyzing: $script_name"

    # Extract purpose from header comments (first 30 lines)
    local purpose
    purpose=$(head -30 "$script_path" 2>/dev/null | \
        grep -E "^#\s+" | \
        grep -v "^#!/" | \
        grep -v "^#\s*-" | \
        grep -v "^#\s*shellcheck" | \
        sed 's/^#\s*//' | \
        head -3 | \
        tr '\n' ' ')

    if [ -n "$purpose" ]; then
        log_info "  Purpose: $purpose"
    else
        # Try to infer from filename
        case "$script_name" in
            install.sh) log_info "  Purpose: Installation script (inferred)" ;;
            test*.sh) log_info "  Purpose: Test script (inferred)" ;;
            setup*.sh) log_info "  Purpose: Setup/configuration script (inferred)" ;;
            build*.sh) log_info "  Purpose: Build script (inferred)" ;;
            post-*.sh) log_info "  Purpose: Lifecycle hook script (inferred)" ;;
            *) log_info "  Purpose: Unknown - no comments found" ;;
        esac
    fi
}

# ----------------------------------------
# Detect command patterns used in script
# ----------------------------------------
detect_command_patterns() {
    local script_path="$1"

    if [ ! -f "$script_path" ]; then
        return 1
    fi

    log_info "  Commands used:"

    local found_any=false

    # Common DevOps tools
    local tools=(
        "git:Version control"
        "docker:Container management"
        "npm:Node.js packages"
        "pip:Python packages"
        "apt-get:Debian packages"
        "yum:RedHat packages"
        "curl:HTTP requests"
        "wget:File downloads"
        "make:Build automation"
        "kubectl:Kubernetes"
        "aws:AWS CLI"
        "az:Azure CLI"
        "gcloud:Google Cloud"
    )

    for tool_desc in "${tools[@]}"; do
        local tool="${tool_desc%%:*}"
        local desc="${tool_desc#*:}"

        if grep -q "\b$tool\b" "$script_path" 2>/dev/null; then
            found_any=true
            log_info "    • $tool - $desc"
        fi
    done

    if [ "$found_any" = false ]; then
        log_info "    • No external commands detected"
    fi
}

# ----------------------------------------
# Map function call hierarchy
# ----------------------------------------
map_function_hierarchy() {
    local script_path="$1"

    if [ ! -f "$script_path" ]; then
        return 1
    fi

    log_info "  Functions defined:"

    # Find function definitions
    local functions
    functions=$(grep -E "^(function\s+[a-zA-Z_][a-zA-Z0-9_]*|[a-zA-Z_][a-zA-Z0-9_]*\s*\(\))" "$script_path" 2>/dev/null | \
        sed -E 's/^function\s+//; s/\s*\(\).*//' | \
        sed 's/\s*{.*//')

    if [ -n "$functions" ]; then
        echo "$functions" | while read -r func; do
            log_info "    • $func()"

            # Try to find what this function calls
            local calls
            calls=$(grep -A 20 "^$func\s*(" "$script_path" 2>/dev/null | \
                grep -E "^\s+[a-zA-Z_][a-zA-Z0-9_]*\s" | \
                sed 's/^\s*//' | \
                cut -d' ' -f1 | \
                sort -u | \
                head -3)

            if [ -n "$calls" ]; then
                echo "$calls" | while read -r called; do
                    log_info "      → calls: $called"
                done
            fi
        done
    else
        log_info "    • No functions defined"
    fi
}

# ----------------------------------------
# Identify external dependencies
# ----------------------------------------
identify_dependencies() {
    local script_path="$1"

    if [ ! -f "$script_path" ]; then
        return 1
    fi

    log_info "  Dependencies:"

    local found_any=false

    # Check for sourced files
    local sources
    sources=$(grep -E "^(source|\.) " "$script_path" 2>/dev/null | \
        sed -E 's/^(source|\.)\s+//' | \
        sed 's/"//g; s/'\''//g' | \
        cut -d' ' -f1)

    if [ -n "$sources" ]; then
        found_any=true
        log_info "    Sources:"
        echo "$sources" | while read -r src; do
            log_info "      • $src"
        done
    fi

    # Check for required commands
    local required
    required=$(grep -E "(command -v|which|type -P)" "$script_path" 2>/dev/null | \
        sed -E 's/.*(command -v|which|type -P)\s+//' | \
        sed 's/[;&|>].*$//' | \
        sed 's/"//g; s/'\''//g' | \
        sort -u)

    if [ -n "$required" ]; then
        found_any=true
        log_info "    Required commands:"
        echo "$required" | while read -r cmd; do
            log_info "      • $cmd"
        done
    fi

    if [ "$found_any" = false ]; then
        log_info "    • No external dependencies detected"
    fi
}

# ----------------------------------------
# Main analyzer function for a single script
# ----------------------------------------
analyze_bash_script() {
    local script_path="$1"

    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        return 1
    fi

    # Run all analysis functions
    analyze_script_purpose "$script_path"
    detect_command_patterns "$script_path"
    map_function_hierarchy "$script_path"
    identify_dependencies "$script_path"
}

# ----------------------------------------
# Analyze all scripts in a project
# ----------------------------------------
analyze_all_scripts() {
    local project_dir="${1:-.}"

    log_phase "Bash Scripts Deep Analysis"

    # Find key scripts to analyze
    local key_scripts=(
        "$project_dir/install.sh"
        "$project_dir/src/riso-bootstrap/install.sh"
        "$project_dir/test.sh"
        "$project_dir/Makefile"
    )

    local analyzed_count=0

    for script in "${key_scripts[@]}"; do
        if [ -f "$script" ]; then
            analyze_bash_script "$script"
            ((analyzed_count++))
        fi
    done

    # Also analyze first few .sh files found
    # Note: Using process substitution to avoid subshell issue with counter
    while IFS= read -r script; do
        if [[ ! " ${key_scripts[*]} " =~ ${script} ]]; then
            analyze_bash_script "$script"
            ((analyzed_count++))
        fi
    done < <(find "$project_dir" -type f -name "*.sh" 2>/dev/null | head -5)

    if [ "$analyzed_count" -eq 0 ]; then
        log_warning "No scripts found to analyze"
        return 1
    fi

    log_success "Analysis complete - analyzed $analyzed_count scripts"
}
