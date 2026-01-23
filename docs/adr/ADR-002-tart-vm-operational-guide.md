# ADR-002: Tart VM Operational Guide

## Operational Learnings for CAL VM Management

**ADR:** 002
**Status:** Accepted
**Created:** 2026-01-21
**Purpose:** Document operational learnings, setup procedures, and known issues for managing Tart macOS VMs in CAL

---

## Context

CAL (Coding Agent Loader) uses Tart to run macOS VMs that provide isolated environments for AI coding agents. Through the development of `cal-bootstrap`, `vm-setup.sh`, and `vm-auth.sh`, we discovered numerous operational details, edge cases, and best practices that are essential for maintaining and extending the system.

This ADR serves as a comprehensive reference for developers maintaining CAL, capturing the "tribal knowledge" embedded in the scripts.

---

## Decision Summary

We established a three-VM architecture with automated setup, transparent networking, and safety checks. Key decisions:

1. **Three-tier VM structure**: cal-clean → cal-dev → cal-init
2. **SSH-first access** with tmux for session persistence
3. **Transparent proxy** using sshuttle for corporate network compatibility
4. **Automatic git safety checks** before destructive operations
5. **VM detection mechanism** for agent awareness

---

## VM Architecture and Naming

### VM Hierarchy

```
ghcr.io/cirruslabs/macos-sequoia-base:latest
            │
            ▼
      ┌─────────────┐
      │  cal-clean  │  ← Pristine base image (never modified after creation)
      └─────────────┘
            │
            ▼
      ┌─────────────┐
      │   cal-dev   │  ← Working development VM (daily use)
      └─────────────┘
            │
            ▼
      ┌─────────────┐
      │  cal-init   │  ← Snapshot after initial setup (tools + auth configured)
      └─────────────┘
            │
            ▼
      ┌─────────────┐
      │  snapshots  │  ← User-created snapshots (before-refactor, etc.)
      └─────────────┘
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
# Required
brew install cirruslabs/cli/tart
brew install jq  # For snapshot list with sizes

# Optional (installed automatically if missing)
brew install esolitos/ipa/sshpass  # Or: hudochenkov/sshpass/sshpass
```

### The Init Workflow

The `--init` command performs these steps in order:

```
Step 1: Create cal-clean from base image
        └─ tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-clean
        └─ tart set cal-clean --cpu 4 --memory 8192 --disk-size 80

Step 2: Create cal-dev from cal-clean
        └─ tart clone cal-clean cal-dev

Step 3: Start cal-dev in background
        └─ tart run --no-graphics cal-dev &
        └─ Wait for IP (poll tart ip cal-dev)
        └─ Wait for SSH (test port 22 connectivity)

Step 4: Setup SSH keys (host→VM)
        └─ Generate ~/.ssh/id_ed25519 if missing
        └─ Copy public key to VM's ~/.ssh/authorized_keys

Step 5: Setup network access
        └─ Test github.com connectivity
        └─ If blocked: setup VM→Host SSH keys
        └─ Start bootstrap SOCKS proxy (SSH -D 1080)

Step 6: Copy helper scripts to VM
        └─ scp vm-setup.sh vm-auth.sh → ~/scripts/
        └─ Add ~/scripts to PATH in .zshrc

Step 7: Run vm-setup.sh
        └─ Install: node, gh, tmux, sshuttle
        └─ Install agents: claude, agent (Cursor), opencode
        └─ Configure: auto-login, keychain, terminal, VM detection

Step 8: Switch to sshuttle (if proxy needed)
        └─ Stop bootstrap SOCKS proxy
        └─ Start sshuttle transparent proxy

Step 9: Run vm-auth.sh in tmux
        └─ Interactive authentication for each agent
        └─ User completes OAuth flows

Step 10: Create cal-init snapshot
         └─ Stop cal-dev
         └─ tart clone cal-dev cal-init
```

### Handling Existing VMs

Before init, the script checks for existing VMs:

```bash
# If cal-dev or cal-init exist:
1. Warn user about deletion
2. Start cal-dev to check for git changes (if exists)
3. Show any uncommitted/unpushed changes
4. Get confirmation (unless --yes)
5. Delete existing VMs
6. Proceed with fresh init
```

---

## Network Configuration

### VM Network Topology

Tart VMs use a virtual network with NAT:

```
┌─────────────────────────────────────┐
│ Host Mac                            │
│   IP: 192.168.64.1                  │
│   Internet: via host connection     │
└──────────────┬──────────────────────┘
               │ Virtual Network (vmnet)
┌──────────────┴──────────────────────┐
│ VM (cal-dev)                        │
│   IP: 192.168.64.x (dynamic)        │
│   Gateway: 192.168.64.1             │
└─────────────────────────────────────┘
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

**Key Benefits**:
- No per-application configuration
- DNS queries also tunnel
- Works with any TCP application

### Host Requirements for Proxy

1. **SSH Server enabled**:
   ```bash
   # Check
   nc -z 192.168.64.1 22

   # Enable
   # System Settings → General → Sharing → Remote Login
   # Or: sudo systemsetup -setremotelogin on
   ```

2. **Python installed** (sshuttle requires it on server):
   ```bash
   python3 --version  # macOS includes Python
   ```

### VM→Host SSH Key Setup

For proxy to work, VM needs SSH access to host:

```bash
# In VM: generate key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -C 'cal-vm-proxy'

# On host: add VM's public key
cat vm_key.pub >> ~/.ssh/authorized_keys

# Pre-populate host's key in VM (prevents MITM)
ssh-keyscan -H 192.168.64.1 >> ~/.ssh/known_hosts  # In VM
```

---

## SSH Configuration

### Host→VM SSH Setup

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

### tmux for Session Persistence

All SSH connections use tmux:

```bash
ssh -t admin@<vm_ip> "TERM=xterm-256color /opt/homebrew/bin/tmux new-session -A -s cal"
```

**Benefits**:
- Sessions survive SSH disconnects
- Agents keep running if connection drops
- Scrollback buffer independent of terminal
- Multiple panes for side-by-side work

---

## Tool Installation

### Homebrew Packages

```bash
# Core tools
brew install node      # Required for Claude Code
brew install gh        # GitHub CLI
brew install tmux      # Session persistence
brew install sshuttle  # Transparent proxy
```

### Agent Installation

**Claude Code** (npm):
```bash
npm install -g @anthropic-ai/claude-code
# Installs to: /opt/homebrew/lib/node_modules/
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

### PATH Configuration

```bash
# Added to ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"           # Cursor CLI
export PATH="$HOME/scripts:$PATH"              # Helper scripts
export PATH="$HOME/.opencode/bin:$PATH"        # opencode (alternate location)
export PATH="$HOME/go/bin:$PATH"               # Go binaries (if using go install)
```

---

## macOS Configuration

### Auto-Login (for Screen Sharing)

```bash
# Enable auto-login for admin user
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser admin
```

**Why needed**: Screen Sharing shows lock screen without auto-login, preventing GUI access for agent authentication.

**Takes effect**: After VM reboot.

### Keychain Unlock

```bash
# Unlock login keychain for SSH sessions
security unlock-keychain -p 'admin' login.keychain
```

**Why needed**: Some agents (especially Cursor) require keychain access for credential storage. SSH sessions don't unlock keychain automatically.

**When to unlock**:
- After VM boot (done in `--run`)
- After SSH reconnect
- Before running authentication

### Terminal Fixes

```bash
# Fix delete key
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

---

## Authentication

### Authentication Status Detection

```bash
# GitHub CLI
gh auth status &>/dev/null

# Claude Code
[ -d ~/.claude ] && [ -n "$(ls -A ~/.claude)" ]

# opencode
[ -f ~/.opencode/config.json ] || [ -f ~/.config/opencode/config.json ]

# Cursor (agent)
[ -d ~/.cursor/User/globalStorage ] && [ -n "$(ls -A ~/.cursor/User/globalStorage)" ]
```

### Authentication Flows

**GitHub CLI**:
```bash
gh auth login
# Choose: GitHub.com → HTTPS → Login with browser
# Opens browser for OAuth
```

**Claude Code**:
```bash
claude
# First run triggers authentication
# Opens browser for Anthropic OAuth
```

**opencode**:
```bash
opencode auth login
# Opens browser for authentication
```

**Cursor CLI**: See Known Limitations section.

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
```

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

### Check Implementation

```bash
# Find uncommitted changes
for gitdir in $(find ~/workspace ~/projects ~/repos ~/code -name ".git" -type d 2>/dev/null); do
    dir=$(dirname "$gitdir")
    if [ -n "$(cd "$dir" && git status --porcelain)" ]; then
        echo "$dir"
    fi
done

# Find unpushed commits (requires upstream tracking)
for gitdir in ...; do
    dir=$(dirname "$gitdir")
    branch=$(cd "$dir" && git rev-parse --abbrev-ref HEAD)
    if git rev-parse "$branch@{u}" >/dev/null 2>&1; then
        if [ -n "$(git log "@{u}.." --oneline)" ]; then
            echo "$dir"
        fi
    fi
done
```

### Protected Operations

| Operation | Checks | Behavior |
|-----------|--------|----------|
| `--init` | cal-dev | Warns before deleting |
| `--snapshot restore` | cal-dev | Warns before replacing |
| `--snapshot delete` | Target VM (not cal-clean) | Warns before deleting |

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
tart stop cal-dev
tart delete cal-dev
tart clone my-snapshot cal-dev
```

### Listing Snapshots

Uses `tart list --format json` for accurate size data:

```bash
tart list --format json | jq -r '.[] | "\(.Name)|\(.Size)|\(.State)"'
```

### Snapshot Naming

- No prefix required (changed from earlier `cal-dev-` prefix)
- User provides exact name they want
- Names are case-sensitive

---

## Known Limitations

### Cursor CLI Does Not Work in VMs

**Problem**: Cursor's OAuth authentication uses polling to detect browser completion. This polling fails in VM/SSH-only environments.

**Symptoms**:
- `agent` command starts OAuth flow
- Browser opens and authentication completes
- CLI never detects completion (hangs indefinitely)

**Workaround**: None. Use Claude Code or opencode instead.

**Investigated alternatives**:
- API key authentication: Requires OAuth config to exist first (circular dependency)
- Environment variables: Not supported by Cursor CLI

**Status**: Documented as unfixable; Cursor CLI disabled in `vm-auth.sh`.

### Keychain Quirks

**Issue**: Keychain remains locked in SSH sessions even with auto-login.

**Impact**: Agents that store credentials in keychain may fail.

**Solution**: Unlock keychain on each connection:
```bash
security unlock-keychain -p 'admin' login.keychain
```

### Screen Sharing Lock Screen

**Issue**: First connection shows lock screen despite auto-login setting.

**Cause**: Auto-login only takes effect after VM reboot.

**Solution**: Restart VM after initial setup, or use standard Screen Sharing mode (not High Performance).

### High Performance Screen Sharing

**Issue**: High Performance mode in Screen Sharing can cause display issues.

**Status**: Under investigation. Use standard mode for reliability.

### Unpushed Commit Detection Prerequisites

**Issue**: Git unpushed commit detection requires upstream tracking to be configured.

**Impact**: Repos without upstream tracking won't show unpushed commits warning.

**Solution**: Ensure repos have upstream set:
```bash
git branch -u origin/main
```

### Shell Initialization Required

**Issue**: Some tools report "not found" immediately after installation.

**Cause**: PATH changes in `.zshrc` not loaded in current session.

**Solution**: Restart shell with `exec zsh` or manually source config.

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
# System Preferences → Sharing → Remote Login
```

### Agent Not Found

```bash
# Reload shell
exec zsh

# Check PATH
echo $PATH | tr ':' '\n' | grep -E '(local|homebrew)'

# Reinstall
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

---

## Script Architecture

### cal-bootstrap

Main orchestration script:
- Mode detection (init/run/stop/restart/snapshot)
- VM lifecycle management
- SSH key setup
- Proxy configuration
- Git safety checks

### vm-setup.sh

Runs inside VM:
- Package installation
- Agent installation
- Shell configuration
- VM detection setup
- Proxy function installation

### vm-auth.sh

Interactive authentication:
- Network connectivity check
- Auto-start proxy if needed
- Shows authentication status summary for all services
- Single gate prompt with smart defaults ([Y/n] if any not authenticated, [y/N] if all authenticated)
- Steps through each agent's auth flow if user proceeds
- Individual prompts for each service (re-authenticate or skip)

### Script Location

Scripts are copied to VM during init:
```
Host: scripts/cal-bootstrap
      scripts/vm-setup.sh
      scripts/vm-auth.sh

VM:   ~/scripts/vm-setup.sh
      ~/scripts/vm-auth.sh
```

---

## References

- [cal-bootstrap](../../scripts/cal-bootstrap) - Main orchestration script
- [vm-setup.sh](../../scripts/vm-setup.sh) - VM tool installation
- [vm-auth.sh](../../scripts/vm-auth.sh) - Agent authentication
- [Bootstrap Guide](../bootstrap.md) - Quick start documentation
- [Proxy Documentation](../proxy.md) - Network proxy details
- [VM Detection](../vm-detection.md) - Agent environment detection
- [ADR-001](ADR-001-cal-isolation.md) - Architecture decisions
- [Tart Documentation](https://tart.run/) - Official Tart docs
