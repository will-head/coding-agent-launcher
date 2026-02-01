#!/bin/zsh

echo "🎨 Claude Statusline Setup"
echo "==========================="
echo ""

# Helper function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check for required dependencies
if ! command_exists jq; then
    echo "❌ Error: jq is required but not installed"
    echo "   Install with: brew install jq"
    exit 1
fi

# Define paths
SCRIPT_SOURCE="$(cd "$(dirname "$0")" && pwd)/statusline-command.sh"
SCRIPT_TARGET="$HOME/scripts/statusline-command.sh"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

# Step 1: Install statusline-command.sh to VM
echo "📦 Installing statusline-command.sh..."

# Create target directory if it doesn't exist
if [ ! -d "$HOME/scripts" ]; then
    echo "  Creating ~/scripts directory..."
    mkdir -p "$HOME/scripts"
fi

# Check if source file exists
if [ ! -f "$SCRIPT_SOURCE" ]; then
    echo "❌ Error: Source script not found at $SCRIPT_SOURCE"
    echo "   This script must be run from the scripts/ directory or"
    echo "   statusline-command.sh must be in the same directory."
    exit 1
fi

# Copy script to target location
cp "$SCRIPT_SOURCE" "$SCRIPT_TARGET"
chmod +x "$SCRIPT_TARGET"
echo "  ✓ Installed to $SCRIPT_TARGET"
echo ""

# Step 2: Configure Claude settings.json
echo "⚙️  Configuring Claude settings..."

# Check if Claude directory exists
if [ ! -d "$HOME/.claude" ]; then
    echo "❌ Error: ~/.claude directory not found"
    echo "   Please run Claude Code at least once to initialize settings."
    exit 1
fi

# Backup existing settings.json if it exists
if [ -f "$CLAUDE_SETTINGS" ]; then
    BACKUP_FILE="${CLAUDE_SETTINGS}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$CLAUDE_SETTINGS" "$BACKUP_FILE"
    echo "  ✓ Backed up existing settings to: $BACKUP_FILE"
else
    # Create empty JSON object if settings.json doesn't exist
    echo "{}" > "$CLAUDE_SETTINGS"
    echo "  ✓ Created new settings.json"
fi

# Define the statusLine configuration (use full path, not ~)
STATUSLINE_CONFIG=$(cat <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "$HOME/scripts/statusline-command.sh orange"
  }
}
EOF
)

# Merge statusLine into existing settings.json
# This preserves all existing fields and only adds/updates statusLine
TEMP_FILE="${CLAUDE_SETTINGS}.tmp"
jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" <(echo "$STATUSLINE_CONFIG") > "$TEMP_FILE"

# Validate the merged JSON
if jq empty "$TEMP_FILE" 2>/dev/null; then
    mv "$TEMP_FILE" "$CLAUDE_SETTINGS"
    echo "  ✓ Updated $CLAUDE_SETTINGS with statusLine configuration"
else
    echo "❌ Error: Generated invalid JSON, keeping original settings"
    rm -f "$TEMP_FILE"
    exit 1
fi

echo ""
echo "✅ Statusline setup complete!"
echo ""
echo "The statusline will appear in your Claude Code session showing:"
echo "  🤖 Model name"
echo "  🧠 Context usage percentage (with color warnings at 50% and 80%)"
echo "  ⏱️  Session duration"
echo "  💰 Total cost"
echo ""
echo "Note: The statusline script is located at:"
echo "      $SCRIPT_TARGET"
echo ""
echo "To change the color scheme, edit the 'command' field in $CLAUDE_SETTINGS"
echo "Available colors: blue, green, yellow, orange (default), magenta, cyan, red, white"
echo ""
