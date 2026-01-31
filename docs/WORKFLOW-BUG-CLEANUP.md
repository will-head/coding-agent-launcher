# Bug Cleanup Workflow (10-Step)

> Interactive workflow for resolving tracked bugs from BUGS.md

**Use When:** Fixing bugs tracked in `docs/BUGS.md`

**Key Principles:**
- **Bug-driven** - work items come from `docs/BUGS.md`, not phase TODO files
- **User approval required on HOST** - ask permission before ALL commands (auto-approved when `CAL_VM=true`; see [CAL_VM Auto-Approve](WORKFLOWS.md#cal_vm-auto-approve))
- **Blocking checkpoints** - each step must complete before proceeding
- **Code review mandatory** - all code/script changes reviewed before commit
- **Bug lifecycle** - resolved bugs move from `BUGS.md` to `bugs/README.md`

---

## Overview

The Bug Cleanup workflow is a variant of the Interactive workflow where work items are sourced from `docs/BUGS.md` instead of phase TODO files. It follows the same 10-step process with user approvals at each checkpoint on HOST (auto-approved when `CAL_VM=true`; see [CAL_VM Auto-Approve](WORKFLOWS.md#cal_vm-auto-approve)).

**Target:** main branch (direct commits)
**Approvals:** Required on HOST for all commands (auto-approved when `CAL_VM=true`)
**Steps:** 10 (same as Interactive)

---

## Session Start Procedure

Follow [Session Start Procedure](WORKFLOWS.md#session-start-procedure) from Shared Conventions, highlighting:
- This is the Bug Cleanup workflow (Interactive variant for bug fixes)
- Key principles: bug-driven, user approval required on HOST (auto-approved when `CAL_VM=true`), blocking checkpoints, code review mandatory
- Work items sourced from `docs/BUGS.md`

**Then:**
1. Read `docs/BUGS.md` to get list of active bugs
2. Present active bugs using [Numbered Choice Presentation](WORKFLOWS.md#numbered-choice-presentation)
3. Wait for user to select a bug
4. Read the full bug report (e.g., `docs/bugs/BUG-NNN-slug.md`) for the selected bug

---

## Documentation-Only Changes

For bug fixes that only affect `.md` files or code comments:

1. Make changes
2. Ask user approval to commit (auto-approved when `CAL_VM=true`)
3. Commit and push

**Skip:** tests, build, and code review for docs-only changes.

---

## Code/Script Changes (Full 10-Step Workflow)

**Each step is a blocking checkpoint.**

### Step 1: Implement

- Read the full bug report for context, root cause, and resolution path
- Use TDD: write failing test that reproduces the bug, implement fix, verify test passes
- Follow Go conventions and shell script best practices
- Make minimum changes needed to fix the bug
- Avoid over-engineering or adding unnecessary features

**Exception:** Read/Grep/Glob tools for searching code do not require approval.

### Step 2: Test

- **Ask user approval** before running (auto-approved when `CAL_VM=true`)
- Execute: `go test ./...`
- **Stop if tests fail** - fix issues before proceeding

All tests must pass to continue.

### Step 3: Build

- **Ask user approval** before running (auto-approved when `CAL_VM=true`)
- Execute: `go build -o cal ./cmd/cal`
- **Stop if build fails** - fix issues before proceeding

Build must succeed to continue.

### Step 4: Code Review

Review code changes for:
- **Bug fix correctness** - Does the fix address the root cause documented in the bug report?
- **Regression risk** - Could this fix break other functionality?
- **Code quality** - Readability, maintainability, modularity
- **Test coverage** - Bug reproduction test and edge cases
- **Security** - Input validation, no injection risks, proper error handling
- **Go conventions** - Idiomatic Go code
- **Shell script best practices** - Proper quoting, error handling

Document findings with:
- File and line references
- Severity ratings (critical, moderate, minor)
- Specific recommendations

### Step 5: Present Review

- Always present review findings to user
- **STOP and wait for explicit user approval** (auto-approved when `CAL_VM=true`)
- User responses like "approved", "looks good", "proceed" = approved
- Do not proceed without approval on HOST

### Step 6: Present User Testing Instructions

Present testing instructions to the user **one by one** (not as a batch list):
- Include specific steps to verify the bug is fixed (from the bug report's "Steps to Reproduce")
- Present each test instruction and wait for the user to confirm pass/fail
- If a test fails, the user can choose to:
  - **Fix it now** - address the issue before continuing
  - **Add as a TODO** - add it to the appropriate phase TODO file for later
  - **Accept as known issue** - acknowledge and proceed
- Continue until all user testing instructions have been presented

**STOP and wait for user confirmation** on each test before presenting the next.

### Step 7: Present Final Code Review

After user testing is complete, present a final code review summarizing:
- Confirmation the bug is fixed (root cause addressed)
- Any issues discovered during user testing and their resolutions
- Confirmation that all tests still pass after any fixes
- Final assessment of code quality and readiness for commit

**STOP and wait for explicit user approval** before proceeding (auto-approved when `CAL_VM=true`).

### Step 8: Update Documentation

Update affected documentation files as needed, plus bug-specific updates:

**Bug lifecycle updates:**
1. **Update bug report** (`docs/bugs/BUG-NNN-slug.md`) - change Status to "Resolved", add resolution details and date
2. **Remove from `docs/BUGS.md`** - delete the row from the active bugs table
3. **Update `docs/bugs/README.md`** - change status to "Resolved" and add resolved date

**Other documentation:**
- `README.md` - if user-facing changes
- `CLAUDE.md` - if workflow or rules changed
- `docs/bootstrap.md` - if setup/troubleshooting changed
- Inline comments in changed code files

**Never modify `docs/adr/*` or `docs/prd/*`** - ADRs and PRDs are immutable historical records.

**Always update PLAN.md and phase TODO files** if the bug fix relates to a tracked TODO - follow [TODO → DONE Movement](WORKFLOWS.md#todo--done-movement) rules from Shared Conventions.

### Step 9: Commit and Push

- **Ask user approval** before committing (auto-approved when `CAL_VM=true`)
- Follow [Commit Message Format](WORKFLOWS.md#commit-message-format) from Shared Conventions
- Reference the bug ID in the commit message (e.g., "Fix BUG-001: ...")
- Execute only after all previous steps complete successfully

### Step 10: Complete

Report completion status:
- Confirm bug status updated in all tracking files
- Suggest next bug from `docs/BUGS.md` if any remain
- Or suggest next steps from PLAN.md

---

## Pre-Commit Checklist

Before every commit:
- [ ] Tests pass (`go test ./...`)
- [ ] Build succeeds (`go build -o cal ./cmd/cal`)
- [ ] Code review presented and user approved (for code changes)
- [ ] User testing instructions presented one by one and resolved
- [ ] Final code review presented and user approved
- [ ] Bug report updated with resolution details
- [ ] Bug removed from `docs/BUGS.md` (active bugs)
- [ ] Bug status updated in `docs/bugs/README.md` (all bugs index)
- [ ] Other documentation updated (affected files)
- [ ] PLAN.md updated if bug relates to a tracked TODO
- [ ] User approved commit operation

---

## Bug Lifecycle

```
Open (in BUGS.md + bugs/README.md)
    ↓
Bug Cleanup workflow
    ↓
Resolved (removed from BUGS.md, updated in bugs/README.md)
```

**When a bug is resolved:**
1. Update the individual bug report with resolution details
2. Remove the entry from `docs/BUGS.md` (active bugs only)
3. Update status in `docs/bugs/README.md` (complete index)

---

## Important Notes

### Command Execution Policy

**Ask user approval before running ANY command** (auto-approved when `CAL_VM=true`), including:
- Git operations (commit, push, branch, merge)
- Build commands
- Test commands
- Script execution
- Package installs
- Any destructive operations

**Exception:** Read/Grep/Glob tools for code searching do not require approval.

### Upstream Bugs

Some bugs may have resolution paths that require upstream fixes (e.g., reporting to external projects). For these:
- Document the upstream report in the bug report
- Update status to "Blocked" if waiting on upstream
- Keep in `docs/BUGS.md` until resolved
- Workarounds can be implemented as separate fixes

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-INTERACTIVE.md](WORKFLOW-INTERACTIVE.md) - Base Interactive workflow
- [BUGS.md](BUGS.md) - Active bugs (work item source)
- [bugs/README.md](bugs/README.md) - Complete bug index
- [PLAN.md](../PLAN.md) - Project TODOs and status
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
