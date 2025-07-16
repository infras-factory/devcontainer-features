#!/bin/bash

# Post-create script for devcontainer
# This script runs once when the container is created

set -e

# Enable logging
LOG_FILE="/tmp/post-create.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${RED}[ERROR]${NC} $1"
}

echo -e "${PURPLE}======================================================${NC}"
echo -e "${PURPLE}     RISO OH MY ZSH POST-CREATE SCRIPT EXECUTION${NC}"
echo -e "${PURPLE}======================================================${NC}"

# Get current user
CURRENT_USER=$(whoami)
USER_HOME=$(eval echo ~"$CURRENT_USER")
log_info "Running as user: $CURRENT_USER"
log_info "User home: $USER_HOME"

# ----------------------------------------
# Install Oh My Zsh
# ----------------------------------------
log_info "Checking Oh My Zsh installation..."

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."

    # Install Oh My Zsh non-interactively
    export RUNZSH=no
    export CHSH=no
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        log_success "Oh My Zsh installed successfully"
    else
        log_error "Failed to install Oh My Zsh"
        exit 1
    fi
else
    log_success "Oh My Zsh is already installed"
fi

# Set ZSH_CUSTOM path
export ZSH_CUSTOM=${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}
log_info "ZSH_CUSTOM path: $ZSH_CUSTOM"

# ----------------------------------------
# Install Powerlevel10k Theme
# ----------------------------------------
log_info "Installing Powerlevel10k theme..."
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"; then
        log_success "Powerlevel10k theme installed"
    else
        log_error "Failed to install Powerlevel10k theme"
    fi
else
    log_success "Powerlevel10k theme already installed"
fi

# ----------------------------------------
# Install Required Tools
# ----------------------------------------
log_info "Installing required tools..."

# Install bat (better cat with syntax highlighting)
if ! command -v bat &> /dev/null; then
    log_info "Installing bat..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y bat
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y bat
    elif command -v yum &> /dev/null; then
        sudo yum install -y bat
    elif command -v apk &> /dev/null; then
        sudo apk add --no-cache bat
    elif command -v brew &> /dev/null; then
        brew install bat
    else
        log_warning "Could not install bat - no supported package manager found"
    fi

    if command -v bat &> /dev/null; then
        log_success "bat installed successfully"
    else
        log_warning "bat installation failed"
    fi
else
    log_success "bat is already installed"
fi

# Fix bat command if installed as batcat (common on Ubuntu/Debian)
if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    log_info "Creating bat symlink..."
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
    log_success "bat command configured"
fi

# ----------------------------------------
# Install Zsh Plugins
# ----------------------------------------
log_info "Installing Zsh plugins..."
plugins=(
    "zsh-users/zsh-autosuggestions:zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting:zsh-syntax-highlighting"
    "zdharma-continuum/fast-syntax-highlighting:fast-syntax-highlighting"
    "marlonrichert/zsh-autocomplete:zsh-autocomplete"
    "fdellwing/zsh-bat:zsh-bat"
    "MichaelAquilina/zsh-you-should-use:you-should-use"
)

for plugin_spec in "${plugins[@]}"; do
    plugin_repo="${plugin_spec%%:*}"
    plugin_name="${plugin_spec##*:}"

    if [ ! -d "$ZSH_CUSTOM/plugins/$plugin_name" ]; then
        log_info "Installing plugin: $plugin_name"
        if git clone --depth=1 "https://github.com/$plugin_repo" "$ZSH_CUSTOM/plugins/$plugin_name" 2>/dev/null; then
            log_success "Plugin $plugin_name installed"
        else
            log_error "Failed to install plugin $plugin_name"
        fi
    else
        log_success "Plugin $plugin_name already installed"
    fi
done

# ----------------------------------------
# Configure .zshrc
# ----------------------------------------
log_info "Configuring .zshrc..."

# Backup existing .zshrc
if [ -f "$USER_HOME/.zshrc" ]; then
    cp "$USER_HOME/.zshrc" "$USER_HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    log_info "Backed up existing .zshrc"
fi

# Update ZSH_THEME
if grep -q "^ZSH_THEME=" "$USER_HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$USER_HOME/.zshrc"
else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$USER_HOME/.zshrc"
fi

# Update plugins list
if grep -q "^plugins=" "$USER_HOME/.zshrc"; then
    sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-bat you-should-use)/' "$USER_HOME/.zshrc"
else
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-bat you-should-use)' >> "$USER_HOME/.zshrc"
fi

# Add plugin configurations if not present
if ! grep -q "Plugin configurations" "$USER_HOME/.zshrc"; then
    cat >> "$USER_HOME/.zshrc" << 'EOF'

# Plugin configurations
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export YSU_MESSAGE_POSITION="after"
export YSU_MODE=ALL
export FORGIT_NO_ALIASES=1

# Better history
export HISTSIZE=100000
export SAVEHIST=100000
export HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
EOF
    log_success "Added plugin configurations to .zshrc"
fi

# ----------------------------------------
# Copy Powerlevel10k Configuration
# ----------------------------------------
log_info "Setting up Powerlevel10k configuration..."

# Check if p10k config exists in the feature directory
P10K_CONFIG="/usr/local/share/ohmyzsh/configs/.p10k.zsh"
if [ -f "$P10K_CONFIG" ]; then
    cp "$P10K_CONFIG" "$USER_HOME/.p10k.zsh"
    log_success "Copied Powerlevel10k configuration"

    # Add p10k sourcing to .zshrc if not present
    if ! grep -q "\.p10k\.zsh" "$USER_HOME/.zshrc"; then
        {
            echo ''
            echo "# To customize prompt, run 'p10k configure' or edit ~/.p10k.zsh."
            echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
        } >> "$USER_HOME/.zshrc"
        log_success "Added Powerlevel10k sourcing to .zshrc"
    fi
else
    log_warning "Powerlevel10k config not found at $P10K_CONFIG"
fi

# ----------------------------------------
# Set default shell to zsh
# ----------------------------------------
if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/usr/bin/zsh" ]; then
    log_info "Setting zsh as default shell..."
    if command -v zsh &> /dev/null; then
        # Update the shell for the current user
        if [ -f /etc/passwd ]; then
            sudo usermod -s "$(which zsh)" "$CURRENT_USER"
            log_success "Default shell set to zsh"
        else
            log_warning "Could not set default shell"
        fi
    else
        log_error "Zsh is not installed"
    fi
fi


# Create a marker file to indicate setup is complete
touch "$USER_HOME/.ohmyzsh_setup_complete"
log_success "Created setup complete marker"

echo ""
log_success "Post-create script completed successfully!"
log_info "Log file saved to: $LOG_FILE"
echo ""
