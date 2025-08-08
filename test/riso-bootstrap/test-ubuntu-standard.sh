#!/bin/bash

# Test for riso-bootstrap feature on Ubuntu base image
# Scenario: test-ubuntu-standard (Shell Enhancement Level: standard)

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

# Test package manager utility
check "package-manager.sh exists" test -f "/usr/local/share/riso-bootstrap/utils/layer-0/package-manager.sh"

# Test configs directory
check "configs directory exists" test -d "/usr/local/share/riso-bootstrap/configs"
check ".p10k.zsh config exists" test -f "/usr/local/share/riso-bootstrap/configs/.p10k.zsh"

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

# ============================================
# SECTION 5: Standard Shell Enhancement Tests
# ============================================
echo -e "\n>>> Testing Standard Shell Enhancement..."

# Get test environment
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
ZSH_CUSTOM=${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}

# Powerlevel10k theme (mandatory)
check "powerlevel10k theme installed" test -d "$ZSH_CUSTOM/themes/powerlevel10k"
check "powerlevel10k configured in .zshrc" grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$USER_HOME/.zshrc"
check "p10k config copied to home" test -f "$USER_HOME/.p10k.zsh"
check "p10k config sourced" grep -q "source ~/.p10k.zsh" "$USER_HOME/.zshrc"

# Standard level plugins (includes minimal + additional)
check "zsh-autosuggestions installed" test -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
check "you-should-use installed" test -d "$ZSH_CUSTOM/plugins/you-should-use"
check "zsh-syntax-highlighting installed" test -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
check "zsh-history-substring-search installed" test -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search"

# Standard plugins configured in .zshrc
check "standard plugins configured" grep -q "zsh-autosuggestions you-should-use zsh-syntax-highlighting zsh-history-substring-search" "$USER_HOME/.zshrc"

# Ensure fast-syntax-highlighting is NOT installed (conflict prevention)
check "fast-syntax-highlighting NOT installed" bash -c "! test -d \"$ZSH_CUSTOM/plugins/fast-syntax-highlighting\""
check "fast-syntax-highlighting NOT in .zshrc" bash -c "! grep -q \"fast-syntax-highlighting\" \"$USER_HOME/.zshrc\""

# Shell configurations
check "shell enhancements section" grep -q "# Riso Bootstrap Shell Enhancements" "$USER_HOME/.zshrc"
check "history size configured" grep -q "HISTSIZE=100000" "$USER_HOME/.zshrc"
check "autosuggest style configured" grep -q "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" "$USER_HOME/.zshrc"
check "history substring search bindings" grep -q "history-substring-search-up" "$USER_HOME/.zshrc"

# Package manager detection
if [ -f "/usr/local/share/riso-bootstrap/utils/layer-0/package-manager.sh" ]; then
    source "/usr/local/share/riso-bootstrap/utils/layer-0/package-manager.sh"

    # Test detection
    DETECTED_PM=$(detect_package_manager)
    check "package manager detected" test -n "$DETECTED_PM"
    check "package manager is apt" test "$DETECTED_PM" = "apt"

    # Test validation
    check "validate good package name" validate_package_name "valid-package"
    check "reject malicious package name" bash -c "! validate_package_name '../../etc/passwd'"
fi

# ============================================
# SECTION 6: Standard Level Specific Validations
# ============================================
echo -e "\n>>> Testing Standard Level Specific Features..."

# Verify no poweruser-only plugins are installed
check "zsh-autocomplete NOT installed" bash -c "! test -d \"$ZSH_CUSTOM/plugins/zsh-autocomplete\""
check "zsh-bat NOT installed" bash -c "! test -d \"$ZSH_CUSTOM/plugins/zsh-bat\""
check "poweruser plugins NOT in .zshrc" bash -c "! grep -q \"zsh-autocomplete\\|zsh-bat\" \"$USER_HOME/.zshrc\""

# Verify bat is NOT installed (poweruser only)
check "bat NOT installed" bash -c "! command -v bat && ! command -v batcat"

echo -e "\n\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m"
echo -e "\033[1;36m🧪 riso-bootstrap scenario test: 'TEST-UBUNTU-STANDARD' completed\033[0m"
echo -e "\033[1;36m════════════════════════════════════════════════════════════════════════════════\033[0m\n"
