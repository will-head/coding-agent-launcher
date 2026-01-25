# Interactive Workflow (8-Step)

> Default workflow for direct code changes with user approvals at each step

**Use When:** Making code changes directly to the main branch with interactive approvals

**Key Principles:**
- **User approval required** - ask permission before ALL commands
- **Blocking checkpoints** - each step must complete before proceeding
- **Code review mandatory** - all code/script changes reviewed before commit
- **Documentation-only exception** - skip tests/build/review for `.md` files only

---

## Overview

The Interactive workflow is the default workflow for making code changes directly to the main branch. It requires explicit user approval before running any commands (git, build, tests, installs), ensuring the user maintains full control over all operations.

**Target:** main branch (direct commits)
**Approvals:** Required for all commands
**Steps:** 8 (full workflow) or simplified for docs-only

---

## Session Start Procedure

At the start of each new session using this workflow:

1. **Read this workflow file** - Read `docs/WORKFLOW-INTERACTIVE.md` in full
2. **Reiterate to user** - Summarize the workflow in your own words:
   - Explain this is the Interactive workflow (8-step with approvals)
   - List the key principles (user approval required, blocking checkpoints, code review mandatory)
   - Outline the 8 steps or simplified 3-step process for docs-only
   - Mention important policies (command approval, PLAN.md tracking, commit format)
3. **Confirm understanding** - Acknowledge understanding of the workflow before proceeding
4. **Check environment** - Detect and display execution environment:
   - Run: `echo $CAL_VM`
   - If `CAL_VM=true`: Display "✅ **Running in cal-dev VM** (isolated environment)"
   - If `CAL_VM≠true`: Display "⚠️  **Running on HOST machine** (not isolated)"
   - This ensures awareness of execution environment before proceeding with any operations
5. **Proceed with standard session start** - Continue with git status, PLAN.md reading, etc.

This ensures both agent and user have shared understanding of the workflow being followed.

---

## Documentation-Only Changes

For changes **only** to `.md` files or code comments:

1. Make changes
2. Ask user approval to commit
3. Commit and push

**Skip:** tests, build, and code review for docs-only changes.

---

## Code/Script Changes (Full 8-Step Workflow)

**Each step is a blocking checkpoint.**

### Step 1: Implement

- Use TDD: write failing test first, implement code, verify test passes
- Follow Go conventions and shell script best practices
- Make minimum changes needed to accomplish the goal
- Avoid over-engineering or adding unnecessary features

**Exception:** Read/Grep/Glob tools for searching code do not require approval.

### Step 2: Test

- **Ask user approval** before running
- Execute: `go test ./...`
- **Stop if tests fail** - fix issues before proceeding

All tests must pass to continue.

### Step 3: Build

- **Ask user approval** before running
- Execute: `go build -o cal ./cmd/cal`
- **Stop if build fails** - fix issues before proceeding

Build must succeed to continue.

### Step 4: Code Review

Review code changes for:
- **Code quality** - Readability, maintainability, modularity
- **Test coverage** - All scenarios tested (valid inputs, invalid inputs, errors, edge cases)
- **Security** - Input validation, no injection risks, proper error handling
- **Performance** - Efficient algorithms, no unnecessary operations
- **Go conventions** - Idiomatic Go code
- **Shell script best practices** - Proper quoting, error handling
- **New TODOs** - Must add to PLAN.md

Document findings with:
- File and line references
- Severity ratings (critical, moderate, minor)
- Specific recommendations

### Step 5: Present Review

- Always present review findings to user
- **STOP and wait for explicit user approval**
- User responses like "approved", "looks good", "proceed" = approved
- Do not proceed without approval

### Step 6: Update Documentation

Update affected documentation files:
- `README.md` - if user-facing changes
- `CLAUDE.md` (AGENTS.md) - if workflow or rules changed
- `docs/SPEC.md` - if technical spec changed
- `docs/architecture.md` - if architecture changed
- `docs/cli.md` - if CLI commands changed
- `docs/bootstrap.md` - if setup changed
- `docs/plugins.md` - if plugins affected
- `docs/roadmap.md` - if roadmap changed
- Inline comments in changed code files

**Never modify `docs/adr/*`** - ADRs are immutable historical records.

**Always update PLAN.md and phase TODO files** with current project status:
- **Move completed TODOs** from TODO file to DONE file (e.g., from `docs/PLAN-PHASE-00-TODO.md` to `docs/PLAN-PHASE-00-DONE.md`)
  - Cut the completed TODO item from TODO file
  - Paste it into DONE file with `[x]` checkbox and completion note
  - Example: `- [x] Add snapshot validation (completed 2026-01-21)`
- Add new TODOs discovered during implementation to appropriate phase TODO file
- Update PLAN.md phase status to reflect actual completion
- Update PLAN.md "Current Status" section if phase completion changed
- Ensure all code TODOs have corresponding entries in phase TODO files

### Step 7: Commit and Push

- **Ask user approval** before committing
- Use imperative mood commit messages
- Include Co-Authored-By line:
  ```
  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
  ```
- Use heredoc format for multi-line commits:
  ```bash
  git commit -m "$(cat <<'EOF'
  Brief summary (imperative mood)

  Detailed description of what changed and why.

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
  EOF
  )"
  ```
- Execute only after all previous steps complete successfully

### Step 8: Complete

Report completion status and suggest next steps from PLAN.md.

---

## Pre-Commit Checklist

Before every commit:
- [ ] Tests pass (`go test ./...`)
- [ ] Build succeeds (`go build -o cal ./cmd/cal`)
- [ ] Code review presented and user approved (for code changes)
- [ ] Documentation updated (affected files)
- [ ] PLAN.md updated with current project status
- [ ] Completed TODOs moved from phase TODO file to phase DONE file
- [ ] New TODOs added to appropriate phase TODO file
- [ ] User approved commit operation

---

## Important Notes

### Command Execution Policy

**Ask user approval before running ANY command**, including:
- Git operations (commit, push, branch, merge)
- Build commands
- Test commands
- Script execution
- Package installs
- Any destructive operations

**Exception:** Read/Grep/Glob tools for code searching do not require approval.

### TODO Tracking

**PLAN.md and phase TODO files are the single source of truth** for all TODOs.

Rules:
- Phase overview in PLAN.md, detailed TODOs in phase-specific files (e.g., `docs/PLAN-PHASE-00-TODO.md`)
- All phase-affecting TODOs must be in the appropriate phase TODO file
- Phase complete only when ALL checkboxes in phase TODO file are `[x]`
- Code TODOs are notes only, must also be tracked in phase TODO files
- Before commit, verify each TODO has an entry in the appropriate phase TODO file

### Commit Message Format

```
Brief summary (imperative mood)

Detailed description of what changed and why.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [PLAN.md](../PLAN.md) - Project TODOs and status
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
