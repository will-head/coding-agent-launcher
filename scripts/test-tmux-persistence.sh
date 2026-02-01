#!/bin/zsh
# test-tmux-persistence.sh - Test tmux session persistence
#
# This script tests that tmux session persistence is properly configured.
#
# Usage: Run this script in the VM after vm-tmux-resurrect.sh has been executed

set -e

echo "============================================"
echo "Tmux Session Persistence Test"
echo "============================================"
echo ""

# Test 1: Check if TPM is installed
echo "Test 1: Check TPM installation..."
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "  ✓ TPM installed at ~/.tmux/plugins/tpm"
else
    echo "  ✗ FAILED: TPM not found"
    exit 1
fi

# Test 2: Check if tmux.conf exists and has resurrection settings
echo ""
echo "Test 2: Check tmux.conf configuration..."
if [[ ! -f "$HOME/.tmux.conf" ]]; then
    echo "  ✗ FAILED: ~/.tmux.conf not found"
    exit 1
fi

# Check for key settings
REQUIRED_SETTINGS=(
    "@plugin 'tmux-plugins/tmux-resurrect'"
    "@plugin 'tmux-plugins/tmux-continuum'"
    "@resurrect-capture-pane-contents 'on'"
    "@continuum-restore 'on'"
    "@continuum-save-interval '15'"
)

for setting in "${REQUIRED_SETTINGS[@]}"; do
    if grep -q "$setting" "$HOME/.tmux.conf"; then
        echo "  ✓ Found: $setting"
    else
        echo "  ✗ FAILED: Missing setting: $setting"
        exit 1
    fi
done

# Test 3: Check if plugins are installed
echo ""
echo "Test 3: Check plugin installation..."
PLUGINS=("tmux-resurrect" "tmux-continuum")
for plugin in "${PLUGINS[@]}"; do
    if [[ -d "$HOME/.tmux/plugins/$plugin" ]]; then
        echo "  ✓ Plugin installed: $plugin"
    else
        echo "  ✗ FAILED: Plugin not installed: $plugin"
        exit 1
    fi
done

# Test 4: Check if .zlogout has session save hook
echo ""
echo "Test 4: Check .zlogout configuration..."
if [[ -f "$HOME/.zlogout" ]]; then
    if grep -q "# CAL: Save tmux sessions on logout" "$HOME/.zlogout"; then
        echo "  ✓ .zlogout configured with session save hook"
    else
        echo "  ⚠ WARNING: .zlogout exists but session save hook not found"
    fi
else
    echo "  ⚠ WARNING: .zlogout not found"
fi

# Test 5: Check if tmux is installed
echo ""
echo "Test 5: Check tmux availability..."
if command -v tmux &> /dev/null; then
    TMUX_VERSION=$(tmux -V)
    echo "  ✓ tmux installed: $TMUX_VERSION"
else
    echo "  ✗ FAILED: tmux not found"
    exit 1
fi

# Test 6: Check tmux session name in cal-bootstrap
echo ""
echo "Test 6: Verify session name 'cal-dev' in cal-bootstrap..."
if [[ -f ~/scripts/../../scripts/cal-bootstrap ]]; then
    if grep -q "new-session -A -s cal-dev" ~/scripts/../../scripts/cal-bootstrap; then
        echo "  ✓ Session name 'cal-dev' found in cal-bootstrap"
    else
        echo "  ⚠ WARNING: Session name 'cal-dev' not found in cal-bootstrap"
        echo "  → Check if cal-bootstrap is using correct session name"
    fi
else
    echo "  ⚠ WARNING: cal-bootstrap not found (expected if running in VM)"
fi

echo ""
echo "============================================"
echo "All Tests Passed!"
echo "============================================"
echo ""
echo "Tmux session persistence is properly configured."
echo ""
echo "To test session restoration:"
echo "  1. Start a tmux session: tmux new -s cal-dev"
echo "  2. Create some panes and run commands"
echo "  3. Detach: Ctrl+b d"
echo "  4. Wait 15 minutes or manually save: tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh"
echo "  5. Kill tmux: tmux kill-server"
echo "  6. Start tmux again: tmux new -s cal-dev"
echo "  7. Session should be automatically restored"
echo ""
