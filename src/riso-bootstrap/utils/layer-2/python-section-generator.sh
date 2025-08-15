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

# shellcheck source=../layer-1/python-scanner.sh disable=SC1091
source "${LAYER_ONE_DIR}/python-scanner.sh"

# ----------------------------------------
# utils/layer-2/python-section-generator.sh - Generate Python section for PROJECT.md
# ----------------------------------------

# ----------------------------------------
# Function: Generate Python dependencies markdown
# ----------------------------------------
generate_python_dependencies_markdown() {
    local project_dir="${1:-.}"
    local markdown=""

    # Check requirements.txt
    if [ -f "$project_dir/requirements.txt" ]; then
        # Initialize category arrays
        declare -a core_deps=()
        declare -a db_deps=()
        declare -a testing_deps=()
        declare -a dev_deps=()
        declare -a other_deps=()

        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue

            local category
            category=$(categorize_dependency "$line")

            case "$category" in
                "Core/Framework")
                    core_deps+=("$line")
                    ;;
                "Database/ORM")
                    db_deps+=("$line")
                    ;;
                "Testing")
                    testing_deps+=("$line")
                    ;;
                "Development")
                    dev_deps+=("$line")
                    ;;
                *)
                    other_deps+=("$line")
                    ;;
            esac
        done < "$project_dir/requirements.txt"

        # Generate markdown for each category
        if [ ${#core_deps[@]} -gt 0 ]; then
            markdown+="##### Core/Framework\n"
            for dep in "${core_deps[@]}"; do
                markdown+="- $dep\n"
            done
            markdown+="\n"
        fi

        if [ ${#db_deps[@]} -gt 0 ]; then
            markdown+="##### Database/ORM\n"
            for dep in "${db_deps[@]}"; do
                markdown+="- $dep\n"
            done
            markdown+="\n"
        fi

        if [ ${#testing_deps[@]} -gt 0 ]; then
            markdown+="##### Testing\n"
            for dep in "${testing_deps[@]}"; do
                markdown+="- $dep\n"
            done
            markdown+="\n"
        fi

        if [ ${#dev_deps[@]} -gt 0 ]; then
            markdown+="##### Development\n"
            for dep in "${dev_deps[@]}"; do
                markdown+="- $dep\n"
            done
            markdown+="\n"
        fi

        if [ ${#other_deps[@]} -gt 0 ]; then
            markdown+="##### Other\n"
            for dep in "${other_deps[@]}"; do
                markdown+="- $dep\n"
            done
            markdown+="\n"
        fi
    fi

    echo -e "$markdown"
}

# ----------------------------------------
# Function: Detect Python framework type
# ----------------------------------------
detect_python_framework() {
    local project_dir="${1:-.}"
    local framework=""

    # Check for Django project
    if [ -f "$project_dir/manage.py" ] && grep -q "django" "$project_dir/manage.py" 2>/dev/null; then
        framework="Django"
    # Check for Flask patterns
    elif find "$project_dir" -type f -name "*.py" -exec grep -l "from flask import\|import flask" {} \; 2>/dev/null | head -1 | grep -q .; then
        framework="Flask"
    # Check for FastAPI patterns
    elif find "$project_dir" -type f -name "*.py" -exec grep -l "from fastapi import\|import fastapi" {} \; 2>/dev/null | head -1 | grep -q .; then
        framework="FastAPI"
    fi

    echo "$framework"
}

# ----------------------------------------
# Function: Detect Python testing framework
# ----------------------------------------
detect_python_testing_framework() {
    local project_dir="${1:-.}"
    local testing_framework=""

    # Check for pytest
    if [ -f "$project_dir/pytest.ini" ] || [ -f "$project_dir/.pytest.ini" ]; then
        testing_framework="pytest"
    elif [ -f "$project_dir/pyproject.toml" ] && grep -q "\[tool.pytest" "$project_dir/pyproject.toml" 2>/dev/null; then
        testing_framework="pytest"
    elif [ -f "$project_dir/setup.cfg" ] && grep -q "\[tool:pytest\]" "$project_dir/setup.cfg" 2>/dev/null; then
        testing_framework="pytest"
    elif find "$project_dir" -type f -name "test_*.py" -o -name "*_test.py" 2>/dev/null | head -1 | grep -q .; then
        # Check if test files use pytest
        if find "$project_dir" -type f \( -name "test_*.py" -o -name "*_test.py" \) -exec grep -l "import pytest\|from pytest" {} \; 2>/dev/null | head -1 | grep -q .; then
            testing_framework="pytest"
        fi
    fi

    # Check for unittest
    if [ -z "$testing_framework" ]; then
        if find "$project_dir" -type f -name "test*.py" -exec grep -l "import unittest\|from unittest" {} \; 2>/dev/null | head -1 | grep -q .; then
            testing_framework="unittest"
        fi
    fi

    echo "$testing_framework"
}

# ----------------------------------------
# Function: Generate Python section for PROJECT.md
# ----------------------------------------
generate_python_section() {
    local project_dir="${1:-.}"
    local section=""

    log_phase "Generating Python Section for PROJECT.md"

    # Check if Python project exists
    if ! detect_python_files "$project_dir" >/dev/null 2>&1; then
        log_warning "No Python files detected, skipping Python section"
        return 1
    fi

    section+="### Python Application\n\n"

    # Structure section
    section+="#### Structure\n"

    # Find entry points
    local entry_points=()
    local entry_patterns=("main.py" "app.py" "manage.py" "wsgi.py" "asgi.py" "run.py" "server.py" "__main__.py")

    for pattern in "${entry_patterns[@]}"; do
        if find "$project_dir" -type f -name "$pattern" 2>/dev/null | head -1 | grep -q .; then
            local entry_files
            entry_files=$(find "$project_dir" -type f -name "$pattern" 2>/dev/null | sed "s|^$project_dir/||")
            for file in $entry_files; do
                entry_points+=("$file")
            done
        fi
    done

    if [ ${#entry_points[@]} -gt 0 ]; then
        section+="- **Entry Points**: "
        local first=true
        for entry in "${entry_points[@]}"; do
            if [ "$first" = true ]; then
                section+="$entry"
                first=false
            else
                section+=", $entry"
            fi
        done
        section+="\n"
    else
        section+="- **Entry Points**: None detected\n"
    fi

    # Find packages
    local packages
    packages=$(find "$project_dir" -type f -name "__init__.py" 2>/dev/null | sed 's|/__init__.py||' | sed "s|^$project_dir/||" | grep -v "^$" | sort -u)

    if [ -n "$packages" ]; then
        section+="- **Packages**: "
        local first=true
        echo "$packages" | while read -r package; do
            if [ "$first" = true ]; then
                echo -n "$package"
                first=false
            else
                echo -n ", $package"
            fi
        done >> /tmp/packages_list.txt
        if [ -f /tmp/packages_list.txt ]; then
            section+="$(cat /tmp/packages_list.txt)"
            rm -f /tmp/packages_list.txt
        fi
        section+="\n"
    else
        section+="- **Packages**: No packages found\n"
    fi

    # Find test directories
    local test_dirs=""
    if [ -d "$project_dir/tests" ]; then
        test_dirs="tests"
    elif [ -d "$project_dir/test" ]; then
        test_dirs="test"
    fi

    if [ -n "$test_dirs" ]; then
        section+="- **Tests**: $test_dirs/\n"
    else
        section+="- **Tests**: No test directory found\n"
    fi

    section+="\n"

    # Dependencies section
    section+="#### Dependencies\n"

    local deps_markdown
    deps_markdown=$(generate_python_dependencies_markdown "$project_dir")

    if [ -n "$deps_markdown" ]; then
        section+="$deps_markdown"
    else
        section+="No dependencies file found\n\n"
    fi

    # Configuration section
    section+="#### Configuration\n"

    # Python version
    local python_version=""
    if [ -f "$project_dir/.python-version" ]; then
        python_version=$(cat "$project_dir/.python-version")
        section+="- **Python Version**: $python_version\n"
    elif [ -f "$project_dir/runtime.txt" ]; then
        python_version=$(sed 's/python-//' < "$project_dir/runtime.txt")
        section+="- **Python Version**: $python_version\n"
    elif [ -f "$project_dir/pyproject.toml" ] && grep -q "python" "$project_dir/pyproject.toml" 2>/dev/null; then
        local py_req
        py_req=$(grep -E "python.*=" "$project_dir/pyproject.toml" | head -1 | sed 's/.*=.*"\(.*\)".*/\1/')
        if [ -n "$py_req" ]; then
            section+="- **Python Version**: $py_req\n"
        else
            section+="- **Python Version**: Not specified\n"
        fi
    else
        section+="- **Python Version**: Not specified\n"
    fi

    # Package manager
    local package_manager=""
    if [ -f "$project_dir/Pipfile" ]; then
        package_manager="Pipenv"
    elif [ -f "$project_dir/poetry.lock" ] || ([ -f "$project_dir/pyproject.toml" ] && grep -q "\[tool.poetry\]" "$project_dir/pyproject.toml" 2>/dev/null); then
        package_manager="Poetry"
    elif [ -f "$project_dir/requirements.txt" ]; then
        package_manager="pip"
    fi

    if [ -n "$package_manager" ]; then
        section+="- **Package Manager**: $package_manager\n"
    else
        section+="- **Package Manager**: Not detected\n"
    fi

    # Framework
    local framework
    framework=$(detect_python_framework "$project_dir")
    if [ -n "$framework" ]; then
        section+="- **Framework**: $framework\n"
    else
        section+="- **Framework**: None detected\n"
    fi

    # Testing framework
    local testing_framework
    testing_framework=$(detect_python_testing_framework "$project_dir")
    if [ -n "$testing_framework" ]; then
        section+="- **Testing Framework**: $testing_framework\n"
    else
        section+="- **Testing Framework**: None detected\n"
    fi

    section+="\n"

    echo -e "$section"
    log_success "Python section generated successfully"
    return 0
}

# ----------------------------------------
# Main Function: Add Python section to PROJECT.md
# ----------------------------------------
add_python_section_to_project_md() {
    local project_dir="${1:-.}"
    local project_md_path="$project_dir/.context/PROJECT.md"

    log_phase "Adding Python Section to PROJECT.md"

    # Generate Python section
    local python_section
    python_section=$(generate_python_section "$project_dir")

    if [ -z "$python_section" ]; then
        log_warning "No Python section generated"
        return 1
    fi

    # Check if PROJECT.md exists
    if [ ! -f "$project_md_path" ]; then
        log_error "PROJECT.md not found at $project_md_path"
        log_info "Please run markdown-builder.sh first to create PROJECT.md"
        return 1
    fi

    # Check if Python section already exists
    if grep -q "### Python Application" "$project_md_path" 2>/dev/null; then
        log_info "Python section already exists in PROJECT.md, updating..."

        # Create temp file
        local temp_file="/tmp/project_md_temp_$$"

        # Process the file
        awk -v section="$python_section" '
            BEGIN { in_python = 0; printed = 0 }
            /^### Python Application/ { in_python = 1; next }
            /^### / && in_python { in_python = 0; print section; printed = 1 }
            !in_python { print }
            END { if (in_python && !printed) print section }
        ' "$project_md_path" > "$temp_file"

        # Replace original file
        mv "$temp_file" "$project_md_path"
        log_success "Python section updated in PROJECT.md"
    else
        # Find the right place to insert Python section
        # Look for "## Technologies Detected" section
        if grep -q "## Technologies Detected" "$project_md_path" 2>/dev/null; then
            log_info "Adding Python section to Technologies Detected..."

            # Create temp file
            local temp_file="/tmp/project_md_temp_$$"

            # Process the file
            awk -v section="$python_section" '
                /^## Technologies Detected/ {
                    print
                    getline
                    print
                    print section
                    next
                }
                { print }
            ' "$project_md_path" > "$temp_file"

            # Replace original file
            mv "$temp_file" "$project_md_path"
            log_success "Python section added to PROJECT.md"
        else
            # Append at the end
            log_info "Appending Python section to PROJECT.md..."
            echo -e "\n## Technologies Detected\n\n$python_section" >> "$project_md_path"
            log_success "Python section appended to PROJECT.md"
        fi
    fi

    return 0
}
