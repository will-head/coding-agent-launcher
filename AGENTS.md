# Agent Context

## Project

**CAL** (Coding Agent Loader) - VM-based sandbox for AI coding agents in Tart macOS VMs.

**Stack:** Go + Charm (bubbletea/lipgloss/bubbles) + Cobra + Viper

**Structure:**
```
cmd/cal/main.go           # Entry point
internal/                  # tui/, isolation/, agent/, env/, github/, config/
scripts/                   # Shell scripts (cal-bootstrap, vm-setup, vm-auth)
```

**Commands:** `go build -o cal ./cmd/cal` | `go test ./...` | `golangci-lint run`

---

## Core Rules

### Command Approval
**Ask user approval before running ANY command** (git, build, scripts, installs).
Exception: Read/Grep/Glob tools for searching code.

### Git Workflow (8-Step for Code Changes)

1. **Implement** - TDD: write test first, then code
2. **Test** - Ask approval, run `go test ./...`, stop if fail
3. **Build** - Ask approval, run `go build -o cal ./cmd/cal`, stop if fail
4. **Code Review** - Review quality, security, conventions
5. **Present Review** - Show findings, **STOP for user approval**
6. **Update Docs** - Update affected docs, sync TODOs to PLAN.md
7. **Commit** - Ask approval, use Co-Authored-By line

**Docs-only changes:** Skip steps 2-5, still require user approval to commit.

See `docs/WORKFLOW.md` for detailed procedures.

### TODOs
- **`docs/PLAN.md` is the single source of truth** for all TODOs
- Phase complete only when ALL checkboxes are `[x]`
- Code TODOs must also be in PLAN.md

### ADRs
**Never modify `docs/adr/*`** - ADRs are immutable historical records.
Create new ADR to supersede if needed.

---

## Prohibitions

**Never:**
- Run commands without user approval
- Commit without user approval
- Commit with failing tests or build
- Skip code review for code/script changes
- Modify ADR files
- Mark phase complete with unchecked TODOs

---

## Session Start

1. Ask approval, then run `git status` and `git fetch`
2. Read `docs/PLAN.md` for TODOs and current phase
3. Acknowledge the Git Workflow (8-step process) to confirm understanding
4. Report status and suggest next steps

---

## Documentation

**Immutable (never modify):**
- [ADR-001](docs/adr/ADR-001-cal-isolation.md) - Design decisions

**Planning (read for tasks):**
- [PLAN.md](docs/PLAN.md) - TODOs and implementation tasks **(source of truth)**
- [SPEC.md](docs/SPEC.md) - Technical requirements

**Reference:**
- [WORKFLOW.md](docs/WORKFLOW.md) - Git workflow details
- [architecture.md](docs/architecture.md) - System design
- [cli.md](docs/cli.md) - Command reference
- [bootstrap.md](docs/bootstrap.md) - VM setup
- [roadmap.md](docs/roadmap.md) - Phase summary
