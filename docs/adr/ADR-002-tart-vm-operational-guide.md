# ADR-002: Tart VM Operational Guide

## Operational Learnings for CAL VM Management

**ADR:** 002
**Status:** Accepted
**Created:** 2026-01-21
**Updated:** 2026-01-31
**Purpose:** Comprehensive operational reference for managing Tart macOS VMs in CAL, capturing all Phase 0 learnings

---

## Context

CAL (Coding Agent Loader) uses Tart to run macOS VMs that provide isolated environments for AI coding agents. Through the development of `cal-bootstrap`, `vm-setup.sh`, `vm-auth.sh`, and supporting scripts, we discovered numerous operational details, edge cases, and best practices essential for maintaining and extending the system.

This ADR serves as the definitive operational reference for Phase 1 (CLI Foundation) and beyond.

---

## Decision Summary

We established a three-VM architecture with automated setup, transparent networking, and safety checks. Key decisions:

1. **Three-tier VM structure**: cal-clean -> cal-dev -> cal-init
2. **SSH-first access** with tmux for session persistence, GUI via VNC experimental
3. **Transparent proxy** using sshuttle for corporate network compatibility
4. **Automatic git safety checks** before destructive operations
5. **VM detection mechanism** for agent environment awareness
6. **Keychain auto-unlock** for SSH-based agent authentication
7. **First-run and logout automation** for seamless VM lifecycle
8. **Tart cache sharing** for nested VM support
9. **TERM wrapper** for cross-terminal compatibility

---

## VM Architecture and Naming

### VM Hierarchy

```
ghcr.io/cirruslabs/macos-sequoia-base:latest
            |
            v
      +-------------+
      |  cal-clean  |  <- Pristine base image (never modified after creation)
      +-------------+
            |
            v
      +-------------+
      |   cal-dev   |  <- Working development VM (daily use)
      +-------------+
            |
            v
      +-------------+
      |  cal-init   |  <- Snapshot after initial setup (tools + auth configured)
      +-------------+
            |
            v
      +-------------+
      |  snapshots  |  <- User-created snapshots (before-refactor, etc.)
      +-------------+
```

### Purpose of Each VM

| VM | Purpose | When Modified |
|----|---------|---------------|
| `cal-clean` | Pristine base image for recovery | Never (only created once) |
| `cal-dev` | Active development VM | Continuously during work |
| `cal-init` | Tools installed, agents authenticated | Only during `--init` |
| User snapshots | Point-in-time backups | When user creates them |

### Why This Structure

1. **cal-clean preserves the base** - If cal-dev gets corrupted beyond repair, restore from cal-clean
2. **cal-init saves setup time** - Don't re-run auth flows; restore to configured state
3. **Snapshots are cheap** - Tart uses copy-on-write; only changes consume disk space

---

## Setup Procedure

### Prerequisites (Host Machine)

```bash
# Required (auto-installed by cal-bootstrap if missing)
brew install cirruslabs/cli/tart
brew install jq  # For snapshot list with sizes

# Optional (installed automatically if missing)
brew install esolitos/ipa/sshpass  # Or: hudochenkov/sshpass/sshpass
```

**Note:** `cal-bootstrap --init` automatically installs Tart via Homebrew if not found in PATH. It checks for `brew` availability and provides clear error messages if Homebrew itself is missing.

### The Init Workflow

The `--init` command performs these steps in order:

```
Step 1: Check for existing VMs
        +- If cal-dev or cal-init exist, warn user
        +- Start cal-dev to check for uncommitted/unpushed git changes
        +- Get confirmation (unless --yes)
        +- Delete existing VMs

Step 2: Create cal-clean from base image
        +- tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-clean
        +- tart set cal-clean --cpu 4 --memory 8192 --disk-size 80

Step 3: Create cal-dev from cal-clean
        +- tart clone cal-clean cal-dev

Step 4: Start cal-dev in background
        +- tart run --no-graphics --dir=tart-cache:~/.tart/cache:ro cal-dev &
        +- Wait for IP (poll tart ip cal-dev)
        +- Wait for SSH (test port 22 connectivity)

Step 5: Setup SSH keys (host->VM)
        +- Generate ~/.ssh/id_ed25519 if missing
        +- Copy public key to VM's ~/.ssh/authorized_keys

Step 6: Setup network access
        +- Test github.com connectivity
        +- If blocked: setup VM->Host SSH keys
        +- Start bootstrap SOCKS proxy (SSH -D 1080)

Step 7: Copy helper scripts to VM
        +- scp vm-setup.sh vm-auth.sh vm-first-run.sh tmux-wrapper.sh -> ~/scripts/
        +- Add ~/scripts to PATH in .zshrc

Step 8: Run vm-setup.sh
        +- Install: node, gh, tmux, sshuttle, jq
        +- Install: tart, tart-guest-agent, ghostty (for nested VMs/clipboard)
        +- Install agents: claude, agent (Cursor), opencode, ccs, codex
        +- Install Go tools: golangci-lint, staticcheck, goimports, dlv, mockgen, air
        +- Configure: auto-login, keychain, terminal, VM detection
        +- Configure: logout git check, proxy functions
        +- Set ~/.cal-auth-needed flag

Step 9: Setup Tart cache sharing
        +- Create symlink: ~/.tart/cache -> /Volumes/My Shared Files/tart-cache

Step 10: Switch to sshuttle (if proxy needed)
         +- Stop bootstrap SOCKS proxy
         +- Start sshuttle transparent proxy

Step 11: Reboot VM to apply .zshrc configuration

Step 12: SSH into VM
         +- .zshrc detects ~/.cal-auth-needed flag
         +- Runs vm-auth.sh for interactive authentication
         +- User completes OAuth flows and repository cloning

Step 13: Create cal-init snapshot
         +- Stop cal-dev
         +- tart clone cal-dev cal-init
```

---

## Access Methods

### SSH with tmux (Primary Development Method)

```bash
./scripts/cal-bootstrap --run   # Starts VM and connects with tmux
```

Uses tmux-wrapper.sh to handle TERM compatibility:

```bash
ssh -t admin@<vm_ip> "~/scripts/tmux-wrapper.sh new-session -A -s cal"
```

**Benefits:**
- Sessions survive SSH disconnects
- Agents keep running if connection drops
- Scrollback buffer independent of terminal
- Multiple panes for side-by-side work
- Best performance for command-line tasks

### GUI Console with VNC Experimental (Clipboard Operations)

```bash
./scripts/cal-bootstrap --gui    # or -g
```

Uses `tart run --vnc-experimental` which provides:
- **Bidirectional clipboard** - Copy/paste works both ways reliably
- **No disconnect issues** - Paste operations don't cause crashes
- **Full macOS desktop** - Native GUI access with mouse and keyboard
- **Terminal remains free** - VM runs in background, VNC window opens automatically

**Why experimental mode:** Standard `--vnc` mode uses macOS Screen Sharing which has a Host->VM clipboard disconnect issue. Experimental mode uses Virtualization.Framework's built-in VNC server with reliable clipboard support. Trade-off: may have occasional display quirks.

**When to use GUI console:**
- Copying/pasting text between host and VM
- Agent authentication requiring browser (especially Cursor Agent OAuth)
- Manual keychain unlock
- GUI-based configuration or debugging

### Screen Sharing (Legacy - Not Recommended)

```bash
open vnc://$(tart ip cal-dev)   # password: admin
```

**Limitations:**
- One-way clipboard only (VM -> Host) via tart-guest-agent
- Host -> VM paste causes Screen Sharing disconnect
- High Performance mode incompatible with Tart VMs (black screen)
- Use `--gui` instead for clipboard operations

---

## TERM Environment Variable Handling

### The Problem

Two conflicting requirements for TERM handling:
1. **tmux requires a known TERM** - Ghostty sends `xterm-ghostty` which fails: "missing or unsuitable terminal"
2. **opencode hangs when TERM is explicitly set** in the command environment (e.g., `TERM=xterm-256color opencode run`)

### The Solution: tmux-wrapper.sh

A wrapper script (`~/scripts/tmux-wrapper.sh`) sets TERM in the script environment before launching tmux:

```bash
#!/bin/zsh
export TERM=xterm-256color
exec /opt/homebrew/bin/tmux "$@"
```

**Why this works:**
- TERM is set in the script environment (inherited naturally by opencode) - avoids the hang
- tmux receives a known TERM value (`xterm-256color`) that exists in the VM terminfo database
- Works with Ghostty, Terminal.app, iTerm2, and all terminals

**Key learning:** opencode has a bug where it hangs when TERM is explicitly set in the command environment (`TERM=xterm-256color command`), but works correctly when TERM is inherited from the environment naturally. This distinction matters for any script or wrapper that launches opencode.

---

## Network Configuration

### VM Network Topology

Tart VMs use a virtual network with NAT:

```
+-----------------------------------------+
| Host Mac                                |
|   IP: 192.168.64.1                      |
|   Internet: via host connection         |
+----------------+------------------------+
                 | Virtual Network (vmnet)
+----------------+------------------------+
| VM (cal-dev)                            |
|   IP: 192.168.64.x (dynamic)           |
|   Gateway: 192.168.64.1                |
+-----------------------------------------+
```

### Direct vs Proxy Access

**Direct Access** (most networks):
- VM has internet through host's NAT
- No configuration needed
- `curl https://github.com` works directly

**Proxy Needed** (corporate networks):
- Host's network requires HTTP proxy authentication
- VM traffic blocked or filtered
- Need to tunnel through host

### Proxy Modes

| Mode | Behavior |
|------|----------|
| `auto` (default) | Test github.com connectivity; enable proxy only if needed |
| `on` | Always enable transparent proxy |
| `off` | Never enable proxy (direct access only) |

### Bootstrap Proxy (During Init)

**Problem**: Need network to install sshuttle, but sshuttle isn't installed yet.

**Solution**: Use SSH's built-in SOCKS proxy (-D flag):

```bash
# From VM, create SOCKS tunnel to host
ssh -D 1080 -f -N user@192.168.64.1

# Install packages using SOCKS proxy
ALL_PROXY=socks5h://localhost:1080 brew install sshuttle

# Note: socks5h:// means DNS also goes through proxy
```

### Transparent Proxy (sshuttle)

After installation, sshuttle provides truly transparent routing:

```bash
# Routes ALL TCP traffic through host
# No HTTP_PROXY env vars needed - any app works
sshuttle --dns -r user@192.168.64.1 0.0.0.0/0 \
    -x 192.168.64.1/32 \      # Exclude host gateway
    -x 192.168.64.0/24        # Exclude VM network
```

**Key Benefits:**
- No per-application configuration
- DNS queries also tunnel
- Works with any TCP application

### Host Requirements for Proxy

1. **SSH Server enabled**:
   ```bash
   # Check
   nc -z 192.168.64.1 22

   # Enable
   # System Settings -> General -> Sharing -> Remote Login
   # Or: sudo systemsetup -setremotelogin on
   ```

2. **Python installed** (sshuttle requires it on server):
   ```bash
   python3 --version  # macOS includes Python
   ```

### VM->Host SSH Key Setup

For proxy to work, VM needs SSH access to host:

```bash
# In VM: generate key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -C 'cal-vm-proxy'

# On host: add VM's public key
cat vm_key.pub >> ~/.ssh/authorized_keys

# Pre-populate host's key in VM (prevents MITM)
ssh-keyscan -H 192.168.64.1 >> ~/.ssh/known_hosts  # In VM
```

### Proxy Auto-Start

Proxy auto-starts on shell initialization based on mode:
- `PROXY_MODE=on`: Always starts proxy silently
- `PROXY_MODE=auto`: Tests github.com, starts proxy only if connectivity fails
- Errors suppressed during auto-start to avoid spamming shell startup

### VM Proxy Commands

```bash
proxy-start     # Start proxy manually
proxy-stop      # Stop proxy
proxy-restart   # Restart proxy
proxy-status    # Check status and test connectivity
proxy-log       # View proxy logs (tail ~/.cal-proxy.log)
```

---

## SSH Configuration

### Host->VM SSH Setup

```bash
# Generate key if needed (on host)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Copy to VM (requires password initially)
# Using sshpass:
SSHPASS=admin sshpass -e ssh -o StrictHostKeyChecking=no admin@<vm_ip> \
    "mkdir -p ~/.ssh && echo '<pubkey>' >> ~/.ssh/authorized_keys"

# Using expect (fallback):
expect -c "
    spawn ssh admin@<vm_ip> {mkdir -p ~/.ssh && ...}
    expect \"*assword*\" { send \"admin\r\"; exp_continue }
    eof
"
```

### SSH Options Used Throughout

```bash
# Standard options for automation
-o StrictHostKeyChecking=no      # Accept new host keys
-o UserKnownHostsFile=/dev/null  # Don't save host keys
-o ConnectTimeout=2              # Quick timeout for testing
-o BatchMode=yes                 # Fail instead of prompting
-o PreferredAuthentications=password  # Force password auth
```

### Waiting for SSH Readiness

```bash
# VM may take 30-60 seconds to boot
max_wait=60
count=0

while [ $count -lt $max_wait ]; do
    # Test if SSH port is open
    if nc -z -w 2 "$VM_IP" 22; then
        echo "SSH is ready"
        break
    fi
    sleep 2
    count=$((count + 2))
done
```

---

## Tool Installation

### Homebrew Packages

```bash
# Core tools
brew install node      # Required for Claude Code, CCS, Codex
brew install gh        # GitHub CLI
brew install tmux      # Session persistence
brew install sshuttle  # Transparent proxy
brew install jq        # JSON processing

# Nested VM and GUI support
brew install cirruslabs/cli/tart           # Nested VMs (uses host cache)
brew install cirruslabs/cli/tart-guest-agent  # Clipboard sharing
brew install --cask ghostty                # Modern terminal emulator
```

### Agent Installation

**Claude Code** (npm):
```bash
npm install -g @anthropic-ai/claude-code
# Binary: claude
```

**Cursor CLI** (curl script):
```bash
curl -fsSL https://cursor.com/install | bash
# Installs to: ~/.local/bin/
# Binary: agent
```

**opencode** (Homebrew tap):
```bash
brew install anomalyco/tap/opencode
# Binary: opencode
```

**CCS - Claude Code Switch** (npm):
```bash
npm install -g @kaitranntt/ccs
# Binary: ccs
```

**Codex CLI** (npm):
```bash
npm install -g @openai/codex
# Binary: codex
```

### Go Development Tools

**Linters and Static Analysis:**
```bash
brew install golangci-lint                               # Meta-linter with 50+ linters
go install honnef.co/go/tools/cmd/staticcheck@latest    # Fast static analyzer
```

**Development Tools:**
```bash
go install golang.org/x/tools/cmd/goimports@latest      # Auto-import formatter
go install github.com/go-delve/delve/cmd/dlv@latest     # Debugger
go install go.uber.org/mock/mockgen@latest               # Test mocking
go install github.com/air-verse/air@latest               # Hot reload
```

**Note:** Core Go tools (go fmt, go vet, go test, go mod) are built-in.

### PATH Configuration

```bash
# Added to ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"           # Cursor CLI
export PATH="$HOME/scripts:$PATH"              # Helper scripts
export PATH="$HOME/.opencode/bin:$PATH"        # opencode (alternate location)
export GOPATH="$HOME/go"                       # Go workspace
export PATH="$GOPATH/bin:$PATH"                # Go development tools
```

---

## macOS Configuration

### Auto-Login (for Screen Sharing / GUI)

```bash
# Enable auto-login for admin user
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser admin
```

**Why needed:** Screen Sharing and VNC show lock screen without auto-login, preventing GUI access for agent authentication.

**Takes effect:** After VM reboot.

### Keychain Auto-Unlock

The VM automatically unlocks the login keychain on every SSH login to support agent OAuth authentication.

**Implementation:**
1. VM password saved to `~/.cal-vm-config` (mode 600, owner-only access)
2. `.zshrc` keychain unlock block runs on every login shell
3. `CAL_SESSION_INITIALIZED` environment variable prevents re-execution when logout is cancelled (exec zsh -l preserves the flag)

```bash
# In .zshrc - runs once per session chain
if [[ -o login ]] && [ -z "$CAL_SESSION_INITIALIZED" ]; then
    export CAL_SESSION_INITIALIZED=1
    source ~/.cal-vm-config
    security unlock-keychain -p "${VM_PASSWORD:-admin}" login.keychain
fi
```

**Why needed:** Some agents (especially Cursor) require keychain access for credential storage. SSH sessions don't unlock keychain automatically.

**Security trade-off:** Password stored in plaintext (protected by mode 600 permissions). Acceptable given VM isolation architecture.

### Terminal Fixes

```bash
# Fix delete key and terminal compatibility
export TERM=xterm-256color

# Fix up arrow history
bindkey "^[[A" up-line-or-history
```

### tmux Configuration

Default config installed to `~/.tmux.conf`:
- Mouse support enabled (scroll, click, resize)
- 50,000 line scrollback buffer
- Vi-style keybindings
- Custom CAL status bar styling
- Window/pane numbering starts at 1
- Easy config reload with Ctrl+b r
- Vim-style pane navigation (h/j/k/l)
- Pipe/dash splitting preserving current path

---

## Authentication

### Authentication Status Detection

```bash
# GitHub CLI
gh auth status &>/dev/null

# Claude Code - check settings.json has actual content (not just empty braces)
[ -f ~/.claude/settings.json ] && \
    content=$(cat ~/.claude/settings.json | tr -d '[:space:]') && \
    [ "$content" != "{}" ] && [ -n "$content" ]

# opencode - check if any credentials exist
! opencode auth list 2>/dev/null | grep -q "0 credentials"

# Cursor (agent) - check if logged in
! agent whoami 2>/dev/null | grep -q "Not logged in"
```

**Key learning:** Claude Code auth detection must check settings.json *content*, not just file existence. An empty `{}` file means not authenticated.

### Authentication Flows

**GitHub CLI:**
```bash
gh auth login
# Choose: GitHub.com -> HTTPS -> Login with browser
# Opens browser for OAuth
```

**Claude Code:**
```bash
claude
# First run triggers authentication
# Opens browser for Anthropic OAuth
# IMPORTANT: Press 'c' to copy the auth URL (do not mouse-select - line wrapping breaks URL)
```

**opencode:**
```bash
opencode auth login
# Opens browser for authentication
```

**Cursor CLI:**
```bash
agent
# OAuth authentication (requires keychain unlock for credential storage)
# Works in VM with automatic keychain unlock
```

**Codex CLI:**
```bash
codex
# Authentication via OpenAI credentials
```

### Authentication Script (vm-auth.sh)

The authentication script provides a unified flow:
1. Network connectivity check with proxy auto-start
2. Authentication status summary for all services
3. Single gate prompt with smart defaults:
   - `[Y/n]` if any service not authenticated
   - `[y/N]` if all services authenticated
4. Individual prompts for each service (re-authenticate or skip)
5. Ctrl+C trap handlers for clean interruption of each auth flow
6. GitHub repository cloning after gh authentication

**Username extraction:** Uses `gh api user -q .login` for locale-independent username retrieval (avoids parsing locale-dependent `gh auth status` output).

### Repository Cloning

After GitHub CLI authentication, vm-auth.sh prompts to clone repositories:
- Format: `owner/repo` or just `repo` (assumes authenticated user)
- Clones to: `~/code/github.com/[owner]/[repo]`
- Skips existing repositories
- Interactive one-per-line entry

---

## VM Detection

### Environment Variable

Set automatically in VM's `~/.zshrc`:

```bash
export CAL_VM=true
export CAL_VM_INFO="$HOME/.cal-vm-info"
```

### Info File

Created at `~/.cal-vm-info`:

```bash
CAL_VM=true
CAL_VM_NAME=cal-dev
CAL_VM_CREATED=2026-01-21T12:34:56Z
CAL_VERSION=0.1.0
```

### Helper Functions

```bash
# Check if running in VM
is-cal-vm() {
    [ -f ~/.cal-vm-info ] && [ "$CAL_VM" = "true" ]
}

# Display VM info
cal-vm-info() {
    cat ~/.cal-vm-info
}
```

### Usage in Agents

```bash
# Shell
if [ "$CAL_VM" = "true" ]; then
    echo "Running in CAL VM - safe to proceed"
fi

# Python
import os
if os.getenv('CAL_VM') == 'true':
    print("In CAL VM")

# Go
import "os"
if os.Getenv("CAL_VM") == "true" {
    fmt.Println("Running in CAL VM")
}
```

### Persistence

VM detection persists across shell sessions, SSH reconnections, VM reboots, and snapshot restores.

---

## First-Run and Logout Automation

### Auth-Needed Flag (During --init)

During `--init`, `vm-setup.sh` creates `~/.cal-auth-needed`. On next login, `.zshrc` detects this flag, removes it, and runs `vm-auth.sh` for initial authentication. After auth completes, the shell exits to allow `cal-bootstrap` to continue with `cal-init` creation.

### First-Run Flag (After Restore)

When restoring from `cal-init`, the `~/.cal-first-run` flag triggers `vm-first-run.sh` on first login. This script:
1. Checks network connectivity (auto-starts proxy if needed)
2. Scans `~/code` for git repositories
3. Fetches remote updates for each repo
4. Reports which repos have available updates (doesn't auto-pull)
5. Categorizes fetch failures (authentication, network, other)

**Key design decision:** vm-first-run.sh only *checks* for updates, it doesn't pull them. This avoids surprising merge conflicts on login.

### First-Run Flag Reliability

**Problem:** Booting cal-init briefly to set the flag didn't get IP consistently (network timing issue).

**Solution:** Set flag in cal-dev (while running with known IP) -> Clone to cal-init (flag copies) -> Remove flag from cal-dev after restart.

### Logout Git Status Check

Configured in `~/.zlogout`:
1. Scans `~/code` for repositories with uncommitted or unpushed changes
2. Shows warnings listing affected repositories
3. Prompts user to continue or cancel logout
4. Cancel starts a new login shell (`exec zsh -l`) with `CAL_SESSION_INITIALIZED` preserved (avoids re-running keychain unlock)

### Session Initialization Guard

`CAL_SESSION_INITIALIZED` environment variable prevents `.zshrc` from re-running keychain unlock and first-run checks when logout is cancelled. The flag persists through `exec zsh -l` because it's an environment variable, not a shell-local variable.

---

## Git Safety Checks

### What Is Checked

Before destructive operations (init, restore, delete):

1. **Uncommitted changes**: Modified files not yet committed
2. **Unpushed commits**: Local commits not pushed to remote

### Search Locations

```bash
# Directories searched for git repos:
~/workspace
~/projects
~/repos
~/code
~  (depth 2 only)
```

### Protected Operations

| Operation | Checks | Behavior |
|-----------|--------|----------|
| `--init` | cal-dev | Warns before deleting. Single confirmation for entire init. |
| `--snapshot restore` | cal-dev (if exists) | Warns before replacing. Creates cal-dev if it doesn't exist. |
| `--snapshot delete` | Target VM (not cal-clean) | Warns before deleting. Supports multiple VM names. |
| `--snapshot delete --force` | None | Skips git checks and avoids booting VM (for unresponsive VMs). |
| Logout | cal-dev repos | Scans ~/code, prompts to push before exit. |

### Reusable Implementation

`check_vm_git_changes()` is a reusable function in `cal-bootstrap` used by all destructive operations. It:
1. Starts the VM if not running (to access filesystem via SSH)
2. Scans search locations for git repos
3. Shows uncommitted and unpushed changes
4. Prompts for confirmation
5. Stops VM if it wasn't running before the check

### Unpushed Commit Detection Prerequisites

Requires upstream tracking to be configured:
```bash
git branch -u origin/main
```
Repos cloned from GitHub automatically have this set up.

---

## Snapshot Management

### Creating Snapshots

```bash
# Tart snapshots are actually clones
tart stop cal-dev
tart clone cal-dev my-snapshot
```

### Restoring Snapshots

```bash
# If cal-dev exists: checks git, deletes, clones from snapshot
# If cal-dev doesn't exist: clones directly from snapshot
tart stop cal-dev     # (if running)
tart delete cal-dev   # (if exists)
tart clone my-snapshot cal-dev
```

### Listing Snapshots

Uses `tart list --format json` for accurate size data:

```bash
tart list --format json | jq -r '.[] | "\(.Name)|\(.Size)|\(.State)"'
```

### Snapshot Naming

- No prefix required
- User provides exact name they want
- Names are case-sensitive

### Deleting Snapshots

- Accepts multiple VM names: `--snapshot delete vm1 vm2 vm3`
- `--force` flag skips git checks and avoids booting VM (for unresponsive VMs)

---

## Tart Cache Sharing (Nested VM Support)

### Problem

Running cal-bootstrap inside cal-dev VM would re-download macos-sequoia-base:latest (~30-47GB), wasting bandwidth and time.

### Solution

Share host's Tart cache directory with VM using Tart's directory sharing feature:

```bash
# VM started with shared cache
tart run --no-graphics --dir=tart-cache:~/.tart/cache:ro cal-dev &
```

Inside the VM, a symlink is created:
```bash
~/.tart/cache -> /Volumes/My Shared Files/tart-cache
```

### Key Details

- **Read-only sharing** prevents VM from corrupting host cache
- **Automatic** - cache sharing added to all VM start operations (--init, --run, --restart, --gui)
- **Idempotent setup** - safe to run `setup_tart_cache_sharing()` multiple times
- **Graceful degradation** - if sharing not available, Tart downloads normally

### Tools Installed for Nested VMs

- **Tart** (`brew install cirruslabs/cli/tart`) - VM management inside VM
- **Ghostty** (`brew install --cask ghostty`) - Modern terminal emulator
- **jq** (`brew install jq`) - JSON processing for snapshot listing

### Verification

```bash
# Inside cal-dev VM
ls -la ~/.tart/cache/              # Should show symlink
tart list --format json | jq -r '.[] | select(.Source == "OCI") | .Name'
```

---

## Clipboard Support

### VNC Experimental (Recommended)

`--gui` mode uses `tart run --vnc-experimental`:
- **Bidirectional clipboard** (Host <-> VM)
- No disconnect issues
- Uses Virtualization.Framework's built-in VNC server

### Screen Sharing Standard Mode (Legacy)

- **One-way clipboard** (VM -> Host only) via tart-guest-agent
- Host -> VM paste causes Screen Sharing disconnect
- tart-guest-agent implements SPICE vdagent protocol

### Screen Sharing High Performance Mode (Incompatible)

- **Do not use** - shows black screen / locked VM
- Virtualization.Framework doesn't support High Performance mode
- This is a macOS/Tart limitation, not a bug

### tart-guest-agent

- Installed during vm-setup.sh via Homebrew
- Configured as launchd service (`~/Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist`)
- Runs automatically on boot (KeepAlive enabled)
- Enables VM -> Host clipboard in Screen Sharing Standard mode
- Logs: `/tmp/tart-guest-agent.log`

---

## Configuration Files in VM

| File | Purpose | Permissions |
|------|---------|-------------|
| `~/.cal-vm-info` | VM metadata (name, version, created date) | Default |
| `~/.cal-vm-config` | VM password for keychain unlock | 600 |
| `~/.cal-proxy-config` | Proxy settings (HOST_GATEWAY, HOST_USER, PROXY_MODE) | Default |
| `~/.cal-auth-needed` | Flag: run vm-auth.sh on next login (during --init) | Default |
| `~/.cal-first-run` | Flag: run vm-first-run.sh on next login (after restore) | Default |
| `~/.cal-proxy.log` | sshuttle proxy logs | Default |
| `~/.cal-proxy.pid` | sshuttle process ID | Default |
| `~/.tmux.conf` | tmux configuration | Default |
| `~/.zlogout` | Logout git status check | Default |

---

## Known Limitations and Learnings

### Opencode TERM Bug

**Problem:** `opencode run` hangs indefinitely when TERM is explicitly set in the command environment.

**Works:** `opencode run "test"` (TERM inherited from environment)
**Hangs:** `TERM=xterm-256color opencode run "test"` (TERM explicit in command)

**Solution:** tmux-wrapper.sh sets TERM in script environment, not command environment.

**Status:** Upstream bug in opencode. Worked around in CAL.

### Claude Code OAuth URL Line Wrapping

**Problem:** Mouse-selecting the OAuth URL from terminal includes literal newlines, breaking the URL when pasted in browser.

**Solution:** Press `c` when prompted to copy the auth URL. Claude Code has a built-in copy feature.

### Cursor CLI Authentication

**Status:** Working with automatic keychain unlock.

**History:** Previously documented as broken in VM/SSH environments. The fix was implementing automatic keychain unlock on every SSH login via `.zshrc`, which enables Cursor OAuth flows to access browser credentials.

### Shell Initialization Required

**Issue:** Some tools report "not found" immediately after installation.

**Cause:** PATH changes in `.zshrc` not loaded in current session.

**Solution:** Restart shell with `exec zsh` or manually source config.

### BSD awk Compatibility

**Issue:** `vm_exists()` and `vm_running()` initially used GNU awk syntax incompatible with BSD awk.

**Solution:** Use flag variable pattern instead of column matching:
```bash
# Works with BSD awk
tart list | awk -v name="cal-dev" '$1 == name {found=1} END {exit !found}'
```

### macOS timeout Command

**Issue:** `timeout` command not available on macOS by default.

**Solution:** Removed dependency. Git has built-in timeouts, external `timeout` not needed.

### Filesystem Sync Timing

**Issue:** Flag files (`.cal-auth-needed`, `.cal-first-run`) sometimes didn't survive VM reboot.

**Solution:** Call `sync` after creating flag files to ensure filesystem writes are flushed.

---

## Troubleshooting

### VM Won't Start

```bash
# Check if already running
tart list | grep running

# Force stop
tart stop cal-dev --force
```

### SSH Connection Refused

```bash
# Wait longer (VM still booting)
sleep 60

# Check Remote Login enabled in VM
# System Preferences -> Sharing -> Remote Login
```

### Agent Not Found

```bash
# Reload shell
exec zsh

# Check PATH
echo $PATH | tr ':' '\n' | grep -E '(local|homebrew|go)'

# Reinstall specific agent
npm install -g @anthropic-ai/claude-code
```

### Proxy Not Working

```bash
# Check host SSH
nc -z 192.168.64.1 22

# Check host Python
python3 --version

# View logs
tail -50 ~/.cal-bootstrap.log  # Host
proxy-log                       # VM (tail ~/.cal-proxy.log)
```

### Disk Space in VM

```bash
# Check usage
df -h

# Clean up
rm -rf ~/Library/Caches/*
rm -rf ~/.npm/_cacache
go clean -cache
```

### Opencode Hangs

```bash
# WRONG - will hang:
TERM=xterm-256color opencode run "test"

# CORRECT - works fine:
opencode run "test"
```

### Clipboard Issues

```bash
# Use --gui for reliable clipboard
./scripts/cal-bootstrap --gui

# If Screen Sharing: only copy FROM VM, never paste TO VM
# Enable: Edit -> Use Shared Clipboard
```

### First-Run Didn't Trigger

```bash
# Check if flag exists
ls -la ~/.cal-first-run

# If missing, run manually
~/scripts/vm-first-run.sh
```

---

## Script Architecture

### cal-bootstrap (Host)

Main orchestration script. Modes:
- `--init` / `-i`: Full VM creation and setup
- `--run` (default): Start VM and SSH in with tmux
- `--stop` / `-s`: Stop cal-dev
- `--restart` / `-r`: Restart VM and reconnect
- `--gui` / `-g`: Launch with VNC experimental mode
- `--snapshot` / `-S`: List, create, restore, delete snapshots
- `--proxy on/off/auto`: Control proxy mode
- `--yes` / `-y`: Skip confirmation prompts

Key functions:
- `start_vm_background()`: Starts VM with cache sharing, waits for IP and SSH
- `setup_tart_cache_sharing()`: Creates cache symlink in VM
- `setup_scripts_folder()`: Copies helper scripts to VM (idempotent)
- `check_vm_git_changes()`: Reusable git safety check
- `do_gui()`: Starts VM with `--vnc-experimental`, displays connection info

### vm-setup.sh (VM)

Runs inside VM during `--init`:
- Package installation (Homebrew, npm, go install)
- Agent installation (claude, agent, opencode, ccs, codex)
- Go development tool installation
- Shell configuration (.zshrc, .zlogout)
- VM detection setup (.cal-vm-info)
- Keychain auto-unlock configuration
- Proxy function installation
- tart-guest-agent launchd configuration
- tmux configuration

### vm-auth.sh (VM)

Interactive authentication during `--init`:
- Network connectivity check with proxy auto-start
- Authentication status summary for all services
- Smart gate prompt (Y/n vs y/N based on current auth state)
- Individual auth flows with Ctrl+C trap handlers
- GitHub repository cloning
- Locale-independent username via API

### vm-first-run.sh (VM)

Post-restore repository update checker:
- Network connectivity check with proxy auto-start
- Scans ~/code for git repositories
- Fetches remote updates
- Reports update availability (doesn't auto-pull)
- Categorizes fetch failures (auth, network, other)

### tmux-wrapper.sh (VM)

TERM compatibility wrapper:
- Sets `TERM=xterm-256color` in script environment
- Launches tmux with passed arguments
- Solves Ghostty/opencode compatibility issues

### Script Locations

```
Host: scripts/cal-bootstrap
      scripts/vm-setup.sh
      scripts/vm-auth.sh
      scripts/vm-first-run.sh
      scripts/tmux-wrapper.sh

VM:   ~/scripts/vm-setup.sh
      ~/scripts/vm-auth.sh
      ~/scripts/vm-first-run.sh
      ~/scripts/tmux-wrapper.sh
```

---

## Testing Lessons Learned

Issues discovered and fixed during Phase 0:

1. **vm_exists() / vm_running()**: BSD awk incompatibility - use flag variable pattern
2. **Double/triple confirmation prompts**: Consolidated to single prompt per operation
3. **Git check coverage**: Expanded from ~/workspace only to five directories
4. **Git check VM state**: Always boot VM if needed for check, stop after if it wasn't running
5. **$vm_to_run undefined**: Must use $VM_DEV constant
6. **Argument parsing**: `shift || true` errors in zsh - use `[[ $# -gt 0 ]] && shift`
7. **scp error handling**: Must check exit codes for all scp operations
8. **Snapshot delete**: Don't stop running VM before git check (use it while running)
9. **Filesystem sync**: Flag files need `sync` before VM reboot
10. **Network timeout**: Use git's built-in timeouts, not macOS `timeout` command

---

## Security Model

| Risk | Mitigation |
|------|------------|
| Agent deletes files | VM isolated; git preserves history |
| Bad code pushed | Work on branches; PR review |
| Token leak | Fine-grained PAT, limited scope |
| Malware | Snapshots enable quick recovery |
| VM accessing host | SSH keys only valid from VM network; host key verification |
| Keychain password exposure | Mode 600 permissions; VM isolation |
| Proxy SSH access | Key generated for VM only; local network only |

---

## Phase 1 Readiness

### What Phase 1 (CLI Foundation) Will Replace

Phase 1 replaces manual Tart commands with a `cal isolation` CLI. The following `cal-bootstrap` operations need Go equivalents:

| Current (Shell) | Phase 1 (Go CLI) |
|-----------------|-------------------|
| `cal-bootstrap --init` | `cal isolation init` |
| `cal-bootstrap --run` | `cal isolation start` / `cal isolation ssh` |
| `cal-bootstrap --stop` | `cal isolation stop` |
| `cal-bootstrap --restart` | `cal isolation restart` |
| `cal-bootstrap --gui` | `cal isolation gui` |
| `cal-bootstrap -S list` | `cal isolation snapshot list` |
| `cal-bootstrap -S create` | `cal isolation snapshot create` |
| `cal-bootstrap -S restore` | `cal isolation snapshot restore` |
| `cal-bootstrap -S delete` | `cal isolation snapshot delete` |

### Operational Knowledge Required

Phase 1 must preserve all behaviors documented in this ADR:
- Three-tier VM architecture
- Git safety checks before destructive operations
- Transparent proxy with auto-detection
- Bootstrap SOCKS proxy during init
- TERM wrapper for tmux sessions
- Keychain auto-unlock mechanism
- First-run and auth-needed flag system
- Tart cache sharing for nested VMs
- VNC experimental mode for GUI access
- All VM configuration files and their purposes
- Helper script deployment and PATH setup

### VM Configuration Files to Manage

The CLI must be aware of and manage:
- `~/.cal-vm-info` (read by agents for VM detection)
- `~/.cal-vm-config` (password for keychain unlock)
- `~/.cal-proxy-config` (proxy settings)
- `~/.cal-auth-needed` / `~/.cal-first-run` (lifecycle flags)
- `~/.tmux.conf` (tmux configuration)
- `~/.zshrc` (shell configuration blocks)
- `~/.zlogout` (logout git check)

---

## References

- [cal-bootstrap](../../scripts/cal-bootstrap) - Main orchestration script
- [vm-setup.sh](../../scripts/vm-setup.sh) - VM tool installation
- [vm-auth.sh](../../scripts/vm-auth.sh) - Agent authentication
- [vm-first-run.sh](../../scripts/vm-first-run.sh) - Post-restore update checker
- [tmux-wrapper.sh](../../scripts/tmux-wrapper.sh) - TERM compatibility wrapper
- [Bootstrap Guide](../bootstrap.md) - Quick start documentation
- [Proxy Documentation](../proxy.md) - Network proxy details
- [VM Detection](../vm-detection.md) - Agent environment detection
- [ADR-001](ADR-001-cal-isolation.md) - Architecture decisions
- [Tart Documentation](https://tart.run/) - Official Tart docs
