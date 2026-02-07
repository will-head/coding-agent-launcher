#!/bin/zsh

# Initialize environment with all paths
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/go/bin:/opt/homebrew/bin:$PATH"

# Load proxy configuration if available
if [ -f ~/.calf-proxy-config ]; then
    source ~/.calf-proxy-config
fi

clear
echo ""
echo "============================================"
echo "  CALF VM First Run - Check Repository Updates"
echo "============================================"
echo ""

# Show keychain status (unlocked in .zshrc before this script)
if security show-keychain-info login.keychain 2>/dev/null | grep -q "no-timeout"; then
    echo "🔐 Login keychain: ✓"
else
    echo "🔐 Login keychain: ⚠ Could not verify unlock status"
fi
echo ""

# Network connectivity check
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
    nohup sshuttle --dns -r ${HOST_USER}@${HOST_GATEWAY} 0.0.0.0/0 -x ${HOST_GATEWAY}/32 -x 192.168.64.0/24 >> ~/.calf-proxy.log 2>&1 &

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

    echo "  ⚠ Proxy failed to start (check ~/.calf-proxy.log)"
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
        echo "  → Check ~/.calf-proxy.log for errors"
        echo ""
        echo "  ⚠ Repository checks may fail without network"
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
                echo "  → Check ~/.calf-proxy.log for errors"
                echo ""
                echo "  ⚠ Repository checks may fail without network"
                echo ""
            fi
        else
            echo ""
            echo "  ⚠ Could not start proxy automatically"
            echo "  → Try manually: proxy-start"
            echo "  → Or restart VM with: cal-bootstrap --restart"
            echo ""
            echo "  ⚠ Repository checks may fail without network"
            echo ""
        fi
    fi
fi

# Check for repositories
echo "🔄 Checking Repositories for Remote Updates"
echo "---------------------------------------------"

# Find all git repositories in ~/code
all_repos=()
repos_with_updates=()
fetch_failed_count=0

if [ -d ~/code ]; then
    echo "  Scanning ~/code for git repositories..."

    # Count total repos found
    repo_count=0

    # Find all .git directories
    while IFS= read -r gitdir; do
        [ -z "$gitdir" ] && continue
        repo_dir=$(dirname "$gitdir")
        all_repos+=("$repo_dir")
        repo_count=$((repo_count + 1))
    done < <(find ~/code -name ".git" -type d 2>/dev/null)

    if [ $repo_count -eq 0 ]; then
        echo "  → No repositories found"
    else
        echo "  → Found $repo_count $([ $repo_count -eq 1 ] && echo 'repository' || echo 'repositories')"
        echo ""

        # Check for remote updates
        for repo_dir in "${all_repos[@]}"; do
            # Check if repo has a remote
            cd "$repo_dir" 2>/dev/null || continue

            if ! git remote -v &>/dev/null || [ -z "$(git remote)" ]; then
                continue
            fi

            # Get current branch
            current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            if [ -z "$current_branch" ] || [ "$current_branch" = "HEAD" ]; then
                continue
            fi

            # Check if branch has upstream
            if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
                continue
            fi

            # Fetch updates (git has built-in timeout, no need for timeout command)
            echo -n "    $repo_dir: "
            fetch_error=$(git fetch --quiet 2>&1)
            fetch_exit=$?
            if [ $fetch_exit -eq 0 ]; then
                # Check if remote is ahead
                local_commit=$(git rev-parse HEAD 2>/dev/null)
                remote_commit=$(git rev-parse @{u} 2>/dev/null)

                if [ "$local_commit" != "$remote_commit" ]; then
                    # Check if remote is ahead (not just diverged)
                    if git merge-base --is-ancestor HEAD @{u} 2>/dev/null; then
                        echo "updates available"
                        repos_with_updates+=("$repo_dir")
                    else
                        echo "diverged (manual merge needed)"
                    fi
                else
                    echo "up to date"
                fi
            else
                fetch_failed_count=$((fetch_failed_count + 1))
                # Show why fetch failed (auth, network, etc.)
                if echo "$fetch_error" | grep -qi "authentication\|permission\|denied"; then
                    echo "fetch failed (authentication required)"
                elif echo "$fetch_error" | grep -qi "could not resolve\|network\|connection\|timed out"; then
                    echo "fetch failed (network error)"
                else
                    echo "fetch failed"
                    # Show error details if non-empty
                    if [ -n "$fetch_error" ]; then
                        echo "      Error: $(echo "$fetch_error" | head -1)"
                    fi
                fi
            fi
        done

        echo ""

        # Summary
        repo_update_count=${#repos_with_updates[@]}
        if [ $repo_update_count -gt 0 ]; then
            # Proper pluralization
            if [ $repo_update_count -eq 1 ]; then
                echo "  ✓ Found 1 repository with available updates:"
            else
                echo "  ✓ Found $repo_update_count repositories with available updates:"
            fi
            for repo in "${repos_with_updates[@]}"; do
                echo "    - $repo"
            done
            echo ""
            echo "  → To update, cd into each repository and run: git pull"
        elif [ $fetch_failed_count -gt 0 ]; then
            echo "  ⚠ Could not check all repositories (some fetches failed)"
        else
            echo "  ✓ All repositories are up to date"
        fi
    fi
else
    echo "  → No ~/code directory found"
fi

echo ""

# Enable tmux session persistence (only runs on first login after setup)
echo "🔄 Enabling Tmux Session Persistence"
echo "------------------------------------"
echo ""

# Turn on tmux history by loading TPM
if [ -f ~/.tmux/plugins/tpm/tpm ]; then
    echo "  Loading tmux plugins..."
    ~/.tmux/plugins/tpm/tpm 2>/dev/null
    echo "  ✓ Tmux plugins loaded"
else
    echo "  ⚠ TPM not found at ~/.tmux/plugins/tpm/tpm"
    echo "  → Session persistence may not be available"
fi

# Remove first-run flag (only after tmux history is enabled)
if [ -f ~/.calf-first-run ]; then
    rm -f ~/.calf-first-run && sync
    echo "  ✓ First-run flag removed"
    echo ""
    echo "✓ Tmux session persistence enabled"
    echo "  → Sessions will auto-save every 15 minutes"
    echo "  → Sessions will restore on login"
else
    echo "  → First-run flag already removed"
fi

echo ""
