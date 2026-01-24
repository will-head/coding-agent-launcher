#!/bin/zsh
#
# Test script for keyboard layout detection
#
# This script tests the keyboard layout detection functionality
# used in cal-bootstrap and vm-setup.sh
#
# Usage:
#   chmod +x test-keyboard-layout.sh
#   ./test-keyboard-layout.sh

echo "=========================================="
echo "Keyboard Layout Detection Test"
echo "=========================================="
echo ""

# Detect keyboard layout using same method as cal-bootstrap
detect_keyboard_layout() {
    local plist_path="$HOME/Library/Preferences/com.apple.HIToolbox.plist"

    # Check if preferences file exists
    if [ ! -f "$plist_path" ]; then
        echo "❌ Keyboard preferences file not found at: $plist_path"
        return 1
    fi

    echo "✓ Found keyboard preferences file"
    echo ""

    # Try using PlistBuddy to read keyboard layout
    # macOS uses either AppleSelectedInputSources or AppleEnabledInputSources
    local array_key="AppleSelectedInputSources"

    # Check if AppleSelectedInputSources exists, if not try AppleEnabledInputSources
    if ! /usr/libexec/PlistBuddy -c "Print :$array_key" "$plist_path" >/dev/null 2>&1; then
        array_key="AppleEnabledInputSources"
    fi

    local i=0
    local layout=""
    local found_count=0

    echo "Searching for keyboard layouts in $array_key..."
    echo ""

    while true; do
        # Try to read the input source at index i
        local source_kind
        source_kind=$(/usr/libexec/PlistBuddy -c "Print :$array_key:$i:InputSourceKind" "$plist_path" 2>/dev/null)

        # If we can't read this index, we've reached the end
        if [ -z "$source_kind" ]; then
            break
        fi

        echo "[$i] InputSourceKind: $source_kind"

        # Check if this is a keyboard layout source
        # Note: InputSourceKind can be "Keyboard Layout" or "Keyboard Layout Source"
        if [[ "$source_kind" == *"Keyboard Layout"* ]]; then
            # Try to get the layout name (note: key has space, must be quoted)
            local name
            name=$(/usr/libexec/PlistBuddy -c "Print :$array_key:$i:'KeyboardLayout Name'" "$plist_path" 2>/dev/null)

            # Try to get the layout ID
            local id
            id=$(/usr/libexec/PlistBuddy -c "Print :$array_key:$i:'KeyboardLayout ID'" "$plist_path" 2>/dev/null)

            # Show what we found
            if [ -n "$name" ]; then
                echo "    ✓ Layout Name: $name"
            fi
            if [ -n "$id" ]; then
                echo "    ✓ Layout ID: $id"
            fi

            # Use the first keyboard layout we find
            if [ -z "$layout" ]; then
                if [ -n "$name" ]; then
                    layout="$name"
                elif [ -n "$id" ]; then
                    layout="$id"
                fi
            fi

            found_count=$((found_count + 1))
        fi

        i=$((i + 1))

        # Safety limit
        if [ $i -gt 20 ]; then
            echo "    (stopped after 20 entries)"
            break
        fi
    done

    echo ""
    echo "Summary:"
    echo "  Total input sources checked: $i"
    echo "  Keyboard layouts found: $found_count"

    if [ -n "$layout" ]; then
        echo "  Primary keyboard layout: $layout"
        echo ""
        echo "✅ Test PASSED - Keyboard layout detected successfully"
        return 0
    else
        echo "  Primary keyboard layout: (not found)"
        echo ""
        echo "❌ Test FAILED - Could not detect keyboard layout"
        return 1
    fi
}

# Run the test
detect_keyboard_layout

exit $?
