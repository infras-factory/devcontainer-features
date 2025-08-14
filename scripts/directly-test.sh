#!/bin/bash
set -e

# ----------------------------------------
# Direct Function Tester
# Usage: bash scripts/directly-test.sh <function_name>
# ----------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FEATURE_DIR="$PROJECT_DIR/src/riso-bootstrap"
# UTILS_DIR may be used in future test cases
# shellcheck disable=SC2034
UTILS_DIR="$FEATURE_DIR/utils"

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
print_header() {
    echo -e "${CYAN}===========================================${NC}" >&2
    echo -e "${CYAN}  Direct Function Test Runner${NC}" >&2
    echo -e "${CYAN}===========================================${NC}" >&2
}

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
    # Create temp directory for testing
    TEST_TMP_DIR=$(mktemp -d)
    export TEST_TMP_DIR
    echo -e "${CYAN}Test environment: ${TEST_TMP_DIR}${NC}" >&2

    # Trap to cleanup on exit
    trap 'rm -rf "$TEST_TMP_DIR"' EXIT
}

# ----------------------------------------
# Test Functions
# ----------------------------------------
test_bash_scanner() {
    print_test_start "bash-script-scanner"

    # Source the scanner
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-1/bash-script-scanner.sh"

    # Create mock project structure
    echo -e "${BLUE}Creating mock DevContainer feature project...${NC}" >&2
    mkdir -p "$TEST_TMP_DIR/feature/scripts"
    mkdir -p "$TEST_TMP_DIR/feature/utils"

    # Create some test scripts
    cat > "$TEST_TMP_DIR/feature/install.sh" << 'EOF'
#!/bin/bash
# Install script for test feature
echo "Installing feature..."
EOF
    chmod +x "$TEST_TMP_DIR/feature/install.sh"

    cat > "$TEST_TMP_DIR/feature/test.sh" << 'EOF'
#!/bin/bash
# Test runner for feature
echo "Running tests..."
EOF
    chmod +x "$TEST_TMP_DIR/feature/test.sh"

    cat > "$TEST_TMP_DIR/feature/utils/helper.sh" << 'EOF'
#!/bin/bash
# Helper utilities
helper_function() {
    echo "Helper"
}
EOF

    # Create Makefile
    cat > "$TEST_TMP_DIR/feature/Makefile" << 'EOF'
test:
	@echo "Running tests"
build:
	@echo "Building"
EOF

    # Test the scanner
    echo -e "\n${BLUE}Running scanner on mock project...${NC}" >&2
    scan_bash_project "$TEST_TMP_DIR/feature"

    print_success "Bash scanner test completed"
}

# shellcheck disable=SC2317  # Will be called when test case is selected
test_bash_analyzer() {
    print_test_start "bash-analyzer"

    # Source the analyzer
    # shellcheck source=/dev/null
    source "$FEATURE_DIR/utils/layer-1/bash-analyzer.sh"

    # Create a more complex test script
    echo -e "${BLUE}Creating test script with various patterns...${NC}" >&2
    cat > "$TEST_TMP_DIR/complex-script.sh" << 'EOF'
#!/bin/bash
# This is a complex installation script
# It installs various tools and sets up environment

set -e

# Source some utilities
source ./utils/logger.sh
. ./utils/helper.sh

# Main installation function
install_tools() {
    echo "Installing tools..."

    # Check for git
    if command -v git >/dev/null 2>&1; then
        git clone https://example.com/repo.git
    fi

    # Install with package managers
    apt-get update
    apt-get install -y curl wget
    npm install -g some-package

    setup_environment
    validate_installation
}

setup_environment() {
    echo "Setting up environment..."
    docker pull nginx:latest
}

validate_installation() {
    echo "Validating..."
    make test
}

# Entry point
main() {
    install_tools
    echo "Done!"
}

main "$@"
EOF

    # Test the analyzer on this script
    echo -e "\n${BLUE}Running analyzer on test script...${NC}" >&2
    analyze_bash_script "$TEST_TMP_DIR/complex-script.sh"

    echo -e "\n${BLUE}Testing full project analysis...${NC}" >&2
    # Create mini project
    mkdir -p "$TEST_TMP_DIR/project"
    cp "$TEST_TMP_DIR/complex-script.sh" "$TEST_TMP_DIR/project/install.sh"

    analyze_all_scripts "$TEST_TMP_DIR/project"

    print_success "Bash analyzer test completed"
}

# ----------------------------------------
# Main Logic
# ----------------------------------------
main() {
    print_header

    # Check arguments
    if [ $# -eq 0 ]; then
        echo -e "${YELLOW}Usage: bash scripts/directly-test.sh <function_name>${NC}" >&2
        echo -e "${YELLOW}No functions to test yet. Add tests as functions are implemented.${NC}" >&2
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
        *)
            print_error "No test for function: $function_name"
            echo -e "${YELLOW}Add test for this function when it's implemented${NC}" >&2
            echo -e "${YELLOW}Available tests: bash-scanner, bash-analyzer${NC}" >&2
            exit 1
            ;;
    esac
}

# Run main
main "$@"
