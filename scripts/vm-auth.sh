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
    # Check if opencode has any credentials configured
    command_exists opencode && ! opencode auth list 2>/dev/null | grep -q "0 credentials"
}

cursor_authenticated() {
    # Check if agent is logged in (not "Not logged in")
    command_exists agent && ! agent whoami 2>/dev/null | grep -q "Not logged in"
}

claude_authenticated() {
    command_exists claude && [ -d ~/.claude ] && [ -n "$(ls -A ~/.claude 2>/dev/null)" ]
}

# Show authentication status summary
echo "Authentication Status:"
echo "----------------------"

# Track if all services are authenticated
all_authenticated=true

# 1. GitHub CLI
if gh_authenticated; then
    echo "  1. GitHub CLI (gh)      ✓ Authenticated"
elif command_exists gh; then
    echo "  1. GitHub CLI (gh)      ⚠ Not authenticated"
    all_authenticated=false
else
    echo "  1. GitHub CLI (gh)      ✗ Not installed"
fi

# 2. Opencode
if opencode_authenticated; then
    echo "  2. Opencode             ✓ Authenticated"
elif command_exists opencode; then
    echo "  2. Opencode             ⚠ Not authenticated"
    all_authenticated=false
else
    echo "  2. Opencode             ✗ Not installed"
fi

# 3. Cursor Agent
if cursor_authenticated; then
    echo "  3. Cursor Agent         ✓ Authenticated"
elif command_exists agent; then
    echo "  3. Cursor Agent         ⚠ Not authenticated"
    all_authenticated=false
else
    echo "  3. Cursor Agent         ✗ Not installed"
fi

# 4. Claude Code
if claude_authenticated; then
    echo "  4. Claude Code          ✓ Authenticated"
elif command_exists claude; then
    echo "  4. Claude Code          ⚠ Not authenticated"
    all_authenticated=false
else
    echo "  4. Claude Code          ✗ Not installed"
fi

echo ""

# Adjust default based on authentication status
if [ "$all_authenticated" = true ]; then
    echo -n "Do you want to authenticate services? [y/N] "
    read -r -k 1 proceed
    echo ""
    if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
        skip_auth=true
    else
        skip_auth=false
    fi
else
    echo -n "Do you want to authenticate services? [Y/n] "
    read -r -k 1 proceed
    echo ""
    if [[ "$proceed" =~ ^[Nn]$ ]]; then
        skip_auth=true
    else
        skip_auth=false
    fi
fi

if [ "$skip_auth" = true ]; then
    echo "  → Skipping authentication"
else
    # Run all authentication steps

# 1. GitHub CLI
echo ""
echo "1. GitHub CLI (gh)"
echo "-------------------"
if gh_authenticated; then
    GH_USER=$(gh api user -q .login 2>/dev/null || gh auth status 2>&1 | grep "Logged in" | head -1 | sed 's/.*as \([^ ]*\).*/\1/')
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

fi  # End of authentication block

# GitHub Repository Sync (after all authentications)
echo ""
echo "📦 GitHub Repository Sync"
echo "-------------------------"

if gh_authenticated; then
    # Get authenticated username
    GH_USER=$(gh api user -q .login 2>/dev/null || gh auth status 2>&1 | grep "Logged in" | head -1 | sed 's/.*as \([^ ]*\).*/\1/')

    echo "  Clone repositories to ~/code/github.com/[owner]/[repo]"
    echo ""
    echo -n "  Do you want to clone repositories? [Y/n] "
    read -r -k 1 clone_reply
    echo ""

    if [[ ! "$clone_reply" =~ ^[Nn]$ ]]; then
        echo ""
        echo "  Enter repository names (one per line):"
        echo "  - Format: 'owner/repo' or just 'repo' (assumes your account)"
        echo "  - Press Enter on empty line when done"
        echo ""

        repo_count=0
        success_count=0
        skip_count=0
        fail_count=0

        while true; do
            echo -n "  Repository: "
            read -r repo_input

            # Empty input means done
            if [ -z "$repo_input" ]; then
                break
            fi

            # Parse repo input
            if [[ "$repo_input" == *"/"* ]]; then
                # Full owner/repo format
                repo_full="$repo_input"
                repo_owner=$(echo "$repo_input" | cut -d'/' -f1)
                repo_name=$(echo "$repo_input" | cut -d'/' -f2)
            else
                # Just repo name, use authenticated user
                repo_full="${GH_USER}/${repo_input}"
                repo_owner="$GH_USER"
                repo_name="$repo_input"
            fi

            repo_count=$((repo_count + 1))

            # Target directory
            target_dir="$HOME/code/github.com/${repo_owner}/${repo_name}"

            # Check if already exists
            if [ -d "$target_dir" ]; then
                echo "    ⊘ Already exists: $target_dir"
                skip_count=$((skip_count + 1))
                continue
            fi

            # Create parent directory
            mkdir -p "$(dirname "$target_dir")"

            # Clone repository
            echo "    → Cloning ${repo_full}..."
            if gh repo clone "$repo_full" "$target_dir" 2>&1; then
                echo "    ✓ Cloned to: $target_dir"
                success_count=$((success_count + 1))
            else
                echo "    ✗ Failed to clone ${repo_full}"
                fail_count=$((fail_count + 1))
            fi
        done

        # Summary
        if [ $repo_count -gt 0 ]; then
            echo ""
            echo "  Summary: $success_count cloned, $skip_count skipped, $fail_count failed"
        else
            echo "  → No repositories entered"
        fi
    else
        echo "  → Skipped repository cloning"
    fi
else
    echo "  ⚠ GitHub CLI not authenticated"
    echo ""
    echo -n "  Do you want to clone repositories? [y/N] "
    read -r -k 1 clone_reply
    echo ""

    if [[ "$clone_reply" =~ ^[Yy]$ ]]; then
        echo "  ✗ Cannot clone - please authenticate GitHub CLI first"
    else
        echo "  → Skipped repository cloning"
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

# If running during init (first-run), prompt to continue setup
if [ -n "$CAL_FIRST_RUN" ]; then
    echo "Press Enter to continue setup..."
    read -r
    exit 0
fi
