#!/bin/bash
set -e

echo "🚀 CAL VM Setup Script"
echo "======================"
echo ""

# Update homebrew and install dependencies
echo "📦 Installing dependencies via Homebrew..."
brew update
brew install node gh ripgrep fzf

# Install Claude Code
echo "🤖 Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

# Install Cursor CLI
echo "🖱️  Installing Cursor CLI..."
npm install -g cursor-cli

# Install Go and opencode
echo "🐹 Installing Go and opencode..."
brew install go
go install github.com/opencode-ai/opencode@latest

# Configure shell environment
echo "⚙️  Configuring shell environment..."

# Add go/bin to PATH if not already present
if ! grep -q 'export PATH="$HOME/go/bin:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.zshrc
    echo "  ✓ Added go/bin to PATH"
fi

# Fix terminal TERM setting
if ! grep -q 'export TERM=xterm-256color' ~/.zshrc; then
    echo 'export TERM=xterm-256color' >> ~/.zshrc
    echo "  ✓ Fixed TERM setting for delete key"
fi

# Fix up arrow history keybinding
if ! grep -q 'bindkey "\^\[\[A" up-line-or-history' ~/.zshrc; then
    echo 'bindkey "^[[A" up-line-or-history' >> ~/.zshrc
    echo "  ✓ Fixed up arrow history keybinding"
fi

# Source the updated config
source ~/.zshrc

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Authenticate with GitHub: gh auth login"
echo "  2. Configure opencode:"
echo "     - Run 'opencode init' to set up your agent and API keys"
echo "     - Follow the prompts to select your preferred AI agent"
echo "  3. Verify installations:"
echo "     - claude --version"
echo "     - cursor-cli --version"
echo "     - opencode version"
echo ""
echo "💡 You may need to restart your shell or run: source ~/.zshrc"
