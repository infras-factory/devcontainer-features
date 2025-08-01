#!/bin/bash

# Test for riso-bootstrap feature on Ubuntu base image
# Scenario: test-ubuntu-minimal

set -e

# Import testing library
# shellcheck source=dev-container-features-test-lib disable=SC1091
source dev-container-features-test-lib

# Feature-specific tests
check "utils directory exists" test -d "/usr/local/share/riso-bootstrap/utils"
check "scripts directory exists" test -d "/usr/local/share/riso-bootstrap/scripts"

# Test layer structure directories exist
check "layer-0 directory exists" test -d "/usr/local/share/riso-bootstrap/utils/layer-0"
check "layer-1 directory exists" test -d "/usr/local/share/riso-bootstrap/utils/layer-1"

# Test utility files exist
check "logger.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-0/logger.sh"
check "validator.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-1/validator.sh"
check "file-ops.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-1/file-ops.sh"

# Test base scripts exist
check "post-create.sh exists" test -f "/usr/local/share/riso-bootstrap/scripts/post-create.sh"

# Test Claude CLI installation and login status
check "claude CLI is installed" command -v claude
check "claude CLI version is valid" bash -c 'claude --version 2>&1 | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+"'
check "claude CLI is logged in" bash -c "output=\$(echo \"test\" | claude --print 2>&1); if echo \"\$output\" | grep -q \"Invalid API key\"; then exit 1; else exit 0; fi"

echo -e "\n\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;36m🧪 riso-bootstrap scenario test: 'TEST-UBUNTU-MINIMAL' completed\033[0m"
echo -e "\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m\n"
