# Roadmap

> Quick reference derived from [PLAN.md](../PLAN.md) - the authoritative source for status and TODOs.
>
> See also: [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) (operational guide) | [SPEC](SPEC.md) (technical spec)

## Phase 0: Bootstrap (Complete)
Automated Tart setup for immediate safe agent use.

**All tasks complete** — see [PLAN-PHASE-00-DONE.md](PLAN-PHASE-00-DONE.md) for full details.

**Highlights:**
- [x] Three-tier VM architecture (cal-clean → cal-dev → cal-init)
- [x] Automated vm-setup and vm-auth scripts
- [x] SSH/tmux session management with session persistence (tmux-resurrect)
- [x] Transparent proxy via sshuttle for corporate networks
- [x] Git safety checks before destructive operations
- [x] VM detection for agents (CAL_VM environment variable)
- [x] Keychain auto-unlock for Cursor OAuth authentication
- [x] First-run automation (vm-auth.sh runs automatically after init)
- [x] GUI console with VNC experimental mode (bidirectional clipboard)
- [x] Tart cache sharing for nested VM support
- [x] Auto-install Tart during init if missing
- [x] Full Go development tools in VM
- [x] Documentation (ADR-002 comprehensive operational guide)

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
