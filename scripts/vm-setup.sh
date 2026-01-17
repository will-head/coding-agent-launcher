#!/bin/bash

echo "🚀 CAL VM Setup Script"
echo "======================"
echo ""

# Helper function to check if a brew package is installed
brew_installed() {
    brew list "$1" &>/dev/null
}

# Helper function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Update homebrew
echo "📦 Updating Homebrew..."
if brew update &>/dev/null; then
    echo "  ✓ Homebrew updated"
else
    echo "  ⚠ Homebrew update skipped (may already be running)"
fi

# Install Homebrew dependencies
echo ""
echo "📦 Installing Homebrew packages..."
for pkg in node gh ripgrep fzf go; do
    if brew_installed "$pkg"; then
        echo "  ✓ $pkg already installed"
    else
        echo "  → Installing $pkg..."
        if brew install "$pkg"; then
            echo "  ✓ $pkg installed"
        else
            echo "  ✗ Failed to install $pkg"
        fi
    fi
done

# Install Claude Code
echo ""
echo "🤖 Installing Claude Code..."
if command_exists claude; then
    echo "  ✓ Claude Code already installed"
else
    if npm install -g @anthropic-ai/claude-code; then
        echo "  ✓ Claude Code installed"
    else
        echo "  ✗ Failed to install Claude Code"
    fi
fi

# Install Cursor CLI
echo ""
echo "🖱️  Installing Cursor CLI..."
if command_exists agent; then
    echo "  ✓ Cursor CLI already installed"
else
    if curl -fsSL https://cursor.com/install | bash; then
        echo "  ✓ Cursor CLI installed"
    else
        echo "  ✗ Failed to install Cursor CLI"
    fi
fi

# Install opencode
echo ""
echo "🐹 Installing opencode..."
if command_exists opencode; then
    echo "  ✓ opencode already installed"
else
    if go install github.com/opencode-ai/opencode@latest; then
        echo "  ✓ opencode installed"
    else
        echo "  ✗ Failed to install opencode"
    fi
fi

# Configure shell environment
echo ""
echo "⚙️  Configuring shell environment..."

# Add .local/bin to PATH if not already present (for Cursor CLI)
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo "  ✓ Added .local/bin to PATH"
else
    echo "  ✓ .local/bin already in PATH"
fi

# Add go/bin to PATH if not already present
if ! grep -q 'export PATH="$HOME/go/bin:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.zshrc
    echo "  ✓ Added go/bin to PATH"
else
    echo "  ✓ go/bin already in PATH"
fi

# Fix terminal TERM setting
if ! grep -q 'export TERM=xterm-256color' ~/.zshrc; then
    echo 'export TERM=xterm-256color' >> ~/.zshrc
    echo "  ✓ Fixed TERM setting for delete key"
else
    echo "  ✓ TERM setting already configured"
fi

# Fix up arrow history keybinding
if ! grep -q 'bindkey "\^\[\[A" up-line-or-history' ~/.zshrc; then
    echo 'bindkey "^[[A" up-line-or-history' >> ~/.zshrc
    echo "  ✓ Fixed up arrow history keybinding"
else
    echo "  ✓ History keybinding already configured"
fi

# Source the updated config
if source ~/.zshrc 2>/dev/null; then
    echo "  ✓ Shell configuration reloaded"
else
    echo "  ⚠ Could not reload shell config (restart shell manually)"
fi

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
echo "     - agent --version"
echo "     - opencode version"
echo ""
echo "💡 You may need to restart your shell or run: source ~/.zshrc"
