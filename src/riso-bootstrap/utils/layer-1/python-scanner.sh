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
# utils/layer-1/python-scanner.sh - Python project structure scanner
# ----------------------------------------

# ----------------------------------------
# Function 1: Detect if project has Python files
# Returns: 0 if found, 1 if not found
# ----------------------------------------
detect_python_files() {
    local project_dir="${1:-.}"

    # Find any .py files
    if find "$project_dir" -type f -name "*.py" 2>/dev/null | head -1 | grep -q .; then
        log_success "Project uses Python"
        return 0
    else
        log_warning "No Python files found"
        return 1
    fi
}

# ----------------------------------------
# Function 2: Find Python entry points
# ----------------------------------------
find_python_entry_points() {
    local project_dir="${1:-.}"

    log_section "Python Entry Points"

    # Common Python entry point patterns
    local entry_patterns=(
        "main.py"
        "app.py"
        "manage.py"
        "wsgi.py"
        "asgi.py"
        "run.py"
        "server.py"
        "__main__.py"
    )

    local found_entries=()

    for pattern in "${entry_patterns[@]}"; do
        if find "$project_dir" -type f -name "$pattern" 2>/dev/null | head -1 | grep -q .; then
            local entry_files
            entry_files=$(find "$project_dir" -type f -name "$pattern" 2>/dev/null)
            for file in $entry_files; do
                found_entries+=("$file")
                log_info "Entry point: $file"
            done
        fi
    done

    if [ ${#found_entries[@]} -eq 0 ]; then
        log_warning "No common Python entry points found"
        return 1
    fi

    return 0
}

# ----------------------------------------
# Function 3: Identify Python project type
# ----------------------------------------
identify_python_project_type() {
    local project_dir="${1:-.}"

    log_section "Python Project Type Analysis"

    # Check for Django project
    if [ -f "$project_dir/manage.py" ] && grep -q "django" "$project_dir/manage.py" 2>/dev/null; then
        log_info "Project type: Django Application"
        return 0
    fi

    # Check for Flask patterns
    if find "$project_dir" -type f -name "*.py" -exec grep -l "from flask import\|import flask" {} \; 2>/dev/null | head -1 | grep -q .; then
        log_info "Project type: Flask Application"
        return 0
    fi

    # Check for FastAPI patterns
    if find "$project_dir" -type f -name "*.py" -exec grep -l "from fastapi import\|import fastapi" {} \; 2>/dev/null | head -1 | grep -q .; then
        log_info "Project type: FastAPI Application"
        return 0
    fi

    # Check for setup.py (library/package)
    if [ -f "$project_dir/setup.py" ] || [ -f "$project_dir/pyproject.toml" ]; then
        log_info "Project type: Python Library/Package"
        return 0
    fi

    # Check for __init__.py files (package structure)
    if find "$project_dir" -type f -name "__init__.py" 2>/dev/null | head -1 | grep -q .; then
        log_info "Project type: Python Package"
        return 0
    fi

    # Default to application
    log_info "Project type: Python Application"
    return 0
}

# ----------------------------------------
# Function 4: Parse Python dependency files
# ----------------------------------------
parse_python_dependencies() {
    local project_dir="${1:-.}"

    log_section "Python Dependencies Analysis"

    # Check requirements.txt
    if [ -f "$project_dir/requirements.txt" ]; then
        log_info "Found requirements.txt"
        local req_count
        req_count=$(grep -c "^[^#]" "$project_dir/requirements.txt" 2>/dev/null || echo "0")
        log_info "Dependencies in requirements.txt: $req_count"

        # Show top dependencies
        if [ "$req_count" -gt 0 ]; then
            log_subsection "Key dependencies:"
            head -5 "$project_dir/requirements.txt" | grep -v "^#" | while read -r dep; do
                [ -n "$dep" ] && log_info "  - $dep"
            done
        fi
    fi

    # Check pyproject.toml
    if [ -f "$project_dir/pyproject.toml" ]; then
        log_info "Found pyproject.toml"

        # Check for Poetry
        if grep -q "\[tool.poetry\]" "$project_dir/pyproject.toml" 2>/dev/null; then
            log_info "Package manager: Poetry"
        fi

        # Check for build system
        if grep -q "\[build-system\]" "$project_dir/pyproject.toml" 2>/dev/null; then
            log_info "Build system configuration detected"
        fi
    fi

    # Check setup.py
    if [ -f "$project_dir/setup.py" ]; then
        log_info "Found setup.py"
        if grep -q "install_requires" "$project_dir/setup.py" 2>/dev/null; then
            log_info "Dependencies defined in setup.py"
        fi
    fi

    # Check Pipfile (Pipenv)
    if [ -f "$project_dir/Pipfile" ]; then
        log_info "Found Pipfile (Pipenv)"
        log_info "Package manager: Pipenv"
    fi

    return 0
}

# ----------------------------------------
# Function 5: List Python packages/modules
# ----------------------------------------
list_python_packages() {
    local project_dir="${1:-.}"

    log_section "Python Package Structure"

    # Find directories with __init__.py (packages)
    local packages
    packages=$(find "$project_dir" -type f -name "__init__.py" 2>/dev/null | sed 's|/__init__.py||' | sort)

    if [ -n "$packages" ]; then
        log_subsection "Python packages found:"
        echo "$packages" | while read -r package; do
            local package_name
            package_name=$(basename "$package")
            log_info "  📦 $package_name (${package#"$project_dir"/})"
        done
    else
        log_warning "No Python packages found (no __init__.py files)"
    fi

    return 0
}

# ----------------------------------------
# Function 6: Analyze Python version requirements
# ----------------------------------------
analyze_python_version() {
    local project_dir="${1:-.}"

    log_section "Python Version Analysis"

    # Check .python-version file
    if [ -f "$project_dir/.python-version" ]; then
        local py_version
        py_version=$(cat "$project_dir/.python-version")
        log_info "Python version (from .python-version): $py_version"
    fi

    # Check runtime.txt (Heroku)
    if [ -f "$project_dir/runtime.txt" ]; then
        local runtime
        runtime=$(cat "$project_dir/runtime.txt")
        log_info "Runtime specification: $runtime"
    fi

    # Check pyproject.toml for Python version
    if [ -f "$project_dir/pyproject.toml" ] && grep -q "python" "$project_dir/pyproject.toml" 2>/dev/null; then
        local py_req
        py_req=$(grep -E "python.*=" "$project_dir/pyproject.toml" | head -1)
        [ -n "$py_req" ] && log_info "Python requirement: $py_req"
    fi

    return 0
}

# ----------------------------------------
# Main Function: Complete Python project scan
# ----------------------------------------
scan_python_project() {
    local project_dir="${1:-.}"

    log_phase "Python Project Structure Scan"
    log_info "Scanning directory: $project_dir"

    # Check if Python project exists
    if ! detect_python_files "$project_dir"; then
        log_error "No Python project detected in $project_dir"
        return 1
    fi

    # Run all analysis functions
    find_python_entry_points "$project_dir"
    identify_python_project_type "$project_dir"
    parse_python_dependencies "$project_dir"
    list_python_packages "$project_dir"
    analyze_python_version "$project_dir"

    log_success "Python project scan completed"
    return 0
}
