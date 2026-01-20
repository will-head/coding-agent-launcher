#!/bin/zsh

echo "🚀 CAL VM Setup Script"
echo "======================"
echo ""

# SOCKS tunnel settings (passed from cal-bootstrap)
SOCKS_PORT="${SOCKS_PORT:-1080}"
HTTP_PROXY_PORT="${HTTP_PROXY_PORT:-8080}"
HOST_GATEWAY="${HOST_GATEWAY:-192.168.64.1}"
SOCKS_MODE="${SOCKS_MODE:-auto}"
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

# Store whether we're using SOCKS proxy (check early before helper functions)
USING_SOCKS_PROXY=false
if [ -n "$HTTP_PROXY" ] && [ -n "$HTTPS_PROXY" ]; then
    USING_SOCKS_PROXY=true
fi

# Check if we have proxy environment variables set (indicating SOCKS is active)
# These are passed by cal-bootstrap when SOCKS tunnel was started before vm-setup.sh
if [ "$USING_SOCKS_PROXY" = "true" ]; then
    echo "🌐 Network: Using SOCKS proxy"
    echo "   ALL_PROXY=$ALL_PROXY"
    echo "   HTTP_PROXY=$HTTP_PROXY"
    echo "   HTTPS_PROXY=$HTTPS_PROXY"
    echo ""
    
    # Export lowercase versions too (some tools need lowercase)
    export http_proxy="$HTTP_PROXY"
    export https_proxy="$HTTPS_PROXY"
    export all_proxy="$ALL_PROXY"
    
    # Also set NO_PROXY to avoid proxying localhost/internal addresses
    export NO_PROXY="localhost,127.0.0.1,::1,192.168.64.0/24"
    export no_proxy="$NO_PROXY"
    
    # Git needs special config for SOCKS proxy
    git config --global http.proxy "$ALL_PROXY"
    git config --global https.proxy "$ALL_PROXY"
    
    # Test if proxy is actually working
    echo "  Testing proxy connectivity..."
    
    # First, verify SOCKS tunnel is accessible
    if nc -z localhost ${SOCKS_PORT} 2>/dev/null; then
        echo "  ✓ SOCKS tunnel is listening on port ${SOCKS_PORT}"
    else
        echo "  ✗ SOCKS tunnel NOT accessible on port ${SOCKS_PORT}"
        echo "    This will cause all installations to fail!"
        echo ""
    fi
    
    # Test actual connectivity through proxy using curl with explicit --socks5 flag
    # (More reliable than relying on HTTP_PROXY env var)
    echo "  → Testing https://github.com through proxy..."
    if curl --socks5-hostname localhost:${SOCKS_PORT} --connect-timeout 10 -s -I https://github.com 2>&1 | head -1 | grep -q "HTTP"; then
        echo "  ✓ SOCKS proxy is working (github.com reachable)"
        echo ""
    else
        echo "  ✗ SOCKS proxy test failed"
        echo "  ⚠ Installations will likely fail!"
        echo ""
    fi
    
    # CRITICAL: Install gost FIRST (it's needed for HTTP-to-SOCKS bridge)
    # Homebrew is slow with SOCKS5, so we need the HTTP bridge running
    echo "📦 Installing gost (HTTP-to-SOCKS bridge) first..."
    echo "   (Required for Homebrew to work properly with SOCKS proxy)"
    echo "   ⚠️  This may take 5-10 minutes with SOCKS5 - please be patient!"
    echo ""
    
    # TODO: Investigate why gost install is so slow/hangs with SOCKS5
    # See SOCKS_ISSUES.md for details and attempted solutions
    
    # Install gost using Homebrew with ALL_PROXY (no timeout - let it complete)
    if ! command_exists gost; then
        echo "  → Installing gost via Homebrew..."
        echo "     (Downloading through SOCKS5 proxy - this is slow but works)"
        
        # Simple approach - just run it and wait
        # User can Ctrl+C if they want to abort
        if env ALL_PROXY="$ALL_PROXY" brew install gost 2>&1 | grep -E "Downloaded|Pouring|Installed|Error|Failed" | sed 's/^/     /'; then
            # Check if gost is now available
            hash -r 2>/dev/null || true  # Rehash PATH
            if command_exists gost; then
                echo "  ✓ gost installed successfully"
            else
                echo "  ⚠ gost install completed but command not found"
                echo "     Continuing without HTTP bridge"
            fi
        else
            echo "  ✗ gost install failed"
            echo "     Continuing without HTTP bridge"
        fi
    else
        echo "  ✓ gost already installed"
    fi
    echo ""
    
    # Start HTTP-to-SOCKS bridge NOW (before other installations)
    if command_exists gost; then
        echo "  Starting HTTP-to-SOCKS bridge..."
        # Kill any existing gost process
        pkill -f "gost -L" 2>/dev/null || true
        # Start gost in background
        nohup gost -L "http://:${HTTP_PROXY_PORT}" -F "socks5://localhost:${SOCKS_PORT}" >/dev/null 2>&1 &
        echo $! > ~/.cal-http-proxy.pid
        disown 2>/dev/null || true
        sleep 2
        
        # Verify it's running
        if nc -z localhost ${HTTP_PROXY_PORT} 2>/dev/null; then
            echo "  ✓ HTTP bridge running on port ${HTTP_PROXY_PORT}"
            
            # Now switch to HTTP proxy (much faster for Homebrew)
            export HTTP_PROXY="http://localhost:${HTTP_PROXY_PORT}"
            export HTTPS_PROXY="http://localhost:${HTTP_PROXY_PORT}"
            export http_proxy="$HTTP_PROXY"
            export https_proxy="$HTTPS_PROXY"
            
            echo "  ✓ Switched to HTTP proxy for better performance"
            echo ""
        else
            echo "  ⚠ HTTP bridge failed to start"
            echo "  → Continuing with SOCKS5 (installations will be slower)"
            echo ""
        fi
    else
        echo "  ⚠ gost not available"
        echo "  → Continuing with SOCKS5 directly (installations will be slower)"
        echo "  → This is OK but may take 5-10 minutes for Homebrew operations"
        echo ""
    fi
else
    echo "🌐 Network: Direct connection"
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

if command_exists gost; then
    GOST_VERSION=$(gost --version 2>/dev/null | head -n1)
    echo "  ✓ gost: $GOST_VERSION"
else
    echo "  ✗ gost: not found"
fi

# Configure SOCKS tunnel for reliable network access
# (Only configure for future use - tunnel should already be running if needed)
if [ -n "$HOST_USER" ]; then
    echo ""
    echo "🌐 Configuring SOCKS tunnel for network access..."

    # Save SOCKS configuration (but NOT the proxy environment variables yet)
    # Proxy vars will only be set when SOCKS tunnel is actually running
    cat > ~/.cal-socks-config <<EOF
# CAL SOCKS Configuration
export SOCKS_PORT="${SOCKS_PORT}"
export HTTP_PROXY_PORT="${HTTP_PROXY_PORT}"
export HOST_GATEWAY="${HOST_GATEWAY}"
export HOST_USER="${HOST_USER}"
export SOCKS_MODE="${SOCKS_MODE}"
# Proxy environment variables are set dynamically when SOCKS tunnel starts
# export ALL_PROXY="socks5://localhost:${SOCKS_PORT}"
# export HTTP_PROXY="http://localhost:${HTTP_PROXY_PORT}"
# export HTTPS_PROXY="http://localhost:${HTTP_PROXY_PORT}"
EOF
    echo "  ✓ SOCKS configuration saved to ~/.cal-socks-config"

    # Add SOCKS tunnel functions to .zshrc if not present
    if ! grep -q '# CAL SOCKS Tunnel Functions' ~/.zshrc; then
        cat >> ~/.zshrc <<'EOF'

# CAL SOCKS Tunnel Functions
# Auto-loaded from vm-setup.sh

# Load SOCKS configuration
if [ -f ~/.cal-socks-config ]; then
    source ~/.cal-socks-config
fi

# Set proxy environment variables (only when SOCKS is running)
set_proxy_vars() {
    export ALL_PROXY="socks5://localhost:${SOCKS_PORT}"
    export HTTP_PROXY="http://localhost:${HTTP_PROXY_PORT}"
    export HTTPS_PROXY="http://localhost:${HTTP_PROXY_PORT}"
}

# Unset proxy environment variables
unset_proxy_vars() {
    unset ALL_PROXY HTTP_PROXY HTTPS_PROXY
}

# Start SOCKS tunnel (VM→Host for network access)
start_socks() {
    # Check if tunnel is already running
    if nc -z localhost ${SOCKS_PORT} 2>/dev/null; then
        echo "SOCKS tunnel already running on port ${SOCKS_PORT}"
        set_proxy_vars  # Ensure proxy vars are set
        return 0
    fi

    echo "Starting SOCKS tunnel (VM→Host on port ${SOCKS_PORT})..."
    ssh -D ${SOCKS_PORT} -f -N \
        -o StrictHostKeyChecking=yes \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=3 \
        -o ExitOnForwardFailure=yes \
        ${HOST_USER}@${HOST_GATEWAY} 2>>~/.cal-socks.log

    # Wait for tunnel
    local count=0
    while [ $count -lt 5 ]; do
        if nc -z localhost ${SOCKS_PORT} 2>/dev/null; then
            echo "✓ SOCKS tunnel started"
            set_proxy_vars  # Set proxy vars now that tunnel is running
            # Also start HTTP bridge
            start_http_proxy
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done

    echo "⚠ SOCKS tunnel failed to start (check ~/.cal-socks.log)"
    return 1
}

# Stop SOCKS tunnel
stop_socks() {
    local pid=$(lsof -ti :${SOCKS_PORT} 2>/dev/null)
    if [ -n "$pid" ]; then
        echo "Stopping SOCKS tunnel (PID: $pid)..."
        kill "$pid" 2>/dev/null
        echo "✓ SOCKS tunnel stopped"
        unset_proxy_vars  # Unset proxy vars since tunnel is stopped
    else
        echo "SOCKS tunnel not running"
    fi

    # Also stop HTTP bridge
    stop_http_proxy
}

# Restart SOCKS tunnel
restart_socks() {
    stop_socks
    sleep 1
    start_socks
}

# Check SOCKS tunnel status
socks_status() {
    echo "SOCKS Tunnel Status:"
    echo "  Mode: ${SOCKS_MODE}"
    echo "  SOCKS port: ${SOCKS_PORT}"
    echo "  HTTP proxy port: ${HTTP_PROXY_PORT}"
    echo "  Host: ${HOST_USER}@${HOST_GATEWAY}"
    echo ""

    if nc -z localhost ${SOCKS_PORT} 2>/dev/null; then
        local pid=$(lsof -ti :${SOCKS_PORT} 2>/dev/null)
        echo "  Status: ✓ Running (PID: $pid)"

        # Test connectivity
        if curl -s --connect-timeout 5 --socks5-hostname localhost:${SOCKS_PORT} -I https://www.google.com 2>&1 | grep -q '200'; then
            echo "  Connectivity: ✓ Working"
        else
            echo "  Connectivity: ⚠ Not working"
        fi
        
        # Show current proxy vars
        if [ -n "$HTTP_PROXY" ]; then
            echo "  Proxy vars: ✓ Set"
        else
            echo "  Proxy vars: ⚠ Not set (run: source ~/.zshrc)"
        fi
    else
        echo "  Status: ✗ Not running"
    fi

    echo ""
    if nc -z localhost ${HTTP_PROXY_PORT} 2>/dev/null; then
        local http_pid=$(lsof -ti :${HTTP_PROXY_PORT} 2>/dev/null)
        echo "  HTTP Bridge: ✓ Running (PID: $http_pid)"
    else
        echo "  HTTP Bridge: ✗ Not running"
    fi
}

# Start HTTP-to-SOCKS bridge (for Node.js tools like opencode)
start_http_proxy() {
    # Check if bridge is already running
    if nc -z localhost ${HTTP_PROXY_PORT} 2>/dev/null; then
        return 0
    fi

    # Check if gost is installed
    if ! command -v gost >/dev/null 2>&1; then
        return 1
    fi

    # Start gost bridge (silent, with PID tracking for cleaner management)
    nohup gost -L "http://:${HTTP_PROXY_PORT}" -F "socks5://localhost:${SOCKS_PORT}" >>~/.cal-http-proxy.log 2>&1 &
    local gost_pid=$!
    echo "$gost_pid" > ~/.cal-http-proxy.pid
    disown
    sleep 1
}

# Stop HTTP-to-SOCKS bridge
stop_http_proxy() {
    # Try PID file first (cleaner), fall back to port-based detection
    if [ -f ~/.cal-http-proxy.pid ]; then
        local pid=$(cat ~/.cal-http-proxy.pid)
        if kill "$pid" 2>/dev/null; then
            rm ~/.cal-http-proxy.pid
            return 0
        fi
        # PID file stale, remove it
        rm ~/.cal-http-proxy.pid
    fi

    # Fallback: find by port (handles cases where PID file is missing)
    local pid=$(lsof -ti :${HTTP_PROXY_PORT} 2>/dev/null)
    if [ -n "$pid" ]; then
        kill "$pid" 2>/dev/null
    fi
}

# Auto-start SOCKS tunnel on shell initialization (if mode=on or mode=auto with failed connectivity test)
# NOTE: Errors are intentionally suppressed during auto-start to avoid spamming shell startup
# If SOCKS fails to start automatically, users can manually run:
#   start_socks        - to see error messages
#   socks_status       - to check current state
#   ~/.cal-socks.log   - to view error logs
if [ "$SOCKS_MODE" = "on" ] || [ "$SOCKS_MODE" = "auto" ]; then
    # Don't spam output - check silently
    if ! nc -z localhost ${SOCKS_PORT} 2>/dev/null; then
        # SOCKS not running - should we start it?
        if [ "$SOCKS_MODE" = "on" ]; then
            start_socks >/dev/null 2>&1  # Silent: errors logged to ~/.cal-socks.log
        elif [ "$SOCKS_MODE" = "auto" ]; then
            # Test if we can reach github.com directly (quietly)
            if ! curl -s --connect-timeout 5 -I https://github.com 2>&1 | grep -q 'HTTP'; then
                # Network restricted - start SOCKS
                start_socks >/dev/null 2>&1  # Silent: errors logged to ~/.cal-socks.log
            fi
        fi
    else
        # Tunnel is running, make sure proxy vars are set
        set_proxy_vars
    fi
fi
EOF
        echo "  ✓ SOCKS tunnel functions added to ~/.zshrc"
    else
        echo "  ✓ SOCKS tunnel functions already in ~/.zshrc"
    fi

    # Source the configuration
    if source ~/.zshrc 2>/dev/null; then
        echo "  ✓ Shell configuration reloaded with SOCKS support"
    else
        echo "  ⚠ Could not reload shell config (restart shell manually)"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Reload shell configuration: source ~/.zshrc"
echo "  2. Authenticate with GitHub: gh auth login"
echo "  3. Authenticate agents: claude, opencode auth login, agent"
if [ "$SOCKS_TUNNEL_AVAILABLE" = "true" ]; then
    echo "  4. Check SOCKS tunnel: socks_status"
fi
echo ""
echo "💡 Notes:"
echo "  • Auto-login is enabled - VM will boot to desktop for Screen Sharing"
echo "  • Login keychain is unlocked - enables agent authentication via SSH"
if [ "$SOCKS_TUNNEL_AVAILABLE" = "true" ]; then
    echo "  • SOCKS tunnel configured - provides reliable network access"
    echo "  • SOCKS commands: start_socks, stop_socks, restart_socks, socks_status"
fi
echo "  • Helper scripts available in ~/scripts/:"
echo "    - vm-setup.sh: Re-run this setup script"
echo "    - vm-auth.sh: Re-authenticate all agents"
echo "  • If any commands show 'not found', restart your shell with: exec zsh"
echo "  • Auto-login takes effect on next VM reboot"
