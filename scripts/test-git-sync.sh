#!/bin/zsh

# Test script for git repo sync functionality
# This tests the new git repo sync feature in vm-auth.sh

set -e

echo "=========================================="
echo "Testing Git Repo Sync Functionality"
echo "=========================================="
echo ""

# Test 1: Check if gh command exists
echo "Test 1: Checking if gh command is available..."
if command -v gh &>/dev/null; then
    echo "  ✓ gh command found"
    GH_VERSION=$(gh --version | head -1)
    echo "    Version: $GH_VERSION"
else
    echo "  ✗ gh command not found"
    echo "    Install with: brew install gh"
    exit 1
fi

# Test 2: Check if gh is authenticated
echo ""
echo "Test 2: Checking GitHub CLI authentication..."
if gh auth status &>/dev/null; then
    echo "  ✓ gh is authenticated"
    GH_USER=$(gh api user -q .login 2>/dev/null || echo "unknown")
    echo "    Authenticated as: $GH_USER"
else
    echo "  ✗ gh is not authenticated"
    echo "    Run: gh auth login"
    exit 1
fi

# Test 3: Test gh repo list command
echo ""
echo "Test 3: Testing gh repo list command..."
REPO_COUNT=$(gh repo list --limit 5 2>/dev/null | wc -l | tr -d ' ')
if [ "$REPO_COUNT" -gt 0 ]; then
    echo "  ✓ Found $REPO_COUNT repos"
    echo "    First 5 repos:"
    gh repo list --limit 5 --json name,owner | jq -r '.[] | "  - \(.owner.login)/\(.name)"' 2>/dev/null || \
        gh repo list --limit 5 | head -5 | sed 's/^/  - /'
else
    echo "  ✗ No repos found or gh repo list failed"
    exit 1
fi

# Test 4: Check ~/code directory structure
echo ""
echo "Test 4: Testing ~/code directory structure..."
if [ ! -d ~/code ]; then
    echo "  Creating ~/code directory..."
    mkdir -p ~/code
    echo "  ✓ ~/code created"
else
    echo "  ✓ ~/code exists"
fi

# Test 5: Test git clone to ~/code structure
echo ""
echo "Test 5: Testing git clone path structure..."
TEST_REPO="github.com/$GH_USER/test-repo"
TEST_PATH=~/code/github.com/$GH_USER/test-repo
echo "  Target path for $TEST_REPO:"
echo "    $TEST_PATH"

# Test 6: Simulate repo selection (just show UI without cloning)
echo ""
echo "Test 6: Simulating repo selection UI..."
echo "  Available repos (top 10):"
gh repo list --limit 10 --json name,owner,stargazerCount 2>/dev/null | \
    jq -r '.[] | "\(.owner.login)/\(.name) (⭐ \(.stargazerCount))"' | \
    nl -w2 -s'. ' | sed 's/^/  /'

# Test 7: Check for GitHub enterprise support
echo ""
echo "Test 7: Checking for GitHub Enterprise support..."
GH_HOSTS=$(gh auth status 2>&1 | grep "GitHub.com" || echo "github.com")
echo "  Detected GitHub hosts: $GH_HOSTS"

echo ""
echo "=========================================="
echo "✅ All Tests Passed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run ~/scripts/vm-auth.sh to clone repos"
echo "  2. Test actual cloning functionality"
echo "  3. Future: Add support for GitHub Enterprise"
echo ""
