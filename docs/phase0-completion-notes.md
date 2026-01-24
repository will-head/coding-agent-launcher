# Phase 0 Reference Document

> ⚠️ **NOTE:** This is a historical reference snapshot documenting Phase 0 work.
> **For current status and TODOs, see [PLAN.md](../PLAN.md)** - the single source of truth.

**Snapshot Date:** January 17, 2026  
**Current Status:** See [PLAN.md Current Status section](PLAN.md#current-status)

## Summary

This document captures the state of Phase 0 (Bootstrap) at a point in time. All objectives were achieved, providing a fully functional manual VM setup process with the cal-bootstrap script for VM management.

## Completed Deliverables

### 1. Base VM Setup
- ✅ Automated vm-setup script (`scripts/vm-setup.sh`)
- ✅ Installs all three agents (Claude Code, Cursor CLI, opencode)
- ✅ Configures GitHub CLI
- ✅ Sets up proper terminal environment (TERM, keybindings, PATH)

### 2. VM Management
- ✅ cal-bootstrap script (`scripts/cal-bootstrap`)
  - Unified VM management CLI
  - `--init`: Create and configure VMs
  - `--run`: Start VM and SSH in
  - `--stop`: Stop VM
  - `--snapshot`: Snapshot management

### 3. Terminal Environment
- ✅ Comprehensive keybinding test plan
- ✅ All keybindings verified working (navigation, editing, Emacs-style, Option/Alt)
- ✅ Proper TERM setting (xterm-256color)
- ✅ Arrow key history navigation configured

### 4. Documentation
- ✅ Complete bootstrap guide
- ✅ Manual setup instructions
- ✅ Automated workflow documentation
- ✅ Usage examples and troubleshooting

## Key Features

### cal-bootstrap Capabilities

The cal-bootstrap script provides unified VM management:

- `--init`: Initialize VMs with tools and SSH keys
- `--run`: Start VM and automatically SSH in
- `--stop`: Stop the VM
- `--snapshot list/create/restore/delete`: Snapshot management
- Keychain unlock automation for agent authentication
- Background process cleanup on exit

## Manual Steps

GitHub CLI authentication is a one-time manual step:

```bash
# After VM setup
ssh admin@<vm-ip>
gh auth login  # Interactive OAuth flow
```

This requires interactive OAuth, which cannot be automated without storing tokens. This is by design for security.

## Testing Status

- ✅ Agent installation verified
- ✅ Keybindings tested comprehensively
- ✅ Rollback to snapshots tested
- ✅ Background VM cleanup tested
- ✅ Keychain unlock automation tested

## Historical Context

This snapshot documents the completion of Phase 0 at a point in time. The project has since evolved with the cal-bootstrap script providing comprehensive VM management capabilities.

For current project status, see:
- [PLAN.md](../PLAN.md) - Current status and TODOs
- [roadmap.md](roadmap.md) - Phase overview
