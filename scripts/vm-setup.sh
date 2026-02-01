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
for pkg in node gh tmux sshuttle jq; do
    if brew_installed "$pkg"; then
        echo "  → Upgrading $pkg..."
        upgrade_output=$(brew upgrade "$pkg" 2>&1)
        upgrade_exit=$?
        if [ $upgrade_exit -eq 0 ]; then
            echo "  ✓ $pkg upgraded"
        elif echo "$upgrade_output" | grep -q "already installed"; then
            echo "  ✓ $pkg already up to date"
        else
            echo "  ⚠ $pkg upgrade failed"
            echo "  Error: $(echo "$upgrade_output" | head -2 | sed 's/^/    /')"
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

# Install Tart (for nested VM support - uses host's cache)
echo ""
echo "🖥️  Installing Tart (for nested VMs)..."
if brew_installed "tart"; then
    echo "  → Upgrading tart..."
    upgrade_output=$(brew upgrade cirruslabs/cli/tart 2>&1)
    upgrade_exit=$?
    if [ $upgrade_exit -eq 0 ]; then
        echo "  ✓ tart upgraded"
    elif echo "$upgrade_output" | grep -q "already installed"; then
        echo "  ✓ tart already up to date"
    else
        echo "  ⚠ tart upgrade failed"
        echo "  Error: $(echo "$upgrade_output" | head -2 | sed 's/^/    /')"
    fi
else
    echo "  → Installing tart..."
    if brew install cirruslabs/cli/tart; then
        echo "  ✓ tart installed"
        echo "  ℹ️  Tart can use host's image cache via ~/.tart/cache (shared from host)"
    else
        echo "  ✗ Failed to install tart"
    fi
fi

# Install tart-guest-agent (enables clipboard sharing)
echo ""
echo "📋 Installing Tart Guest Agent (for clipboard support)..."
if brew_installed "tart-guest-agent"; then
    echo "  → Upgrading tart-guest-agent..."
    upgrade_output=$(brew upgrade cirruslabs/cli/tart-guest-agent 2>&1)
    upgrade_exit=$?
    if [ $upgrade_exit -eq 0 ]; then
        echo "  ✓ tart-guest-agent upgraded"
    elif echo "$upgrade_output" | grep -q "already installed"; then
        echo "  ✓ tart-guest-agent already up to date"
    else
        echo "  ⚠ tart-guest-agent upgrade failed"
        echo "  Error: $(echo "$upgrade_output" | head -2 | sed 's/^/    /')"
    fi
else
    echo "  → Installing tart-guest-agent..."
    if brew install cirruslabs/cli/tart-guest-agent; then
        echo "  ✓ tart-guest-agent installed"
    else
        echo "  ✗ Failed to install tart-guest-agent"
    fi
fi

# Install Ghostty (modern terminal emulator)
echo ""
echo "🖥️  Installing Ghostty (terminal emulator)..."
# Check if cask is installed (different command for casks)
if brew list --cask ghostty &>/dev/null; then
    echo "  → Upgrading ghostty..."
    upgrade_output=$(brew upgrade --cask ghostty 2>&1)
    upgrade_exit=$?
    if [ $upgrade_exit -eq 0 ]; then
        echo "  ✓ ghostty upgraded"
    elif echo "$upgrade_output" | grep -q "already installed"; then
        echo "  ✓ ghostty already up to date"
    else
        echo "  ⚠ ghostty upgrade failed"
        echo "  Error: $(echo "$upgrade_output" | head -2 | sed 's/^/    /')"
    fi
else
    echo "  → Installing ghostty..."
    if brew install --cask ghostty; then
        echo "  ✓ ghostty installed"
    else
        echo "  ✗ Failed to install ghostty"
    fi
fi

# Configure tart-guest-agent to start automatically (enables clipboard sharing)
echo ""
echo "📋 Configuring Tart Guest Agent auto-start..."

# Detect tart-guest-agent path
TART_AGENT_PATH=""
if command_exists tart-guest-agent; then
    TART_AGENT_PATH=$(command -v tart-guest-agent)
    echo "  → Detected tart-guest-agent at: $TART_AGENT_PATH"
else
    echo "  ✗ tart-guest-agent not found in PATH - cannot configure auto-start"
fi

if [ -n "$TART_AGENT_PATH" ]; then
    AGENT_PLIST="$HOME/Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist"
    # Ensure user LaunchAgents directory exists
    mkdir -p "$HOME/Library/LaunchAgents"
    if [ ! -f "$AGENT_PLIST" ]; then
        echo "  → Creating launchd configuration..."
        cat > "$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.cirruslabs.tart-guest-agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>${TART_AGENT_PATH}</string>
        <string>--run-agent</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin</string>
        <key>TERM</key>
        <string>xterm-256color</string>
    </dict>
    <key>WorkingDirectory</key>
    <string>/Users/admin</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/tart-guest-agent.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/tart-guest-agent.log</string>
</dict>
</plist>
EOF

        # Set proper permissions for user LaunchAgent
        chmod 644 "$AGENT_PLIST"
        echo "  ✓ Created launchd configuration at $AGENT_PLIST"

        # Load the agent (will start automatically on boot)
        load_output=$(launchctl load "$AGENT_PLIST" 2>&1)
        load_exit=$?
        if [ $load_exit -eq 0 ]; then
            echo "  ✓ Tart Guest Agent started (clipboard sharing enabled)"
        else
            echo "  ⚠ Could not start agent now (will start on next boot)"
            if [ -n "$load_output" ]; then
                echo "  Error: $(echo "$load_output" | head -1 | sed 's/^/    /')"
            fi
        fi
    else
        echo "  ✓ Tart Guest Agent already configured"

        # Check if running
        if launchctl list | grep -q "org.cirruslabs.tart-guest-agent"; then
            echo "  ✓ Tart Guest Agent is running"
        else
            echo "  → Starting Tart Guest Agent..."
            load_output=$(launchctl load "$AGENT_PLIST" 2>&1)
            load_exit=$?
            if [ $load_exit -eq 0 ]; then
                echo "  ✓ Tart Guest Agent started"
            else
                echo "  ⚠ Could not start agent (may need reboot)"
                if [ -n "$load_output" ]; then
                    echo "  Error: $(echo "$load_output" | head -1 | sed 's/^/    /')"
                fi
            fi
        fi
    fi
fi

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

# Install CCS (Claude Code Switch)
echo ""
echo "🚀 Installing CCS (Claude Code Switch)..."
if command_exists ccs; then
    echo "  ✓ CCS already installed"
else
    # Ensure node/npm is in PATH (reload brew environment)
    eval "$(/opt/homebrew/bin/brew shellenv)"

    if npm install -g @kaitranntt/ccs --force; then
        echo "  ✓ CCS installed"
        # Sync CCS configuration after installation
        if ccs sync; then
            echo "  ✓ CCS configuration synced"
        else
            echo "  ⚠ CCS sync failed (you may need to run 'ccs sync' manually)"
        fi
    else
        echo "  ✗ Failed to install CCS"
    fi
fi

# Install Codex CLI
echo ""
echo "🤖 Installing Codex CLI..."
if command_exists codex; then
    echo "  ✓ Codex CLI already installed"
else
    # Ensure node/npm is in PATH (reload brew environment)
    eval "$(/opt/homebrew/bin/brew shellenv)"

    if npm install -g @openai/codex; then
        echo "  ✓ Codex CLI installed"
    else
        echo "  ✗ Failed to install Codex CLI"
    fi
fi

# Install Go development tools
echo ""
echo "🛠️  Installing Go development tools..."
echo "  Core Go tools (go fmt, go vet, go test, go mod) are built-in"
echo ""

# Ensure Go is in PATH (from Homebrew)
if [ -d "/opt/homebrew/opt/go/libexec/bin" ]; then
    export PATH="/opt/homebrew/opt/go/libexec/bin:$PATH"
fi
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Install golangci-lint (comprehensive linters runner - includes 50+ linters)
echo "  → golangci-lint (meta-linter with 50+ linters)..."
if command_exists golangci-lint; then
    echo "    ✓ Already installed"
else
    if brew install golangci-lint; then
        echo "    ✓ Installed"
    else
        echo "    ✗ Failed to install"
    fi
fi

# Install staticcheck (fast, standalone static analyzer)
echo "  → staticcheck (static analyzer)..."
if command_exists staticcheck; then
    echo "    ✓ Already installed"
else
    if go install honnef.co/go/tools/cmd/staticcheck@latest; then
        echo "    ✓ Installed"
    else
        echo "    ✗ Failed to install"
    fi
fi

# Install goimports (auto-import formatter)
echo "  → goimports (import formatter)..."
if command_exists goimports; then
    echo "    ✓ Already installed"
else
    if go install golang.org/x/tools/cmd/goimports@latest; then
        echo "    ✓ Installed"
    else
        echo "    ✗ Failed to install"
    fi
fi

# Install delve (debugger)
echo "  → delve (debugger)..."
if command_exists dlv; then
    echo "    ✓ Already installed"
else
    if go install github.com/go-delve/delve/cmd/dlv@latest; then
        echo "    ✓ Installed"
    else
        echo "    ✗ Failed to install"
    fi
fi

# Install mockgen (test mocking)
echo "  → mockgen (test mocking)..."
if command_exists mockgen; then
    echo "    ✓ Already installed"
else
    if go install go.uber.org/mock/mockgen@latest; then
        echo "    ✓ Installed"
    else
        echo "    ✗ Failed to install"
    fi
fi

# Install air (hot reload for development)
echo "  → air (hot reload)..."
if command_exists air; then
    echo "    ✓ Already installed"
else
    if go install github.com/air-verse/air@latest; then
        echo "    ✓ Installed"
    else
        echo "    ✗ Failed to install"
    fi
fi

echo "  ✓ Go development tools setup complete"

# Create code directory for development
echo ""
echo "📁 Creating code directory..."
if [ ! -d ~/code ]; then
    mkdir -p ~/code
    echo "  ✓ Created ~/code directory"
else
    echo "  ✓ ~/code directory already exists"
fi

# Save VM credentials and settings for login scripts
echo ""
echo "🔑 Saving VM configuration..."
cat > ~/.cal-vm-config <<EOF
# CAL VM Configuration (restricted permissions)
VM_PASSWORD="${VM_PASSWORD:-admin}"
EOF
chmod 600 ~/.cal-vm-config
echo "  ✓ Saved to ~/.cal-vm-config (mode 600)"

# Add keychain auto-unlock to .zshrc (runs on every login)
if ! grep -q '# CAL Keychain Auto-Unlock' ~/.zshrc; then
    cat >> ~/.zshrc <<'KEYCHAIN_EOF'

# CAL Keychain Auto-Unlock
# Only run on login shells, and only if not already done in this session chain
if [[ -o login ]] && [ -z "$CAL_SESSION_INITIALIZED" ]; then
    export CAL_SESSION_INITIALIZED=1

    if [ -f ~/.cal-vm-config ]; then
        source ~/.cal-vm-config
        if security unlock-keychain -p "${VM_PASSWORD:-admin}" login.keychain 2>/dev/null; then
            echo "🔐 Login keychain: ✓"
        else
            echo "🔐 Login keychain: ⚠ Could not unlock (may need manual unlock)"
        fi
    fi

    # CAL Auth Needed (during --init)
    # Runs vm-auth.sh for initial authentication during cal-bootstrap --init
    if [ -f ~/.cal-auth-needed ]; then
        rm -f ~/.cal-auth-needed
        if [ -f ~/scripts/vm-auth.sh ]; then
            echo ""
            echo "🚀 Running initial authentication..."
            echo ""
            CAL_AUTH_NEEDED=1 zsh ~/scripts/vm-auth.sh
            # Exit to allow cal-bootstrap to continue with cal-init creation
            # User will be automatically reconnected after cal-init is ready
            exit 0
        fi
    fi

    # CAL First Run (after restoring cal-init)
    # Runs vm-first-run.sh to check for remote repository updates after restoring cal-init
    if [ -f ~/.cal-first-run ]; then
        rm -f ~/.cal-first-run
        if [ -f ~/scripts/vm-first-run.sh ]; then
            echo ""
            echo "🔄 First login detected - checking for repository updates..."
            echo ""
            zsh ~/scripts/vm-first-run.sh
            # Stay in cal-dev shell (don't exit like vm-auth does)
        fi
    fi
fi
KEYCHAIN_EOF
    echo "  ✓ Added keychain auto-unlock to ~/.zshrc"
else
    echo "  ✓ Keychain auto-unlock already in ~/.zshrc"
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

# Add Go bin paths to PATH if not already present (for Go development tools)
if ! grep -q 'export GOPATH="\$HOME/go"' ~/.zshrc; then
    cat >> ~/.zshrc <<'GO_PATH_EOF'
# Go development environment
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
GO_PATH_EOF
    echo "  ✓ Added Go paths to PATH"
else
    echo "  ✓ Go paths already in PATH"
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

# Configure logout git status check
echo ""
echo "⚙️  Configuring logout git status check..."

if [ ! -f ~/.zlogout ] || ! grep -q '# CAL Logout Git Status Check' ~/.zlogout; then
    cat >> ~/.zlogout <<'EOF'
# CAL Logout Git Status Check
# Scans for uncommitted or unpushed changes before logout
# Note: This scan may take a few seconds if ~/code has many repositories

# Only run for interactive shells
if [[ -o interactive ]]; then
    # Find all git repositories in ~/code
    # Using arrays for cleaner handling of repository paths
    uncommitted_repos=()
    unpushed_repos=()

    if [ -d ~/code ]; then
        # Scan for repositories with uncommitted or unpushed changes
        while IFS= read -r gitdir; do
            [ -z "$gitdir" ] && continue
            repo_dir=$(dirname "$gitdir")

            cd "$repo_dir" 2>/dev/null || continue

            # Check for uncommitted changes
            if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                uncommitted_repos+=("$repo_dir")
            fi

            # Check for unpushed commits
            current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            if [ -n "$current_branch" ] && [ "$current_branch" != "HEAD" ]; then
                if git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
                    if [ -n "$(git log @{u}.. --oneline 2>/dev/null)" ]; then
                        unpushed_repos+=("$repo_dir")
                    fi
                fi
            fi
        done < <(find ~/code -name ".git" -type d 2>/dev/null)

        # Show warning if changes found
        uncommitted_count=${#uncommitted_repos[@]}
        unpushed_count=${#unpushed_repos[@]}

        if [ $uncommitted_count -gt 0 ] || [ $unpushed_count -gt 0 ]; then
            echo ""
            echo "⚠️  WARNING: Uncommitted or unpushed git changes detected!"
            echo ""

            if [ $uncommitted_count -gt 0 ]; then
                echo "Repositories with uncommitted changes:"
                for repo in "${uncommitted_repos[@]}"; do
                    echo "  - $repo"
                done
                echo ""
            fi

            if [ $unpushed_count -gt 0 ]; then
                echo "Repositories with unpushed commits:"
                for repo in "${unpushed_repos[@]}"; do
                    echo "  - $repo"
                done
                echo ""
            fi

            echo -n "Continue logout anyway? [y/N] "
            read -r -k 1 continue_reply
            echo ""

            if [[ ! "$continue_reply" =~ ^[Yy]$ ]]; then
                echo ""
                echo "Logout cancelled. Push your changes and try again."
                echo ""
                # Prevent logout by starting a new login shell
                # This replaces the current shell process, effectively cancelling the logout
                # The CAL_SESSION_INITIALIZED flag prevents re-running keychain unlock
                # But .zlogout will still run on next exit to check git again
                exec zsh -l
            else
                echo ""
                echo "Logging out despite uncommitted/unpushed changes..."
            fi
        fi
    fi
fi
EOF
    echo "  ✓ Added logout git status check to ~/.zlogout"
else
    echo "  ✓ Logout git status check already configured in ~/.zlogout"
fi

# Configure VM detection for coding agents
echo ""
echo "🔍 Configuring VM detection..."

# Create VM info file
# NOTE: CAL_VERSION should be updated when making significant changes to CAL.
# Version format: MAJOR.MINOR.PATCH (semver)
# - MAJOR: Breaking changes to VM detection API or structure
# - MINOR: New features or enhancements (backward compatible)
# - PATCH: Bug fixes and minor improvements
cat > ~/.cal-vm-info <<EOF
# CAL VM Information
# This file indicates this system is running inside a CAL VM
# Coding agents can check for this file to detect VM environment

CAL_VM=true
CAL_VM_NAME=${CAL_VM_NAME:-cal-dev}
CAL_VM_CREATED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CAL_VERSION=0.1.0
EOF
echo "  ✓ Created VM info file at ~/.cal-vm-info"

# Add CAL_VM environment variable to .zshrc
if ! grep -q 'export CAL_VM=' ~/.zshrc; then
    cat >> ~/.zshrc <<'EOF'

# CAL VM Detection
# Indicates this system is running inside a CAL VM
export CAL_VM=true
export CAL_VM_INFO="$HOME/.cal-vm-info"

# Helper function to display VM info
cal-vm-info() {
    if [ -f ~/.cal-vm-info ]; then
        cat ~/.cal-vm-info
    else
        echo "Not running in a CAL VM"
        return 1
    fi
}

# Helper function to check if running in CAL VM
is-cal-vm() {
    [ -f ~/.cal-vm-info ] && [ "$CAL_VM" = "true" ]
}
EOF
    echo "  ✓ Added VM detection to ~/.zshrc"
else
    echo "  ✓ VM detection already configured in ~/.zshrc"
fi

# Reload configuration to make CAL_VM available
export CAL_VM=true
export CAL_VM_INFO="$HOME/.cal-vm-info"

# Configure tmux with session persistence
echo ""
echo "🖥️  Configuring tmux with session persistence..."
if [ -f ~/scripts/vm-tmux-resurrect.sh ]; then
    zsh ~/scripts/vm-tmux-resurrect.sh
else
    echo "  ⚠ vm-tmux-resurrect.sh not found in ~/scripts/"
    echo "  → Tmux session persistence not configured"
    echo "  → Run ~/scripts/vm-tmux-resurrect.sh manually to enable"
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

if command_exists codex; then
    CODEX_VERSION=$(codex --version 2>/dev/null | head -n1)
    echo "  ✓ codex: $CODEX_VERSION"
else
    echo "  ✗ codex: not found (may need to restart shell)"
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

if command_exists tart; then
    TART_VERSION=$(tart --version 2>/dev/null | head -n1)
    echo "  ✓ tart: $TART_VERSION"
    # Check if cache is shared from host
    if [ -L ~/.tart/cache ]; then
        echo "    → Cache: Shared from host (saves ~30GB downloads)"
    elif [ -d ~/.tart/cache ]; then
        echo "    → Cache: Local (not using host cache)"
    else
        echo "    → Cache: Not initialized"
    fi
else
    echo "  ✗ tart: not found"
fi

if command_exists tart-guest-agent; then
    TART_AGENT_VERSION=$(tart-guest-agent --version 2>/dev/null | head -n1)
    echo "  ✓ tart-guest-agent: $TART_AGENT_VERSION"
    # Check if agent is running
    if launchctl list | grep -q "org.cirruslabs.tart-guest-agent"; then
        echo "    → Status: Running (clipboard sharing enabled)"
    else
        echo "    → Status: Not running (will start on reboot)"
    fi
else
    echo "  ✗ tart-guest-agent: not found"
fi

if [ -d "/Applications/Ghostty.app" ]; then
    # Ghostty doesn't have a CLI version command, just check if app exists
    echo "  ✓ ghostty: Installed"
else
    echo "  ✗ ghostty: not found"
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

# Create auth-needed flag for automatic vm-auth during --init
touch ~/.cal-auth-needed
sync  # Ensure filesystem writes are flushed before VM reboot
echo "  ✓ Auth-needed flag set (vm-auth will run on next login)"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Reload shell configuration: source ~/.zshrc"
echo "  2. Authenticate with GitHub: gh auth login"
echo "  3. Authenticate agents:"
echo "     • Claude Code: claude"
echo "     • Opencode: opencode auth login"
echo "     • Cursor: agent"
echo "     • Codex CLI: codex"
echo ""
echo "💡 Notes:"
echo "  • Auto-login is enabled - VM will boot to desktop for Screen Sharing"
echo "  • Login keychain is unlocked - enables agent authentication via SSH"
echo "  • Clipboard sharing enabled - VM to Host copy works in Screen Sharing (Edit → Use Shared Clipboard)"
echo "  • WARNING: Do NOT paste from Host to VM - this will crash the VM"
if [ -n "$HOST_USER" ]; then
    echo "  • Transparent proxy configured (sshuttle) - no app config needed"
    echo "  • Proxy commands: proxy-start, proxy-stop, proxy-status, proxy-log"
fi
echo "  • Helper scripts available in ~/scripts/:"
echo "    - vm-setup.sh: Re-run this setup script"
echo "    - vm-auth.sh: Re-authenticate all agents"
echo "    - vm-tmux-resurrect.sh: Setup tmux session persistence"
echo "  • If any commands show 'not found', restart your shell with: exec zsh"
echo "  • Auto-login takes effect on next VM reboot"
