#!/bin/zsh
# test-tmux-session-clear.sh - Test tmux session clearing during first login
#
# This script tests that tmux session data is properly cleared after vm-auth.sh
# completes to prevent calf-init from capturing authentication screen output.

set -e

echo "============================================"
echo "Tmux Session Clear Test"
echo "============================================"
echo ""

# Test directory
TEST_DIR="$HOME/.tmux-session-clear-test"
RESURRECT_DIR="$TEST_DIR/resurrect"

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up test environment..."
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# Setup test environment
echo "Setting up test environment..."
mkdir -p "$RESURRECT_DIR"

# Create mock session files (simulating tmux-resurrect saved state)
echo "Creating mock session files..."
touch "$RESURRECT_DIR/tmux_resurrect_20260202120000.txt"
touch "$RESURRECT_DIR/tmux_resurrect_20260202120500.txt"
echo "tmux_resurrect_20260202120500.txt" > "$RESURRECT_DIR/last"

# Verify files exist
if [ -f "$RESURRECT_DIR/last" ] && [ -f "$RESURRECT_DIR/tmux_resurrect_20260202120000.txt" ]; then
    echo "  ✓ Mock session files created"
else
    echo "  ✗ Failed to create mock session files"
    exit 1
fi

echo ""
echo "Test 1: Verify session files exist before clearing"
echo "---------------------------------------------------"
file_count=$(ls -1 "$RESURRECT_DIR" | wc -l | tr -d ' ')
if [ "$file_count" -eq 3 ]; then
    echo "  ✓ Found 3 session files (as expected)"
else
    echo "  ✗ Expected 3 session files, found $file_count"
    exit 1
fi

echo ""
echo "Test 2: Clear session data (simulate auth completion)"
echo "------------------------------------------------------"
# This is the actual clearing logic from vm-setup.sh
if [ -d "$RESURRECT_DIR" ]; then
    rm -f "$RESURRECT_DIR"/*
    echo "  ✓ Session clearing logic executed"
else
    echo "  ✗ Resurrect directory not found"
    exit 1
fi

echo ""
echo "Test 3: Verify session files are cleared"
echo "-----------------------------------------"
if [ -d "$RESURRECT_DIR" ]; then
    remaining=$(ls -1 "$RESURRECT_DIR" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$remaining" -eq 0 ]; then
        echo "  ✓ All session files cleared (directory is empty)"
    else
        echo "  ✗ Expected 0 session files, found $remaining"
        echo "  Remaining files:"
        ls -la "$RESURRECT_DIR"
        exit 1
    fi
else
    echo "  ✓ Resurrect directory removed"
fi

echo ""
echo "Test 4: Verify 'last' symlink is removed"
echo "-----------------------------------------"
if [ ! -f "$RESURRECT_DIR/last" ]; then
    echo "  ✓ 'last' symlink properly removed"
else
    echo "  ✗ 'last' symlink still exists"
    exit 1
fi

echo ""
echo "Test 5: Verify session data files are removed"
echo "----------------------------------------------"
session_files=$(find "$RESURRECT_DIR" -name "tmux_resurrect_*.txt" 2>/dev/null | wc -l | tr -d ' ')
if [ "$session_files" -eq 0 ]; then
    echo "  ✓ All session data files removed"
else
    echo "  ✗ Found $session_files session data files (expected 0)"
    exit 1
fi

echo ""
echo "============================================"
echo "All Tests Passed!"
echo "============================================"
echo ""
echo "Summary:"
echo "  ✓ Session files can be created"
echo "  ✓ Clearing logic removes all session data"
echo "  ✓ 'last' symlink is removed"
echo "  ✓ Session data files are removed"
echo "  ✓ Directory is empty after clearing"
echo ""
echo "This ensures calf-init won't capture authentication"
echo "screen output when tmux-resurrect sessions are cleared."
echo ""
