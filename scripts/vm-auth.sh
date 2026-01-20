#!/bin/zsh

# Initialize environment with all paths
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/go/bin:/opt/homebrew/bin:$PATH"

# Load proxy configuration if available
if [ -f ~/.cal-proxy-config ]; then
    source ~/.cal-proxy-config
fi

clear
echo ""
echo "============================================"
echo "  CAL VM Setup - Authenticate Agents"
echo "============================================"
echo ""

# Network connectivity check
# With transparent proxy (sshuttle), no env vars needed - traffic routes automatically
echo "🌐 Checking network connectivity..."

test_network() {
    # Quick connectivity test - 2 second timeout
    if curl -s --connect-timeout 2 -I https://github.com 2>&1 | grep -q 'HTTP'; then
        return 0
    else
        return 1
    fi
}

# Function to start proxy (standalone, doesn't require .zshrc functions)
start_proxy_standalone() {
    if [ -z "$HOST_USER" ] || [ -z "$HOST_GATEWAY" ]; then
        echo "  ⚠ Proxy not configured (missing HOST_USER or HOST_GATEWAY)"
        return 1
    fi

    if ! command -v sshuttle >/dev/null 2>&1; then
        echo "  ⚠ sshuttle not installed"
        return 1
    fi

    echo "  Starting transparent proxy (sshuttle)..."
    nohup sshuttle --dns -r ${HOST_USER}@${HOST_GATEWAY} 0.0.0.0/0 -x ${HOST_GATEWAY}/32 -x 192.168.64.0/24 >> ~/.cal-proxy.log 2>&1 &
    
    # Wait for it to start (usually takes 1-2 seconds)
    local count=0
    while [ $count -lt 5 ]; do
        sleep 0.5
        count=$((count + 1))
        if pgrep -f sshuttle >/dev/null 2>&1; then
            echo "  ✓ Proxy started"
            return 0
        fi
    done

    echo "  ⚠ Proxy failed to start (check ~/.cal-proxy.log)"
    return 1
}

if test_network; then
    echo "  ✓ Network connectivity working"
    echo ""
else
    echo "  ⚠ Network connectivity issue"
    echo ""
    echo "  Checking transparent proxy (sshuttle)..."

    if pgrep -f sshuttle >/dev/null 2>&1; then
        echo "  → Proxy is running but connectivity failed"
        echo "  → Check ~/.cal-proxy.log for errors"
        echo ""
        echo "  ⚠ Authentication may fail without network"
        echo ""
    else
        echo "  → Proxy not running, attempting to start..."
        echo ""
        
        if start_proxy_standalone; then
            # Re-test network after starting proxy
            sleep 1
            if test_network; then
                echo "  ✓ Network now working via proxy"
                echo ""
            else
                echo "  ⚠ Proxy started but network still not working"
                echo "  → Check ~/.cal-proxy.log for errors"
                echo ""
                echo "  ⚠ Authentication may fail without network"
                echo ""
            fi
        else
            echo ""
            echo "  ⚠ Could not start proxy automatically"
            echo "  → Try manually: proxy-start"
            echo "  → Or restart VM with: cal-bootstrap --restart"
            echo ""
            echo "  ⚠ Authentication may fail without network"
            echo ""
        fi
    fi
fi

echo "💡 tmux: Ctrl+b d to detach if needed"
echo ""

# Helper: check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Authentication status checks
gh_authenticated() {
    command_exists gh && gh auth status &>/dev/null
}

opencode_authenticated() {
    command_exists opencode && {
        [ -f ~/.opencode/config.json ] && [ -s ~/.opencode/config.json ] ||
        [ -f ~/.config/opencode/config.json ] && [ -s ~/.config/opencode/config.json ] ||
        [ -d ~/.opencode ] && [ -n "$(ls -A ~/.opencode 2>/dev/null)" ]
    }
}

cursor_authenticated() {
    command_exists agent && [ -d ~/.cursor/User/globalStorage ] && [ -n "$(ls -A ~/.cursor/User/globalStorage 2>/dev/null)" ]
}

claude_authenticated() {
    command_exists claude && [ -d ~/.claude ] && [ -n "$(ls -A ~/.claude 2>/dev/null)" ]
}

# 1. GitHub CLI
echo ""
echo "1. GitHub CLI (gh)"
echo "-------------------"
if gh_authenticated; then
    GH_USER=$(gh auth status 2>&1 | grep "Logged in" | head -1 | awk '{print $NF}')
    echo "  ✓ Already authenticated as $GH_USER"
    echo -n "  Re-authenticate? [y/N] "
    read -r -k 1 reply
    echo ""
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        gh auth login
    else
        echo "  → Skipped"
    fi
else
    if command_exists gh; then
        echo "  ⚠ Not authenticated"
        echo -n "  Authenticate now? [Y/n] "
        read -r -k 1 reply
        echo ""
        if [[ ! "$reply" =~ ^[Nn]$ ]]; then
            gh auth login
        else
            echo "  → Skipped"
        fi
    else
        echo "  ✗ gh not installed"
    fi
fi

# 2. Opencode
echo ""
echo "2. Opencode"
echo "-----------"
if opencode_authenticated; then
    echo "  ✓ Already authenticated"
    echo -n "  Re-authenticate? [y/N] "
    read -r -k 1 reply
    echo ""
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        opencode auth login
    else
        echo "  → Skipped"
    fi
else
    if command_exists opencode; then
        echo "  ⚠ Not authenticated"
        echo -n "  Authenticate now? [Y/n] "
        read -r -k 1 reply
        echo ""
        if [[ ! "$reply" =~ ^[Nn]$ ]]; then
            opencode auth login
        else
            echo "  → Skipped"
        fi
    else
        echo "  ✗ opencode not installed"
    fi
fi

# 3. Cursor Agent
echo ""
echo "3. Cursor Agent"
echo "---------------"
if cursor_authenticated; then
    echo "  ✓ Already authenticated"
    echo -n "  Re-authenticate? [y/N] "
    read -r -k 1 reply
    echo ""
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        agent
    else
        echo "  → Skipped"
    fi
else
    if command_exists agent; then
        echo "  ⚠ Not authenticated"
        echo -n "  Authenticate now? [Y/n] "
        read -r -k 1 reply
        echo ""
        if [[ ! "$reply" =~ ^[Nn]$ ]]; then
            agent
        else
            echo "  → Skipped"
        fi
    else
        echo "  ✗ agent not installed"
    fi
fi

# 4. Claude Code (LAST - takes over screen)
echo ""
echo "4. Claude Code"
echo "--------------"
if claude_authenticated; then
    echo "  ✓ Already authenticated"
    echo -n "  Re-authenticate? [y/N] "
    read -r -k 1 reply
    echo ""
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        echo "  Press Ctrl+C to exit when done."
        claude
    else
        echo "  → Skipped"
    fi
else
    if command_exists claude; then
        echo "  ⚠ Not authenticated"
        echo -n "  Authenticate now? [Y/n] "
        read -r -k 1 reply
        echo ""
        if [[ ! "$reply" =~ ^[Nn]$ ]]; then
            echo "  Press Ctrl+C to exit when done."
            claude
        else
            echo "  → Skipped"
        fi
    else
        echo "  ✗ claude not installed"
    fi
fi

echo ""
echo "============================================"
echo "  ✅ Setup Complete!"
echo "============================================"
echo ""
echo "💡 Proxy commands:"
echo "   proxy-status  - Check if proxy is running"
echo "   proxy-start   - Start proxy manually"
echo "   proxy-stop    - Stop proxy"
echo "   proxy-log     - View proxy logs"
echo ""
echo "💡 To re-authenticate agents later, run:"
echo "   ~/scripts/vm-auth.sh"
echo ""
