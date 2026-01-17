# Bootstrap Guide

> Extracted from [ADR-001](adr/ADR-001-cal-isolation.md) for quick reference.

Manual Tart setup until CAL CLI is implemented.

## Setup

```bash
# Install Tart
brew install cirruslabs/cli/tart

# Create VM (~25GB download)
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-dev
tart set cal-dev --cpu 4 --memory 8192 --disk-size 80
tart run cal-dev  # login: admin/admin
```

## Accessing the VM

Once the VM is running, you can access it in several ways:

**Option 1: SSH (Recommended)**
```bash
# Get the VM's IP address
tart ip cal-dev

# SSH into the VM (password: admin)
ssh admin@$(tart ip cal-dev)
```

**Option 2: GUI**
The `tart run cal-dev` command opens a window with the VM's display. You can interact with it directly through that window (login: admin/admin).

**Option 3: Headless with VNC**
```bash
# Start VM headless with VNC available
tart run cal-dev --no-graphics --vnc &

# Connect via VNC (password: admin)
open vnc://$(tart ip cal-dev)
```

Inside VM:
```bash
brew update && brew install node gh
npm install -g @anthropic-ai/claude-code
gh auth login

# Optional: cursor-cli
brew install --cask cursor
# Add Cursor CLI to PATH
echo 'export PATH="/Applications/Cursor.app/Contents/Resources/app/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Optional: opencode
brew install go && go install github.com/opencode-ai/opencode@latest
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.zshrc
```

## Safety Snapshot (Critical)

On host, before any agent session:
```bash
tart stop cal-dev
tart clone cal-dev cal-dev-clean
```

## Daily Use

```bash
# Start headless with VNC available
tart run cal-dev --no-graphics --vnc &
sleep 30 && ssh admin@$(tart ip cal-dev)

# Or with artifact sync
mkdir -p ~/cal-output
tart run cal-dev --no-graphics --dir=output:~/cal-output &
# VM path: /Volumes/My Shared Files/output/
```

## Rollback

```bash
tart stop cal-dev && tart delete cal-dev && tart clone cal-dev-clean cal-dev
```

## Aliases (~/.zshrc)

```bash
alias cal-start='tart run cal-dev --no-graphics & sleep 30 && ssh admin@$(tart ip cal-dev)'
alias cal-stop='tart stop cal-dev'
alias cal-ssh='ssh admin@$(tart ip cal-dev)'
alias cal-rollback='tart stop cal-dev && tart delete cal-dev && tart clone cal-dev-clean cal-dev'
alias cal-vnc='open vnc://$(tart ip cal-dev)'  # password: admin
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
- **Agent not found**: Check PATH includes `~/go/bin`
- **Disk full**: `rm -rf ~/Library/Caches/* ~/.npm/_cacache && go clean -cache`
- **VNC needed**: `tart run cal-dev --vnc` then connect via Screen Sharing app
