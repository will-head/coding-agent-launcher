# Roadmap

> **Quick reference derived from [PLAN.md](PLAN.md)** - the authoritative source for status and TODOs.
>
> See also: [SPEC](SPEC.md) (technical requirements) | [ADR-001](adr/ADR-001-cal-isolation.md) (design decisions)

## Phase 0: Bootstrap (Mostly Complete - Testing Pending)
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
  - `--stop`: Stop VM
  - `--snapshot`: List, create, restore, delete snapshots
- [x] **macOS Auto-Login for Screen Sharing** - Fixed lock screen issue
- [x] **Keychain Access for Cursor Agent** - Implementation complete
  - [x] Implement keychain unlock in vm-setup.sh
  - [x] Implement keychain unlock in cal-bootstrap
  - [x] Create test script and documentation
  - [ ] **USER TODO: Complete testing** (see TESTING.md)

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
