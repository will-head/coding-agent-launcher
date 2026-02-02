#!/bin/zsh
# test-tmux-status-prompt.sh - Test tmux status prompt for new shells
#
# This script tests that tmux status prompt:
# - Shows when inside tmux session
# - Doesn't show when outside tmux
# - Detects correct prefix key
# - Handles custom prefix keys

set -e

echo "============================================"
echo "Tmux Status Prompt Test"
echo "============================================"
echo ""

# Test directory
TEST_DIR="$HOME/.tmux-prompt-test"
TEST_ZSHRC="$TEST_DIR/.zshrc"

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up test environment..."
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# Setup test environment
echo "Setting up test environment..."
mkdir -p "$TEST_DIR"

# Create test .zshrc with the prompt code
cat > "$TEST_ZSHRC" <<'EOF'
# CAL Tmux Status Prompt
# Show helpful message when starting new shells inside tmux
if [ -n "$TMUX" ]; then
    # Get current tmux prefix key
    TMUX_PREFIX=$(tmux show-options -gv prefix 2>/dev/null || echo "C-b")
    # Convert tmux prefix notation to human-readable format
    case "$TMUX_PREFIX" in
        C-b) PREFIX_DISPLAY="Ctrl+b" ;;
        C-a) PREFIX_DISPLAY="Ctrl+a" ;;
        C-*) PREFIX_DISPLAY="Ctrl+${TMUX_PREFIX#C-}" ;;
        M-*) PREFIX_DISPLAY="Alt+${TMUX_PREFIX#M-}" ;;
        *) PREFIX_DISPLAY="$TMUX_PREFIX" ;;
    esac
    echo "💡 tmux: Sessions saved automatically - use ${PREFIX_DISPLAY} d to detach"
fi
EOF

echo "  ✓ Test .zshrc created"
echo ""

# Test 1: Verify prompt DOES NOT show outside tmux
echo "Test 1: Prompt should NOT show outside tmux"
echo "-------------------------------------------"
unset TMUX
output=$(zsh -c "source $TEST_ZSHRC" 2>&1 || true)
if [ -z "$output" ]; then
    echo "  ✓ No output when outside tmux (correct)"
else
    echo "  ✗ Unexpected output when outside tmux:"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

echo ""

# Test 2: Verify prompt DOES show inside tmux (simulated)
echo "Test 2: Prompt should show inside tmux"
echo "---------------------------------------"
# Create a mock tmux script that returns prefix based on environment variable
MOCK_TMUX="$TEST_DIR/tmux"
cat > "$MOCK_TMUX" <<'MOCK_EOF'
#!/bin/zsh
if [[ "$*" == "show-options -gv prefix" ]]; then
    echo "${MOCK_PREFIX:-C-b}"
else
    exit 1
fi
MOCK_EOF
chmod +x "$MOCK_TMUX"

# Simulate being inside tmux and use mock tmux
export TMUX="/tmp/tmux-1000/default,12345,0"
export MOCK_PREFIX="C-b"
export PATH="$TEST_DIR:$PATH"

output=$(zsh -c "source $TEST_ZSHRC" 2>&1)
if echo "$output" | grep -q "Sessions saved automatically"; then
    echo "  ✓ Prompt shown when inside tmux"
else
    echo "  ✗ Prompt not shown when inside tmux"
    echo "  Output: $output"
    exit 1
fi

echo ""

# Test 3: Verify default prefix (Ctrl+b) is displayed
echo "Test 3: Default prefix (Ctrl+b) detection"
echo "------------------------------------------"
if echo "$output" | grep -q "Ctrl+b d to detach"; then
    echo "  ✓ Default prefix Ctrl+b detected correctly"
else
    echo "  ✗ Default prefix not detected correctly"
    echo "  Output: $output"
    exit 1
fi

echo ""

# Test 4: Verify custom prefix (Ctrl+a) is detected
echo "Test 4: Custom prefix (Ctrl+a) detection"
echo "-----------------------------------------"
export MOCK_PREFIX="C-a"
output=$(zsh -c "source $TEST_ZSHRC" 2>&1)
if echo "$output" | grep -q "Ctrl+a d to detach"; then
    echo "  ✓ Custom prefix Ctrl+a detected correctly"
else
    echo "  ✗ Custom prefix not detected correctly"
    echo "  Output: $output"
    exit 1
fi

echo ""

# Test 5: Verify Alt/Meta prefix is detected
echo "Test 5: Alt/Meta prefix (M-b) detection"
echo "----------------------------------------"
export MOCK_PREFIX="M-b"
output=$(zsh -c "source $TEST_ZSHRC" 2>&1)
if echo "$output" | grep -q "Alt+b d to detach"; then
    echo "  ✓ Alt prefix M-b detected correctly"
else
    echo "  ✗ Alt prefix not detected correctly"
    echo "  Output: $output"
    exit 1
fi

echo ""

# Test 6: Verify fallback when tmux command fails
echo "Test 6: Fallback to default when tmux unavailable"
echo "--------------------------------------------------"
# Remove mock tmux to simulate command failure
rm "$MOCK_TMUX"
output=$(zsh -c "source $TEST_ZSHRC" 2>&1)
if echo "$output" | grep -q "Ctrl+b d to detach"; then
    echo "  ✓ Fallback to Ctrl+b when tmux unavailable"
else
    echo "  ✗ Fallback not working correctly"
    echo "  Output: $output"
    exit 1
fi

echo ""
echo "============================================"
echo "All Tests Passed!"
echo "============================================"
echo ""
echo "Summary:"
echo "  ✓ Prompt hidden when outside tmux"
echo "  ✓ Prompt shown when inside tmux"
echo "  ✓ Default prefix (Ctrl+b) detected"
echo "  ✓ Custom prefix (Ctrl+a) detected"
echo "  ✓ Alt prefix (M-b) detected"
echo "  ✓ Fallback to default when tmux unavailable"
echo ""
echo "This ensures users always see the correct prefix"
echo "key in the tmux status prompt message."
echo ""
