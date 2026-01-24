# Phase 0 Reference Document

> ⚠️ **NOTE:** This is a reference snapshot documenting Phase 0 work.
> **For current status and TODOs, see [PLAN.md](../PLAN.md)** - the single source of truth.

**Snapshot Date:** January 17, 2026  
**Current Status:** See [PLAN.md Current Status section](PLAN.md#current-status)

## Overview

Phase 0 (Bootstrap) is mostly complete. The manual Tart VM setup process is fully documented and automated with the cal-bootstrap script, providing immediate safe agent use with excellent terminal behavior.

## Completed Tasks

### 1. Research & Documentation
- ✅ Researched Tart VM capabilities
- ✅ Documented manual setup process in `docs/bootstrap.md`
- ✅ Created comprehensive ADR-001 with all design decisions

### 2. Automation Scripts
- ✅ **`scripts/vm-setup.sh`** - Automated VM provisioning
  - Installs Homebrew packages (node, gh)
  - Installs all three agents (Claude Code, Cursor CLI, opencode)
  - Configures shell environment (PATH, TERM, keybindings)
  - Verifies all installations
  - Idempotent (can be run multiple times safely)

- ✅ **`scripts/cal-bootstrap`** - Unified VM management
  - `--init`: Create and configure VMs
  - `--run`: Start VM and SSH in
  - `--stop`: Stop VM
  - `--snapshot`: Snapshot management
  - Keychain unlock automation

### 3. Terminal Environment
- ✅ Fixed delete key behavior (`TERM=xterm-256color`)
- ✅ Fixed up arrow history navigation (`bindkey "^[[A" up-line-or-history`)
- ✅ **Created comprehensive test plan** (`docs/terminal-keybindings-test.md`)
- ✅ **Created test script** (`scripts/test-keybindings.sh`)
- ✅ **Executed full keybinding tests**

### 4. VM Setup Process
- ✅ Base VM creation documented
- ✅ Agent installation automated
- ✅ Snapshot workflow documented
- ✅ Quick reset capability implemented

## Terminal Testing Results

Comprehensive testing revealed **excellent terminal behavior** in the VM SSH environment:

### All Working Keys ✅

**Navigation:**
- Arrow keys (up/down/left/right)
- Home/End (via Ctrl+A/E Emacs bindings)
- Page Up/Down (terminal scrollback)

**Editing:**
- Delete/Backspace
- Ctrl+K/U/W/Y (kill/yank operations)

**Cursor Movement:**
- All Emacs bindings (Ctrl+A/E/B/F/P/N)

**Word Navigation:**
- Option+Left/Right (backward/forward word)
- Option+Backspace (delete word backward)

**Special Functions:**
- Ctrl+C/D/Z/L (signal handling, clear)
- Ctrl+R (reverse search)
- Tab completion

### No Broken Keys ✅

**Zero additional fixes needed** beyond the two already in `vm-setup.sh`:
1. `export TERM=xterm-256color`
2. `bindkey "^[[A" up-line-or-history`

### Escape Sequences Documented

Option/Alt keys correctly transmit as ESC+key sequences:
- Option+Left: ESC+b (0x1b 0x62)
- Option+Right: ESC+f (0x1b 0x66)
- Option+Backspace: ESC+DEL (0x1b 0x7f)

These match standard Emacs/readline conventions and work natively in ZSH.

## Key Deliverables

### Scripts
1. `scripts/vm-setup.sh` - Automated VM provisioning
2. `scripts/cal-bootstrap` - Unified VM management
3. `scripts/test-keybindings.sh` - Interactive keybinding tester

### Documentation
1. `docs/bootstrap.md` - Manual setup guide
2. `docs/terminal-keybindings-test.md` - Test plan and results
3. `PLAN.md` - Implementation plan (Phase 0 complete)
4. `docs/roadmap.md` - Phase overview (Phase 0 complete)
5. `docs/phase0-completion-summary.md` - This document

### VM Configuration
- Base VM with 4 CPU, 8GB RAM, 80GB disk
- All three agents installed and verified
- GitHub CLI authenticated
- Terminal environment optimized
- Clean snapshot for rollback

## Usage Instructions

### Initial Setup
```bash
# On host: Install Tart and create VM
brew install cirruslabs/cli/tart
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-dev
tart set cal-dev --cpu 4 --memory 8192 --disk-size 80
tart run cal-dev --no-graphics &
sleep 30

# Copy and run setup script
scp scripts/vm-setup.sh admin@$(tart ip cal-dev):~/
ssh admin@$(tart ip cal-dev)
chmod +x ~/vm-setup.sh
./vm-setup.sh

# Authenticate with GitHub
gh auth login

# Create safety snapshot
tart stop cal-dev
tart clone cal-dev cal-dev-pristine
tart run cal-dev --no-graphics &
```

### Daily Use
```bash
# Start VM
tart run cal-dev --no-graphics &
sleep 30 && ssh admin@$(tart ip cal-dev)

# Use agents
claude      # Claude Code
agent       # Cursor CLI
opencode    # opencode
```

### Snapshot Management
```bash
# List snapshots
scripts/cal-bootstrap --snapshot list

# Create snapshot
scripts/cal-bootstrap --snapshot create my-snapshot

# Restore snapshot
scripts/cal-bootstrap --snapshot restore my-snapshot
```

## Success Criteria

- ✅ **Isolation verified** - VM provides complete filesystem isolation
- ✅ **Agent parity** - All three agents work identically to local
- ✅ **Terminal UX** - All keybindings work correctly (tested comprehensively)
- ✅ **Recovery** - Snapshot management via cal-bootstrap
- ✅ **Automation** - Setup and VM management are scripted
- ✅ **Documentation** - Complete guides for setup, testing, and usage

## Next Phase

Once Phase 0 is complete, **Phase 1: CLI Foundation** can begin.

Goals:
- Replace manual Tart commands with `cal isolation` CLI
- Go project scaffolding
- Tart wrapper (`internal/isolation/tart.go`)
- Configuration management (`~/.cal/config.yaml`)
- CLI commands: `init`, `start`, `stop`, `ssh`, `snapshot`

See `PLAN.md` for Phase 1 implementation details.

## Historical Context

This snapshot documents Phase 0 at a point in time. The project evolved with cal-bootstrap providing comprehensive VM management.

**For current status, see [PLAN.md](../PLAN.md)**
