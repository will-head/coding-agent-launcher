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

**Commands:** `go build -o cal ./cmd/cal` | `go test ./...` | `staticcheck ./...`

---

## Core Rules

### CAL_VM Auto-Approve

The agent **MUST** verify VM status at session start by running `echo $CAL_VM` before any approval-gated step:
- `CAL_VM=true` → Display "Running in cal-dev VM (isolated environment)" → auto-approve enabled
- Any other value (empty, unset, `false`, etc.) → Display "Running on HOST machine (not isolated)" → require all approvals
- **Fail-safe:** If the check cannot be performed or returns unexpected output, default to HOST (require approval)
- **Never assume VM status** — always verify explicitly

When `CAL_VM=true` (confirmed via explicit check):
- All operations proceed without user confirmation
- EXCEPTION: Destructive remote git operations always require approval:
  - `push --force` (overwrites remote history)
  - `push --delete` / deleting remote branches
- Local-only operations (reset, checkout, clean, etc.) are allowed — GitHub is the restore point
- This applies to ALL workflows (Interactive, Bug Cleanup, Documentation, etc.)

When `CAL_VM` is not true (running on HOST):
- Standard workflow approvals apply as documented
- **When in doubt, require approval**

### Workflow Modes

**Interactive** is the default workflow unless user specifies otherwise or changes are docs-only.

Routing rules:
- "bug cleanup" → Bug Cleanup workflow
- "refine" / "refinement" → Refine workflow
- "create PR" → Create PR workflow
- "review PR" → Review & Fix PR workflow
- "update PR" → Update PR workflow (rare fallback for architectural issues)
- "test PR" → Test PR workflow
- "merge PR" → Merge PR workflow
- Documentation-only changes → Documentation workflow

**If unclear, ask user explicitly which workflow to use.**

See [WORKFLOWS.md](docs/WORKFLOWS.md) for complete index, quick reference table, shared conventions, and detailed procedures.

### TODOs
- **`PLAN.md` and phase TODO files are the single source of truth** for all TODOs
- Phase overview in `PLAN.md`, detailed TODOs in `docs/PLAN-PHASE-XX-TODO.md`
- **Completed items must be moved from TODO to DONE files** (e.g., `PLAN-PHASE-XX-TODO.md` → `PLAN-PHASE-XX-DONE.md`)
  - On merge: move with PR number and date
  - On PR closure: move with closure reason
  - On direct implementation: move with completion date
- Phase complete only when ALL items moved from TODO to DONE
- Code TODOs must also be tracked in phase TODO files

### ADRs and PRDs
**Never modify `docs/adr/*` or `docs/prd/*`** - ADRs and PRDs are immutable historical records.
Create new ADR/PRD to supersede if needed.

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
- Run commands without user approval (Interactive workflow — unless `CAL_VM=true`, see [CAL_VM Auto-Approve](#cal_vm-auto-approve))
- Commit without user approval (Interactive workflow — unless `CAL_VM=true`)
- Commit to main branch (Create PR workflow)
- Perform destructive remote git operations without approval (`push --force`, `push --delete` — even when `CAL_VM=true`)
- Commit with failing tests or build
- Skip code review for code/script changes (Interactive workflow)
- Modify ADR or PRD files
- Mark TODOs as `[x]` in TODO files - always move completed items to DONE files
- Mark phase complete with items remaining in TODO file

---

## Quick Workflow Selection

**When user enters a single `.` as their prompt:**

1. Read `docs/WORKFLOWS.md`
2. Present numbered workflow list (see [WORKFLOWS.md Quick Reference](docs/WORKFLOWS.md#quick-reference))
3. Wait for user to select a number
4. Run the chosen workflow following its standard procedure

---

## Session Start

1. **Determine workflow** - If unclear, ask user (see [Workflow Modes](#workflow-modes) routing rules)
2. **Read and reiterate workflow** - Follow [Session Start Procedure](docs/WORKFLOWS.md#session-start-procedure) from Shared Conventions
3. **Check environment** - Run `echo $CAL_VM` (must happen before any approval-gated step):
   - `CAL_VM=true`: Display "Running in cal-dev VM (isolated environment)" — approvals auto-granted
   - Any other value (empty, unset, etc.): Display "Running on HOST machine (not isolated)" — approvals required
   - If check fails: default to HOST (require approval)
4. Run `git status` and `git fetch` (ask approval on HOST; auto-approved when `CAL_VM=true`)
5. Read `PLAN.md` for overview and current phase status
6. Read active phase TODO file (e.g., `docs/PLAN-PHASE-00-TODO.md`) for current tasks
7. Report status and suggest next steps using [Numbered Choice Presentation](docs/WORKFLOWS.md#numbered-choice-presentation)

**Note:** Only read the active phase TODO file. Do not read future phase files until the current phase is complete.

---

## Documentation

**Planning:** [PLAN.md](PLAN.md) **(source of truth)** | [STATUS.md](STATUS.md) | Phase TODO/DONE files in `docs/PLAN-PHASE-XX-{TODO,DONE}.md` (phases 00-05)

**Important:** Read only the active phase TODO file per session.

**Operational:** [ADR-002](docs/adr/ADR-002-tart-vm-operational-guide.md) | [bootstrap.md](docs/bootstrap.md)

**Reference:** [WORKFLOWS.md](docs/WORKFLOWS.md) (index + shared conventions) | [WORKFLOW-*.md](docs/) | [architecture.md](docs/architecture.md) | [cli.md](docs/cli.md) | [SPEC.md](docs/SPEC.md) | [CODING_STANDARDS.md](CODING_STANDARDS.md)

**Historical (immutable):** [ADR-001](docs/adr/ADR-001-cal-isolation.md) | [ADR-002](docs/adr/ADR-002-tart-vm-operational-guide.md) | [PRD-001](docs/prd/prd-001-tart-vm-gui-access.md)
