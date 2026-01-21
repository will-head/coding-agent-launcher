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

User specifies workflow at session start. Default is **Standard** unless Create PR or Documentation is specified.

| Mode | Use Case | Details |
|------|----------|---------|
| **Standard** | Default for code changes | 8-step with approvals |
| **Create PR** | PR-based development | 6-step, no approvals, all changes via PR |
| **Review PR** | Code review of PRs | 6-step, no approvals, autonomous review |
| **Update PR** | Address PR feedback | 8-step, no approvals, autonomous fixes |
| **Merge PR** | Merge reviewed PRs | 8-step with approvals, merge to main |
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

### Create PR Workflow (6-Step)

**No permission needed** for tests/builds/PR creation. **No destructive operations.**
**Never commit to main** - all changes via PR on `create-pr/feature-name` branch.

1. **Read Coding Standards** - Review CODING_STANDARDS.md to avoid past mistakes
2. **Implement** - TDD: write test first, then code (on `create-pr/` branch)
3. **Test** - Run `go test ./...`, must pass
4. **Build** - Run `go build -o cal ./cmd/cal`, must pass
5. **Create PR** - Push branch, create PR with manual testing instructions
6. **Update PRS.md** - Add PR to "Awaiting Review" section, move to next task

### Review PR Workflow (6-Step)

**No permission needed** for review operations. **Autonomous code review and PR updates.**

1. **Read PRS.md** - Get first PR from "Awaiting Review" section
2. **Fetch PR** - Use `gh pr checkout <PR#>` to review locally
3. **Review Code** - Comprehensive review of quality, architecture, security, best practices
4. **Update Standards** - Add recurring error patterns to CODING_STANDARDS.md
5. **Submit Review** - Use `gh pr review` to APPROVE or REQUEST_CHANGES
6. **Update PRS.md** - Switch to main, move PR to "Reviewed" or "Awaiting Changes"

### Update PR Workflow (8-Step)

**No permission needed** for fixes/tests/builds/push. **Autonomous implementation of review feedback.**
**Never commit to main** - work on existing PR branches.

1. **Read Coding Standards** - Review CODING_STANDARDS.md to avoid past mistakes
2. **Read PRS.md** - Get first PR from "Awaiting Changes" section
3. **Fetch PR** - Use `gh pr checkout <PR#>` to check out branch
4. **Analyze Review** - Use `gh pr view <PR#>` to understand feedback
5. **Implement Changes** - Apply fixes based on review feedback, TDD if needed
6. **Test** - Run `go test ./...`, must pass
7. **Build** - Run `go build -o cal ./cmd/cal`, must pass
8. **Push and Update PRS.md** - Push changes, switch to main, move PR to "Awaiting Review"

### Merge PR Workflow (8-Step)

**Ask user approval before running ANY command.** Merge reviewed PRs into main branch.
**Use merge commit strategy** to preserve full PR history.

1. **Read PRS.md** - Get first PR from "Reviewed" section
2. **Fetch PR Details** - Use `gh pr view <PR#>` to verify PR is ready to merge
3. **Merge PR** - Ask approval, run `gh pr merge <PR#> --merge` to merge into main
4. **Update Local Main** - Ask approval, switch to main and run `git pull` to update
5. **Delete Branch** - Ask approval, delete local and remote PR branch
6. **Update PRS.md** - Move PR to "Merged" section with merge date
7. **Update PLAN.md** - Mark related TODOs as complete if applicable
8. **Commit Docs** - Ask approval, commit updated documentation with Co-Authored-By line

### Documentation Workflow

For changes **only** to `.md` files or code comments:
- Skip tests, build, and code review
- Still require user approval to commit (Standard) or create PR (Create PR)

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
- Commit to main branch (Create PR workflow)
- Perform destructive operations without approval (all workflows)
- Commit with failing tests or build
- Skip code review for code/script changes (Standard workflow)
- Modify ADR files
- Mark phase complete with unchecked TODOs

---

## Session Start

1. **Determine workflow** - If user hasn't specified or it's unclear which workflow to use, ask explicitly:
   - Standard (8-step with approvals)
   - Create PR (6-step, autonomous, PR-based)
   - Review PR (6-step, autonomous review)
   - Update PR (8-step, autonomous fixes)
   - Merge PR (8-step with approvals)
   - Documentation (docs-only)
2. Ask approval, then run `git status` and `git fetch`
3. Read `docs/PLAN.md` for TODOs and current phase
4. Acknowledge the active workflow mode to confirm understanding
5. Report status and suggest next steps

---

## Documentation

**Planning (read for tasks):**
- [PLAN.md](docs/PLAN.md) - TODOs and implementation tasks **(source of truth)**
- [PRS.md](PRS.md) - Pull requests tracking (Create PR workflow)

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
