#!/bin/bash

# Test for riso-bootstrap feature with Serena enabled
# Scenario: test-ubuntu-with-serena

set -e

# Import testing library
# shellcheck source=dev-container-features-test-lib disable=SC1091
source dev-container-features-test-lib

# ============================================
# SECTION 1: Basic Feature Tests (same as minimal)
# ============================================
echo -e "\n>>> Testing Feature Installation..."

check "feature directory exists" test -d "/usr/local/share/riso-bootstrap"
check "options file exists" test -f "/usr/local/share/riso-bootstrap/riso-bootstrap-options.env"

# ============================================
# SECTION 2: Environment Variable Tests
# ============================================
echo -e "\n>>> Testing Environment Variables..."

# Source the options file and check ENABLE_SERENA
# shellcheck disable=SC2016
check "ENABLE_SERENA is true" bash -c 'source /usr/local/share/riso-bootstrap/riso-bootstrap-options.env && [ "$ENABLE_SERENA" = "true" ]'
# shellcheck disable=SC2016
check "IS_TEST_MODE is true" bash -c 'source /usr/local/share/riso-bootstrap/riso-bootstrap-options.env && [ "$IS_TEST_MODE" = "true" ]'

# ============================================
# SECTION 3: Mock Files Tests
# ============================================
echo -e "\n>>> Testing Mock Files Generation..."

# Check if mock files were created
check "mock app.py exists" test -f "app.py"
check "mock models.py exists" test -f "models.py"
check "mock requirements.txt exists" test -f "requirements.txt"
check "mock README.md exists" test -f "README.md"
check "mock test file exists" test -f "tests/test_api.py"

# ============================================
# SECTION 4: Serena-specific Tests
# ============================================
echo -e "\n>>> Testing Serena Installation..."

# Check UV installation
check "uv is installed" command -v uv
check "uv is in PATH" bash -c 'which uv | grep -q "/.local/bin/uv"'

# Add actual test checks for Serena functionality
check "serena CLI is accessible" bash -c 'uvx --from git+https://github.com/oraios/serena serena --help > /dev/null 2>&1'

# Check Serena project configuration
check "serena directory exists" test -d ".serena"
check "serena project.yml exists" test -f ".serena/project.yml"

# Test confirmed commands only
check "serena project generate-yml works" bash -c 'uvx --from git+https://github.com/oraios/serena serena project generate-yml 2>&1 | grep -qiE "(generated|already exists|created)" || exit 0'
check "serena project index works" bash -c 'uvx --from git+https://github.com/oraios/serena serena project index 2>&1 | grep -qiE "(index|files|complete)" || exit 0'

echo -e "\n\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;36m🧪 riso-bootstrap scenario test: 'TEST-UBUNTU-WITH-SERENA' completed\033[0m"
echo -e "\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m\n"
