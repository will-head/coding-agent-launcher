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

# Clone Git Repositories Function
clone_git_repos() {
    echo ""
    echo "2. Clone Git Repositories"
    echo "-------------------------"

    if ! command_exists gh; then
        echo "  ✗ gh not installed, skipping git clone"
        return 0
    fi

    if ! gh auth status &>/dev/null; then
        echo "  ⚠ gh not authenticated, skipping git clone"
        return 0
    fi

    echo -n "  Clone repositories from GitHub? [Y/n] "
    read -r -k 1 reply
    echo ""

    if [[ "$reply" =~ ^[Nn]$ ]]; then
        echo "  → Skipped"
        return 0
    fi

    echo ""
    echo "  Fetching your repositories..."
    echo ""

    local gh_user
    gh_user=$(gh api user -q .login 2>/dev/null || echo "")

    if [ -z "$gh_user" ]; then
        echo "  ✗ Could not get GitHub username"
        return 1
    fi

    local repos
    repos=$(gh repo list --limit 50 --json name,owner,stargazerCount,pushedAt 2>/dev/null)

    if [ -z "$repos" ]; then
        echo "  ✗ No repositories found"
        return 1
    fi

    echo "  Your repositories (top 50, sorted by last push):"
    echo ""

    # Check if jq is available for pretty formatting and sorting
    if command_exists jq; then
        echo "$repos" | jq -r 'sort_by(.pushedAt) | reverse | .[] | "  \(.owner.login)/\(.name) (⭐ \(.stargazerCount))"'
    else
        # Fallback without jq (no sorting or formatting)
        gh repo list --limit 50 | sed 's/^/  /'
    fi

    echo ""
    echo "  Enter repos to clone (comma-separated, e.g., repo1,repo2)"
    echo "  Or press Enter to skip"
    echo -n "  Repos: "
    read -r repos_input

    if [ -z "$repos_input" ]; then
        echo "  → Skipped"
        return 0
    fi

    echo ""
    echo "  Cloning repositories to ~/code/github.com/..."

    local failed_repos=""
    local success_count=0

    IFS=',' read -ra REPO_ARRAY <<< "$repos_input"
    for repo in "${REPO_ARRAY[@]}"; do
        repo=$(echo "$repo" | xargs)

        if [[ "$repo" != */* ]]; then
            repo="$gh_user/$repo"
        fi

        local owner repo_name
        owner=$(echo "$repo" | cut -d'/' -f1)
        repo_name=$(echo "$repo" | cut -d'/' -f2)

        local clone_path="${HOME}/code/github.com/$owner/$repo_name"

        echo -n "    Cloning $repo... "

        if [ -d "$clone_path" ]; then
            echo "  ⚠ Already exists"
            continue
        fi

        # Capture stderr for better error reporting
        local clone_error
        clone_error=$(git clone "git@github.com:$repo.git" "$clone_path" 2>&1)
        local clone_status=$?

        if [ $clone_status -eq 0 ]; then
            echo "  ✓ Done"
            success_count=$((success_count + 1))
        else
            echo "  ✗ Failed"
            # Show first line of error for context
            local error_msg=$(echo "$clone_error" | head -1 | sed 's/^/      /')
            if [ -n "$error_msg" ]; then
                echo "$error_msg"
            fi
            failed_repos="$failed_repos $repo"
        fi
    done

    echo ""
    echo "  ✓ Cloned $success_count repositories"

    if [ -n "$failed_repos" ]; then
        echo "  ✗ Failed to clone:$failed_repos"
        echo "  💡 Check your SSH keys: ssh -T git@github.com"
    fi
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

clone_git_repos

# 3. Opencode
echo ""
echo "3. Opencode"
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

# 4. Cursor Agent (DISABLED - OAuth polling fails in VM environments)
# See PLAN.md Phase 0.8 line 39 for details
# echo ""
# echo "4. Cursor Agent"
# echo "---------------"
# if cursor_authenticated; then
#     echo "  ✓ Already authenticated"
#     echo -n "  Re-authenticate? [y/N] "
#     read -r -k 1 reply
#     echo ""
#     if [[ "$reply" =~ ^[Yy]$ ]]; then
#         echo "  ⚠ OAuth over SSH may require Screen Sharing for browser auth"
#         echo "  → Use: open vnc://$(hostname -I | awk '{print $1}')"
#         agent
#     else
#         echo "  → Skipped"
#     fi
# else
#     if command_exists agent; then
#         echo "  ⚠ Not authenticated"
#         echo ""
#         echo "  ⚠ OAuth requires browser access and keychain unlock"
#         echo "  → For GUI access use: open vnc://$(hostname -I | awk '{print $1}')"
#         echo ""
#         echo -n "  Authenticate now? [Y/n] "
#         read -r -k 1 reply
#         echo ""
#         if [[ ! "$reply" =~ ^[Nn]$ ]]; then
#             agent
#         else
#             echo "  → Skipped"
#         fi
#     else
#         echo "  ✗ agent not installed"
#     fi
# fi

# 5. Claude Code
echo ""
echo "5. Claude Code"
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
echo "💡 Git repositories are cloned to:"
echo "   ~/code/github.com/<username>/<repo>/"
echo ""
