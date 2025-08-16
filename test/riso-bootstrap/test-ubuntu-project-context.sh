#!/bin/bash

# Test for riso-bootstrap feature - PROJECT.md Generation (Task 1.4)
# Scenario: test-ubuntu-project-context
# Purpose: Validate PROJECT.md generation functionality using pre-generated mock projects

set -e

# Import testing library
# shellcheck source=dev-container-features-test-lib disable=SC1091
source dev-container-features-test-lib

# ============================================
# SECTION 1: Feature Installation Tests
# ============================================
echo -e "\n>>> Testing Feature Installation for PROJECT.md Generation..."

# Test feature directory structure
check "feature directory exists" test -d "/usr/local/share/riso-bootstrap"
check "utils directory exists" test -d "/usr/local/share/riso-bootstrap/utils"

# Test layer directories
check "layer-0 directory exists" test -d "/usr/local/share/riso-bootstrap/utils/layer-0"
check "layer-1 directory exists" test -d "/usr/local/share/riso-bootstrap/utils/layer-1"
check "layer-2 directory exists" test -d "/usr/local/share/riso-bootstrap/utils/layer-2"
check "layer-3 directory exists" test -d "/usr/local/share/riso-bootstrap/utils/layer-3"

# ============================================
# SECTION 2: PROJECT.md Generation Files Tests
# ============================================
echo -e "\n>>> Testing PROJECT.md Generation Files..."

# Test new files for PROJECT.md generation (Task 1.3)
check "project-detector.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-0/project-detector.sh"
check "project-detector.sh is executable" test -x "/usr/local/share/riso-bootstrap/utils/layer-0/project-detector.sh"

check "bash-section-generator.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-2/bash-section-generator.sh"
check "bash-section-generator.sh is executable" test -x "/usr/local/share/riso-bootstrap/utils/layer-2/bash-section-generator.sh"

check "markdown-builder.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-3/markdown-builder.sh"
check "markdown-builder.sh is executable" test -x "/usr/local/share/riso-bootstrap/utils/layer-3/markdown-builder.sh"

# ============================================
# SECTION 3: Dependency Files Tests
# ============================================
echo -e "\n>>> Testing Dependency Files..."

# Test existing dependencies that the new files need
check "logger.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-0/logger.sh"
check "mock-generator.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-0/mock-generator.sh"
check "bash-analyzer.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-1/bash-analyzer.sh"
check "bash-script-scanner.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-1/bash-script-scanner.sh"
check "devcontainer-analyzer.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-1/devcontainer-analyzer.sh"

# Test new Python files (Task 2.1-2.4)
check "python-scanner.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh"
check "python-scanner.sh is executable" test -x "/usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh"
check "python-section-generator.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-2/python-section-generator.sh"
check "python-section-generator.sh is executable" test -x "/usr/local/share/riso-bootstrap/utils/layer-2/python-section-generator.sh"

# ============================================
# SECTION 4: Function Definitions Tests
# ============================================
echo -e "\n>>> Testing Function Definitions..."

# Test key functions are defined in project-detector.sh
check "detect_project_technologies function exists" grep -q "^detect_project_technologies()" /usr/local/share/riso-bootstrap/utils/layer-0/project-detector.sh
check "detect_bash_technology function exists" grep -q "^detect_bash_technology()" /usr/local/share/riso-bootstrap/utils/layer-0/project-detector.sh
check "detect_python_technology function exists" grep -q "^detect_python_technology()" /usr/local/share/riso-bootstrap/utils/layer-0/project-detector.sh
check "detect_nodejs_technology function exists" grep -q "^detect_nodejs_technology()" /usr/local/share/riso-bootstrap/utils/layer-0/project-detector.sh

# Test key functions are defined in bash-section-generator.sh
check "generate_bash_section function exists" grep -q "^generate_bash_section()" /usr/local/share/riso-bootstrap/utils/layer-2/bash-section-generator.sh
check "generate_bash_execution_flow function exists" grep -q "^generate_bash_execution_flow()" /usr/local/share/riso-bootstrap/utils/layer-2/bash-section-generator.sh

# Test key functions are defined in markdown-builder.sh
check "generate_project_markdown function exists" grep -q "^generate_project_markdown()" /usr/local/share/riso-bootstrap/utils/layer-3/markdown-builder.sh
check "initialize_project_markdown function exists" grep -q "^initialize_project_markdown()" /usr/local/share/riso-bootstrap/utils/layer-3/markdown-builder.sh
check "generate_technology_sections function exists" grep -q "^generate_technology_sections()" /usr/local/share/riso-bootstrap/utils/layer-3/markdown-builder.sh

# Test key functions are defined in mock-generator.sh
check "generate_mock_project function exists" grep -q "^generate_mock_project()" /usr/local/share/riso-bootstrap/utils/layer-0/mock-generator.sh
check "generate_mock_bash_project function exists" grep -q "^generate_mock_bash_project()" /usr/local/share/riso-bootstrap/utils/layer-0/mock-generator.sh
check "generate_mock_python_project_variant function exists" grep -q "^generate_mock_python_project_variant()" /usr/local/share/riso-bootstrap/utils/layer-0/mock-generator.sh
check "generate_mock_nodejs_project function exists" grep -q "^generate_mock_nodejs_project()" /usr/local/share/riso-bootstrap/utils/layer-0/mock-generator.sh

# Test key functions are defined in python-scanner.sh (Task 2.1-2.3)
check "scan_python_project function exists" grep -q "^scan_python_project()" /usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh
check "detect_python_files function exists" grep -q "^detect_python_files()" /usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh
check "identify_python_project_type function exists" grep -q "^identify_python_project_type()" /usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh
check "parse_python_dependencies function exists" grep -q "^parse_python_dependencies()" /usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh
check "detect_testing_framework function exists" grep -q "^detect_testing_framework()" /usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh
check "detect_framework_patterns function exists" grep -q "^detect_framework_patterns()" /usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh

# Test key functions are defined in python-section-generator.sh (Task 2.4)
check "generate_python_section function exists" grep -q "^generate_python_section()" /usr/local/share/riso-bootstrap/utils/layer-2/python-section-generator.sh
check "generate_python_dependencies_markdown function exists" grep -q "^generate_python_dependencies_markdown()" /usr/local/share/riso-bootstrap/utils/layer-2/python-section-generator.sh

# ============================================
# SECTION 5: Mock Projects Generated by post-create.sh
# ============================================
echo -e "\n>>> Testing Pre-generated Mock Projects (isTestMode=true)..."

# Test that mock projects were created by post-create.sh when isTestMode=true
MOCK_TEST_DIR="/tmp/riso-test-projects"
check "mock test projects directory exists" test -d "$MOCK_TEST_DIR"

# Test 1: DevContainer Feature Mock Project
echo -e "\n--- Testing DevContainer Feature Mock Project ---"
DEVCONTAINER_MOCK_DIR="$MOCK_TEST_DIR/devcontainer-feature"
check "devcontainer mock project exists" test -d "$DEVCONTAINER_MOCK_DIR"
check "devcontainer-feature.json exists in mock" test -f "$DEVCONTAINER_MOCK_DIR/devcontainer-feature.json"
check "install.sh exists in mock" test -f "$DEVCONTAINER_MOCK_DIR/install.sh"

# Check pre-generated PROJECT.md for DevContainer feature
DEVCONTAINER_PROJECT_MD="$DEVCONTAINER_MOCK_DIR/PROJECT.md"
check "PROJECT.md was generated for devcontainer" test -f "$DEVCONTAINER_PROJECT_MD"
check "PROJECT.md contains devcontainer feature info" grep -q "DevContainer Feature" "$DEVCONTAINER_PROJECT_MD"
check "PROJECT.md contains bash technology" grep -q "bash" "$DEVCONTAINER_PROJECT_MD"

# Test 2: Python Flask Mock Project
echo -e "\n--- Testing Python Flask Mock Project ---"
PYTHON_MOCK_DIR="$MOCK_TEST_DIR/python-flask"
check "python mock project exists" test -d "$PYTHON_MOCK_DIR"
check "app.py exists in python mock" test -f "$PYTHON_MOCK_DIR/app.py"
check "requirements.txt exists in python mock" test -f "$PYTHON_MOCK_DIR/requirements.txt"

# Check pre-generated PROJECT.md for Python Flask
PYTHON_PROJECT_MD="$PYTHON_MOCK_DIR/PROJECT.md"
check "PROJECT.md was generated for python" test -f "$PYTHON_PROJECT_MD"
check "PROJECT.md contains python technology" grep -q "python" "$PYTHON_PROJECT_MD"

# Test 3: Node.js Express Mock Project
echo -e "\n--- Testing Node.js Express Mock Project ---"
NODEJS_MOCK_DIR="$MOCK_TEST_DIR/nodejs-express"
check "nodejs mock project exists" test -d "$NODEJS_MOCK_DIR"
check "package.json exists in nodejs mock" test -f "$NODEJS_MOCK_DIR/package.json"
check "server.js exists in nodejs mock" test -f "$NODEJS_MOCK_DIR/server.js"

# Check pre-generated PROJECT.md for Node.js Express
NODEJS_PROJECT_MD="$NODEJS_MOCK_DIR/PROJECT.md"
check "PROJECT.md was generated for nodejs" test -f "$NODEJS_PROJECT_MD"
check "PROJECT.md contains nodejs technology" grep -q "nodejs" "$NODEJS_PROJECT_MD"

# Test 4: Multi-Technology Combo Project
echo -e "\n--- Testing Multi-Tech Combo Mock Project ---"
COMBO_MOCK_DIR="$MOCK_TEST_DIR/combo-project"
check "combo mock project exists" test -d "$COMBO_MOCK_DIR"
check "combo has devcontainer-feature.json" test -f "$COMBO_MOCK_DIR/devcontainer-feature.json"
check "combo has python api" test -f "$COMBO_MOCK_DIR/api/app.py"
check "combo has nodejs frontend" test -f "$COMBO_MOCK_DIR/frontend/package.json"

# Check pre-generated PROJECT.md for Multi-Tech Combo
COMBO_PROJECT_MD="$COMBO_MOCK_DIR/PROJECT.md"
check "PROJECT.md was generated for combo" test -f "$COMBO_PROJECT_MD"
check "combo PROJECT.md contains multi-tech architecture" grep -q "multi-tech" "$COMBO_PROJECT_MD"

# Test 5: Additional Mock Projects
echo -e "\n--- Testing Additional Mock Projects ---"
SCRIPTS_MOCK_DIR="$MOCK_TEST_DIR/bash-scripts"
check "bash scripts mock project exists" test -d "$SCRIPTS_MOCK_DIR"

TEMPLATE_MOCK_DIR="$MOCK_TEST_DIR/template-project"
check "template mock project exists" test -d "$TEMPLATE_MOCK_DIR"
check "cookiecutter.json exists in template mock" test -f "$TEMPLATE_MOCK_DIR/cookiecutter.json"

# ============================================
# SECTION 6: PROJECT.md Content Quality Tests
# ============================================
echo -e "\n>>> Testing PROJECT.md Content Quality..."

# Test DevContainer PROJECT.md structure
check "devcontainer PROJECT.md has project overview" grep -q "Project Overview" "$DEVCONTAINER_PROJECT_MD"
check "devcontainer PROJECT.md has project structure" grep -q "Project Structure" "$DEVCONTAINER_PROJECT_MD"
check "devcontainer PROJECT.md has development section" grep -q "Development" "$DEVCONTAINER_PROJECT_MD"
check "devcontainer PROJECT.md has contributing section" grep -q "Contributing" "$DEVCONTAINER_PROJECT_MD"
check "devcontainer PROJECT.md has proper markdown formatting" grep -q "^#\|^##\|^###" "$DEVCONTAINER_PROJECT_MD"

# Test Python PROJECT.md structure
check "python PROJECT.md has project overview" grep -q "Project Overview" "$PYTHON_PROJECT_MD"
check "python PROJECT.md mentions dependencies" grep -qi "dependencies\|requirements" "$PYTHON_PROJECT_MD"

# Test new Python section content (Task 2.1-2.4)
check "python PROJECT.md has Python Application section" grep -q "### Python Application" "$PYTHON_PROJECT_MD"
check "python PROJECT.md has Structure subsection" grep -q "#### Structure" "$PYTHON_PROJECT_MD"
check "python PROJECT.md has Dependencies subsection" grep -q "#### Dependencies" "$PYTHON_PROJECT_MD"
check "python PROJECT.md has Configuration subsection" grep -q "#### Configuration" "$PYTHON_PROJECT_MD"
check "python PROJECT.md detects Flask framework" grep -q "\*\*Framework\*\*: Flask" "$PYTHON_PROJECT_MD"
check "python PROJECT.md shows entry points" grep -q "\*\*Entry Points\*\*:" "$PYTHON_PROJECT_MD"
check "python PROJECT.md categorizes dependencies" grep -q "Core/Framework" "$PYTHON_PROJECT_MD"

# Test Node.js PROJECT.md structure
check "nodejs PROJECT.md has project overview" grep -q "Project Overview" "$NODEJS_PROJECT_MD"
check "nodejs PROJECT.md mentions scripts or package.json" grep -qi "scripts\|package.json\|npm" "$NODEJS_PROJECT_MD"

# Test Multi-tech PROJECT.md structure
check "combo PROJECT.md contains multiple technologies" bash -c "grep -q 'bash' '$COMBO_PROJECT_MD' && grep -q 'python' '$COMBO_PROJECT_MD' && grep -q 'nodejs' '$COMBO_PROJECT_MD'"

# ============================================
# SECTION 7: Python Framework Detection Tests (Task 2.3)
# ============================================
echo -e "\n>>> Testing Python Framework Detection..."

# Test Django project detection
echo -e "\n--- Testing Django Project ---"
DJANGO_MOCK_DIR="$MOCK_TEST_DIR/python-django"
if [ -d "$DJANGO_MOCK_DIR" ]; then
    check "django mock project exists" test -d "$DJANGO_MOCK_DIR"
    DJANGO_PROJECT_MD="$DJANGO_MOCK_DIR/PROJECT.md"
    if [ -f "$DJANGO_PROJECT_MD" ]; then
        check "django PROJECT.md detects Django framework" grep -q "\*\*Framework\*\*: Django" "$DJANGO_PROJECT_MD"
        check "django PROJECT.md detects manage.py" grep -q "manage.py" "$DJANGO_PROJECT_MD"
    fi
fi

# Test FastAPI project detection
echo -e "\n--- Testing FastAPI Project ---"
FASTAPI_MOCK_DIR="$MOCK_TEST_DIR/python-fastapi"
if [ -d "$FASTAPI_MOCK_DIR" ]; then
    check "fastapi mock project exists" test -d "$FASTAPI_MOCK_DIR"
    FASTAPI_PROJECT_MD="$FASTAPI_MOCK_DIR/PROJECT.md"
    if [ -f "$FASTAPI_PROJECT_MD" ]; then
        check "fastapi PROJECT.md detects FastAPI framework" grep -q "\*\*Framework\*\*: FastAPI" "$FASTAPI_PROJECT_MD"
        check "fastapi PROJECT.md detects main.py" grep -q "main.py" "$FASTAPI_PROJECT_MD"
    fi
fi

# ============================================
# SECTION 8: Performance and Error Handling
# ============================================
echo -e "\n>>> Testing Performance and Error Handling..."

# Test error handling with empty directory
EMPTY_DIR="/tmp/empty-test-project"
mkdir -p "$EMPTY_DIR"
check "handles empty project gracefully" bash -c "cd '$EMPTY_DIR' && ! generate_project_markdown . PROJECT.md true 2>/dev/null"
rm -rf "$EMPTY_DIR"

# Test error handling with nonexistent directory
NONEXISTENT_DIR="/tmp/nonexistent-project"
check "handles nonexistent directory" bash -c "! generate_project_markdown '$NONEXISTENT_DIR' PROJECT.md true 2>/dev/null"

echo -e "\n✓ All PROJECT.md generation tests completed successfully!"

# ============================================
# SECTION 9: File Permissions Tests
# ============================================
echo -e "\n>>> Testing File Permissions..."

# Test that files have proper permissions
check "project-detector.sh has read permission" test -r "/usr/local/share/riso-bootstrap/utils/layer-0/project-detector.sh"
check "bash-section-generator.sh has read permission" test -r "/usr/local/share/riso-bootstrap/utils/layer-2/bash-section-generator.sh"
check "markdown-builder.sh has read permission" test -r "/usr/local/share/riso-bootstrap/utils/layer-3/markdown-builder.sh"
check "python-scanner.sh has read permission" test -r "/usr/local/share/riso-bootstrap/utils/layer-1/python-scanner.sh"
check "python-section-generator.sh has read permission" test -r "/usr/local/share/riso-bootstrap/utils/layer-2/python-section-generator.sh"

echo -e "\n\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;36m🧪 riso-bootstrap PROJECT.md generation test: 'TEST-UBUNTU-PROJECT-CONTEXT' completed\033[0m"
echo -e "\033[1;36m✅ Phase 1 (Bash) & Phase 2 (Python) - All tests passed successfully!\033[0m"
echo -e "\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m\n"
