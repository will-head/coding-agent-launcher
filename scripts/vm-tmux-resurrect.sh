#!/bin/zsh
# vm-tmux-resurrect.sh - Setup tmux session persistence
#
# This script installs and configures tmux-resurrect and tmux-continuum plugins
# to automatically save and restore tmux sessions across VM restarts and snapshots.
#
# Session persistence features:
# - Auto-save every 15 minutes
# - Save on tmux detach (Ctrl+b d)
# - Save on SSH disconnect
# - Save on logout via .zlogout hook
# - Restore pane contents (scrollback up to 5000 lines)
# - Restore sessions on login
# - Disabled during first-run to prevent capturing authentication screen
#
# Usage: Run this script during VM setup (called from vm-setup.sh)

set -e

echo "============================================"
echo "Tmux Session Persistence Setup"
echo "============================================"
echo ""

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. Please install tmux first."
    exit 1
fi

# Create TPM (Tmux Plugin Manager) directory
TPM_DIR="$HOME/.tmux/plugins/tpm"
TPM_CACHE="/Volumes/My Shared Files/cal-cache/git/tpm"

if [[ ! -d "$TPM_DIR" ]]; then
    echo "Installing Tmux Plugin Manager (TPM)..."

    mkdir -p "$HOME/.tmux/plugins"
    RETRY_COUNT=0
    MAX_RETRIES=3
    RETRY_DELAY=5
    TPM_INSTALLED=false

    while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
        # Try to use cached TPM first (from host git cache)
        if [[ -d "$TPM_CACHE" ]]; then
            echo "  Using cached TPM from host git cache..."
            # Update cache before using it
            if git -C "$TPM_CACHE" fetch --all &>/dev/null; then
                echo "  ✓ Cache updated"
            fi
            # Clone from local cache (faster than GitHub, no network needed)
            if git clone "$TPM_CACHE" "$TPM_DIR"; then
                echo "✓ TPM installed from cache"
                TPM_INSTALLED=true
                break
            else
                echo "  ⚠ Cache clone failed, falling back to GitHub..."
            fi
        fi

        # No cache or cache failed, download from GitHub
        echo "  Cloning from GitHub..."
        if git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"; then
            echo "✓ TPM installed from GitHub"

            # Populate cache for future use (if shared volume exists)
            if [[ -d "/Volumes/My Shared Files/cal-cache/git" ]]; then
                echo "  Populating git cache for future bootstraps..."
                # Clone to cache directory (this will appear on host)
                if git clone "$TPM_DIR" "$TPM_CACHE" 2>/dev/null; then
                    echo "  ✓ TPM cached to host (reusable on next bootstrap)"
                else
                    echo "  ⚠ Failed to cache TPM (will re-download on next bootstrap)"
                fi
            fi

            TPM_INSTALLED=true
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
                echo "  ⚠ Clone failed, retrying in ${RETRY_DELAY}s (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
                sleep $RETRY_DELAY
            fi
        fi
    done

    if [[ "$TPM_INSTALLED" == "false" ]]; then
        echo ""
        echo "✗ FATAL: Failed to install TPM after $MAX_RETRIES attempts"
        echo ""
        echo "Network connectivity issue detected."
        echo "Bootstrap cannot continue with incomplete tmux setup."
        echo ""
        echo "Please check your network connection and re-run:"
        echo "  ~/scripts/vm-tmux-resurrect.sh"
        echo ""
        echo "Or re-run full bootstrap:"
        echo "  cal-bootstrap --init"
        echo ""
        exit 1
    fi
else
    echo "✓ TPM already installed"
fi

# Create or update tmux.conf with session persistence settings
TMUX_CONF="$HOME/.tmux.conf"
echo ""
echo "Configuring tmux.conf..."

# Backup existing config if it exists
if [[ -f "$TMUX_CONF" ]]; then
    cp "$TMUX_CONF" "$TMUX_CONF.backup.$(date +%Y%m%d_%H%M%S)"
    echo "  Backed up existing tmux.conf"
fi

# Write tmux configuration
cat > "$TMUX_CONF" <<'EOF'
# CAL Tmux Configuration
# Session persistence with tmux-resurrect and tmux-continuum

# Set PATH to include Homebrew so tmux-resurrect scripts can find tmux command
# This is critical for auto-save and manual save to work correctly
set-environment -g PATH "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Better terminal support
set -g default-terminal "screen-256color"

# Mouse support - enables pane selection, resizing, scrolling
# When enabled: right-click shows tmux menu (Swap, Kill, Respawn, Mark, Rename, etc.)
# When disabled: right-click shows terminal app menu (Copy, Paste, Split, etc.)
# Default: on (provides tmux context menu functionality)
# To disable mouse mode: change 'on' to 'off' and reload config (Ctrl+b R)
set -g mouse on

# Increase scrollback buffer
set -g history-limit 50000

# Don't rename windows automatically
set-option -g allow-rename off

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Enable activity alerts
setw -g monitor-activity on
set -g visual-activity off

# Faster command sequences (no delay)
set -s escape-time 0

# Vi-style key bindings in copy mode
setw -g mode-keys vi

# Easy config reload
bind R source-file ~/.tmux.conf \; display "Config reloaded!"

# Resize pane to 67%
bind r resize-pane -y 67%

# Better splitting with current path
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Pane navigation (Vim-style)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Pane resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Status bar styling
set -g status-style bg=colour235,fg=colour255
set -g status-left-length 30
set -g status-left '#[fg=colour76,bold]CAL-BOOTSTRAP '
set -g status-right '#[fg=colour245]%H:%M '
set -g window-status-current-style bg=colour240,fg=colour255,bold
set -g window-status-style fg=colour245

# Pane border styling
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour76

# Plugin manager
set -g @plugin 'tmux-plugins/tpm'

# Session persistence plugins
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Resurrect settings
set -g @resurrect-capture-pane-contents 'on'

# Continuum settings
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# Save session state on detach (Ctrl+b d)
set-hook -g client-detached 'run-shell "~/.tmux/plugins/tmux-resurrect/scripts/save.sh"'

# Initialize TPM only after first-run completes
# This prevents tmux-resurrect from capturing the authentication screen during initial setup
# The ~/.cal-first-run flag is removed by vm-first-run.sh after first login
run-shell 'if [ ! -f ~/.cal-first-run ]; then ~/.tmux/plugins/tpm/tpm; fi'
EOF

echo "✓ tmux.conf configured"

# Install plugins directly (TPM's auto-install only LOADS plugins, doesn't INSTALL them)
# We need to run install_plugins explicitly during setup
echo ""
echo "Installing tmux plugins..."

# Run install_plugins directly with correct PATH and TMUX_PLUGIN_MANAGER_PATH
# The install_plugins script requires TMUX_PLUGIN_MANAGER_PATH to be set
# Temporarily disable exit-on-error to capture failures gracefully
set +e
INSTALL_OUTPUT=$(TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" PATH="/opt/homebrew/bin:$PATH" "$TPM_DIR/bin/install_plugins" 2>&1)
INSTALL_EXIT=$?
set -e

# Verify both plugins installed by checking directories
if [ -d "$HOME/.tmux/plugins/tmux-resurrect" ] && [ -d "$HOME/.tmux/plugins/tmux-continuum" ]; then
    echo "✓ Plugins installed (tmux-resurrect, tmux-continuum)"
elif [ $INSTALL_EXIT -ne 0 ]; then
    echo ""
    echo "✗ Plugin installation failed with exit code $INSTALL_EXIT"
    echo ""
    echo "Output:"
    echo "$INSTALL_OUTPUT"
    echo ""
    exit 1
else
    echo "⚠ Plugin installation incomplete (install_plugins succeeded but plugins missing):"
    [ ! -d "$HOME/.tmux/plugins/tmux-resurrect" ] && echo "  - tmux-resurrect missing"
    [ ! -d "$HOME/.tmux/plugins/tmux-continuum" ] && echo "  - tmux-continuum missing"
    echo ""
    echo "Output:"
    echo "$INSTALL_OUTPUT"
    echo ""
    exit 1
fi

# Configure .zlogout to save sessions on logout
ZLOGOUT="$HOME/.zlogout"
echo ""
echo "Configuring .zlogout to save sessions..."

# Create .zlogout if it doesn't exist
if [[ ! -f "$ZLOGOUT" ]]; then
    touch "$ZLOGOUT"
fi

# Add tmux session save block if not already present
if ! grep -q "# CAL: Save tmux sessions on logout" "$ZLOGOUT" 2>/dev/null; then
    cat >> "$ZLOGOUT" <<'EOF'

# CAL: Save tmux sessions on logout
if command -v tmux &> /dev/null && tmux list-sessions &> /dev/null; then
    # Save all tmux sessions before logout
    tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh &> /dev/null || true
fi
EOF
    echo "✓ .zlogout configured"
else
    echo "✓ .zlogout already configured"
fi

echo ""
echo "============================================"
echo "Tmux Session Persistence Setup Complete"
echo "============================================"
echo ""
echo "Features configured:"
echo "  • Auto-save every 15 minutes"
echo "  • Save on logout"
echo "  • Restore on login (automatic)"
echo "  • Pane contents saved (50,000 line scrollback)"
echo "  • Plugins will auto-install on first tmux start"
echo ""
echo "Keybindings:"
echo "  • Manual save: Ctrl+b Ctrl+s"
echo "  • Manual restore: Ctrl+b Ctrl+r"
echo "  • Reload config: Ctrl+b R"
echo "  • Resize pane to 67%: Ctrl+b r"
echo ""
echo "Session data: ~/.local/share/tmux/resurrect/"
    echo "TPM cache: /Volumes/My Shared Files/cal-cache/git/tpm/ (persists across snapshots, shared from host)"
echo ""
