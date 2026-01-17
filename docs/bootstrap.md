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

## VM Setup

Once inside the VM, you can set up all agents and tools automatically or manually.

**Automated Setup (Recommended):**
```bash
# Copy setup script to VM (run from host)
scp scripts/vm-setup.sh admin@$(tart ip cal-dev):~/

# Inside VM, run the setup script
ssh admin@$(tart ip cal-dev)
chmod +x ~/vm-setup.sh
./vm-setup.sh

# Authenticate with GitHub
gh auth login

# Configure opencode
opencode init
```

**Manual Setup:**

Inside VM:
```bash
brew update && brew install node gh ripgrep fzf
npm install -g @anthropic-ai/claude-code
gh auth login

# Optional: cursor-cli (command: agent)
curl -fsSL https://cursor.com/install | bash
# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# Optional: opencode (requires ripgrep and fzf)
brew install go && go install github.com/opencode-ai/opencode@latest
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.zshrc
opencode init  # Configure agent and API keys
```

## Using the Agents

Once installed, use these commands to launch each agent:

```bash
# Claude Code
claude

# Cursor CLI
agent

# opencode
opencode
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

**Automated (Recommended):**
```bash
# Reset VM from pristine snapshot (interactive)
scripts/reset-vm.sh cal-dev cal-dev-pristine

# The script will:
# 1. Prompt for confirmation before deleting
# 2. Clone from pristine snapshot
# 3. Start VM in background
# 4. Wait for SSH availability
# 5. Copy vm-setup.sh to VM
```

**Manual:**
```bash
tart stop cal-dev && tart delete cal-dev && tart clone cal-dev-clean cal-dev
```

## Aliases (~/.zshrc)

```bash
alias cal-start='tart run cal-dev --no-graphics & sleep 30 && ssh admin@$(tart ip cal-dev)'
alias cal-stop='tart stop cal-dev'
alias cal-ssh='ssh admin@$(tart ip cal-dev)'
alias cal-rollback='tart stop cal-dev && tart delete cal-dev && tart clone cal-dev-clean cal-dev'
alias cal-reset='scripts/reset-vm.sh cal-dev cal-dev-pristine'  # Automated reset
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
- **Delete key not working**: Add to `~/.zshrc` in VM: `export TERM=xterm-256color` then `source ~/.zshrc`
- **Up arrow history broken**: SSH with proper terminal allocation: `ssh -t admin@$(tart ip cal-dev)` or add `bindkey "^[[A" up-line-or-history` to `~/.zshrc`

## Terminal Keybinding Testing

To test and verify terminal keybindings in the VM:

```bash
# Copy test script to VM
scp scripts/test-keybindings.sh admin@$(tart ip cal-dev):~/

# Run interactive test
ssh admin@$(tart ip cal-dev)
chmod +x ~/test-keybindings.sh
./test-keybindings.sh
```

See [Terminal Keybindings Test Plan](terminal-keybindings-test.md) for detailed test procedures and results.
