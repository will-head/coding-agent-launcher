#!/bin/zsh

echo "🚀 CAL VM Setup Script"
echo "======================"
echo ""

# Ensure Homebrew is in PATH (needed for non-interactive SSH)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Helper function to check if a brew package is installed
brew_installed() {
    brew list "$1" &>/dev/null
}

# Helper function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Update homebrew
echo "📦 Updating Homebrew..."
if brew update &>/dev/null; then
    echo "  ✓ Homebrew updated"
else
    echo "  ⚠ Homebrew update skipped (may already be running)"
fi

# Install Homebrew dependencies
echo ""
echo "📦 Installing/upgrading Homebrew packages..."
for pkg in node gh tmux; do
    if brew_installed "$pkg"; then
        echo "  → Upgrading $pkg..."
        if brew upgrade "$pkg" 2>/dev/null; then
            echo "  ✓ $pkg upgraded"
        else
            echo "  ✓ $pkg already up to date"
        fi
    else
        echo "  → Installing $pkg..."
        if brew install "$pkg"; then
            echo "  ✓ $pkg installed"
        else
            echo "  ✗ Failed to install $pkg"
        fi
    fi
done

# Install Claude Code
echo ""
echo "🤖 Installing Claude Code..."
if command_exists claude; then
    echo "  ✓ Claude Code already installed"
else
    if npm install -g @anthropic-ai/claude-code; then
        echo "  ✓ Claude Code installed"
    else
        echo "  ✗ Failed to install Claude Code"
    fi
fi

# Install Cursor CLI
echo ""
echo "🖱️  Installing Cursor CLI..."
if command_exists agent; then
    echo "  ✓ Cursor CLI already installed"
else
    if curl -fsSL https://cursor.com/install | bash; then
        echo "  ✓ Cursor CLI installed"
    else
        echo "  ✗ Failed to install Cursor CLI"
    fi
fi

# Install opencode
echo ""
echo "🐹 Installing opencode..."
if command_exists opencode; then
    echo "  ✓ opencode already installed"
else
    if curl -fsSL https://opencode.ai/install | bash; then
        echo "  ✓ opencode installed"
    else
        echo "  ✗ Failed to install opencode"
    fi
fi

# Configure shell environment
echo ""
echo "⚙️  Configuring shell environment..."

# Add .local/bin to PATH if not already present (for Cursor CLI)
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo "  ✓ Added .local/bin to PATH"
else
    echo "  ✓ .local/bin already in PATH"
fi

# Add .opencode/bin to PATH if not already present (for opencode)
if ! grep -q 'export PATH="$HOME/.opencode/bin:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.zshrc
    echo "  ✓ Added .opencode/bin to PATH"
else
    echo "  ✓ .opencode/bin already in PATH"
fi

# Fix terminal TERM setting
if ! grep -q 'export TERM=xterm-256color' ~/.zshrc; then
    echo 'export TERM=xterm-256color' >> ~/.zshrc
    echo "  ✓ Fixed TERM setting for delete key"
else
    echo "  ✓ TERM setting already configured"
fi

# Fix up arrow history keybinding
if ! grep -q 'bindkey "\^\[\[A" up-line-or-history' ~/.zshrc; then
    echo 'bindkey "^[[A" up-line-or-history' >> ~/.zshrc
    echo "  ✓ Fixed up arrow history keybinding"
else
    echo "  ✓ History keybinding already configured"
fi

# Source the updated config
if source ~/.zshrc 2>/dev/null; then
    echo "  ✓ Shell configuration reloaded"
else
    echo "  ⚠ Could not reload shell config (restart shell manually)"
fi

# Configure tmux
echo ""
echo "🖥️  Configuring tmux..."
if [ ! -f ~/.tmux.conf ]; then
    cat > ~/.tmux.conf <<'EOF'
# Better terminal support
set -g default-terminal "screen-256color"

# Enable mouse support (scrolling, pane selection, resizing)
set -g mouse on

# Increase scrollback buffer
set -g history-limit 50000

# Don't rename windows automatically
set-option -g allow-rename off

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Enable activity alerts
setw -g monitor-activity on
set -g visual-activity off

# Faster command sequences (no delay)
set -s escape-time 0

# Vi-style key bindings in copy mode
setw -g mode-keys vi

# Easy config reload
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Better splitting with current path
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Pane navigation (Vim-style)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Pane resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Status bar styling
set -g status-style bg=colour235,fg=colour255
set -g status-left-length 20
set -g status-left '#[fg=colour76,bold]CAL '
set -g status-right '#[fg=colour245]%H:%M '
set -g window-status-current-style bg=colour240,fg=colour255,bold
set -g window-status-style fg=colour245

# Pane border styling
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour76
EOF
    echo "  ✓ Created default tmux configuration"
else
    echo "  ✓ tmux configuration already exists"
fi

# Enable auto-login for Screen Sharing
echo ""
echo "🔓 Enabling auto-login..."
if sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser admin; then
    echo "  ✓ Auto-login enabled for admin user"
else
    echo "  ✗ Failed to enable auto-login"
fi

# Configure keychain for SSH/headless access
echo ""
echo "🔐 Configuring keychain for SSH access..."
# Unlock the login keychain (default password is 'admin' for Tart VMs)
if security unlock-keychain -p "${VM_PASSWORD:-admin}" login.keychain 2>/dev/null; then
    echo "  ✓ Login keychain unlocked"
else
    echo "  ⚠ Could not unlock keychain (may need manual unlock)"
fi

# Verify installations
echo ""
echo "🔍 Verifying installations..."

# Reload PATH for verification
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

if command_exists claude; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null | head -n1)
    echo "  ✓ claude: $CLAUDE_VERSION"
else
    echo "  ✗ claude: not found"
fi

if command_exists agent; then
    AGENT_VERSION=$(agent --version 2>/dev/null | head -n1)
    echo "  ✓ agent: $AGENT_VERSION"
else
    echo "  ✗ agent: not found (may need to restart shell)"
fi

if command_exists opencode; then
    OPENCODE_VERSION=$(opencode --version 2>/dev/null | head -n1)
    echo "  ✓ opencode: $OPENCODE_VERSION"
else
    echo "  ✗ opencode: not found (may need to restart shell)"
fi

if command_exists gh; then
    GH_VERSION=$(gh --version 2>/dev/null | head -n1)
    echo "  ✓ gh: $GH_VERSION"
else
    echo "  ✗ gh: not found"
fi

if command_exists tmux; then
    TMUX_VERSION=$(tmux -V 2>/dev/null)
    echo "  ✓ tmux: $TMUX_VERSION"
else
    echo "  ✗ tmux: not found"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Reload shell configuration: source ~/.zshrc"
echo "  2. Authenticate with GitHub: gh auth login"
echo "  3. Authenticate agents: claude, opencode auth login, agent"
echo ""
echo "💡 Notes:"
echo "  • Auto-login is enabled - VM will boot to desktop for Screen Sharing"
echo "  • Login keychain is unlocked - enables agent authentication via SSH"
echo "  • If any commands show 'not found', restart your shell with: exec zsh"
echo "  • Auto-login takes effect on next VM reboot"
