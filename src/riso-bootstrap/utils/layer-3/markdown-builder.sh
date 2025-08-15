#!/bin/bash
set -e

# ----------------------------------------
# Local Variables
# ----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LAYER_ZERO_DIR="${BASE_DIR}/layer-0"
LAYER_TWO_DIR="${BASE_DIR}/layer-2"

# ----------------------------------------
# Import Utilities
# ----------------------------------------
# shellcheck source=../layer-0/logger.sh disable=SC1091
source "${LAYER_ZERO_DIR}/logger.sh"
# shellcheck source=../layer-0/project-detector.sh disable=SC1091
source "${LAYER_ZERO_DIR}/project-detector.sh"
# shellcheck source=../layer-2/bash-section-generator.sh disable=SC1091
source "${LAYER_TWO_DIR}/bash-section-generator.sh"
# shellcheck source=../layer-2/python-section-generator.sh disable=SC1091
source "${LAYER_TWO_DIR}/python-section-generator.sh"

# ----------------------------------------
# utils/layer-2/markdown-builder.sh - Central PROJECT.md generator
# ----------------------------------------

# ----------------------------------------
# Function 1: Generate complete PROJECT.md for any project type
# Returns: 0 on success, 1 on failure
# ----------------------------------------
generate_project_markdown() {
    local project_path="${1:-.}"
    local output_file="${2:-PROJECT.md}"
    local force_overwrite="${3:-false}"

    log_workflow_start "PROJECT.md Generation"
    log_workflow_step "Validating input parameters"
    log_file_operation "Target output" "$output_file"
    log_workflow_substep "Project path: $(realpath "$project_path")"

    # Validate inputs
    if [ ! -d "$project_path" ]; then
        log_error "Project path does not exist: $project_path"
        return 1
    fi

    # Check if output file exists
    if [ -f "$output_file" ] && [ "$force_overwrite" != "true" ]; then
        log_warning "Output file exists: $output_file"
        log_info "Use force_overwrite=true to overwrite"
        return 1
    fi

    # Detect all technologies in the project
    log_workflow_step "Detecting project technologies"
    if ! detect_project_technologies "$project_path"; then
        log_error "No technologies detected in project"
        log_workflow_end "PROJECT.md Generation" "failed"
        return 1
    fi

    # Initialize output file
    log_workflow_step "Initializing PROJECT.md structure"
    initialize_project_markdown "$project_path" "$output_file"

    # Generate technology-specific sections
    log_workflow_step "Generating technology-specific sections"
    generate_technology_sections "$project_path" "$output_file"

    # Add universal sections
    log_workflow_step "Adding universal project sections"
    generate_universal_sections "$project_path" "$output_file"

    # Finalize document
    finalize_project_markdown "$project_path" "$output_file"

    log_workflow_end "PROJECT.md Generation"
    log_result "Generated $(wc -l < "$output_file") lines in $output_file"
    return 0
}

# ----------------------------------------
# Function 2: Initialize PROJECT.md with header and overview
# ----------------------------------------
initialize_project_markdown() {
    local project_path="$1"
    local output_file="$2"

    log_subsection "Initializing Document"

    # Get project metadata
    local project_name project_description
    project_name=$(detect_project_name "$project_path")
    project_description=$(detect_project_description "$project_path")

    # Create header
    cat > "$output_file" << EOF
# $project_name

$project_description

## 📋 Project Overview

**Primary Technology:** $PRIMARY_TECHNOLOGY
**Architecture:** $PROJECT_ARCHITECTURE
**Technologies:** $DETECTED_TECHNOLOGIES

EOF

    # Add project structure
    generate_project_structure_section "$project_path" "$output_file"

    log_debug "Document header initialized"
}

# ----------------------------------------
# Function 3: Generate project structure overview
# ----------------------------------------
generate_project_structure_section() {
    local project_path="$1"
    local output_file="$2"

    {
        cat << EOF

### 📁 Project Structure

\`\`\`
EOF

        # Generate simplified tree structure
        generate_simplified_tree "$project_path"

        cat << EOF
\`\`\`

EOF
    } >> "$output_file"
}

# ----------------------------------------
# Function 4: Generate simplified directory tree
# ----------------------------------------
generate_simplified_tree() {
    local project_path="$1"
    local max_files=20

    # Use find to create a simplified tree
    (
        cd "$project_path" || return 1

        # Show directories first
        find . -type d -not -path '*/.*' | head -n 10 | sort | sed 's|^./||' | sed 's|^|├── |'

        # Show important files
        find . -maxdepth 2 -type f \( -name "*.md" -o -name "*.json" -o -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) -not -path '*/.*' | head -n 10 | sort | sed 's|^./||' | sed 's|^|├── |'

    ) | head -n $max_files
}

# ----------------------------------------
# Function 5: Generate technology-specific sections
# ----------------------------------------
generate_technology_sections() {
    local project_path="$1"
    local output_file="$2"

    log_subsection "Technology Sections"

    # Generate section for each detected technology
    for tech in $DETECTED_TECHNOLOGIES; do
        log_info "Generating $tech section..."

        case "$tech" in
            "bash")
                generate_bash_technology_section "$project_path" "$output_file"
                ;;
            "python")
                generate_python_technology_section "$project_path" "$output_file"
                ;;
            "nodejs")
                generate_nodejs_technology_section "$project_path" "$output_file"
                ;;
            "template")
                generate_template_technology_section "$project_path" "$output_file"
                ;;
            *)
                log_warning "Unknown technology: $tech"
                ;;
        esac
    done
}

# ----------------------------------------
# Function 6: Generate bash technology section
# ----------------------------------------
generate_bash_technology_section() {
    local project_path="$1"
    local output_file="$2"

    log_workflow_substep "Generating bash section"
    # Generate bash section content and append to output file
    generate_bash_section "$project_path" >> "$output_file"
    log_result "Bash section added to PROJECT.md"
}

# ----------------------------------------
# Function 7: Generate python technology section
# ----------------------------------------
generate_python_technology_section() {
    local project_path="$1"
    local output_file="$2"

    log_workflow_substep "Generating Python section"

    # Generate Python section content and append to output file
    local python_section
    python_section=$(generate_python_section "$project_path")

    if [ -n "$python_section" ]; then
        echo -e "\n## 🐍 Python Technology\n" >> "$output_file"
        echo -e "$python_section" >> "$output_file"
        log_result "Python section added to PROJECT.md"
    else
        log_warning "Failed to generate Python section"
    fi
}

# ----------------------------------------
# Function 8: Generate nodejs technology section (placeholder)
# ----------------------------------------
generate_nodejs_technology_section() {
    local project_path="$1"
    local output_file="$2"

    cat >> "$output_file" << EOF

## 🟢 Node.js Application

### Overview
This project contains Node.js code for ${NODEJS_PROJECT_TYPE} development.

### Node.js Project Type
**Type:** $NODEJS_PROJECT_TYPE

### Installation
\`\`\`bash
# Install dependencies
npm install

# Run the application
npm start
\`\`\`

EOF

    log_debug "Node.js section generated (placeholder)"
}

# ----------------------------------------
# Function 9: Generate template technology section (placeholder)
# ----------------------------------------
generate_template_technology_section() {
    local project_path="$1"
    local output_file="$2"

    cat >> "$output_file" << EOF

## 📄 Template Project

### Overview
This project contains templates for ${TEMPLATE_PROJECT_TYPE} generation.

### Template Type
**Type:** $TEMPLATE_PROJECT_TYPE

### Usage
\`\`\`bash
# Generate from template
cookiecutter .
\`\`\`

EOF

    log_debug "Template section generated (placeholder)"
}

# ----------------------------------------
# Function 10: Generate universal sections (development, contributing, etc.)
# ----------------------------------------
generate_universal_sections() {
    local project_path="$1"
    local output_file="$2"

    log_subsection "Universal Sections"

    # Development section
    generate_development_section "$project_path" "$output_file"

    # Contributing section
    generate_contributing_section "$project_path" "$output_file"

    # License section
    generate_license_section "$project_path" "$output_file"
}

# ----------------------------------------
# Function 11: Generate development section
# ----------------------------------------
generate_development_section() {
    local project_path="$1"
    local output_file="$2"

    cat >> "$output_file" << EOF

## 🛠️ Development

### Prerequisites
EOF

    # Add technology-specific prerequisites
    for tech in $DETECTED_TECHNOLOGIES; do
        case "$tech" in
            "bash")
                cat >> "$output_file" << EOF
- Bash 4.0 or higher
- Standard Unix utilities
EOF
                ;;
            "python")
                cat >> "$output_file" << EOF
- Python 3.8 or higher
- pip package manager
EOF
                ;;
            "nodejs")
                cat >> "$output_file" << EOF
- Node.js 16 or higher
- npm package manager
EOF
                ;;
        esac
    done

    cat >> "$output_file" << EOF

### Development Workflow
1. Clone the repository
2. Install dependencies
3. Make your changes
4. Test your changes
5. Submit a pull request

EOF

    # Add testing section if test files exist
    if find "$project_path" -name "*test*" -o -name "*spec*" | grep -q .; then
        cat >> "$output_file" << EOF

### Testing
\`\`\`bash
# Run tests
./test.sh
\`\`\`

EOF
    fi
}

# ----------------------------------------
# Function 12: Generate contributing section
# ----------------------------------------
generate_contributing_section() {
    local project_path="$1"
    local output_file="$2"

    cat >> "$output_file" << EOF

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Ensure all tests pass
6. Submit a pull request

### Code Style
EOF

    # Add technology-specific style guidelines
    for tech in $DETECTED_TECHNOLOGIES; do
        case "$tech" in
            "bash")
                cat >> "$output_file" << EOF
- Follow shellcheck recommendations
- Use proper error handling with \`set -e\`
- Include comprehensive logging
EOF
                ;;
            "python")
                cat >> "$output_file" << EOF
- Follow PEP 8 style guidelines
- Use type hints where appropriate
- Include docstrings for functions
EOF
                ;;
            "nodejs")
                cat >> "$output_file" << EOF
- Follow ESLint configuration
- Use consistent formatting with Prettier
- Include JSDoc comments
EOF
                ;;
        esac
    done

    echo "" >> "$output_file"
}

# ----------------------------------------
# Function 13: Generate license section
# ----------------------------------------
generate_license_section() {
    local project_path="$1"
    local output_file="$2"

    # Check if LICENSE file exists
    local license_file=""
    for file in LICENSE LICENSE.txt LICENSE.md license license.txt license.md; do
        if [ -f "$project_path/$file" ]; then
            license_file="$file"
            break
        fi
    done

    if [ -n "$license_file" ]; then
        cat >> "$output_file" << EOF

## 📄 License

This project is licensed under the terms of the [$license_file]($license_file) file.

EOF
    else
        cat >> "$output_file" << EOF

## 📄 License

Please see the license file for details.

EOF
    fi
}

# ----------------------------------------
# Function 14: Finalize PROJECT.md document
# ----------------------------------------
finalize_project_markdown() {
    local project_path="$1"
    local output_file="$2"

    # Add footer
    cat >> "$output_file" << EOF

---

*This PROJECT.md was generated automatically by riso-bootstrap.*

EOF

    log_debug "Document finalized"
}

# ----------------------------------------
# Function 15: Detect project description from various sources
# ----------------------------------------
detect_project_description() {
    local project_path="$1"

    # Try README files first
    for readme in README.md README.txt readme.md readme.txt; do
        if [ -f "$project_path/$readme" ]; then
            # Extract first paragraph or line that looks like a description
            local desc
            desc=$(head -n 10 "$project_path/$readme" | grep -v "^#" | grep -v "^$" | head -n 1)
            if [ -n "$desc" ]; then
                echo "$desc"
                return 0
            fi
        fi
    done

    # Try package.json description
    if [ -f "$project_path/package.json" ]; then
        local desc
        desc=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_path/package.json" | sed 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -n "$desc" ]; then
            echo "$desc"
            return 0
        fi
    fi

    # Try devcontainer-feature.json description
    if [ -f "$project_path/devcontainer-feature.json" ]; then
        local desc
        desc=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_path/devcontainer-feature.json" | sed 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -n "$desc" ]; then
            echo "$desc"
            return 0
        fi
    fi

    # Fallback description
    echo "A $PRIMARY_TECHNOLOGY project with $PROJECT_ARCHITECTURE architecture."
}

# ----------------------------------------
# Function 16: Fallback bash section (simplified)
# ----------------------------------------
generate_fallback_bash_section() {
    local project_path="$1"
    local output_file="$2"

    cat >> "$output_file" << EOF

## 📜 Bash Scripts

### Overview
This project contains bash scripts for automation.

### Project Type
**Type:** $BASH_PROJECT_TYPE

EOF
}

# ----------------------------------------
# Main function for standalone execution
# ----------------------------------------
main() {
    local project_path="${1:-.}"
    local output_file="${2:-PROJECT.md}"
    local force_overwrite="${3:-false}"

    generate_project_markdown "$project_path" "$output_file" "$force_overwrite"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
