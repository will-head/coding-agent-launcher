#!/bin/zsh
#
# Terminal Keybinding Test Script
#
# This script helps capture and identify escape sequences for terminal keys.
# Run this inside the VM to test which keybindings work correctly.
#
# Usage:
#   chmod +x test-keybindings.sh
#   ./test-keybindings.sh

echo "=========================================="
echo "Terminal Keybinding Test Script"
echo "=========================================="
echo ""
echo "This script will help you test terminal keybindings."
echo ""

# Function to test a specific key
test_key() {
    local key_name="$1"
    echo -n "Test $key_name (press the key, then Enter): "
    read -r response
    if [ -n "$response" ]; then
        echo "  ✓ Key captured input: $response"
    else
        echo "  ⚠ No input captured (may be working at terminal level)"
    fi
    echo ""
}

# Function to capture raw escape sequences
capture_raw() {
    echo "=========================================="
    echo "Raw Escape Sequence Capture Mode"
    echo "=========================================="
    echo ""
    echo "Press keys to see their escape sequences."
    echo "Press Ctrl+C to exit this mode."
    echo ""
    
    while IFS= read -rsn1 char; do
        if [ -z "$char" ]; then
            printf "Key pressed: <Enter> (0x0a)\n"
        else
            printf "Key pressed: %q (hex: " "$char"
            printf "%s" "$char" | xxd -p
            printf ")\n"
        fi
    done
}

# Main menu
while true; do
    echo "=========================================="
    echo "Test Options:"
    echo "=========================================="
    echo "1. Test specific keybindings (guided)"
    echo "2. Capture raw escape sequences (advanced)"
    echo "3. Show current ZSH bindings"
    echo "4. Show current TERM setting"
    echo "5. Test arrow keys in command history"
    echo "6. Exit"
    echo ""
    echo -n "Select option (1-6): "
    read -r option
    echo ""
    
    case $option in
        1)
            echo "=========================================="
            echo "Guided Keybinding Test"
            echo "=========================================="
            echo ""
            echo "Testing basic navigation..."
            test_key "Home"
            test_key "End"
            test_key "Page Up"
            test_key "Page Down"
            
            echo "Testing editing keys..."
            test_key "Delete"
            test_key "Backspace"
            
            echo "Note: Ctrl+Key combinations work at terminal level"
            echo "      and won't be captured by 'read' command."
            echo ""
            read -p "Press Enter to continue..."
            ;;
        2)
            capture_raw
            echo ""
            ;;
        3)
            echo "=========================================="
            echo "Current ZSH Key Bindings"
            echo "=========================================="
            echo ""
            bindkey | head -n 20
            echo ""
            echo "... (showing first 20 bindings)"
            echo "Run 'bindkey' manually to see all bindings"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        4)
            echo "=========================================="
            echo "Terminal Settings"
            echo "=========================================="
            echo ""
            echo "TERM: $TERM"
            echo ""
            echo "Terminal capabilities:"
            infocmp | head -n 5
            echo ""
            read -p "Press Enter to continue..."
            ;;
        5)
            echo "=========================================="
            echo "Arrow Key History Test"
            echo "=========================================="
            echo ""
            echo "Adding test commands to history..."
            echo "test command 1" >> ~/.zsh_history
            echo "test command 2" >> ~/.zsh_history
            echo "test command 3" >> ~/.zsh_history
            echo ""
            echo "Now try pressing Up Arrow and Down Arrow"
            echo "You should see previous commands"
            echo ""
            echo "Exit this shell with 'exit' when done testing"
            zsh
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select 1-6."
            echo ""
            ;;
    esac
done
