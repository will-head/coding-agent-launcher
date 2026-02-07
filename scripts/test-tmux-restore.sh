#!/bin/bash
# Test script to debug tmux restore process

# Load Homebrew into PATH
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

echo "=== Tmux Restore Debug Test ==="
echo ""

# Check current tmux state
echo "1. Checking current tmux server state..."
if tmux list-sessions 2>/dev/null; then
    echo "   Tmux server is running with sessions above"
else
    echo "   No tmux server running"
fi
echo ""

# Check resurrect data
echo "2. Checking resurrect data..."
echo "   Last save file:"
ls -lh ~/.local/share/tmux/resurrect/last 2>/dev/null || echo "   No last symlink"
if [ -L ~/.local/share/tmux/resurrect/last ]; then
    echo "   Points to: $(readlink ~/.local/share/tmux/resurrect/last)"
    echo "   Contents:"
    cat ~/.local/share/tmux/resurrect/last
fi
echo ""

# Kill any existing tmux server
echo "3. Killing any existing tmux server..."
tmux kill-server 2>/dev/null || echo "   No server to kill"
echo ""

# Start fresh server
echo "4. Starting fresh tmux server..."
TERM=xterm-256color tmux start-server
echo "   Server started"
echo ""

# Check sessions before restore
echo "5. Sessions before restore:"
tmux list-sessions 2>/dev/null || echo "   No sessions"
echo ""

# Trigger restore
echo "6. Triggering restore..."
TERM=xterm-256color tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
echo "   Restore triggered, waiting 2 seconds..."
sleep 2
echo ""

# Check sessions after restore
echo "7. Sessions after restore:"
tmux list-sessions 2>/dev/null || echo "   No sessions"
echo ""

# Try to attach to calf-dev
echo "8. Attempting to attach to calf-dev..."
if tmux has-session -t calf-dev 2>/dev/null; then
    echo "   ✓ calf-dev session exists!"
    echo "   Attaching..."
    TERM=xterm-256color tmux attach -t calf-dev
else
    echo "   ✗ calf-dev session not found"
    echo "   Creating new session..."
    TERM=xterm-256color tmux new-session -s calf-dev
fi
