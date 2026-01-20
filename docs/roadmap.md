# Roadmap

> **Quick reference derived from [PLAN.md](PLAN.md)** - the authoritative source for status and TODOs.
>
> See also: [SPEC](SPEC.md) (technical requirements) | [ADR-001](adr/ADR-001-cal-isolation.md) (design decisions)

## Phase 0: Bootstrap (Mostly Complete - multiple improvements pending)
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
- [x] **Transparent Proxy Support** (Phase 0.9 - Complete, migrated to sshuttle)
  - [x] Implement transparent proxy via sshuttle
  - [x] Add bootstrap SOCKS proxy for --init phase
  - [x] Add --proxy on/off/auto flag
  - [x] Auto-detection of network connectivity
  - [x] VM→Host SSH keys with host key verification
  - [x] VM commands (proxy-start, proxy-stop, proxy-status, proxy-log)
  - [x] Auto-start in vm-auth.sh
  - [x] Documentation (proxy.md)
  - [x] Update architecture.md and bootstrap.md
 - [ ] **Init Improvements and Enhancements** (Phase 0.10 - Pending)
   - [ ] Add option to sync git repos on init
   - [ ] Try to install Tart automatically during init
   - [ ] Consider using GUIDs for VM/snapshot names
   - [ ] Add Codex GitHub CLI Antigravity tools installation
   - [ ] Check and fix auth flows (GH PAT, opencode status check)
   - [x] Renamed cal-initialised to cal-init
   - [x] Create code directory in user home during --init
   - [ ] Make `--init` safer with pre-deletion checks and warnings
   - [ ] Install all packages required for full Go development in cal-dev during --init
 - [ ] **cal-bootstrap Script Enhancements**
   - [ ] Show VM/snapshot sizes in `--snapshot list`
   - [ ] Allow `--snapshot delete` to accept multiple VM names
 - [ ] **Session State Management** (Phase 0.11 - Future)
   - [ ] Implement constant context state persistence for seamless recovery
 - [ ] **Documentation Cleanup**
   - [ ] Clean up AGENTS.md (fix refs, merge duplicates, add TDD to Step 1)

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
