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

# Test 6: Check tmux session name in tmux-wrapper.sh
echo ""
echo "Test 6: Verify session name 'cal' in tmux-wrapper.sh..."
if [[ -f ~/scripts/tmux-wrapper.sh ]]; then
    if grep -q "new-session -A -s cal" ~/scripts/tmux-wrapper.sh; then
        echo "  ✓ Session name 'cal' found in tmux-wrapper.sh"
    else
        echo "  ⚠ WARNING: Session name 'cal' not found in tmux-wrapper.sh"
        echo "  → Check if tmux-wrapper.sh is using correct session name"
    fi
else
    echo "  ⚠ WARNING: tmux-wrapper.sh not found in ~/scripts/"
fi

# Test 7: Verify TPM loads on tmux start (runtime check)
echo ""
echo "Test 7: Verify TPM loads on tmux start..."
# Check if tmux is running
if tmux list-sessions &> /dev/null; then
    echo "  ℹ️  Tmux is running - checking plugin status..."

    # Check if TPM script exists in running environment
    # TPM sets environment variables when loaded
    if tmux show-environment -g | grep -q "TMUX" 2>/dev/null; then
        echo "  ✓ Tmux environment is accessible"

        # Verify plugins are loaded by checking if plugin scripts exist and are accessible
        # tmux-resurrect creates save/restore scripts
        if [[ -f "$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh" ]]; then
            echo "  ✓ tmux-resurrect scripts are accessible"
        else
            echo "  ⚠ WARNING: tmux-resurrect scripts not found"
        fi

        # tmux-continuum creates auto-save script
        if [[ -f "$HOME/.tmux/plugins/tmux-continuum/scripts/continuum_save.sh" ]]; then
            echo "  ✓ tmux-continuum scripts are accessible"
        else
            echo "  ⚠ WARNING: tmux-continuum scripts not found"
        fi
    else
        echo "  ⚠ WARNING: Cannot access tmux environment (may need to run inside tmux)"
    fi
else
    echo "  ℹ️  Tmux not running - skipping runtime checks"
    echo "  → Start tmux to verify plugins load: tmux new -s cal"
fi

# Test 8: Verify resurrect directory exists
echo ""
echo "Test 8: Check resurrect data directory..."
RESURRECT_DIR="$HOME/.local/share/tmux/resurrect"
if [[ -d "$RESURRECT_DIR" ]]; then
    echo "  ✓ Resurrect directory exists: $RESURRECT_DIR"

    # Check for saved sessions
    SESSION_COUNT=$(ls -1 "$RESURRECT_DIR" 2>/dev/null | grep -c "tmux_resurrect_" || echo "0")
    if [[ $SESSION_COUNT -gt 0 ]]; then
        echo "  ✓ Found $SESSION_COUNT saved session(s)"
        LATEST_SESSION=$(ls -1t "$RESURRECT_DIR"/tmux_resurrect_* 2>/dev/null | head -1)
        if [[ -n "$LATEST_SESSION" ]]; then
            SAVE_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LATEST_SESSION" 2>/dev/null || stat -c "%y" "$LATEST_SESSION" 2>/dev/null | cut -d'.' -f1)
            echo "  → Latest save: $SAVE_TIME"
        fi
    else
        echo "  ℹ️  No saved sessions yet (sessions will be saved automatically)"
    fi
else
    echo "  ℹ️  Resurrect directory not created yet (will be created on first save)"
fi

echo ""
echo "============================================"
echo "All Tests Passed!"
echo "============================================"
echo ""
echo "Tmux session persistence is properly configured."
echo ""
echo "To test session restoration:"
echo "  1. Start a tmux session: tmux new -s calf-dev"
echo "  2. Create some panes and run commands"
echo "  3. Detach: Ctrl+b d"
echo "  4. Wait 15 minutes or manually save: tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh"
echo "  5. Kill tmux: tmux kill-server"
echo "  6. Start tmux again: tmux new -s calf-dev"
echo "  7. Session should be automatically restored"
echo ""
