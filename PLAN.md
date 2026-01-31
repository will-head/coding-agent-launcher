# CAL Implementation Plan

> 🎯 **THIS IS THE SINGLE SOURCE OF TRUTH FOR PROJECT STATUS AND TODOS**
>
> - Phase completion is determined by checkboxes in phase TODO files
> - All TODOs must be tracked in phase files (code TODOs should reference this file)
> - Operational guide: [ADR-002](docs/adr/ADR-002-tart-vm-operational-guide.md)
> - Original design: [ADR-001](docs/adr/ADR-001-cal-isolation.md) (immutable)

## Current Status

**Phase 0 (Bootstrap): Complete** - Core functionality documented in [ADR-002](docs/adr/ADR-002-tart-vm-operational-guide.md). Only 1 optional future improvement remains (see [Phase 0 TODO](docs/PLAN-PHASE-00-TODO.md) for details).

Three-tier VM architecture (cal-clean, cal-dev, cal-init), automated setup via cal-bootstrap, transparent proxy for network reliability, comprehensive git safety checks, VM detection capabilities, first-run/logout git automation, Tart cache sharing for nested VMs, and Ghostty terminal emulator are all operational.

**Active Work:** Phase 0 is feature-complete. Ready to begin Phase 1 (CLI Foundation).

---

## Phases Overview

| Phase | Name | Status | Outstanding TODOs | Detail Files |
|-------|------|--------|-------------------|--------------|
| 0 | Bootstrap | Complete | 1 (optional) | [TODO](docs/PLAN-PHASE-00-TODO.md) • [DONE](docs/PLAN-PHASE-00-DONE.md) |
| 1 | CLI Foundation | Not Started | ~50 | [TODO](docs/PLAN-PHASE-01-TODO.md) • [DONE](docs/PLAN-PHASE-01-DONE.md) |
| 2 | Agent Integration & UX | Not Started | ~20 | [TODO](docs/PLAN-PHASE-02-TODO.md) • [DONE](docs/PLAN-PHASE-02-DONE.md) |
| 3 | GitHub Workflow | Not Started | ~15 | [TODO](docs/PLAN-PHASE-03-TODO.md) • [DONE](docs/PLAN-PHASE-03-DONE.md) |
| 4 | Environment Plugin System | Not Started | ~25 | [TODO](docs/PLAN-PHASE-04-TODO.md) • [DONE](docs/PLAN-PHASE-04-DONE.md) |
| 5 | TUI & Polish | Not Started | ~15 | [TODO](docs/PLAN-PHASE-05-TODO.md) • [DONE](docs/PLAN-PHASE-05-DONE.md) |

### Phase Goals

**Phase 0 (Bootstrap):** Manual VM setup and bootstrap automation
**Deliverable:** Three-tier VM architecture with automated setup and safety features

**Phase 1 (CLI Foundation):** Replace manual Tart commands with `cal isolation` CLI
**Deliverable:** Working `cal isolation` CLI that wraps Tart operations

**Phase 2 (Agent Integration & UX):** Seamless agent launching with safety UI
**Deliverable:** `cal isolation run <workspace>` launches agent with full UX

**Phase 3 (GitHub Workflow):** Complete git workflow from VM
**Deliverable:** Clone → Edit → Commit → PR workflow working

**Phase 4 (Environment Plugin System):** Pluggable development environments
**Deliverable:** Multi-platform development with pluggable environments

**Phase 5 (TUI & Polish):** Full terminal UI experience
**Deliverable:** Complete TUI for CAL

---

## Recommended Order of Implementation

### Immediate (Phase 0)
1. Complete manual VM setup following bootstrap guide
2. Verify all agents work
3. Create safety snapshot
4. Begin using for development
5. Complete outstanding Phase 0 enhancements

### Short-term (Phase 1)
1. Project scaffolding (1.1)
2. Configuration management (1.2)
3. Tart wrapper (1.3)
4. Snapshot management (1.4)
5. SSH management (1.5)
6. CLI commands (1.6)
7. Git safety checks (1.7)
8. Proxy management (1.8)
9. VM lifecycle automation (1.9)
10. Helper script deployment (1.10)

### Medium-term (Phases 2-3)
1. Status banner (2.2)
2. Launch confirmation (2.3)
3. Agent management (2.4)
4. GitHub auth (3.1)
5. Clone/commit/PR (3.2-3.4)
6. TUI framework (2.1)
7. SSH tunnel with overlay (2.5)

### Long-term (Phases 4-5)
1. Plugin system (4.1-4.4)
2. Core plugins (4.3)
3. Templates (4.5)
4. Full TUI (5.1-5.4)

---

## Testing Strategy

### Unit Tests
- Configuration parsing
- Git command generation
- SSH command building

### Integration Tests
- VM lifecycle
- Snapshot operations
- SSH connectivity

### End-to-End Tests
- Full workflow: init → start → clone → run → commit → pr
- Agent installation verification
- Rollback verification

### Manual Testing
- Destructive operation containment
- Network interruption recovery
- VM crash recovery

---

## Dependencies to Install (for development)

```bash
# On host (for building CAL)
brew install go
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Verify
go version
golangci-lint --version
```

---

## Next Action

**Phase 0 is complete.** All operational learnings captured in [ADR-002](docs/adr/ADR-002-tart-vm-operational-guide.md).

**Begin Phase 1 (CLI Foundation):**
1. Project scaffolding and Go module setup (1.1)
2. Configuration management with VM config file awareness (1.2)
3. Tart wrapper with cache sharing, VNC experimental, BSD awk compat (1.3)
4. Build out remaining subsystems per ADR-002 operational requirements

Read [PLAN-PHASE-01-TODO.md](docs/PLAN-PHASE-01-TODO.md) for detailed tasks.
See [ADR-002 § Phase 1 Readiness](docs/adr/ADR-002-tart-vm-operational-guide.md) for command mapping and operational requirements.
