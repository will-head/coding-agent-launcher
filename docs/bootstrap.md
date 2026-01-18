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
```

## cal-bootstrap Script

The `cal-bootstrap` script automates VM setup and management.

### Commands

```bash
# First-time setup (creates cal-clean, cal-dev, cal-initialised)
./scripts/cal-bootstrap --init
./scripts/cal-bootstrap -i

# Start cal-dev and SSH in (default if VMs exist)
./scripts/cal-bootstrap --run
./scripts/cal-bootstrap -r
./scripts/cal-bootstrap          # Auto-detects mode

# Stop cal-dev
./scripts/cal-bootstrap --stop
./scripts/cal-bootstrap -s

# Snapshot management
./scripts/cal-bootstrap --snapshot list
./scripts/cal-bootstrap -S list
./scripts/cal-bootstrap -S create before-refactor
./scripts/cal-bootstrap -S restore before-refactor
./scripts/cal-bootstrap -S restore cal-initialised  # Restore from base
./scripts/cal-bootstrap -S delete before-refactor

# Skip confirmation prompts
./scripts/cal-bootstrap -y -S restore cal-initialised
```

### Init Workflow

The `--init` command performs these steps:

1. Creates `cal-clean` from base macOS image (~25GB download)
2. Creates `cal-dev` from `cal-clean`
3. Starts VM and waits for SSH
4. Sets up SSH keys (generates if needed)
5. Runs `vm-setup.sh` to install tools
6. Prompts for manual login setup (gh, claude, opencode, agent)
7. Creates `cal-initialised` snapshot

### VMs Created

| VM | Purpose |
|----|---------|
| `cal-clean` | Base macOS image (pristine) |
| `cal-dev` | Development VM (use this) |
| `cal-initialised` | Snapshot with tools and auth configured |

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

**SSH (Recommended):**
```bash
./scripts/cal-bootstrap --run   # Starts VM and SSHs in
# Or manually:
ssh admin@$(tart ip cal-dev)
```

**VNC:**
```bash
open vnc://$(tart ip cal-dev)   # password: admin
```

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
./scripts/cal-bootstrap -S restore cal-initialised

# List all VMs and snapshots
./scripts/cal-bootstrap -S list
```

## Aliases (~/.zshrc)

```bash
alias cal='./scripts/cal-bootstrap'
alias cal-start='./scripts/cal-bootstrap --run'
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
- **Cursor Agent login fails**: Known issue - run `agent login` and complete browser OAuth flow

## Terminal Keybinding Testing

```bash
# Copy and run test script
scp scripts/test-keybindings.sh admin@$(tart ip cal-dev):~/
ssh admin@$(tart ip cal-dev) "chmod +x ~/test-keybindings.sh && ~/test-keybindings.sh"
```

See [Terminal Keybindings Test Plan](terminal-keybindings-test.md) for details.
