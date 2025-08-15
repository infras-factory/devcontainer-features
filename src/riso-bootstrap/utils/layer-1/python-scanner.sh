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
# Function 3a: Detect Python testing framework
# ----------------------------------------
detect_testing_framework() {
    local project_dir="${1:-.}"
    local testing_framework=""

    # Check for pytest
    if [ -f "$project_dir/pytest.ini" ] || [ -f "$project_dir/.pytest.ini" ]; then
        testing_framework="pytest"
        log_info "Testing framework: pytest (pytest.ini found)"
    elif [ -f "$project_dir/pyproject.toml" ] && grep -q "\[tool.pytest" "$project_dir/pyproject.toml" 2>/dev/null; then
        testing_framework="pytest"
        log_info "Testing framework: pytest (configured in pyproject.toml)"
    elif [ -f "$project_dir/setup.cfg" ] && grep -q "\[tool:pytest\]" "$project_dir/setup.cfg" 2>/dev/null; then
        testing_framework="pytest"
        log_info "Testing framework: pytest (configured in setup.cfg)"
    elif find "$project_dir" -type f -name "test_*.py" -o -name "*_test.py" 2>/dev/null | head -1 | grep -q .; then
        # Check if test files use pytest
        if find "$project_dir" -type f \( -name "test_*.py" -o -name "*_test.py" \) -exec grep -l "import pytest\|from pytest" {} \; 2>/dev/null | head -1 | grep -q .; then
            testing_framework="pytest"
            log_info "Testing framework: pytest (pytest imports in test files)"
        fi
    fi

    # Check for unittest
    if [ -z "$testing_framework" ]; then
        if find "$project_dir" -type f -name "test*.py" -exec grep -l "import unittest\|from unittest" {} \; 2>/dev/null | head -1 | grep -q .; then
            testing_framework="unittest"
            log_info "Testing framework: unittest (standard library)"
        fi
    fi

    # Check for coverage configuration
    if [ -f "$project_dir/.coveragerc" ]; then
        log_info "Coverage configuration: .coveragerc found"
    elif [ -f "$project_dir/pyproject.toml" ] && grep -q "\[tool.coverage" "$project_dir/pyproject.toml" 2>/dev/null; then
        log_info "Coverage configuration: configured in pyproject.toml"
    elif [ -f "$project_dir/setup.cfg" ] && grep -q "\[coverage:" "$project_dir/setup.cfg" 2>/dev/null; then
        log_info "Coverage configuration: configured in setup.cfg"
    fi

    if [ -z "$testing_framework" ]; then
        log_info "Testing framework: Not detected"
    fi

    return 0
}

# ----------------------------------------
# Function 3b: Detect framework-specific patterns
# ----------------------------------------
detect_framework_patterns() {
    local project_dir="${1:-.}"
    local framework="$2"

    case "$framework" in
        "Django")
            log_subsection "Django-specific patterns:"

            # Check for Django structure
            if [ -f "$project_dir/settings.py" ] || find "$project_dir" -name "settings.py" -type f 2>/dev/null | head -1 | grep -q .; then
                log_info "  - settings.py configuration found"
            fi

            if [ -f "$project_dir/urls.py" ] || find "$project_dir" -name "urls.py" -type f 2>/dev/null | head -1 | grep -q .; then
                log_info "  - urls.py routing found"
            fi

            if find "$project_dir" -name "models.py" -type f 2>/dev/null | head -1 | grep -q .; then
                log_info "  - models.py database models found"
            fi

            if find "$project_dir" -name "views.py" -type f 2>/dev/null | head -1 | grep -q .; then
                log_info "  - views.py found"
            fi

            if find "$project_dir" -name "admin.py" -type f 2>/dev/null | head -1 | grep -q .; then
                log_info "  - admin.py Django admin found"
            fi

            if [ -d "$project_dir/templates" ]; then
                log_info "  - templates directory found"
            fi

            if [ -d "$project_dir/static" ]; then
                log_info "  - static files directory found"
            fi
            ;;

        "Flask")
            log_subsection "Flask-specific patterns:"

            # Check for Flask app factory pattern
            if find "$project_dir" -name "*.py" -exec grep -l "def create_app" {} \; 2>/dev/null | head -1 | grep -q .; then
                log_info "  - App factory pattern detected"
            fi

            # Check for blueprints
            if find "$project_dir" -name "*.py" -exec grep -l "Blueprint\|from flask import.*Blueprint" {} \; 2>/dev/null | head -1 | grep -q .; then
                log_info "  - Flask blueprints detected"
            fi

            # Check for Flask extensions
            if find "$project_dir" -name "*.py" -exec grep -l "flask_sqlalchemy\|flask_migrate\|flask_login" {} \; 2>/dev/null | head -1 | grep -q .; then
                log_info "  - Flask extensions detected"
            fi

            if [ -d "$project_dir/templates" ]; then
                log_info "  - templates directory found"
            fi

            if [ -d "$project_dir/static" ]; then
                log_info "  - static files directory found"
            fi
            ;;

        "FastAPI")
            log_subsection "FastAPI-specific patterns:"

            # Check for routers
            if find "$project_dir" -name "*.py" -exec grep -l "APIRouter\|from fastapi import.*APIRouter" {} \; 2>/dev/null | head -1 | grep -q .; then
                log_info "  - FastAPI routers detected"
            fi

            # Check for Pydantic schemas
            if find "$project_dir" -name "*.py" -exec grep -l "BaseModel\|from pydantic import.*BaseModel" {} \; 2>/dev/null | head -1 | grep -q .; then
                log_info "  - Pydantic schemas detected"
            fi

            # Check for dependency injection
            if find "$project_dir" -name "*.py" -exec grep -l "Depends\|from fastapi import.*Depends" {} \; 2>/dev/null | head -1 | grep -q .; then
                log_info "  - Dependency injection patterns detected"
            fi

            # Check for async patterns
            if find "$project_dir" -name "*.py" -exec grep -l "async def" {} \; 2>/dev/null | head -1 | grep -q .; then
                log_info "  - Async/await patterns detected"
            fi

            if [ -d "$project_dir/routers" ]; then
                log_info "  - routers directory found"
            fi

            if [ -d "$project_dir/schemas" ]; then
                log_info "  - schemas directory found"
            fi
            ;;
    esac

    return 0
}

# ----------------------------------------
# Function 3: Identify Python project type
# ----------------------------------------
identify_python_project_type() {
    local project_dir="${1:-.}"

    log_section "Python Project Type Analysis"

    # Framework variable can be used for future enhancements
    # local framework_detected=""

    # Check for Django project
    if [ -f "$project_dir/manage.py" ] && grep -q "django" "$project_dir/manage.py" 2>/dev/null; then
        log_info "Project type: Django Application"
        # framework_detected="Django"
        detect_framework_patterns "$project_dir" "Django"
    # Check for Flask patterns
    elif find "$project_dir" -type f -name "*.py" -exec grep -l "from flask import\|import flask" {} \; 2>/dev/null | head -1 | grep -q .; then
        log_info "Project type: Flask Application"
        # framework_detected="Flask"
        detect_framework_patterns "$project_dir" "Flask"
    # Check for FastAPI patterns
    elif find "$project_dir" -type f -name "*.py" -exec grep -l "from fastapi import\|import fastapi" {} \; 2>/dev/null | head -1 | grep -q .; then
        log_info "Project type: FastAPI Application"
        # framework_detected="FastAPI"
        detect_framework_patterns "$project_dir" "FastAPI"
    # Check for setup.py (library/package)
    elif [ -f "$project_dir/setup.py" ] || [ -f "$project_dir/pyproject.toml" ]; then
        log_info "Project type: Python Library/Package"
    # Check for __init__.py files (package structure)
    elif find "$project_dir" -type f -name "__init__.py" 2>/dev/null | head -1 | grep -q .; then
        log_info "Project type: Python Package"
    else
        # Default to application
        log_info "Project type: Python Application"
    fi

    # Detect testing framework regardless of project type
    detect_testing_framework "$project_dir"

    return 0
}

# ----------------------------------------
# Function 4a: Categorize Python dependency by type
# ----------------------------------------
categorize_dependency() {
    local dep_name="$1"

    # Extract package name without version specifiers
    local package_name
    package_name=$(echo "$dep_name" | sed 's/[<>=!].*//' | sed 's/\[.*//')

    # Core/Framework dependencies
    case "$package_name" in
        django|Django|flask|Flask|fastapi|FastAPI|tornado|pyramid|bottle|starlette|sanic)
            echo "Core/Framework"
            return 0
            ;;
    esac

    # Database/ORM dependencies
    case "$package_name" in
        sqlalchemy|SQLAlchemy|psycopg2|psycopg2-binary|pymongo|PyMongo|redis|mysql-connector-python|mysqlclient|PyMySQL|peewee|tortoise-orm|asyncpg|elasticsearch)
            echo "Database/ORM"
            return 0
            ;;
    esac

    # Testing tools
    case "$package_name" in
        pytest|pytest-cov|pytest-flask|pytest-django|unittest2|nose|nose2|coverage|mock|tox|factory-boy|hypothesis|faker|httpx|requests-mock)
            echo "Testing"
            return 0
            ;;
    esac

    # Development tools
    case "$package_name" in
        mypy|mypy-extensions|black|Black|flake8|pyflakes|pycodestyle|isort|autopep8|pylint|bandit|pre-commit|sphinx|mkdocs|jupyter|ipython|pydantic|marshmallow)
            echo "Development"
            return 0
            ;;
    esac

    # Default to Other if not categorized
    echo "Other"
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

        # Initialize category counters
        local core_count=0
        local db_count=0
        local testing_count=0
        local dev_count=0
        local other_count=0

        # Arrays to store dependencies by category
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
                    ((core_count++))
                    ;;
                "Database/ORM")
                    db_deps+=("$line")
                    ((db_count++))
                    ;;
                "Testing")
                    testing_deps+=("$line")
                    ((testing_count++))
                    ;;
                "Development")
                    dev_deps+=("$line")
                    ((dev_count++))
                    ;;
                *)
                    other_deps+=("$line")
                    ((other_count++))
                    ;;
            esac
        done < "$project_dir/requirements.txt"

        # Display categorized dependencies
        local total_count=$((core_count + db_count + testing_count + dev_count + other_count))
        log_info "Total dependencies: $total_count"

        if [ "$core_count" -gt 0 ]; then
            log_subsection "Core/Framework dependencies: $core_count"
            for dep in "${core_deps[@]}"; do
                log_info "  - $dep"
            done
        fi

        if [ "$db_count" -gt 0 ]; then
            log_subsection "Database/ORM dependencies: $db_count"
            for dep in "${db_deps[@]}"; do
                log_info "  - $dep"
            done
        fi

        if [ "$testing_count" -gt 0 ]; then
            log_subsection "Testing dependencies: $testing_count"
            for dep in "${testing_deps[@]}"; do
                log_info "  - $dep"
            done
        fi

        if [ "$dev_count" -gt 0 ]; then
            log_subsection "Development dependencies: $dev_count"
            for dep in "${dev_deps[@]}"; do
                log_info "  - $dep"
            done
        fi

        if [ "$other_count" -gt 0 ]; then
            log_subsection "Other dependencies: $other_count"
            for dep in "${other_deps[@]}"; do
                log_info "  - $dep"
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
