# Bootstrap Guide

> Extracted from [ADR-001](adr/ADR-001-cal-isolation.md) for quick reference.

## Quick Start

```bash
# 1. Install Tart
brew install cirruslabs/cli/tart

# 2. Run bootstrap script (creates VMs, installs tools, sets up SSH keys)
./scripts/cal-bootstrap --init

# 3. After manual login setup, start developing
./scripts/cal-bootstrap --run

# OR: Restart VM and reconnect (quick refresh)
./scripts/cal-bootstrap --restart
```

**Migration Note:** If you have an existing `cal-initialised` VM from before this change, it will not be automatically renamed. You can:
1. Keep it as a backup
2. Delete it manually: `tart delete cal-initialised`
3. Or re-run `--init` to create fresh `cal-init`

## cal-bootstrap Script

The `cal-bootstrap` script automates VM setup and management.

### Commands

```bash
# First-time setup (creates cal-clean, cal-dev, cal-init)
./scripts/cal-bootstrap --init
./scripts/cal-bootstrap -i

# Start cal-dev and SSH in (default if VMs exist)
./scripts/cal-bootstrap --run
./scripts/cal-bootstrap          # Auto-detects mode

# Restart cal-dev and SSH in (quick refresh)
./scripts/cal-bootstrap --restart
./scripts/cal-bootstrap -r

# Stop cal-dev
./scripts/cal-bootstrap --stop
./scripts/cal-bootstrap -s

# Snapshot management
./scripts/cal-bootstrap --snapshot list
./scripts/cal-bootstrap -S list
./scripts/cal-bootstrap -S create before-refactor
./scripts/cal-bootstrap -S restore before-refactor
./scripts/cal-bootstrap -S restore cal-init  # Restore from base
./scripts/cal-bootstrap -S delete before-refactor

# Skip confirmation prompts
./scripts/cal-bootstrap -y -S restore cal-init
```

### Transparent Proxy (Optional)

For corporate environments with restrictive network proxies, CAL supports transparent proxying via sshuttle to enable reliable VM network access.

**When you need proxy:**
- Corporate network blocks direct VM internet access
- HTTP proxy required but VM can't use it
- `curl https://github.com` fails inside the VM

**Prerequisites:**
- SSH server enabled on host Mac (System Settings → Sharing → Remote Login)
- Python installed on host (included with macOS)

**Usage:**
```bash
# Auto mode (default) - detects if proxy is needed
./scripts/cal-bootstrap --init

# Force proxy on (always enable)
./scripts/cal-bootstrap --init --proxy on

# Force proxy off (disable)
./scripts/cal-bootstrap --init --proxy off
```

**Proxy Modes:**
- `auto` (default): Tests github.com connectivity, enables proxy only if needed
- `on`: Always enable transparent proxy
- `off`: Never enable proxy

**In VM commands:**
```bash
proxy-status      # Check proxy status
proxy-start       # Start proxy manually
proxy-stop        # Stop proxy
proxy-restart     # Restart proxy
proxy-log         # View proxy logs
```

**See [Proxy Documentation](proxy.md) for complete setup, troubleshooting, and security details.**

---

### Init Workflow

The `--init` command performs these steps:

1. Creates `cal-clean` from base macOS image (~25GB download)
2. Creates `cal-dev` from `cal-clean`
3. Starts VM and waits for SSH
4. Sets up SSH keys (host→VM, generates if needed)
5. Sets up network access (VM→Host SSH, bootstrap proxy if needed)
6. Copies helper scripts to `~/scripts/` in VM
7. Runs `vm-setup.sh` to install tools (node, gh, tmux, sshuttle, claude, agent, opencode)
8. Switches from bootstrap proxy to sshuttle (if proxy enabled)
9. Opens tmux session running `vm-auth.sh` for agent authentication
10. Creates `cal-init` snapshot

### VMs Created

| VM | Purpose |
|----|---------|
| `cal-clean` | Base macOS image (pristine) |
| `cal-dev` | Development VM (use this) |
| `cal-init` | Snapshot with tools and auth configured |

### Helper Scripts in VM

The init process installs helper scripts in `~/scripts/` (added to PATH):

- **`vm-auth.sh`** - Re-authenticate all agents (gh, opencode, agent, claude)
  - Detects which agents are already authenticated
  - Smart defaults: skip if authenticated, prompt if not
  - Checks network connectivity before authentication
  - Run anytime: `vm-auth.sh`

- **`vm-setup.sh`** - Re-run tool installation and configuration
  - Useful for resetting VM or installing missing tools
  - Run: `~/scripts/vm-setup.sh`

## Manual Setup (Alternative)

If you prefer manual setup:

```bash
# Create VM
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-clean
tart set cal-clean --cpu 4 --memory 8192 --disk-size 80
tart clone cal-clean cal-dev

# Start and connect
tart run cal-dev --no-graphics &
sleep 30 && ssh admin@$(tart ip cal-dev)  # password: admin

# In VM: run setup script
# (copy from host first: scp scripts/vm-setup.sh admin@$(tart ip cal-dev):~/)
chmod +x ~/vm-setup.sh && ./vm-setup.sh
```

## Accessing the VM

**SSH with tmux (Default):**
```bash
./scripts/cal-bootstrap --run   # Starts VM and connects with tmux
# Or manually:
ssh -t admin@$(tart ip cal-dev) "TERM=xterm-256color /opt/homebrew/bin/tmux new-session -A -s cal"
```

tmux is now the default for all connections, providing:
- **Session persistence** - Sessions survive SSH disconnects
- **Multiple panes** - Split screen for side-by-side work
- **Scrollback buffer** - Independent of terminal emulator
- **Better terminal handling** - Enhanced features

**VNC (for GUI access):**
```bash
open vnc://$(tart ip cal-dev)   # password: admin
```

### About tmux

tmux is enabled by default for all SSH connections, providing advanced terminal features:

**Benefits:**
- Sessions survive SSH disconnects (agents keep running)
- Multiple panes for side-by-side work
- Scrollback buffer independent of terminal
- Copy/paste mode for text selection

**Basic Commands:**
```bash
# Session control
Ctrl+b d        # Detach from session (VM keeps running)
Ctrl+b ?        # Show all key bindings

# Panes (split windows)
Ctrl+b |        # Split vertically
Ctrl+b -        # Split horizontally
Ctrl+b arrow    # Navigate between panes
Ctrl+b x        # Close current pane

# Windows (tabs)
Ctrl+b c        # Create new window
Ctrl+b n        # Next window
Ctrl+b p        # Previous window
Ctrl+b 0-9      # Switch to window number

# Copy mode (scrollback)
Ctrl+b [        # Enter copy mode (use arrows to scroll)
q               # Exit copy mode

# Config
Ctrl+b r        # Reload tmux config
```

**Reattaching to Sessions:**
If you disconnect from SSH, your tmux session keeps running:
```bash
./scripts/cal-bootstrap --run   # Reattaches to 'cal' session automatically
# Or manually:
ssh -t admin@$(tart ip cal-dev) "tmux attach -t cal"
```

**Mouse Support:**
The default config enables mouse support - you can:
- Click to select panes
- Scroll with mouse wheel
- Resize panes by dragging borders

## Using the Agents

Once logged in to the VM:

```bash
claude      # Claude Code
agent       # Cursor CLI
opencode    # opencode
gh          # GitHub CLI
```

## Snapshots and Rollback

```bash
# Create snapshot before risky changes
./scripts/cal-bootstrap -S create before-experiment

# Restore if something goes wrong
./scripts/cal-bootstrap -S restore before-experiment

# Restore to freshly-configured state
./scripts/cal-bootstrap -S restore cal-init

# List all VMs and snapshots
./scripts/cal-bootstrap -S list
```

## Aliases (~/.zshrc)

```bash
alias cal='./scripts/cal-bootstrap'
alias cal-start='./scripts/cal-bootstrap --run'
alias cal-restart='./scripts/cal-bootstrap --restart'
alias cal-stop='./scripts/cal-bootstrap --stop'
alias cal-snap='./scripts/cal-bootstrap --snapshot'
```

## Tart Reference

```bash
tart list                    # List VMs
tart ip <vm>                 # Get VM IP
tart get <vm>                # VM info
tart stop <vm> [--force]     # Stop VM
tart delete <vm>             # Delete VM
tart clone <src> <dst>       # Clone/snapshot
```

## Troubleshooting

- **SSH refused**: VM still booting - wait or check System Preferences → Sharing → Remote Login
- **Agent not found**: Restart shell with `exec zsh` or check PATH
- **Disk full**: `rm -rf ~/Library/Caches/* ~/.npm/_cacache`
- **Delete key not working**: Already fixed in vm-setup.sh (TERM=xterm-256color)
- **Up arrow history broken**: Already fixed in vm-setup.sh (bindkey)
- **Cursor Agent login fails**: Fixed via keychain unlock (see [cursor-login-fix.md](cursor-login-fix.md)). Use Screen Sharing to complete initial login: `open vnc://$(tart ip cal-dev)` then run `agent` in Terminal.
- **Agent login fails**: If SSH agent login fails, use Screen Sharing (standard mode, not High Performance) to authenticate: `open vnc://$(tart ip cal-dev)` → authenticate agent → return to terminal
- **Screen Sharing shows lock screen**: Auto-login is configured by vm-setup.sh but requires VM reboot to activate. Stop and restart the VM, then Screen Sharing will show the desktop.
- **opencode not found**: Try `export PATH="$HOME/.opencode/bin:$PATH"` or `export PATH="$HOME/go/bin:$PATH"` - opencode may have installed to a different location. Use Go install if shell script fails.
- **Proxy issues**: See [Proxy Documentation](proxy.md) - requires SSH server enabled on host (admin privileges). Network issues in VM may be resolved by enabling proxy: `./scripts/cal-bootstrap --restart --proxy on`

## Terminal Keybinding Testing

```bash
# Copy and run test script
scp scripts/test-keybindings.sh admin@$(tart ip cal-dev):~/
ssh admin@$(tart ip cal-dev) "chmod +x ~/test-keybindings.sh && ~/test-keybindings.sh"
```

See [Terminal Keybindings Test Plan](terminal-keybindings-test.md) for details.
