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
        *)
            print_error "No test for function: $function_name"
            echo -e "${YELLOW}Add test for this function when it's implemented${NC}" >&2
            exit 1
            ;;
    esac
}

# Run main
main "$@"
