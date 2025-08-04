#!/bin/bash

# Test for riso-bootstrap feature on Ubuntu base image
# Scenario: test-ubuntu-minimal

set -e

# Import testing library
# shellcheck source=dev-container-features-test-lib disable=SC1091
source dev-container-features-test-lib

# ============================================
# SECTION 1: Feature Installation Tests
# ============================================
echo -e "\n>>> Testing Feature Installation..."

# Test feature directory structure
check "feature directory exists" test -d "/usr/local/share/riso-bootstrap"
check "utils directory exists" test -d "/usr/local/share/riso-bootstrap/utils"
check "scripts directory exists" test -d "/usr/local/share/riso-bootstrap/scripts"

# Test layer structure
check "layer-0 directory exists" test -d "/usr/local/share/riso-bootstrap/utils/layer-0"
check "layer-1 directory exists" test -d "/usr/local/share/riso-bootstrap/utils/layer-1"

# Test utility files
check "logger.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-0/logger.sh"
check "commands.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-0/commands.sh"
check "validator.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-1/validator.sh"
check "file-ops.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-1/file-ops.sh"

# Test scripts
check "post-create.sh exists" test -f "/usr/local/share/riso-bootstrap/scripts/post-create.sh"
check "post-attach.sh exists" test -f "/usr/local/share/riso-bootstrap/scripts/post-attach.sh"
check "post-start.sh exists" test -f "/usr/local/share/riso-bootstrap/scripts/post-start.sh"

# Test options file
check "options file exists" test -f "/usr/local/share/riso-bootstrap/riso-bootstrap-options.env"

# ============================================
# SECTION 2: Claude CLI Tests
# ============================================
echo -e "\n>>> Testing Claude CLI..."

check "claude CLI is installed" command -v claude
check "claude CLI version is valid" bash -c 'claude --version 2>&1 | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+"'
check "claude CLI is logged in" bash -c "output=\$(echo \"test\" | claude --print 2>&1); if echo \"\$output\" | grep -q \"Invalid API key\"; then exit 1; else exit 0; fi"

# ============================================
# SECTION 3: Mount Points and Permissions Tests
# ============================================
echo -e "\n>>> Testing Mount Points and Permissions..."

# Claude configuration mount
check ".claude directory exists (if mounted)" bash -c "test -d \"$HOME/.claude\" || test -f \"$HOME/.claude.json\" || exit 0"
check ".claude.json permissions (if exists)" bash -c "if [ -f \"$HOME/.claude.json\" ]; then stat -c \"%a\" \"$HOME/.claude.json\" | grep -E \"^(600|644)$\"; else exit 0; fi"

# SSH mount and permissions
check ".ssh directory exists" test -d "$HOME/.ssh"
check ".ssh directory has correct permissions" bash -c "stat -c \"%a\" \"$HOME/.ssh\" | grep -E \"^700$\""
check ".ssh/config permissions (if exists)" bash -c "if [ -f \"$HOME/.ssh/config\" ]; then stat -c \"%a\" \"$HOME/.ssh/config\" | grep -E \"^(600|644)$\"; else exit 0; fi"
check ".ssh private key permissions (if exists)" bash -c "for key in \"$HOME\"/.ssh/id_*; do if [ -f \"\$key\" ] && [[ ! \"\$key\" =~ \\.pub$ ]]; then stat -c \"%a\" \"\$key\" | grep -E \"^600$\" || exit 1; fi; done; exit 0"

# ============================================
# SECTION 4: Dependency Features Tests
# ============================================
echo -e "\n>>> Testing Dependency Features..."

# Common utilities
check "zsh is installed" command -v zsh
check "oh-my-zsh directory exists" test -d "$HOME/.oh-my-zsh"

# Git
check "git is installed" command -v git
check "github CLI is installed" command -v gh

# Node.js
check "node is installed" command -v node
check "npm is installed" command -v npm
check "nvm directory exists" test -d "/usr/local/share/nvm"

# Python
check "python is installed" command -v python
check "pip is installed" command -v pip
check "pre-commit is installed" command -v pre-commit


echo -e "\n\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;36m🧪 riso-bootstrap scenario test: 'TEST-UBUNTU-MINIMAL' completed\033[0m"
echo -e "\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m\n"
