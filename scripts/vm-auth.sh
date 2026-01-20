#!/bin/zsh

# Initialize environment with all paths
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

clear
echo ""
echo "============================================"
echo "  CAL VM Setup - Authenticate Agents"
echo "============================================"
echo ""

# Network connectivity detection and proxy setup
# Strategy: Try direct connection first, only use SOCKS if direct fails

echo "🌐 Checking network connectivity..."

# Function to test network connectivity
test_network() {
    # Test with timeout - if curl or nc work, we have connectivity
    if curl -s --connect-timeout 3 -I https://github.com 2>&1 | grep -q 'HTTP'; then
        return 0
    elif nc -z -w 3 github.com 443 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ALWAYS start with NO proxy vars set - test direct connection first
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy

if test_network; then
    # Direct connection works - use it!
    echo "  ✓ Direct connection working"
    echo ""
else
    # Direct connection failed - try SOCKS proxy
    echo "  ⚠ Direct connection failed"
    echo "  → Checking for SOCKS proxy..."
    
    # Load SOCKS configuration if available
    if [ -f ~/.cal-socks-config ]; then
        source ~/.cal-socks-config
        
        # Check if SOCKS tunnel is running
        if nc -z localhost ${SOCKS_PORT:-1080} 2>/dev/null; then
            echo "  → SOCKS tunnel detected on port ${SOCKS_PORT:-1080}"
            
            # Set proxy environment variables
            export ALL_PROXY="socks5://localhost:${SOCKS_PORT:-1080}"
            export HTTP_PROXY="http://localhost:${HTTP_PROXY_PORT:-8080}"
            export HTTPS_PROXY="http://localhost:${HTTP_PROXY_PORT:-8080}"
            
            # Test connectivity with proxy
            if test_network; then
                echo "  ✓ Using SOCKS proxy successfully"
                echo "     HTTP_PROXY=$HTTP_PROXY"
                echo ""
            else
                echo "  ⚠ SOCKS proxy not working"
                echo "     Authentication may fail"
                echo ""
                # Unset proxy since it's not helping
                unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
            fi
        else
            # SOCKS not running - try to start it
            echo "  → SOCKS tunnel not running, attempting to start..."
            
            # Try to start SOCKS if functions are available
            if type start_socks &>/dev/null; then
                if start_socks >/dev/null 2>&1; then
                    # Wait a moment for tunnel to stabilize
                    sleep 2
                    
                    # Set proxy vars and test again
                    export ALL_PROXY="socks5://localhost:${SOCKS_PORT:-1080}"
                    export HTTP_PROXY="http://localhost:${HTTP_PROXY_PORT:-8080}"
                    export HTTPS_PROXY="http://localhost:${HTTP_PROXY_PORT:-8080}"
                    
                    if test_network; then
                        echo "  ✓ SOCKS tunnel started and working"
                        echo "     HTTP_PROXY=$HTTP_PROXY"
                        echo ""
                    else
                        echo "  ⚠ SOCKS started but not working"
                        echo "     Authentication may fail"
                        echo ""
                        unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
                    fi
                else
                    echo "  ✗ Failed to start SOCKS tunnel"
                    echo "     Try manually: start_socks"
                    echo "     Authentication may fail"
                    echo ""
                fi
            else
                echo "  ✗ SOCKS functions not available"
                echo "     Try manually: source ~/.zshrc && start_socks"
                echo "     Authentication may fail"
                echo ""
            fi
        fi
    else
        echo "  ✗ No SOCKS configuration found"
        echo "     Direct connection failed and no proxy available"
        echo "     Authentication will likely fail"
        echo ""
    fi
fi

echo ""
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
    # Check multiple possible config locations for opencode
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
echo "💡 To re-authenticate agents later, run:"
echo "   ~/scripts/vm-auth.sh"
echo ""
