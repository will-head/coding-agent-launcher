# Phase 0 Reference Document

> ⚠️ **NOTE:** This is a reference snapshot documenting Phase 0 work.
> **For current status and TODOs, see [PLAN.md](PLAN.md)** - the single source of truth.

**Snapshot Date:** January 17, 2026  
**Current Status:** See [PLAN.md Current Status section](PLAN.md#current-status)

## Overview

Phase 0 (Bootstrap) is mostly complete. The manual Tart VM setup process is fully documented and automated, providing immediate safe agent use with excellent terminal behavior. However, there are 6 remaining improvements to the `reset-vm.sh` script identified during code review that need to be completed before Phase 0 can be considered fully done.

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

- 🔄 **`scripts/reset-vm.sh`** - Automated VM reset workflow (6 TODOs remaining)
  - ✅ Interactive confirmation prompt
  - ✅ Automatic VM state detection and cleanup
  - ✅ Waits for VM boot and SSH availability
  - ✅ Copies vm-setup.sh to freshly reset VM
  - ❌ TODO: Add cleanup trap for background VM process
  - ❌ TODO: Automate SSH/SCP password authentication
  - ❌ TODO: Make VM credentials configurable
  - ❌ TODO: Add --yes flag for non-interactive mode
  - ❌ TODO: Run shellcheck and address warnings
  - ❌ TODO: Fully automate post-reset setup steps

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
1. `scripts/vm-setup.sh` - Automated VM provisioning (166 lines)
2. `scripts/reset-vm.sh` - Automated VM reset (existing)
3. `scripts/test-keybindings.sh` - Interactive keybinding tester (new)

### Documentation
1. `docs/bootstrap.md` - Manual setup guide
2. `docs/terminal-keybindings-test.md` - Test plan and results
3. `docs/PLAN.md` - Implementation plan (Phase 0 complete)
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

### Reset VM
```bash
# Automated reset (recommended)
scripts/reset-vm.sh cal-dev cal-dev-pristine

# Manual reset
tart stop cal-dev && tart delete cal-dev && tart clone cal-dev-pristine cal-dev
```

## Success Criteria

- ✅ **Isolation verified** - VM provides complete filesystem isolation
- ✅ **Agent parity** - All three agents work identically to local
- ✅ **Terminal UX** - All keybindings work correctly (tested comprehensively)
- ✅ **Recovery** - Snapshot rollback works (<2 minutes with automated script)
- 🔄 **Automation** - Setup and reset are scripted (reset-vm.sh needs 6 improvements)
- ✅ **Documentation** - Complete guides for setup, testing, and usage

## Remaining Work for Phase 0

Before moving to Phase 1, complete the 6 TODOs in `reset-vm.sh`:

1. **Add cleanup trap** - Kill background VM process on script exit
2. **Password-less SSH** - Set up ssh-copy-id or use sshpass
3. **Configurable credentials** - Support VM_USER/VM_PASSWORD env vars
4. **--yes flag** - Enable non-interactive mode for automation
5. **Shellcheck validation** - Run shellcheck and fix warnings
6. **Full automation** - Automatically run vm-setup.sh and handle gh auth

These improvements will make the reset workflow truly zero-touch.

## Next Phase

Once Phase 0 is complete, **Phase 1: CLI Foundation** can begin.

Goals:
- Replace manual Tart commands with `cal isolation` CLI
- Go project scaffolding
- Tart wrapper (`internal/isolation/tart.go`)
- Configuration management (`~/.cal/config.yaml`)
- CLI commands: `init`, `start`, `stop`, `ssh`, `snapshot`

See `docs/PLAN.md` for Phase 1 implementation details.

## Conclusion

Phase 0 is very close to completion. The manual VM setup is well-automated, the terminal environment is excellent (no broken keybindings), and the workflow is functional for immediate use.

**Users can safely run AI coding agents in isolated VMs TODAY** with a fully functional terminal experience and rapid rollback capability. The remaining work is polish to make the reset workflow fully automated.

🔄 **Phase 0: 6 TODOs remaining before complete**
