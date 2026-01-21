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

### Workflow Modes

User specifies workflow at session start. Default is **Standard** unless GLM or Documentation is specified.

| Mode | Use Case | Details |
|------|----------|---------|
| **Standard** | Default for code changes | 8-step with approvals |
| **GLM** | PR-based development | 5-step, no approvals, all changes via PR |
| **Documentation** | Docs-only changes | Skip tests/build/review |

See `docs/WORKFLOW.md` for detailed procedures.

### Standard Workflow (8-Step)

**Ask user approval before running ANY command** (git, build, scripts, installs).
Exception: Read/Grep/Glob tools for searching code.

1. **Implement** - TDD: write test first, then code
2. **Test** - Ask approval, run `go test ./...`, stop if fail
3. **Build** - Ask approval, run `go build -o cal ./cmd/cal`, stop if fail
4. **Code Review** - Review quality, security, conventions
5. **Present Review** - Show findings, **STOP for user approval**
6. **Update Docs** - Update affected docs, sync TODOs to PLAN.md
7. **Commit** - Ask approval, use Co-Authored-By line

### GLM Workflow (5-Step)

**No permission needed** for tests/builds/PR creation. **No destructive operations.**
**Never commit to main** - all changes via PR on `glm/feature-name` branch.

1. **Implement** - TDD: write test first, then code (on `glm/` branch)
2. **Test** - Run `go test ./...`, must pass
3. **Build** - Run `go build -o cal ./cmd/cal`, must pass
4. **Create PR** - Push branch, create PR with manual testing instructions
5. **Update PRS.md** - Add PR to "Awaiting Review" section, move to next task

### Documentation Workflow

For changes **only** to `.md` files or code comments:
- Skip tests, build, and code review
- Still require user approval to commit (Standard) or create PR (GLM)

### TODOs
- **`docs/PLAN.md` is the single source of truth** for all TODOs
- Phase complete only when ALL checkboxes are `[x]`
- Code TODOs must also be in PLAN.md

### ADRs
**Never modify `docs/adr/*`** - ADRs are immutable historical records.
Create new ADR to supersede if needed.

### Coding Standards
**All code must meet mandatory quality standards.** Common errors to avoid:
- **Code duplication** - Never leave copy-paste artifacts
- **Missing dependency checks** - Always verify external tools before use
- **Documentation mismatches** - Code must match what docs claim
- **Silent error suppression** - Never hide errors with `&>/dev/null`
- **Missing validation** - Check preconditions before operations
- **Dangerous constructs** - Avoid `eval` and injection risks

**Must test all scenarios:** valid inputs, invalid inputs, missing dependencies, auth failures, existing state, network failures.

See [CODING_STANDARDS.md](CODING_STANDARDS.md) for complete requirements and patterns.

---

## Prohibitions

**Never:**
- Run commands without user approval (Standard workflow)
- Commit without user approval (Standard workflow)
- Commit to main branch (GLM workflow)
- Perform destructive operations without approval (all workflows)
- Commit with failing tests or build
- Skip code review for code/script changes (Standard workflow)
- Modify ADR files
- Mark phase complete with unchecked TODOs

---

## Session Start

1. Ask approval, then run `git status` and `git fetch`
2. Read `docs/PLAN.md` for TODOs and current phase
3. Acknowledge the active workflow mode to confirm understanding
4. Report status and suggest next steps

---

## Documentation

**Planning (read for tasks):**
- [PLAN.md](docs/PLAN.md) - TODOs and implementation tasks **(source of truth)**
- [PRS.md](PRS.md) - Pull requests tracking (GLM workflow)

**Operational:**
- [ADR-002](docs/adr/ADR-002-tart-vm-operational-guide.md) - Comprehensive operational guide
- [bootstrap.md](docs/bootstrap.md) - Quick start VM setup

**Reference:**
- [WORKFLOW.md](docs/WORKFLOW.md) - Git workflow details
- [architecture.md](docs/architecture.md) - System design
- [cli.md](docs/cli.md) - Command reference
- [SPEC.md](docs/SPEC.md) - Technical specification

**Historical (immutable):**
- [ADR-001](docs/adr/ADR-001-cal-isolation.md) - Original design decisions
