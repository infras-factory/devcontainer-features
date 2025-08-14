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
# utils/layer-1/devcontainer-analyzer.sh - DevContainer Features Analysis
# ----------------------------------------

# ----------------------------------------
# DEVCONTAINER FEATURE ANALYSIS
# ----------------------------------------

# ----------------------------------------
# Function 1: Analyze DevContainer feature structure
# Returns: 0 if DevContainer feature found, 1 if not found
# ----------------------------------------
analyze_devcontainer_feature() {
    local project_path="$1"

    log_info "Analyzing DevContainer feature at: $project_path"

    # Check if this is a DevContainer feature
    if [ ! -f "$project_path/devcontainer-feature.json" ]; then
        log_warning "No devcontainer-feature.json found - not a DevContainer feature"
        return 1
    fi

    log_section "DevContainer Feature Analysis"

    # Analyze feature metadata
    analyze_feature_metadata "$project_path/devcontainer-feature.json"

    # Analyze installation script
    if [ -f "$project_path/install.sh" ]; then
        analyze_install_script "$project_path/install.sh"
    fi

    # Analyze test scenarios
    analyze_test_scenarios "$project_path"

    # Analyze lifecycle hooks
    analyze_lifecycle_hooks "$project_path"

    return 0
}

# ----------------------------------------
# Function 2: Analyze feature metadata from JSON
# ----------------------------------------
analyze_feature_metadata() {
    local json_file="$1"

    log_subsection "Feature Metadata"

    # Extract basic information using grep and sed for compatibility
    local feature_id
    local feature_name
    local feature_version
    local feature_description

    feature_id=$(grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    feature_name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    feature_version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    feature_description=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$json_file" | sed 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

    log_info "Feature ID: ${feature_id:-"N/A"}"
    log_info "Feature Name: ${feature_name:-"N/A"}"
    log_info "Version: ${feature_version:-"N/A"}"
    log_info "Description: ${feature_description:-"N/A"}"    # Analyze options
    analyze_feature_options "$json_file"

    # Analyze dependencies
    analyze_feature_dependencies "$json_file"
}

# ----------------------------------------
# Function 3: Analyze feature options
# ----------------------------------------
analyze_feature_options() {
    local json_file="$1"

    log_subsection "Feature Options"

    # Check if options section exists
    if grep -q '"options"' "$json_file"; then
        log_info "Options found in feature definition:"

        # Extract options using basic text processing
        # Look for option definitions between "options" and next top-level key
        local in_options=false
        local brace_count=0
        local option_name=""

        while IFS= read -r line; do
            if [[ "$line" =~ \"options\"[[:space:]]*: ]]; then
                in_options=true
                continue
            fi

            if [[ "$in_options" == "true" ]]; then
                # Count braces to know when we exit options
                brace_count=$((brace_count + $(echo "$line" | tr -cd '{' | wc -c)))
                brace_count=$((brace_count - $(echo "$line" | tr -cd '}' | wc -c)))

                # Extract option names
                if [[ "$line" == *\"*\"*:*\{* ]]; then
                    # Extract text between first quotes using bash parameter expansion
                    local temp_line="${line#*\"}"
                    option_name="${temp_line%%\"*}"
                    if [[ -n "$option_name" && "$option_name" != "options" ]]; then
                        log_info "  • $option_name"
                    fi
                fi

                # Extract option descriptions
                if [[ "$line" == *\"description\"* ]]; then
                    # Extract description value using bash parameter expansion
                    local temp_desc="${line#*\"description\"*:*\"}"
                    description="${temp_desc%%\"*}"
                    if [[ -n "$description" ]]; then
                        log_info "    Description: $description"
                    fi
                fi

                # Extract default values
                if [[ "$line" == *\"default\"* ]]; then
                    default_val=$(echo "$line" | sed 's/.*"default"[[:space:]]*:[[:space:]]*"\?\([^",}]*\).*/\1/' | sed 's/"$//')
                    if [[ -n "$default_val" ]]; then
                        log_info "    Default: $default_val"
                    fi
                fi                # Exit options section when braces are balanced
                if [[ $brace_count -eq 0 && "$option_name" != "" ]]; then
                    break
                fi
            fi
        done < "$json_file"
    else
        log_info "No options defined"
    fi
}

# ----------------------------------------
# Function 4: Analyze feature dependencies
# ----------------------------------------
analyze_feature_dependencies() {
    local json_file="$1"

    log_subsection "Feature Dependencies"

        # Check for installsAfter
    if grep -q '"installsAfter"' "$json_file"; then
        log_info "InstallsAfter dependencies:"
        grep -A 10 '"installsAfter"' "$json_file" | grep -o '"[^"]*"' | grep -v '"installsAfter"' | sed 's/"//g' | while read -r dep; do
            if [[ -n "$dep" && "$dep" != "]" && "$dep" != "[" ]]; then
                log_info "  • $dep"
            fi
        done
    fi

    # Check for installsAsDefault
    if grep -q '"installsAsDefault"' "$json_file"; then
        log_info "InstallsAsDefault dependencies:"
        grep -A 10 '"installsAsDefault"' "$json_file" | grep -o '"[^"]*"' | grep -v '"installsAsDefault"' | sed 's/"//g' | while read -r dep; do
            if [[ -n "$dep" && "$dep" != "]" && "$dep" != "[" ]]; then
                log_info "  • $dep"
            fi
        done
    fi

    if ! grep -q '"installsAfter"\|"installsAsDefault"' "$json_file"; then
        log_info "No dependencies defined"
    fi
}

# ----------------------------------------
# Function 5: Analyze installation script
# ----------------------------------------
analyze_install_script() {
    local install_script="$1"

    log_subsection "Installation Script Analysis"

    # Basic script info
    local line_count
    line_count=$(wc -l < "$install_script")
    log_info "Install script: $(basename "$install_script") ($line_count lines)"

    # Detect shell type
    local shebang
    shebang=$(head -1 "$install_script")
    log_info "Shell: $shebang"

    # Analyze installation patterns
    log_info "Installation patterns detected:"

    # Package managers
    if grep -q "apt-get\|apt " "$install_script"; then
        log_info "  • APT package installation"
    fi
    if grep -q "yum\|dnf" "$install_script"; then
        log_info "  • YUM/DNF package installation"
    fi
    if grep -q "apk " "$install_script"; then
        log_info "  • Alpine APK installation"
    fi

    # Language-specific package managers
    if grep -q "npm\|yarn\|pnpm" "$install_script"; then
        log_info "  • Node.js package installation"
    fi
    if grep -q "pip\|pip3" "$install_script"; then
        log_info "  • Python package installation"
    fi
    if grep -q "gem install" "$install_script"; then
        log_info "  • Ruby gem installation"
    fi
    if grep -q "go install\|go get" "$install_script"; then
        log_info "  • Go package installation"
    fi

    # Download patterns
    if grep -q "curl\|wget" "$install_script"; then
        log_info "  • File download operations"
    fi
    if grep -q "git clone" "$install_script"; then
        log_info "  • Git repository cloning"
    fi

    # Container operations
    if grep -q "docker" "$install_script"; then
        log_info "  • Docker operations"
    fi    # Configuration patterns
    if grep -q "echo.*>>\|cat.*>" "$install_script"; then
        log_info "  • Configuration file creation"
    fi
    if grep -q "chmod\|chown" "$install_script"; then
        log_info "  • File permission changes"
    fi

    # Environment setup
    if grep -q "export\|PATH=" "$install_script"; then
        log_info "  • Environment variable setup"
    fi

    # Analyze option usage
    log_info "--- Option Variables Used ---"
    grep -o '\$[A-Z_][A-Z0-9_]*' "$install_script" | sort | uniq | while read -r var; do
        log_info "  • $var"
    done

    # Check for error handling
    log_info "--- Error Handling ---"
    if grep -q "set -e" "$install_script"; then
        log_info "  • Exit on error enabled (set -e)"
    fi
    if grep -q "trap" "$install_script"; then
        log_info "  • Error traps configured"
    fi
    if grep -q "if.*command.*-v\|which" "$install_script"; then
        log_info "  • Command availability checks"
    fi
}

# Analyze test scenarios
analyze_test_scenarios() {
    local project_path="$1"

    log_info "--- Test Scenarios ---"

    local test_dir="$project_path/test"
    if [[ ! -d "$test_dir" ]]; then
        log_info "No test directory found"
        return 0
    fi

    log_info "Test directory found: $test_dir"

    # Find test scripts
    local test_scripts
    test_scripts=$(find "$test_dir" -name "*.sh" -type f 2>/dev/null || true)

    if [[ -n "$test_scripts" ]]; then
        log_info "Test scripts found:"
        echo "$test_scripts" | while read -r script; do
            local script_name
            script_name=$(basename "$script")
            log_info "  • $script_name"

            # Analyze test content
            if grep -q "check\|assert" "$script"; then
                log_info "    - Contains test assertions"
            fi
            if grep -q "devcontainer-features-test-lib" "$script"; then
                log_info "    - Uses DevContainer test library"
            fi
        done
    else
        log_info "No test scripts found"
    fi

    # Look for test scenarios JSON
    if [[ -f "$project_path/test-scenarios.json" ]]; then
        log_info "Test scenarios configuration found"
    fi
}

# Analyze lifecycle hooks
analyze_lifecycle_hooks() {
    local project_path="$1"

    log_info "--- Lifecycle Hooks ---"

    local hooks_found=false

    # Check for common hook scripts
    local hook_scripts=("post-create.sh" "post-attach.sh" "post-start.sh")

    for hook in "${hook_scripts[@]}"; do
        if [[ -f "$project_path/scripts/$hook" ]]; then
            log_info "  • $hook found"
            hooks_found=true

            # Basic analysis of hook content
            local line_count
            line_count=$(wc -l < "$project_path/scripts/$hook")
            log_info "    - $line_count lines"

            # Check for common hook patterns
            if grep -q "echo\|log" "$project_path/scripts/$hook"; then
                log_info "    - Contains logging/output"
            fi
            if grep -q "git\|clone" "$project_path/scripts/$hook"; then
                log_info "    - Git operations"
            fi
            if grep -q "npm\|pip\|apt" "$project_path/scripts/$hook"; then
                log_info "    - Package installations"
            fi
        fi
    done

    if [[ "$hooks_found" == "false" ]]; then
        log_info "No lifecycle hooks found"
    fi
}

# Generate DevContainer feature summary
generate_devcontainer_summary() {
    local project_path="$1"
    local output_file="$2"

    log_info "Generating DevContainer feature summary to: $output_file"

    {
        echo "# DevContainer Feature Summary"
        echo
        echo "Generated on: $(date)"
        echo "Project: $project_path"
        echo

        # Run analysis and capture output
        if analyze_devcontainer_feature "$project_path" 2>&1; then
            echo
            echo "## Analysis Complete"
            echo "DevContainer feature structure analyzed successfully."
        else
            echo
            echo "## Analysis Failed"
            echo "This does not appear to be a DevContainer feature project."
        fi
    } > "$output_file"

    log_info "DevContainer summary written to: $output_file"
}

# Main analysis entry point
main() {
    local project_path="${1:-.}"

    if [[ ! -d "$project_path" ]]; then
        log_error "Project path does not exist: $project_path"
        exit 1
    fi

    analyze_devcontainer_feature "$project_path"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
