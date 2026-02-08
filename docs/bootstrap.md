# Bootstrap Guide

> Quick start guide. See [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) for comprehensive operational details.

## Quick Start

```bash
# 1. Install Tart (optional - calf-bootstrap will auto-install if not present)
brew install cirruslabs/cli/tart

# 2. Run bootstrap script (creates VMs, installs tools, sets up SSH keys)
./scripts/calf-bootstrap --init

# 3. After manual login setup, start developing
./scripts/calf-bootstrap --run

# OR: Restart VM and reconnect (quick refresh)
./scripts/calf-bootstrap --restart

# OR: Launch with GUI console (VNC with bidirectional clipboard)
./scripts/calf-bootstrap --gui
```

**Note:** calf-bootstrap will automatically install Tart via Homebrew if it's not already installed.

**Migration Note:** If you have an existing `calf-initialised` VM from before this change, it will not be automatically renamed. You can:
1. Keep it as a backup
2. Delete it manually: `tart delete calf-initialised`
3. Or re-run `--init` to create fresh `calf-init`

## calf-bootstrap Script

The `calf-bootstrap` script automates VM setup and management.

### Commands

```bash
# First-time setup (creates calf-clean, calf-dev, calf-init)
./scripts/calf-bootstrap --init
./scripts/calf-bootstrap -i

# Create fully isolated VM with no host filesystem mounts (PERMANENT setting)
./scripts/calf-bootstrap --init --no-mount

# Start calf-dev and SSH in (default if VMs exist)
./scripts/calf-bootstrap --run
./scripts/calf-bootstrap          # Auto-detects mode

# Restart calf-dev and SSH in (quick refresh)
./scripts/calf-bootstrap --restart
./scripts/calf-bootstrap -r

# Launch with GUI console (VNC with clipboard support)
./scripts/calf-bootstrap --gui
./scripts/calf-bootstrap -g

# Stop calf-dev
./scripts/calf-bootstrap --stop

# Show VM status and connection info
./scripts/calf-bootstrap --status
./scripts/calf-bootstrap -s

# Snapshot management
./scripts/calf-bootstrap --snapshot list
./scripts/calf-bootstrap -S list
./scripts/calf-bootstrap -S create before-refactor
./scripts/calf-bootstrap -S restore before-refactor
./scripts/calf-bootstrap -S restore calf-init  # Restore from base
./scripts/calf-bootstrap -S delete before-refactor

# Skip confirmation prompts
./scripts/calf-bootstrap -y -S restore calf-init

# Force script deployment (skip optimization, for troubleshooting)
./scripts/calf-bootstrap --run --clean
./scripts/calf-bootstrap --restart --clean
```

### No-Mount Mode (Isolated VMs)

The `--no-mount` flag creates fully isolated VMs with zero host filesystem access for maximum security.

**Use cases:**
- Running untrusted code in complete isolation
- High-security development environments
- Testing scenarios requiring no host interaction

**Behavior:**
- No tart-cache mount (nested VMs download images independently)
- No calf-cache mount (packages downloaded fresh in VM)
- VM creates local `~/.calf-cache` directories inside the VM
- Bootstrap proxy still works (network-only, no filesystem access)

**Important:**
- **PERMANENT setting** - Cannot be changed after VM creation
- Must destroy and recreate VMs to change modes
- Confirmation prompt shown during `--init` (can skip with `--yes`)
- Status command shows current mode: `./scripts/calf-bootstrap --status`

**Example:**
```bash
# Create isolated VM (with confirmation)
./scripts/calf-bootstrap --init --no-mount

# Create isolated VM (skip confirmation)
./scripts/calf-bootstrap --init --no-mount --yes

# Check current mode
./scripts/calf-bootstrap --status
# Output shows: "Mount mode: Isolated (no host mounts)"
```

### No-Network Mode (Network Isolation)

The `--no-network` flag isolates the VM from local network IPs while still allowing internet access via NAT.
It uses Softnet for isolation.

**Behavior:**
- Blocks direct access to local network IPs (192.168.x.x, 10.x.x.x, etc.)
- Allows internet access via NAT
- Blocks SMB/NetBIOS traffic to the host gateway IP (TCP 445/139, UDP 137/138)

**Requirements:**
- Softnet installed and SUID set
- Patched Tart and Softnet binaries installed in `~/.calf-tools/bin`
  - `calf-bootstrap` will use this path automatically for `--no-network`
  - Override with `CALF_TOOLS_BIN=/path/to/bin`

**SUID setup:**
```bash
sudo chown root:wheel ~/.calf-tools/bin/softnet
sudo chmod u+s ~/.calf-tools/bin/softnet
```

**Example:**
```bash
# Create isolated VM (with confirmation)
./scripts/calf-bootstrap --init --no-network

# Create isolated VM (skip confirmation)
./scripts/calf-bootstrap --init --no-network --yes
```

### Safe Mode (Maximum Isolation)

The `--safe-mode` flag enables both `--no-mount` and `--no-network`.

```bash
./scripts/calf-bootstrap --init --safe-mode --yes
```

### Git Safety Features

CAL automatically checks for uncommitted changes and unpushed commits before destructive operations to prevent data loss.

**Protected operations:**
- `--init` - Checks calf-dev before deleting and recreating
- `--snapshot restore` - Checks calf-dev before replacing (if calf-dev exists); creates from snapshot if calf-dev doesn't exist
- `--snapshot delete` - Checks VM being deleted (except calf-clean base image)

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
./scripts/calf-bootstrap --init

# Force proxy on (always enable)
./scripts/calf-bootstrap --init --proxy on

# Force proxy off (disable)
./scripts/calf-bootstrap --init --proxy off
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

### Nested VM Support (Tart Cache Sharing)

CAL automatically shares the host's Tart cache directory with calf-dev, enabling nested virtualization without re-downloading base images.

**What is shared:**
- Host's `~/.tart/cache/` directory (contains OCI images like macos-sequoia-base:latest)
- Shared as read-only to prevent VM from corrupting host cache
- Automatically mounted at `/Volumes/My Shared Files/tart-cache`
- Symlinked to `~/.tart/cache` inside the VM

**Benefits:**
- Saves 30-47GB download when using nested VMs
- Enables running `tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest` inside calf-dev instantly
- Supports nested VM development and testing workflows

**Tools installed in calf-dev:**
- Tart (for creating nested VMs)
- Ghostty (modern terminal emulator)
- jq (JSON processing)

**Verify cache sharing:**
```bash
# Inside calf-dev VM
ls -la ~/.tart/cache/              # Should show symlink
tart list --format json | jq -r '.[] | select(.Source == "OCI") | .Name'
```

**Note:** Tart cache sharing is automatic - no configuration needed.

---

### Init Workflow

The `--init` command performs these steps:

1. Creates `calf-clean` from base macOS image (~25GB download)
2. Creates `calf-dev` from `calf-clean`
3. Starts VM and waits for SSH
4. Sets up SSH keys (host→VM, generates if needed)
5. Sets up network access (VM→Host SSH, bootstrap proxy if needed)
6. Copies helper scripts to `~/scripts/` in VM
7. Runs `vm-setup.sh` to install tools and set up keychain auto-unlock
8. Switches from bootstrap proxy to sshuttle (if proxy enabled)
9. Reboots VM to apply .zshrc configuration
10. Opens login shell - vm-auth.sh runs automatically (first-run detection)
11. Creates `calf-init` snapshot

### VMs Created

| VM | Purpose |
|----|---------|
| `calf-clean` | Base macOS image (pristine) |
| `calf-dev` | Development VM (use this) |
| `calf-init` | Snapshot with tools and auth configured |

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
- VM password saved to `~/.calf-vm-config` (mode 600, owner-only access)
- `.zshrc` unlocks keychain on every login using saved password
- Enables Cursor Agent OAuth flows to access browser credentials over SSH

**Security trade-off:**
- Password stored in plaintext (protected by mode 600 permissions)
- Acceptable given VM isolation architecture (no external network access without proxy)
- Alternative would require manual keychain unlock on every SSH session

**First-run automation:**
- Init creates `~/.calf-first-run` flag file
- On first login after init, .zshrc detects flag and runs vm-auth.sh automatically
- Flag is deleted after first run to prevent repeated execution

## Manual Setup (Alternative)

If you prefer manual setup:

```bash
# Create VM
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest calf-clean
tart set calf-clean --cpu 4 --memory 8192 --disk-size 80
tart clone calf-clean calf-dev

# Start and connect
tart run calf-dev --no-graphics &
sleep 30 && ssh admin@$(tart ip calf-dev)  # password: admin

# In VM: run setup script
# (copy from host first: scp scripts/vm-setup.sh admin@$(tart ip calf-dev):~/)
chmod +x ~/vm-setup.sh && ./vm-setup.sh
```

## Accessing the VM

**GUI Console with Clipboard (Recommended for clipboard operations):**
```bash
./scripts/calf-bootstrap --gui
```

This launches calf-dev with VNC experimental mode, providing:
- **Full macOS desktop** - Native GUI access with mouse and keyboard
- **Bidirectional clipboard** - Copy/paste works both ways reliably
- **No disconnect issues** - Paste operations don't cause crashes
- **Terminal remains free** - VM runs in background, VNC window opens automatically
- **Simple reconnect** - Just run `./scripts/calf-bootstrap --gui` again

**Why experimental mode?**
- Standard VNC (`--vnc`) has clipboard issues: Host→VM paste causes disconnect
- Experimental mode (`--vnc-experimental`) uses Virtualization.Framework's VNC server
- Provides reliable clipboard support without crashes
- Trade-off: May have occasional display quirks, but clipboard works correctly

**When to use GUI console:**
- Copying/pasting text between host and VM
- Agent authentication requiring browser (especially Cursor Agent OAuth)
- Manual keychain unlock
- GUI-based configuration or debugging
- File browsing with Finder

**SSH with tmux (Recommended for development):**
```bash
./scripts/calf-bootstrap --run   # Starts VM and connects with tmux
# Or manually:
ssh -t admin@$(tart ip calf-dev) "TERM=xterm-256color /opt/homebrew/bin/tmux new-session -A -s calf"
```

tmux is the default for SSH connections, providing:
- **Session persistence** - Sessions survive SSH disconnects
- **Multiple panes** - Split screen for side-by-side work
- **Scrollback buffer** - Independent of terminal emulator
- **Better terminal handling** - Enhanced features
- **Better performance** - Faster for command-line work

**When to use SSH:**
- Development work (primary method)
- Running terminal-based tools (agents, git, etc.)
- Better performance for command-line tasks
- tmux session persistence

**Screen Sharing (Legacy VNC - use --gui instead):**
```bash
open vnc://$(tart ip calf-dev)   # password: admin
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
./scripts/calf-bootstrap --run   # Reattaches to 'calf' session automatically
# Or manually:
ssh -t admin@$(tart ip calf-dev) "tmux attach -t calf"
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
ccs         # CCS (Claude Code Switch)
agent       # Cursor CLI
opencode    # opencode (works correctly in VM - see troubleshooting if issues)
codex       # Codex CLI (OpenAI)
gh          # GitHub CLI
```

### VM Detection

Agents can detect they're running in a CAL VM using:

```bash
# Check environment variable
echo $CALF_VM              # Outputs: true

# Use helper functions
is-calf-vm && echo "VM"    # Outputs: VM
calf-vm-info               # Display VM metadata
```

See [VM Detection Guide](vm-detection.md) for complete documentation and integration examples.

## Snapshots and Rollback

```bash
# Create snapshot before risky changes
./scripts/calf-bootstrap -S create before-experiment

# Restore if something goes wrong
./scripts/calf-bootstrap -S restore before-experiment

# Restore to freshly-configured state
./scripts/calf-bootstrap -S restore calf-init

# Restore even if calf-dev was deleted
./scripts/calf-bootstrap -S restore calf-init  # Creates calf-dev from snapshot

# List all VMs and snapshots
./scripts/calf-bootstrap -S list
```

**Note:** `--snapshot restore` can create `calf-dev` from a snapshot even if `calf-dev` doesn't exist. If `calf-dev` exists, it checks for uncommitted/unpushed git changes before replacing it.

## Aliases (~/.zshrc)

```bash
alias calf='./scripts/calf-bootstrap'
alias calf-start='./scripts/calf-bootstrap --run'
alias calf-restart='./scripts/calf-bootstrap --restart'
alias calf-gui='./scripts/calf-bootstrap --gui'
alias calf-stop='./scripts/calf-bootstrap --stop'
alias calf-snap='./scripts/calf-bootstrap --snapshot'
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

## Screen Sharing (Legacy)

> **Recommendation:** Use `./scripts/calf-bootstrap --gui` instead for reliable clipboard support.
>
> This section documents Screen Sharing for reference, but the --gui option provides a better experience with bidirectional clipboard and no disconnect issues.

macOS Screen Sharing provides GUI access to Tart VMs. **Always use Standard mode** - High Performance mode is incompatible with Tart VMs.

### Quick Access

```bash
# Connect to calf-dev via Screen Sharing
open vnc://$(tart ip calf-dev)   # password: admin
```

### Performance Modes

macOS Sonoma offers two Screen Sharing modes when connecting. **Only Standard mode works with Tart VMs.**

#### ✅ Standard Mode (Recommended)

**Use this mode** - it's the only mode that works reliably with Tart VMs.

**Features:**
- ✅ Works with all Tart VMs
- ⚠️ Partial clipboard sharing (VM to Host only - see warning below)
- ✅ Reliable connection
- ✅ Sufficient performance for GUI tasks

**Clipboard Sharing:**

The VM setup now includes [tart-guest-agent](https://github.com/cirruslabs/tart-guest-agent), which enables one-way clipboard sharing from VM to Host:

1. Connect via `open vnc://$(tart ip calf-dev)`
2. In Screen Sharing window: **Edit → Use Shared Clipboard** (enable checkmark)
3. Clipboard sharing works one-way only:
   - ✅ Copy from VM → Paste in Host (works correctly)
   - ❌ Copy from Host → Paste in VM (causes Screen Sharing disconnect - DO NOT USE)

**⚠️ CRITICAL WARNING - Host to VM Paste:**

**DO NOT paste from Host to VM** - this will cause Screen Sharing to disconnect (and may crash the VM in some cases). Only copy from VM to Host is supported.

**Workaround for transferring text to VM:**
- Type text directly in VM
- Use SSH to echo text into files: `ssh admin@$(tart ip calf-dev) 'echo "text" > file.txt'`
- Mount shared folders (if configured)
- Use git to sync files

**Technical Details:**
- The guest agent implements the SPICE vdagent protocol for clipboard operations
- Runs automatically as a launchd service (no manual start required)
- Pre-installed during VM setup via `vm-setup.sh`
- Verify status: `launchctl list | grep tart-guest-agent`

#### ❌ High Performance Mode (Incompatible)

**Do not use** - this mode is incompatible with Tart VMs and will show a black/locked screen.

**Symptoms:**
- Black screen upon connection
- VM appears locked/unresponsive
- No desktop or login window visible

**Why it doesn't work:**
- Tart uses Apple's Virtualization.framework which doesn't support High Performance mode
- When a Tart VM is created with "high performance" profile selected, VNC/Screen Sharing connections are blocked entirely
- This is a limitation of the Virtualization.framework, not a Tart bug

**Technical Details:**
- High Performance mode requires both Macs to be Apple Silicon running macOS Sonoma 14+
- Communicates over UDP ports 5900, 5901, 5902
- Provides 4K display support, high frame rates (30-60 fps), and advanced media features
- However, the Virtualization.framework's performance profile implementation blocks VNC when "high performance" is selected

**References:**
- [Tart GitHub Issue #818](https://github.com/cirruslabs/tart/issues/818) - Documents High Performance incompatibility
- [Apple Support: High Performance Screen Sharing](https://support.apple.com/guide/remote-desktop/use-high-performance-screen-sharing-apdf8e09f5a9/mac)

### Clipboard Support History

**Early Limitation (Resolved):**
- Early versions of Tart had a clipboard bug where copy/paste would cause Screen Sharing to disconnect
- Fixed in [Tart PR #154](https://github.com/cirruslabs/tart/pull/154) - moved VNC to public APIs with clipboard support

**Partial Clipboard Support (Current):**
- One-way clipboard sharing (VM → Host only) via [tart-guest-agent](https://github.com/cirruslabs/tart-guest-agent)
- Implements SPICE vdagent protocol for clipboard operations
- Host → VM paste causes VM crash (known limitation)
- Pre-installed during CAL VM setup

**References:**
- [Tart GitHub Issue #152](https://github.com/cirruslabs/tart/issues/152) - Original clipboard disconnect issue
- [Tart GitHub Issue #14](https://github.com/cirruslabs/tart/issues/14) - Host to VM clipboard support request
- [Tart PR #1046](https://github.com/cirruslabs/tart/pull/1046) - Clipboard sharing implementation
- [Tart Guest Agent Blog Post](https://tart.run/blog/2025/06/01/bridging-the-gaps-with-the-tart-guest-agent/) - Feature announcement

### Use Cases

**Recommended access methods (in order of preference):**

1. **SSH with tmux** (`./scripts/calf-bootstrap --run`) - Primary development method
   - Terminal-based work
   - Running agents, git, development tools
   - Best performance for command-line tasks
   - Session persistence

2. **GUI Console** (`./scripts/calf-bootstrap --gui`) - Clipboard and GUI tasks
   - Copying/pasting between host and VM
   - Agent authentication (browser-based OAuth)
   - Manual keychain unlock
   - GUI configuration and debugging
   - File browsing with Finder
   - **Use this instead of Screen Sharing for clipboard operations**

3. **Screen Sharing** (`open vnc://...`) - Legacy method
   - Only if --gui doesn't work
   - **Note:** One-way clipboard only (VM→Host)
   - Host→VM paste causes disconnects
   - Not recommended for regular use

## Troubleshooting

- **SSH refused**: VM still booting - wait or check System Preferences → Sharing → Remote Login
- **Agent not found**: Restart shell with `exec zsh` or check PATH
- **Disk full**: `rm -rf ~/Library/Caches/* ~/.npm/_cacache`
- **Cursor Agent login fails**: Keychain must be unlocked for OAuth. If automatic unlock fails, use Screen Sharing (Standard mode): `open vnc://$(tart ip calf-dev)` → manually unlock keychain → authenticate agent
- **Screen Sharing shows lock screen**: Auto-login requires VM reboot to activate. Stop and restart the VM.
- **Screen Sharing shows black screen/locked VM**: You selected High Performance mode - disconnect and reconnect using **Standard mode** instead. This mode is incompatible with Tart VMs.
- **Copy/paste not working**: Use `./scripts/calf-bootstrap --gui` for reliable bidirectional clipboard support. The --gui option uses VNC experimental mode which solves clipboard issues. Screen Sharing (standard VNC) only supports VM→Host copying and Host→VM pasting causes disconnects.
- **Screen Sharing disconnects when pasting from Host**: This is a known limitation of standard VNC. Use `./scripts/calf-bootstrap --gui` instead for bidirectional clipboard support without disconnects.
- **Claude Code OAuth URL won't paste correctly**: Do not mouse-select the URL - line breaks will be included. Instead, press `c` when prompted to copy the auth URL to your clipboard. Alternatively, use `./scripts/calf-bootstrap --gui` to access the VM with full clipboard support, allowing you to copy/paste the URL reliably.
- **opencode not found**: Run `exec zsh` or check PATH includes `~/.opencode/bin` or `~/go/bin`
- **opencode run hangs**: This occurs when TERM is explicitly set in the command environment. Use `opencode run` normally (TERM inherited from environment) - it works correctly. See [Opencode VM Summary](opencode-vm-summary.md) for details.
- **First-run automation didn't trigger**: Check if `~/.calf-first-run` flag exists. If missing, run `vm-auth.sh` manually.
- **Proxy issues**: See [Proxy Documentation](proxy.md) - requires SSH server enabled on host

## Terminal Keybinding Testing

```bash
# Copy and run test script
scp scripts/test-keybindings.sh admin@$(tart ip calf-dev):~/
ssh admin@$(tart ip calf-dev) "chmod +x ~/test-keybindings.sh && ~/test-keybindings.sh"
```

See [Terminal Keybindings Test Plan](terminal-keybindings-test.md) for details.
