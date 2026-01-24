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

## Quick Reference

| Workflow | Steps | Approvals | Target | Use Case |
|----------|-------|-----------|--------|----------|
| [Interactive](docs/WORKFLOW-INTERACTIVE.md) | 8 | Required | main branch | Default for code changes |
| [Documentation](docs/WORKFLOW-DOCUMENTATION.md) | 3 | Required | main branch | Docs-only changes |
| [Refine](docs/WORKFLOW-REFINE.md) | 6 | Required | main branch | Refine PLAN.md TODOs |
| [Create PR](docs/WORKFLOW-CREATE-PR.md) | 7 | Not required | PR branch | PR-based development |
| [Review PR](docs/WORKFLOW-REVIEW-PR.md) | 6 | Not required | PR review | Code review of PRs |
| [Update PR](docs/WORKFLOW-UPDATE-PR.md) | 8 | Not required | PR branch | Address review feedback |
| [Test PR](docs/WORKFLOW-TEST-PR.md) | 7 | Test confirmation | PR testing | Manual testing gate |
| [Merge PR](docs/WORKFLOW-MERGE-PR.md) | 8 | Required | main branch | Merge tested PRs |

## Default Workflow

**Interactive** is the default workflow unless:
- User specifies "refine" or "refinement" → use Refine workflow
- User specifies "create PR" → use Create PR workflow
- User specifies "review PR" → use Review PR workflow
- User specifies "update PR" → use Update PR workflow
- User specifies "test PR" → use Test PR workflow
- User specifies "merge PR" → use Merge PR workflow
- Changes are documentation-only → use Documentation workflow

**If unclear, ask user explicitly which workflow to use.**

See `docs/WORKFLOWS.md` for complete index and `docs/WORKFLOW-*.md` for detailed procedures.

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
- Run commands without user approval (Interactive workflow)
- Commit without user approval (Interactive workflow)
- Commit to main branch (Create PR workflow)
- Perform destructive operations without approval (all workflows)
- Commit with failing tests or build
- Skip code review for code/script changes (Interactive workflow)
- Modify ADR files
- Mark phase complete with unchecked TODOs

---

## Quick Workflow Selection

**When user enters a single `.` as their prompt:**

1. Read `docs/WORKFLOWS.md`
2. Present a numbered list of available workflows:
   ```
   Select a workflow:

   1. Interactive - Default for code changes (8-step with approvals)
   2. Documentation - Docs-only changes (3-step with approvals)
   3. Refine - Refine PLAN.md TODOs (6-step with approvals)
   4. Create PR - PR-based development (7-step, autonomous)
   5. Review PR - Code review of PRs (6-step, autonomous)
   6. Update PR - Address review feedback (8-step, autonomous)
   7. Test PR - Manual testing gate (7-step, test confirmation)
   8. Merge PR - Merge tested PRs (8-step with approvals)

   Enter number (1-8):
   ```
3. Wait for user to select a number
4. Run the chosen workflow following its standard procedure

---

## Session Start

1. **Determine workflow** - If user hasn't specified or it's unclear which workflow to use, ask explicitly:
   - Interactive (8-step with approvals)
   - Refine (6-step with approvals, refine TODOs)
   - Create PR (6-step, autonomous, PR-based)
   - Review PR (6-step, autonomous review)
   - Update PR (8-step, autonomous fixes)
   - Test PR (7-step, manual testing gate)
   - Merge PR (8-step with approvals)
   - Documentation (docs-only)
2. **Read and reiterate workflow** - Read the specific workflow file and communicate it to the user:
   - Read the appropriate `docs/WORKFLOW-*.md` file for the selected workflow
   - Summarize the workflow steps and key principles
   - Reiterate the workflow to the user in your own words
   - Confirm understanding of the workflow before proceeding
3. Ask approval, then run `git status` and `git fetch`
4. Read `docs/PLAN.md` for TODOs and current phase
5. Report status and suggest next steps

---

## Documentation

**Planning (read for tasks):**
- [PLAN.md](docs/PLAN.md) - TODOs and implementation tasks **(source of truth)**
- [STATUS.md](STATUS.md) - Project status tracking (refined TODOs and PRs)

**Operational:**
- [ADR-002](docs/adr/ADR-002-tart-vm-operational-guide.md) - Comprehensive operational guide
- [bootstrap.md](docs/bootstrap.md) - Quick start VM setup

**Reference:**
- [WORKFLOWS.md](docs/WORKFLOWS.md) - Index of all workflows with quick reference
- [WORKFLOW-*.md](docs/) - Detailed workflow files (Interactive, Refine, Create PR, Review PR, Update PR, Test PR, Merge PR, Documentation)
- [PR-WORKFLOW-DIAGRAM.md](docs/PR-WORKFLOW-DIAGRAM.md) - Visual PR workflow diagram
- [architecture.md](docs/architecture.md) - System design
- [cli.md](docs/cli.md) - Command reference
- [SPEC.md](docs/SPEC.md) - Technical specification

**Historical (immutable):**
- [ADR-001](docs/adr/ADR-001-cal-isolation.md) - Original design decisions
