# Bootstrap Guide

> Quick start guide. See [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) for comprehensive operational details.

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

### Git Safety Features

CAL automatically checks for uncommitted changes and unpushed commits before destructive operations to prevent data loss.

**Protected operations:**
- `--init` - Checks cal-dev before deleting and recreating
- `--snapshot restore` - Checks cal-dev before replacing with snapshot
- `--snapshot delete` - Checks VM being deleted (except cal-clean base image)

**What is checked:**
- **Uncommitted changes** - Modified files not yet committed
- **Unpushed commits** - Commits not yet pushed to remote (requires upstream tracking)

**Search locations:**
- `~/workspace`, `~/projects`, `~/repos`, `~/code` (recursive)
- `~` (home directory, depth 2 only)

**Example warning:**
```
⚠️  WARNING: Found git changes that will be lost!

Uncommitted changes in:
  - /Users/admin/code/my-project

These changes will be lost if you continue.

Continue? (y/N)
```

**Behavior:**
- VM is automatically started if needed for the check
- VM is stopped again after check if it wasn't running before
- You can abort the operation (type `n`) to preserve your work
- Git warnings are shown even with `--yes` flag (only confirmation is skipped)

**Note:** Unpushed commit detection requires proper upstream tracking (`git branch -u origin/main`). Repos cloned from GitHub automatically have this set up.

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
7. Runs `vm-setup.sh` to install tools and configure keychain auto-unlock
8. Switches from bootstrap proxy to sshuttle (if proxy enabled)
9. Reboots VM to apply .zshrc configuration
10. Opens login shell - vm-auth.sh runs automatically (first-run detection)
11. Creates `cal-init` snapshot

### VMs Created

| VM | Purpose |
|----|---------|
| `cal-clean` | Base macOS image (pristine) |
| `cal-dev` | Development VM (use this) |
| `cal-init` | Snapshot with tools and auth configured |

### Helper Scripts in VM

The init process installs helper scripts in `~/scripts/` (added to PATH):

- **`vm-auth.sh`** - Re-authenticate all agents (gh, claude, agent, opencode)
  - Automatically runs on first login after init
  - Shows authentication status summary for all services
  - Single prompt: "Do you want to authenticate services?"
  - Smart defaults: [Y/n] if any not authenticated, [y/N] if all authenticated
  - Checks network connectivity before authentication
  - Run anytime: `vm-auth.sh`

- **`vm-setup.sh`** - Re-run tool installation and configuration
  - Useful for resetting VM or installing missing tools
  - Run: `~/scripts/vm-setup.sh`

### Keychain Auto-Unlock

The init process configures automatic keychain unlock on every SSH login to support agent OAuth authentication (especially Cursor Agent which requires keychain access for browser-based login).

**How it works:**
- VM password saved to `~/.cal-vm-config` (mode 600, owner-only access)
- `.zshrc` unlocks keychain on every login using saved password
- Enables Cursor Agent OAuth flows to access browser credentials over SSH

**Security trade-off:**
- Password stored in plaintext (protected by mode 600 permissions)
- Acceptable given VM isolation architecture (no external network access without proxy)
- Alternative would require manual keychain unlock on every SSH session

**First-run automation:**
- Init creates `~/.cal-first-run` flag file
- On first login after init, .zshrc detects flag and runs vm-auth.sh automatically
- Flag is deleted after first run to prevent repeated execution

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

### VM Detection

Agents can detect they're running in a CAL VM using:

```bash
# Check environment variable
echo $CAL_VM              # Outputs: true

# Use helper functions
is-cal-vm && echo "VM"    # Outputs: VM
cal-vm-info               # Display VM metadata
```

See [VM Detection Guide](vm-detection.md) for complete documentation and integration examples.

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
- **Cursor Agent login fails**: Keychain must be unlocked for OAuth. If automatic unlock fails, use Screen Sharing (standard mode, not High Performance): `open vnc://$(tart ip cal-dev)` → manually unlock keychain → authenticate agent
- **Screen Sharing shows lock screen**: Auto-login requires VM reboot to activate. Stop and restart the VM.
- **opencode not found**: Run `exec zsh` or check PATH includes `~/.opencode/bin` or `~/go/bin`
- **First-run automation didn't trigger**: Check if `~/.cal-first-run` flag exists. If missing, run `vm-auth.sh` manually.
- **Proxy issues**: See [Proxy Documentation](proxy.md) - requires SSH server enabled on host

## Terminal Keybinding Testing

```bash
# Copy and run test script
scp scripts/test-keybindings.sh admin@$(tart ip cal-dev):~/
ssh admin@$(tart ip cal-dev) "chmod +x ~/test-keybindings.sh && ~/test-keybindings.sh"
```

See [Terminal Keybindings Test Plan](terminal-keybindings-test.md) for details.
