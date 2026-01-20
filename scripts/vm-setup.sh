#!/bin/zsh

echo "🚀 CAL VM Setup Script"
echo "======================"
echo ""

# Transparent proxy settings (passed from cal-bootstrap)
# With sshuttle, no ports or env vars needed - traffic routes automatically
HOST_GATEWAY="${HOST_GATEWAY:-192.168.64.1}"
PROXY_MODE="${PROXY_MODE:-auto}"
HOST_USER="${HOST_USER:-}"

# Ensure Homebrew is in PATH (needed for non-interactive SSH)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Helper function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check network connectivity
echo "🌐 Checking network connectivity..."

# Check if we're using bootstrap SOCKS proxy (passed via env vars during --init)
USING_BOOTSTRAP_PROXY=false
if [ -n "$ALL_PROXY" ] || [ -n "$http_proxy" ]; then
    USING_BOOTSTRAP_PROXY=true
    echo "  Using bootstrap SOCKS proxy: ${ALL_PROXY:-$http_proxy}"
    
    # Configure git to use the proxy
    git config --global http.proxy "${ALL_PROXY:-$http_proxy}"
    git config --global https.proxy "${ALL_PROXY:-$http_proxy}"
fi

# Test connectivity (will use proxy if env vars are set)
if curl -s --connect-timeout 10 -I https://github.com 2>&1 | head -1 | grep -q "HTTP"; then
    if [ "$USING_BOOTSTRAP_PROXY" = "true" ]; then
        echo "  ✓ Network connectivity working (via SOCKS proxy)"
    else
        echo "  ✓ Network connectivity working (direct)"
    fi
    echo ""
else
    echo "  ⚠ Cannot reach github.com"
    
    if [ "$USING_BOOTSTRAP_PROXY" = "true" ]; then
        echo "  → SOCKS proxy is configured but connectivity failed"
        echo "  → Check if SSH tunnel is still running"
    elif pgrep -f sshuttle >/dev/null 2>&1; then
        echo "  → Transparent proxy (sshuttle) is running but connectivity failed"
        echo "  → Check ~/.cal-proxy.log for errors"
    else
        echo "  → No proxy active"
        echo "  → This may cause installations to fail"
    fi
    echo ""
fi

# Helper function to check if a brew package is installed
brew_installed() {
    brew list "$1" &>/dev/null
}

# Update homebrew
echo "📦 Updating Homebrew..."
brew_output=$(brew update 2>&1)
brew_exit=$?
if [ $brew_exit -eq 0 ]; then
    echo "  ✓ Homebrew updated"
else
    echo "  ⚠ Homebrew update failed (exit code: $brew_exit)"
    echo "  Error output:"
    echo "$brew_output" | grep -i "error\|fatal\|failed" | head -5 | sed 's/^/    /'
    echo "  → Continuing anyway, but package installs may fail"
fi

# Install Homebrew dependencies
echo ""
echo "📦 Installing/upgrading Homebrew packages..."
for pkg in node gh tmux sshuttle; do
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
    # Ensure node/npm is in PATH (reload brew environment)
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
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
    # Install via Homebrew (more reliable than shell script)
    if brew install anomalyco/tap/opencode; then
        echo "  ✓ opencode installed"
    else
        echo "  ✗ Failed to install opencode"
    fi
fi

# Create code directory for development
echo ""
echo "📁 Creating code directory..."
if [ ! -d ~/code ]; then
    mkdir -p ~/code
    echo "  ✓ Created ~/code directory"
else
    echo "  ✓ ~/code directory already exists"
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
export PATH="$HOME/.local/bin:$PATH"

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

if command_exists sshuttle; then
    SSHUTTLE_VERSION=$(sshuttle --version 2>/dev/null | head -n1)
    echo "  ✓ sshuttle: $SSHUTTLE_VERSION"
else
    echo "  ✗ sshuttle: not found"
fi

# Configure transparent proxy for reliable network access
# (Only configure for future use - proxy should already be running if needed)
if [ -n "$HOST_USER" ]; then
    echo ""
    echo "🌐 Configuring transparent proxy (sshuttle)..."

    # Save proxy configuration
    cat > ~/.cal-proxy-config <<EOF
# CAL Transparent Proxy Configuration
export HOST_GATEWAY="${HOST_GATEWAY}"
export HOST_USER="${HOST_USER}"
export PROXY_MODE="${PROXY_MODE}"
EOF
    echo "  ✓ Proxy configuration saved to ~/.cal-proxy-config"

    # Add transparent proxy functions to .zshrc if not present
    if ! grep -q '# CAL Transparent Proxy Functions' ~/.zshrc; then
        cat >> ~/.zshrc <<'EOF'

# CAL Transparent Proxy Functions
# Auto-loaded from vm-setup.sh
# Uses sshuttle for truly transparent network routing - no app config needed

# Load proxy configuration
if [ -f ~/.cal-proxy-config ]; then
    source ~/.cal-proxy-config
fi

# Start transparent proxy (sshuttle)
proxy-start() {
    # Check if already running
    if pgrep -f sshuttle >/dev/null 2>&1; then
        echo "Transparent proxy already running"
        return 0
    fi

    echo "Starting transparent proxy (sshuttle)..."
    
    # Check if sshuttle is installed
    if ! command -v sshuttle >/dev/null 2>&1; then
        echo "⚠ sshuttle not installed"
        echo "  Install with: brew install sshuttle"
        return 1
    fi

    # Start sshuttle in background
    # Routes all traffic through host, handles DNS, excludes local network
    nohup sshuttle --dns -r ${HOST_USER}@${HOST_GATEWAY} 0.0.0.0/0 -x ${HOST_GATEWAY}/32 -x 192.168.64.0/24 >> ~/.cal-proxy.log 2>&1 &
    local sshuttle_pid=$!
    echo "$sshuttle_pid" > ~/.cal-proxy.pid
    disown 2>/dev/null || true

    # Wait for sshuttle to start
    local count=0
    while [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
        if pgrep -f sshuttle >/dev/null 2>&1; then
            echo "✓ Transparent proxy started"
            return 0
        fi
    done

    echo "⚠ Transparent proxy may not have started (check ~/.cal-proxy.log)"
    return 1
}

# Stop transparent proxy
proxy-stop() {
    # Try PID file first
    if [ -f ~/.cal-proxy.pid ]; then
        local pid=$(cat ~/.cal-proxy.pid)
        if kill "$pid" 2>/dev/null; then
            rm ~/.cal-proxy.pid
            echo "✓ Transparent proxy stopped"
            return 0
        fi
        rm ~/.cal-proxy.pid 2>/dev/null
    fi

    # Fallback: kill by process name
    if pkill -f sshuttle 2>/dev/null; then
        echo "✓ Transparent proxy stopped"
    else
        echo "Transparent proxy not running"
    fi
}

# Restart transparent proxy
proxy-restart() {
    proxy-stop
    sleep 1
    proxy-start
}

# Check transparent proxy status
proxy-status() {
    echo "Transparent Proxy Status:"
    echo "  Mode: ${PROXY_MODE:-auto}"
    echo "  Host: ${HOST_USER}@${HOST_GATEWAY}"
    echo ""

    if pgrep -f sshuttle >/dev/null 2>&1; then
        local pid=$(pgrep -f sshuttle | head -1)
        echo "  Status: ✓ Running (PID: $pid)"

        # Test connectivity
        if curl -s --connect-timeout 5 -I https://www.google.com 2>&1 | grep -q 'HTTP'; then
            echo "  Connectivity: ✓ Working"
        else
            echo "  Connectivity: ⚠ Not working"
        fi
    else
        echo "  Status: ✗ Not running"
        
        # Test direct connectivity
        if curl -s --connect-timeout 5 -I https://www.google.com 2>&1 | grep -q 'HTTP'; then
            echo "  Direct network: ✓ Working (proxy not needed)"
        else
            echo "  Direct network: ✗ Not working"
            echo "  → Run: proxy-start"
        fi
    fi
}

# View proxy logs
proxy-log() {
    if [ -f ~/.cal-proxy.log ]; then
        tail -50 ~/.cal-proxy.log
    else
        echo "No proxy log file found"
    fi
}

# Auto-start proxy on shell initialization (if mode=on or mode=auto with failed connectivity)
# NOTE: Errors are intentionally suppressed during auto-start to avoid spamming shell startup
if [ "$PROXY_MODE" = "on" ] || [ "$PROXY_MODE" = "auto" ]; then
    # Don't spam output - check silently
    if ! pgrep -f sshuttle >/dev/null 2>&1; then
        # Proxy not running - should we start it?
        if [ "$PROXY_MODE" = "on" ]; then
            proxy-start >/dev/null 2>&1
        elif [ "$PROXY_MODE" = "auto" ]; then
            # Test if we can reach github.com directly (quietly)
            if ! curl -s --connect-timeout 5 -I https://github.com 2>&1 | grep -q 'HTTP'; then
                # Network restricted - start proxy
                proxy-start >/dev/null 2>&1
            fi
        fi
    fi
fi
EOF
        echo "  ✓ Transparent proxy functions added to ~/.zshrc"
    else
        echo "  ✓ Transparent proxy functions already in ~/.zshrc"
    fi

    # Source the configuration
    if source ~/.zshrc 2>/dev/null; then
        echo "  ✓ Shell configuration reloaded with proxy support"
    else
        echo "  ⚠ Could not reload shell config (restart shell manually)"
    fi
fi

# Clean up bootstrap proxy settings (sshuttle is transparent, doesn't need git proxy)
if [ "$USING_BOOTSTRAP_PROXY" = "true" ]; then
    echo ""
    echo "🧹 Cleaning up bootstrap proxy settings..."
    git config --global --unset http.proxy 2>/dev/null || true
    git config --global --unset https.proxy 2>/dev/null || true
    echo "  ✓ Git proxy settings removed (sshuttle is transparent)"
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
if [ -n "$HOST_USER" ]; then
    echo "  • Transparent proxy configured (sshuttle) - no app config needed"
    echo "  • Proxy commands: proxy-start, proxy-stop, proxy-status, proxy-log"
fi
echo "  • Helper scripts available in ~/scripts/:"
echo "    - vm-setup.sh: Re-run this setup script"
echo "    - vm-auth.sh: Re-authenticate all agents"
echo "  • If any commands show 'not found', restart your shell with: exec zsh"
echo "  • Auto-login takes effect on next VM reboot"
