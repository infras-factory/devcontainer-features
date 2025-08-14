#!/bin/bash
set -e

# ----------------------------------------
# Direct Function Tester
# Usage: bash scripts/directly-test.sh [OPTIONS] <function_name>
# Options:
#   --keep-tmp, -k    Keep temporary files after test completion
#   --cleanup, -c     Clean up all test temporary files
#   --help, -h        Show this help message
# ----------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FEATURE_DIR="$PROJECT_DIR/src/riso-bootstrap"
# UTILS_DIR may be used in future test cases
# shellcheck disable=SC2034
UTILS_DIR="$FEATURE_DIR/utils"

# Test configuration
KEEP_TMP_FILES=false
CLEANUP_MODE=false

# Temp file tracking
TMP_FILES_REGISTRY="/tmp/.riso-test-tmp-registry"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ----------------------------------------
# Helper Functions
# ----------------------------------------
show_help() {
    cat << 'HELP_EOF'
Direct Function Test Runner

USAGE:
    ./scripts/directly-test.sh [OPTIONS] <function_name>

OPTIONS:
    -k, --keep-tmp     Keep temporary files after test completion
    -c, --cleanup      Clean up all test temporary files and exit
    -h, --help         Show this help message

FUNCTION NAMES:
    Core Functions:
        bash-scanner, scan         Test bash script scanner
        bash-analyzer, analyze     Test bash analyzer
        devcontainer-analyzer, dc  Test DevContainer feature analyzer

    Mock Generation:
        mock-generator, mock       Test mock generator interface
        mock-bash                  Test bash project generation
        mock-python                Test python project generation
        mock-nodejs, mock-node     Test nodejs project generation
        mock-template              Test template project generation
        mock-combo, mock-all       Test combo project generation

EXAMPLES:
    ./scripts/directly-test.sh mock-python
    ./scripts/directly-test.sh --keep-tmp mock-combo
    ./scripts/directly-test.sh --cleanup

HELP_EOF
}

print_header() {
    echo -e "${CYAN}===========================================${NC}" >&2
    echo -e "${CYAN}  Direct Function Test Runner${NC}" >&2
    echo -e "${CYAN}===========================================${NC}" >&2
}

# ----------------------------------------
# Temp File Management
# ----------------------------------------
register_tmp_file() {
    local tmp_path="$1"
    echo "$tmp_path" >> "$TMP_FILES_REGISTRY"
    echo -e "${CYAN}Registered temp: ${tmp_path}${NC}" >&2
}

cleanup_all_tmp_files() {
    echo -e "${BLUE}Cleaning up all test temporary files...${NC}" >&2

    local cleaned_count=0

    # Clean from registry
    if [[ -f "$TMP_FILES_REGISTRY" ]]; then
        while IFS= read -r tmp_path; do
            if [[ -n "$tmp_path" && -e "$tmp_path" ]]; then
                echo -e "${YELLOW}Removing: $tmp_path${NC}" >&2
                if rm -rf "$tmp_path" 2>/dev/null; then
                    cleaned_count=$((cleaned_count + 1))
                fi
            fi
        done < "$TMP_FILES_REGISTRY"
        rm -f "$TMP_FILES_REGISTRY"
    fi

    # Find and clean orphaned temp files with riso-test pattern
    local orphaned_files
    orphaned_files=$(find /tmp -maxdepth 1 -name "riso-test-*" -type d 2>/dev/null || true)

    if [[ -n "$orphaned_files" ]]; then
        echo -e "${YELLOW}Found orphaned test temp files:${NC}" >&2
        echo "$orphaned_files" >&2
        while IFS= read -r orphaned; do
            if [[ -d "$orphaned" ]]; then
                echo -e "${YELLOW}Removing orphaned: $orphaned${NC}" >&2
                if rm -rf "$orphaned" 2>/dev/null; then
                    cleaned_count=$((cleaned_count + 1))
                fi
            fi
        done <<< "$orphaned_files"
    fi

    echo -e "${GREEN}✓ Cleaned up $cleaned_count temporary files/directories${NC}" >&2
}

# ----------------------------------------
# Helper Functions
# ----------------------------------------

# shellcheck disable=SC2317  # Will be called when test cases are added
print_test_start() {
    local function_name="$1"
    echo -e "\n${BLUE}▶ Testing function: ${YELLOW}${function_name}${NC}" >&2
}

# shellcheck disable=SC2317  # Will be called when test cases are added
print_success() {
    local msg="$1"
    echo -e "${GREEN}✓${NC} ${msg}" >&2
}

print_error() {
    local msg="$1"
    echo -e "${RED}✗${NC} ${msg}" >&2
}

# ----------------------------------------
# Test Setup
# ----------------------------------------
setup_test_env() {
    # Create temp directory for testing with identifiable name
    TEST_TMP_DIR=$(mktemp -d -t "riso-test-XXXXXX")
    export TEST_TMP_DIR

    # Register temp directory for tracking
    register_tmp_file "$TEST_TMP_DIR"

    echo -e "${CYAN}Test environment: ${TEST_TMP_DIR}${NC}" >&2

    if [[ "$KEEP_TMP_FILES" == "true" ]]; then
        echo -e "${YELLOW}Temp files will be kept at: ${TEST_TMP_DIR}${NC}" >&2
        # Don't set up cleanup trap when keeping files
    else
        # Trap to cleanup on exit
        trap 'cleanup_on_exit' EXIT
    fi
}

cleanup_on_exit() {
    if [[ "$KEEP_TMP_FILES" == "false" && -n "$TEST_TMP_DIR" && -d "$TEST_TMP_DIR" ]]; then
        echo -e "${CYAN}Cleaning up test environment: ${TEST_TMP_DIR}${NC}" >&2
        rm -rf "$TEST_TMP_DIR"
    fi
}

# ----------------------------------------
# Test Functions
# ----------------------------------------
test_bash_scanner() {
    print_test_start "bash-script-scanner"

    # Source the scanner
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-1/bash-script-scanner.sh"

    # Source the mock generator
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    # Create mock bash scripts project using mock generator
    echo -e "${BLUE}Creating mock bash scripts project using mock generator...${NC}" >&2
    local mock_scripts_dir="$TEST_TMP_DIR/mock-scripts"
    generate_mock_project "bash" "scripts" "$mock_scripts_dir"

    # Test the scanner
    echo -e "\n${BLUE}Running scanner on generated mock project...${NC}" >&2
    scan_bash_project "$mock_scripts_dir"

    print_success "Bash scanner test completed"
}

# shellcheck disable=SC2317  # Will be called when test case is selected
test_bash_analyzer() {
    print_test_start "bash-analyzer"

    # Source the analyzer
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-1/bash-analyzer.sh"

    # Source the mock generator
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    # Create mock DevContainer feature using mock generator for comprehensive analysis
    echo -e "${BLUE}Creating mock DevContainer feature using mock generator...${NC}" >&2
    local mock_feature_dir="$TEST_TMP_DIR/mock-devcontainer-feature"
    generate_mock_project "bash" "devcontainer" "$mock_feature_dir"

    # Test the analyzer on the generated install script
    echo -e "\n${BLUE}Running analyzer on generated install script...${NC}" >&2
    if [[ -f "$mock_feature_dir/install.sh" ]]; then
        analyze_bash_script "$mock_feature_dir/install.sh"
    fi

    echo -e "\n${BLUE}Testing full project analysis...${NC}" >&2
    analyze_all_scripts "$mock_feature_dir"

    print_success "Bash analyzer test completed"
}

# shellcheck disable=SC2317  # Will be called when test case is selected
test_devcontainer_analyzer() {
    print_test_start "devcontainer-analyzer"

    # Source the DevContainer analyzer
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-1/devcontainer-analyzer.sh"

    # Source the mock generator to create test project
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    # Create mock DevContainer feature using mock generator
    echo -e "${BLUE}Creating mock DevContainer feature project using mock generator...${NC}" >&2
    local mock_feature_dir="$TEST_TMP_DIR/mock-feature"
    generate_mock_project "bash" "devcontainer" "$mock_feature_dir"

    # Test the DevContainer analyzer
    echo -e "\n${BLUE}Running DevContainer analyzer on generated mock feature...${NC}" >&2
    analyze_devcontainer_feature "$mock_feature_dir"

    # Test summary generation
    echo -e "\n${BLUE}Generating DevContainer feature summary...${NC}" >&2
    local summary_file="$TEST_TMP_DIR/devcontainer-summary.md"
    generate_devcontainer_summary "$mock_feature_dir" "$summary_file"

    echo -e "\n${CYAN}Generated summary preview:${NC}" >&2
    head -20 "$summary_file"

    print_success "DevContainer analyzer test completed"
}

# ========================================
# MOCK GENERATOR TESTS
# ========================================

# shellcheck disable=SC2317  # Will be called when test case is selected
test_mock_generator() {
    print_test_start "mock-generator interface"

    # Source the mock generator
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    echo -e "${BLUE}Testing main mock generator interface...${NC}" >&2

    # Test help/usage
    echo -e "\n${CYAN}Available project types:${NC}" >&2
    echo "  - bash (variants: devcontainer, scripts)" >&2
    echo "  - python (variants: simple, flask, django, fastapi)" >&2
    echo "  - nodejs (variants: express, react, nextjs, cli)" >&2
    echo "  - template (variants: cookiecutter)" >&2
    echo "  - combo (variants: bash-python, nodejs-template, all-tech)" >&2

    print_success "Mock generator interface test completed"
}

# shellcheck disable=SC2317  # Will be called when test case is selected
test_mock_bash_projects() {
    print_test_start "mock bash projects"

    # Source the mock generator
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    # Test DevContainer feature generation
    echo -e "\n${BLUE}Generating mock DevContainer feature...${NC}" >&2
    local devcontainer_dir="$TEST_TMP_DIR/mock-devcontainer-feature"
    generate_mock_project "bash" "devcontainer" "$devcontainer_dir"

    echo -e "\n${CYAN}Generated DevContainer feature structure:${NC}" >&2
    tree "$devcontainer_dir" 2>/dev/null || find "$devcontainer_dir" -type f

    echo -e "\n${CYAN}DevContainer feature JSON:${NC}" >&2
    if [[ -f "$devcontainer_dir/devcontainer-feature.json" ]]; then
        head -10 "$devcontainer_dir/devcontainer-feature.json"
    fi

    # Test Bash scripts generation
    echo -e "\n${BLUE}Generating mock Bash scripts project...${NC}" >&2
    local scripts_dir="$TEST_TMP_DIR/mock-bash-scripts"
    generate_mock_project "bash" "scripts" "$scripts_dir"

    echo -e "\n${CYAN}Generated Bash scripts structure:${NC}" >&2
    tree "$scripts_dir" 2>/dev/null || find "$scripts_dir" -type f

    print_success "Mock bash projects test completed"
}

# shellcheck disable=SC2317  # Will be called when test case is selected
test_mock_python_projects() {
    print_test_start "mock python projects"

    # Source the mock generator
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    # Test Flask API generation
    echo -e "\n${BLUE}Generating mock Flask API...${NC}" >&2
    local flask_dir="$TEST_TMP_DIR/mock-flask-api"
    generate_mock_project "python" "flask" "$flask_dir"

    echo -e "\n${CYAN}Generated Flask API structure:${NC}" >&2
    tree "$flask_dir" 2>/dev/null || find "$flask_dir" -type f

    echo -e "\n${CYAN}Flask app.py preview:${NC}" >&2
    if [[ -f "$flask_dir/app.py" ]]; then
        head -15 "$flask_dir/app.py"
    fi

    # Test FastAPI generation
    echo -e "\n${BLUE}Generating mock FastAPI service...${NC}" >&2
    local fastapi_dir="$TEST_TMP_DIR/mock-fastapi-service"
    generate_mock_project "python" "fastapi" "$fastapi_dir"

    echo -e "\n${CYAN}Generated FastAPI structure:${NC}" >&2
    tree "$fastapi_dir" 2>/dev/null || find "$fastapi_dir" -type f

    print_success "Mock python projects test completed"
}

# shellcheck disable=SC2317  # Will be called when test case is selected
test_mock_nodejs_projects() {
    print_test_start "mock nodejs projects"

    # Source the mock generator
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    # Test Express API generation
    echo -e "\n${BLUE}Generating mock Express API...${NC}" >&2
    local express_dir="$TEST_TMP_DIR/mock-express-api"
    generate_mock_project "nodejs" "express" "$express_dir"

    echo -e "\n${CYAN}Generated Express API structure:${NC}" >&2
    tree "$express_dir" 2>/dev/null || find "$express_dir" -type f

    echo -e "\n${CYAN}Express package.json:${NC}" >&2
    if [[ -f "$express_dir/package.json" ]]; then
        head -15 "$express_dir/package.json"
    fi

    # Test React app generation
    echo -e "\n${BLUE}Generating mock React app...${NC}" >&2
    local react_dir="$TEST_TMP_DIR/mock-react-app"
    generate_mock_project "nodejs" "react" "$react_dir"

    echo -e "\n${CYAN}Generated React app structure:${NC}" >&2
    tree "$react_dir" 2>/dev/null || find "$react_dir" -type f

    print_success "Mock nodejs projects test completed"
}

# shellcheck disable=SC2317  # Will be called when test case is selected
test_mock_template_projects() {
    print_test_start "mock template projects"

    # Source the mock generator
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    # Test Cookiecutter template generation
    echo -e "\n${BLUE}Generating mock Cookiecutter template...${NC}" >&2
    local template_dir="$TEST_TMP_DIR/mock-cookiecutter-template"
    generate_mock_project "template" "cookiecutter" "$template_dir"

    echo -e "\n${CYAN}Generated Cookiecutter template structure:${NC}" >&2
    tree "$template_dir" 2>/dev/null || find "$template_dir" -type f

    echo -e "\n${CYAN}Cookiecutter.json:${NC}" >&2
    if [[ -f "$template_dir/cookiecutter.json" ]]; then
        head -15 "$template_dir/cookiecutter.json"
    fi

    echo -e "\n${CYAN}Template hooks:${NC}" >&2
    if [[ -d "$template_dir/hooks" ]]; then
        ls -la "$template_dir/hooks/"
    fi

    print_success "Mock template projects test completed"
}

# shellcheck disable=SC2317  # Will be called when test case is selected
test_mock_combo_projects() {
    print_test_start "mock combo projects"

    # Source the mock generator
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-0/mock-generator.sh"

    # Test Bash + Python combo
    echo -e "\n${BLUE}Generating mock Bash + Python combo...${NC}" >&2
    local combo1_dir="$TEST_TMP_DIR/mock-bash-python-combo"
    generate_mock_project "combo" "bash-python" "$combo1_dir"

    echo -e "\n${CYAN}Generated Bash + Python combo structure:${NC}" >&2
    tree "$combo1_dir" 2>/dev/null || find "$combo1_dir" -type f

    # Test All technologies combo
    echo -e "\n${BLUE}Generating mock All Technologies combo...${NC}" >&2
    local combo2_dir="$TEST_TMP_DIR/mock-all-tech-combo"
    generate_mock_project "combo" "all-tech" "$combo2_dir"

    echo -e "\n${CYAN}Generated All Technologies combo structure:${NC}" >&2
    tree "$combo2_dir" 2>/dev/null || find "$combo2_dir" -type f | head -20

    echo -e "\n${CYAN}Technologies detected in combo project:${NC}" >&2
    echo "  - Bash: $(find "$combo2_dir" -name "*.sh" | wc -l) scripts" >&2
    echo "  - Python: $(find "$combo2_dir" -name "*.py" | wc -l) files" >&2
    echo "  - Node.js: $(find "$combo2_dir" -name "package.json" | wc -l) projects" >&2
    echo "  - Template: $(find "$combo2_dir" -name "cookiecutter.json" | wc -l) templates" >&2

    print_success "Mock combo projects test completed"
}

# ----------------------------------------
# Main Logic
# ----------------------------------------
main() {
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -k|--keep-tmp)
                KEEP_TMP_FILES=true
                shift
                ;;
            -c|--cleanup)
                CLEANUP_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo -e "${RED}Unknown option $1${NC}" >&2
                show_help
                exit 1
                ;;
            *)
                # This is the function name
                break
                ;;
        esac
    done

    print_header

    # Handle cleanup mode
    if [[ "$CLEANUP_MODE" == "true" ]]; then
        cleanup_all_tmp_files
        exit 0
    fi

    # Check if function name provided
    if [ $# -eq 0 ]; then
        echo -e "${YELLOW}No function name provided${NC}" >&2
        show_help
        exit 1
    fi

    local function_name="$1"

    # Setup test environment
    setup_test_env

    # Run the appropriate test
    case "$function_name" in
        bash-scanner|scan)
            test_bash_scanner
            ;;
        bash-analyzer|analyze)
            test_bash_analyzer
            ;;
        devcontainer-analyzer|dc)
            test_devcontainer_analyzer
            ;;
        mock-generator|mock)
            test_mock_generator
            ;;
        mock-bash|mock-devcontainer)
            test_mock_bash_projects
            ;;
        mock-python)
            test_mock_python_projects
            ;;
        mock-nodejs|mock-node)
            test_mock_nodejs_projects
            ;;
        mock-template|mock-cookiecutter)
            test_mock_template_projects
            ;;
        mock-combo|mock-all)
            test_mock_combo_projects
            ;;
        *)
            print_error "No test for function: $function_name"
            echo -e "${YELLOW}Use --help to see available tests${NC}" >&2
            exit 1
            ;;
    esac

    # Show temp file info if keeping them
    if [[ "$KEEP_TMP_FILES" == "true" && -n "$TEST_TMP_DIR" ]]; then
        echo -e "\n${GREEN}✓ Test completed. Temp files kept at: ${TEST_TMP_DIR}${NC}" >&2
        echo -e "${CYAN}To clean up later, run: ./scripts/directly-test.sh --cleanup${NC}" >&2
    fi
}

# Run main
main "$@"
