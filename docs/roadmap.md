# Roadmap

> **Quick reference derived from [PLAN.md](PLAN.md)** - the authoritative source for status and TODOs.
>
> See also: [SPEC](SPEC.md) (technical requirements) | [ADR-001](adr/ADR-001-cal-isolation.md) (design decisions)

## Phase 0: Bootstrap (Mostly Complete - 4 TODOs in 0.8, 8 new TODOs in 0.10)
Automated Tart setup for immediate safe agent use.
- [x] Research Tart
- [x] Document manual process
- [x] Create automated vm-setup script
- [x] Set up base VM
- [x] Install agents, create snapshot
- [x] Create keybinding test plan
- [x] Execute keybinding tests (all working correctly)
- [x] **Create cal-bootstrap script** - unified VM management
  - `--init`: Create VMs, install tools, setup SSH keys
  - `--run`: Start VM and SSH in
  - `--restart`: Restart VM and SSH in
  - `--stop`: Stop VM
  - `--snapshot`: List, create, restore, delete snapshots
- [x] **macOS Auto-Login for Screen Sharing** - Fixed lock screen issue
- [x] **Keychain Access for Cursor Agent** - Implementation complete
  - [x] Implement keychain unlock in vm-setup.sh
  - [x] Implement keychain unlock in cal-bootstrap
  - [x] Create test script and documentation
  - [ ] **USER TODO: Complete testing** (see TESTING.md)
- [x] **VM Management Improvements** (6/10 complete)
  - [x] Fix opencode installation (added Go fallback)
  - [x] Simplify --init auth flow (removed verification prompt)
  - [x] Add --restart option
  - [x] Add Screen Sharing instructions for login failures
  - [x] Add git status warning on restore
  - [x] Simplify snapshot list output
  - [ ] Check VM keyboard layout
  - [ ] Investigate High Performance Screen Sharing issues
  - [ ] Create VM detection capability for agents
- [x] **SOCKS Proxy Support** (Phase 0.9 - Complete)
  - [x] Implement SSH SOCKS tunnel (VM→Host)
  - [x] Add HTTP-to-SOCKS bridge (gost)
  - [x] Add --socks on/off/auto flag
  - [x] Auto-detection of network connectivity
  - [x] Restricted SSH keys (port-forwarding only)
  - [x] VM commands (start_socks, stop_socks, status)
  - [x] Documentation (socks-proxy.md)
  - [x] Update architecture.md and bootstrap.md
 - [ ] **Init Improvements and Enhancements** (Phase 0.10 - Pending)
   - [ ] Add option to sync git repos on init
   - [ ] Try to install Tart automatically during init
   - [ ] Add Cursor API key auth login support
   - [ ] Consider using GUIDs for VM/snapshot names
   - [ ] Verify opencode login flow is fixed
   - [ ] Add Codex GitHub CLI Antigravity tools installation
   - [x] Renamed cal-initialised to cal-init
   - [x] Create code directory in user home during --init
   - [ ] Make `--init` safer with pre-deletion checks and warnings

## Phase 1: CLI Foundation
Basic CLI wrapper around Tart.
- [ ] Project structure (Go monorepo)
- [ ] `cal isolation init/start/stop/ssh`
- [ ] Config management (`~/.cal/`)
- [ ] Snapshot management

## Phase 2: Agent Integration
Seamless agent launching with safety UX.
- [ ] Launch confirmation screen
- [ ] Status banner (green = safe)
- [ ] SSH tunnel with overlay
- [ ] Claude Code / opencode / Cursor integration

## Phase 3: GitHub Workflow
Complete git workflow from VM.
- [ ] `clone` with branch creation
- [ ] `commit`, `push`, `pr`
- [ ] Status display, exit prompts

## Phase 4: Environment Plugins
Pluggable dev environments.
- [ ] Plugin manifest schema
- [ ] Core plugins: ios, android, node, python, go, rust
- [ ] VM templates

## Phase 5: TUI & Polish
Full terminal UI experience.
- [ ] Workspace selector
- [ ] Real-time status
- [ ] Log streaming
- [ ] Multiple VMs

## Future
- Native macOS GUI (SwiftUI)
- Menu bar integration
