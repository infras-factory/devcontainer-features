#!/bin/bash
set -e

# ----------------------------------------
# Local Variables
# ----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LAYER_ZERO_DIR="${BASE_DIR}/layer-0"
LAYER_ONE_DIR="${BASE_DIR}/layer-1"

# ----------------------------------------
# Import Utilities
# ----------------------------------------
# shellcheck source=../layer-0/logger.sh disable=SC1091
source "${LAYER_ZERO_DIR}/logger.sh"
# shellcheck source=../layer-1/bash-script-scanner.sh disable=SC1091
source "${LAYER_ONE_DIR}/bash-script-scanner.sh"
# shellcheck source=../layer-1/bash-analyzer.sh disable=SC1091
source "${LAYER_ONE_DIR}/bash-analyzer.sh"

# ----------------------------------------
# utils/layer-2/bash-section-generator.sh - Generate Bash section for PROJECT.md
# ----------------------------------------

# ----------------------------------------
# Function 1: Generate Bash Scripts section markdown
# Input: project_path - Path to project directory
# Output: Markdown content to stdout
# Returns: 0 on success, 1 on failure
# ----------------------------------------
generate_bash_section() {
    local project_path="${1:-.}"

    if [ ! -d "$project_path" ]; then
        log_error "Project path does not exist: $project_path"
        return 1
    fi

    log_workflow_start "Bash Section Generation"
    log_workflow_step "Scanning for bash scripts in: $(basename "$project_path")"

    # Scan for bash scripts using find command directly
    local bash_files
    bash_files=$(find "$project_path" -type f -name "*.sh" 2>/dev/null)

    if [ -z "$bash_files" ]; then
        log_skip "No bash scripts found in project"
        return 0
    fi

    local file_count
    file_count=$(echo "$bash_files" | wc -l)
    log_result "Found ${file_count} bash script(s)"

    log_workflow_step "Generating script inventory table"

    # Generate markdown header
    cat << 'EOF'
### Bash Scripts

#### Script Inventory
| Script | Purpose | Type | Functions | Dependencies |
|--------|---------|------|-----------|--------------|
EOF

    # Process each bash file
    local current_file=0
    while IFS= read -r script_file; do
        if [ -z "$script_file" ]; then
            continue
        fi

        current_file=$((current_file + 1))
        local script_name
        script_name=$(basename "$script_file")
        log_processing "$script_name" "file $current_file/$file_count"

        # Get script analysis from layer-1
        local script_info
        script_info=$(analyze_bash_script "$script_file" 2>/dev/null || echo "")

        # Extract key information
        script_name=$(basename "$script_file")

        local purpose
        purpose=$(echo "$script_info" | grep "^purpose:" | cut -d: -f2- | sed 's/^ *//' 2>/dev/null || echo "Not documented")

        local script_type
        script_type=$(echo "$script_info" | grep "^type:" | cut -d: -f2- | sed 's/^ *//' 2>/dev/null || echo "script")

        local functions
        functions=$(echo "$script_info" | grep "^functions:" | cut -d: -f2- | sed 's/^ *//' 2>/dev/null || echo "None")

        local dependencies
        dependencies=$(echo "$script_info" | grep "^dependencies:" | cut -d: -f2- | sed 's/^ *//' 2>/dev/null || echo "None")

        # Output table row
        echo "| ${script_name} | ${purpose} | ${script_type} | ${functions} | ${dependencies} |"
        log_workflow_substep "Added ${script_name} to inventory"

    done <<< "$bash_files"

    log_workflow_step "Generating function details section"

    # Generate function details section
    cat << 'EOF'

#### Function Details
EOF

    # Process each script for detailed function info
    local scripts_with_functions=0
    while IFS= read -r script_file; do
        if [ -z "$script_file" ]; then
            continue
        fi

        local script_name
        script_name=$(basename "$script_file")

        # Extract functions directly from script file
        local functions_list
        functions_list=$(grep -E "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*\(\)" "$script_file" 2>/dev/null | sed 's/[[:space:]]*//g' | sed 's/().*$//' || echo "")

        if [ -n "$functions_list" ]; then
            echo ""
            echo "##### ${script_name}"
            scripts_with_functions=$((scripts_with_functions + 1))
            log_processing "functions in $script_name"

            local func_count=0
            while IFS= read -r func_name; do
                if [ -n "$func_name" ]; then
                    # Simple function documentation
                    echo "- **${func_name}**: Function defined in ${script_name}"
                    func_count=$((func_count + 1))
                fi
            done <<< "$functions_list"
            log_workflow_substep "Documented ${func_count} function(s)"
        fi

    done <<< "$bash_files"

    if [ "$scripts_with_functions" -eq 0 ]; then
        log_skip "No functions found in any scripts"
    fi

    log_workflow_step "Generating dependencies section"

    # Generate dependencies section
    cat << 'EOF'

#### Dependencies & Sourcing
EOF

    # Simple sourcing analysis
    echo ""
    echo "**Source Dependencies:**"
    local scripts_with_deps=0
    while IFS= read -r script_file; do
        if [ -z "$script_file" ]; then
            continue
        fi

        local script_name
        script_name=$(basename "$script_file")

        # Find source statements
        local sources
        sources=$(grep -E "^[[:space:]]*source[[:space:]]|^[[:space:]]*\.[[:space:]]" "$script_file" 2>/dev/null | sed 's/^[[:space:]]*//' || echo "")

        if [ -n "$sources" ]; then
            echo "- **${script_name}**:"
            scripts_with_deps=$((scripts_with_deps + 1))
            log_processing "dependencies for $script_name"

            local dep_count=0
            while IFS= read -r source_line; do
                if [ -n "$source_line" ]; then
                    echo "  - \`${source_line}\`"
                    dep_count=$((dep_count + 1))
                fi
            done <<< "$sources"
            log_workflow_substep "Found ${dep_count} source dependencies"
        fi

    done <<< "$bash_files"

    if [ "$scripts_with_deps" -eq 0 ]; then
        log_skip "No source dependencies found"
        echo "No source dependencies detected."
    fi

    log_workflow_end "Bash Section Generation"
    log_result "Generated bash section with ${file_count} scripts"
    return 0
}

# ----------------------------------------
# Function 2: Generate script execution flow
# Input: project_path - Path to project directory
# Output: Markdown content to stdout
# Returns: 0 on success, 1 on failure
# ----------------------------------------
generate_bash_execution_flow() {
    local project_path="${1:-.}"

    log_info "Generating execution flow for: $project_path"

    cat << 'EOF'

#### Execution Flow
EOF

    # Find entry point scripts (main scripts that are likely executed directly)
    local entry_scripts
    entry_scripts=$(find "$project_path" -name "*.sh" -type f -executable 2>/dev/null | head -10)

    if [ -n "$entry_scripts" ]; then
        printf "\n**Entry Points:**\n"
        while IFS= read -r script; do
            if [ -n "$script" ]; then
                local script_name
                script_name=$(basename "$script")
                printf "- \`%s\`\n" "$script_name"
            fi
        done <<< "$entry_scripts"
    fi

    return 0
}

# ----------------------------------------
# Main execution (when script is run directly)
# ----------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    project_path="${1:-.}"

    if [ ! -d "$project_path" ]; then
        log_error "Usage: $0 <project_path>"
        exit 1
    fi

    log_section "Bash Section Generator"
    generate_bash_section "$project_path"
    generate_bash_execution_flow "$project_path"
fi
