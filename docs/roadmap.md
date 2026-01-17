# Roadmap

> Extracted from [ADR-001](adr/ADR-001-cal-isolation.md) for quick reference.
>
> See also: [SPEC](SPEC.md) (technical requirements) | [PLAN](PLAN.md) (implementation steps)

## Phase 0: Bootstrap 🔄 (Mostly Complete)
Manual Tart setup for immediate safe agent use.
- [x] Research Tart
- [x] Document manual process
- [x] Create automated vm-setup script
- [x] Set up base VM
- [x] Install agents, create snapshot
- [x] Create keybinding test plan
- [x] Execute keybinding tests (all working correctly)
- [x] Create automated reset-vm script
- [ ] **Complete reset-vm.sh improvements** (6 TODOs remaining)
  - Cleanup trap, password-less SSH, configurable credentials
  - --yes flag, shellcheck validation, full automation

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
