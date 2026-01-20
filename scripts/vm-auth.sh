#!/bin/zsh

# Initialize environment with all paths (same as old .cal-welcome.sh)
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/go/bin:/opt/homebrew/bin:$PATH"

clear
echo ""
echo "============================================"
echo "  CAL VM Setup - Authenticate Agents"
echo "============================================"
echo ""

# Check if we need SOCKS proxy for network access
# Only load proxy config if direct connection fails
# Use nc (netcat) to test TCP connectivity - more reliable than curl
if nc -z -w 5 github.com 443 2>/dev/null; then
    echo "💡 Network: Direct connection OK"
    # Unset any proxy vars inherited from parent shell (.zshrc may have set them)
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy
else
    echo "⚠️  Network: Direct connection failed, checking SOCKS proxy..."
    if [ -f ~/.cal-socks-config ]; then
        source ~/.cal-socks-config
        # Verify proxy is actually working
        if nc -z -w 5 github.com 443 2>/dev/null; then
            echo "💡 Network: Using SOCKS proxy (HTTP_PROXY=$HTTP_PROXY)"
        else
            echo "⚠️  Network: SOCKS proxy not working - authentication may fail"
            echo "   Try running: start_socks && start_http_proxy"
            # Unset proxy since it's not working
            unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
        fi
    else
        echo "⚠️  Network: No SOCKS config found - authentication may fail"
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
