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
# utils/layer-0/project-detector.sh - Multi-technology project detection
# ----------------------------------------

# ----------------------------------------
# Function 1: Detect all technologies in a project
# Returns: 0 if technologies found, 1 if none found
# ----------------------------------------
detect_project_technologies() {
    local project_path="${1:-.}"

    log_section "Project Technology Detection"
    log_info "Scanning project: $project_path"

    # Initialize detection results array
    declare -a detected_technologies=()

    # Detect each technology type
    if detect_bash_technology "$project_path"; then
        detected_technologies+=("bash")
    fi

    if detect_python_technology "$project_path"; then
        detected_technologies+=("python")
    fi

    if detect_nodejs_technology "$project_path"; then
        detected_technologies+=("nodejs")
    fi

    if detect_template_technology "$project_path"; then
        detected_technologies+=("template")
    fi

    # Output results
    if [ ${#detected_technologies[@]} -eq 0 ]; then
        log_warning "No technologies detected in project"
        return 1
    else
        log_success "Detected technologies: ${detected_technologies[*]}"

        # Export for other scripts to use
        export DETECTED_TECHNOLOGIES="${detected_technologies[*]}"
        export PRIMARY_TECHNOLOGY="${detected_technologies[0]}"

        # Determine architecture type
        if [ ${#detected_technologies[@]} -eq 1 ]; then
            export PROJECT_ARCHITECTURE="single-tech"
        else
            export PROJECT_ARCHITECTURE="multi-tech"
        fi

        log_info "Primary technology: $PRIMARY_TECHNOLOGY"
        log_info "Architecture: $PROJECT_ARCHITECTURE"

        return 0
    fi
}

# ----------------------------------------
# Function 2: Detect Bash scripts and DevContainer features
# ----------------------------------------
detect_bash_technology() {
    local project_path="$1"

    log_debug "Checking for Bash technology..."

    # Check for bash scripts
    if find "$project_path" -type f -name "*.sh" 2>/dev/null | head -1 | grep -q .; then
        log_debug "Found .sh files"

        # Determine bash project type
        if [ -f "$project_path/devcontainer-feature.json" ]; then
            export BASH_PROJECT_TYPE="devcontainer-feature"
            log_debug "Detected: DevContainer feature"
        elif [ -f "$project_path/install.sh" ] && [ -f "$project_path/scripts/post-create.sh" ]; then
            export BASH_PROJECT_TYPE="devcontainer-feature"
            log_debug "Detected: DevContainer feature (by structure)"
        else
            export BASH_PROJECT_TYPE="scripts"
            log_debug "Detected: General bash scripts"
        fi

        return 0
    fi

    return 1
}

# ----------------------------------------
# Function 3: Detect Python applications
# ----------------------------------------
detect_python_technology() {
    local project_path="$1"

    log_debug "Checking for Python technology..."

    # Check for Python files
    if find "$project_path" -type f -name "*.py" 2>/dev/null | head -1 | grep -q .; then
        log_debug "Found .py files"

        # Determine Python project type
        if [ -f "$project_path/requirements.txt" ] || [ -f "$project_path/pyproject.toml" ] || [ -f "$project_path/setup.py" ]; then
            if [ -f "$project_path/app.py" ] && grep -q "Flask" "$project_path/app.py" 2>/dev/null; then
                export PYTHON_PROJECT_TYPE="flask"
                log_debug "Detected: Flask application"
            elif [ -f "$project_path/main.py" ] && grep -q "FastAPI" "$project_path/main.py" 2>/dev/null; then
                export PYTHON_PROJECT_TYPE="fastapi"
                log_debug "Detected: FastAPI application"
            elif [ -f "$project_path/manage.py" ] && grep -q "django" "$project_path/manage.py" 2>/dev/null; then
                export PYTHON_PROJECT_TYPE="django"
                log_debug "Detected: Django application"
            else
                export PYTHON_PROJECT_TYPE="simple"
                log_debug "Detected: Python application"
            fi
        else
            export PYTHON_PROJECT_TYPE="simple"
            log_debug "Detected: Simple Python scripts"
        fi

        return 0
    fi

    return 1
}

# ----------------------------------------
# Function 4: Detect Node.js applications
# ----------------------------------------
detect_nodejs_technology() {
    local project_path="$1"

    log_debug "Checking for Node.js technology..."

    # Check for Node.js indicators
    if [ -f "$project_path/package.json" ]; then
        log_debug "Found package.json"

        # Determine Node.js project type
        if grep -q '"next"' "$project_path/package.json" 2>/dev/null; then
            export NODEJS_PROJECT_TYPE="nextjs"
            log_debug "Detected: Next.js application"
        elif grep -q '"react"' "$project_path/package.json" 2>/dev/null; then
            export NODEJS_PROJECT_TYPE="react"
            log_debug "Detected: React application"
        elif grep -q '"express"' "$project_path/package.json" 2>/dev/null; then
            export NODEJS_PROJECT_TYPE="express"
            log_debug "Detected: Express API"
        elif [ -f "$project_path/server.js" ] || [ -f "$project_path/app.js" ]; then
            export NODEJS_PROJECT_TYPE="server"
            log_debug "Detected: Node.js server"
        else
            export NODEJS_PROJECT_TYPE="library"
            log_debug "Detected: Node.js library/tool"
        fi

        return 0
    fi

    # Check for Node.js files without package.json
    if find "$project_path" -type f -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" 2>/dev/null | head -1 | grep -q .; then
        log_debug "Found JavaScript/TypeScript files"
        export NODEJS_PROJECT_TYPE="scripts"
        return 0
    fi

    return 1
}

# ----------------------------------------
# Function 5: Detect template/generator projects
# ----------------------------------------
detect_template_technology() {
    local project_path="$1"

    log_debug "Checking for Template technology..."

    # Check for Cookiecutter templates
    if [ -f "$project_path/cookiecutter.json" ]; then
        log_debug "Found cookiecutter.json"
        export TEMPLATE_PROJECT_TYPE="cookiecutter"
        log_debug "Detected: Cookiecutter template"
        return 0
    fi

    # Check for other template indicators
    if find "$project_path" -type f -name "*{{*}}*" 2>/dev/null | head -1 | grep -q .; then
        log_debug "Found template files with {{ }} syntax"
        export TEMPLATE_PROJECT_TYPE="jinja2"
        log_debug "Detected: Jinja2 template"
        return 0
    fi

    return 1
}

# ----------------------------------------
# Function 6: Get project name from various sources
# ----------------------------------------
detect_project_name() {
    local project_path="${1:-.}"

    # Try to get name from package.json
    if [ -f "$project_path/package.json" ]; then
        local name
        name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_path/package.json" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -n "$name" ]; then
            echo "$name"
            return 0
        fi
    fi

    # Try to get name from pyproject.toml
    if [ -f "$project_path/pyproject.toml" ]; then
        local name
        name=$(grep -o '^name[[:space:]]*=[[:space:]]*"[^"]*"' "$project_path/pyproject.toml" | sed 's/.*name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -n "$name" ]; then
            echo "$name"
            return 0
        fi
    fi

    # Try to get name from devcontainer-feature.json
    if [ -f "$project_path/devcontainer-feature.json" ]; then
        local name
        name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_path/devcontainer-feature.json" | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -n "$name" ]; then
            echo "$name"
            return 0
        fi
    fi

    # Try to get name from cookiecutter.json
    if [ -f "$project_path/cookiecutter.json" ]; then
        local name
        name=$(grep -o '"project_name"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_path/cookiecutter.json" | sed 's/.*"project_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -n "$name" ]; then
            echo "$name"
            return 0
        fi
    fi

    # Fallback to directory name
    basename "$project_path"
}

# ----------------------------------------
# Function 7: Generate technology summary
# ----------------------------------------
generate_technology_summary() {
    local project_path="${1:-.}"

    log_subsection "Technology Summary"

    # Ensure detection has been run
    if [ -z "$DETECTED_TECHNOLOGIES" ]; then
        detect_project_technologies "$project_path"
    fi

    # Display summary
    local project_name
    project_name=$(detect_project_name "$project_path")

    log_info "Project: $project_name"
    log_info "Primary Technology: $PRIMARY_TECHNOLOGY"
    log_info "All Technologies: $DETECTED_TECHNOLOGIES"
    log_info "Architecture: $PROJECT_ARCHITECTURE"

    # Display technology-specific details
    for tech in $DETECTED_TECHNOLOGIES; do
        case "$tech" in
            "bash")
                log_info "  • Bash: $BASH_PROJECT_TYPE"
                ;;
            "python")
                log_info "  • Python: $PYTHON_PROJECT_TYPE"
                ;;
            "nodejs")
                log_info "  • Node.js: $NODEJS_PROJECT_TYPE"
                ;;
            "template")
                log_info "  • Template: $TEMPLATE_PROJECT_TYPE"
                ;;
        esac
    done
}

# ----------------------------------------
# Main function for standalone execution
# ----------------------------------------
main() {
    local project_path="${1:-.}"

    if [ ! -d "$project_path" ]; then
        log_error "Project path does not exist: $project_path"
        exit 1
    fi

    detect_project_technologies "$project_path"
    generate_technology_summary "$project_path"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
