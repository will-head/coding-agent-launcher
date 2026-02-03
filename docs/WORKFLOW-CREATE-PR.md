# Create PR Workflow (8-Step)

> Autonomous PR-based development starting from refined TODOs

**Use When:** Creating new pull requests from refined TODOs in STATUS.md

**Key Principles:**
- **Start with refined TODOs** - read STATUS.md "Refined" section first
- **No permission needed** - fully autonomous operation for tests, builds, and PR creation
- **Never commit to main** - all changes via PR on `create-pr/feature-name` branch
- **No destructive operations** - no force pushes, branch deletions, or dangerous git operations
- **TDD required** - write test first, then implementation
- **Self-review before submission** - review against requirements before creating PR
- **PLAN.md and STATUS.md updates must be done on main branch**, not PR branch

---

## Overview

The Create PR workflow enables autonomous PR-based development starting from refined TODOs. The agent reads the "Refined" section in STATUS.md, picks the first item, reads the full TODO with constraints from the phase TODO file, reads coding standards, implements changes with TDD, runs tests and build, performs a self-review against the original requirements, creates a PR with manual testing instructions, and updates documentation—all without requiring user approval.

**Target:** `create-pr/` branch → PR (will merge to main later)
**Approvals:** Not required (autonomous)
**Steps:** 8 (streamlined for autonomy with self-review)

---

## Session Start Procedure

Follow [Session Start Procedure](WORKFLOWS.md#session-start-procedure) from Shared Conventions, highlighting:
- This is the Create PR workflow (8-step autonomous PR creation with self-review)
- Key principles: start with refined TODOs, no permission needed, never commit to main, TDD required, self-review before submission
- 8 steps: Read Refined Queue → Read Standards → Implement → Test → Build → Self-Review → Create PR → Update Docs
- Branch naming: `create-pr/feature-name`
- PLAN.md/STATUS.md updates happen on main branch

---

## Branch Naming Convention

Use `create-pr/feature-name` format:

```bash
git checkout -b create-pr/add-snapshot-validation
git checkout -b create-pr/fix-ssh-timeout
git checkout -b create-pr/refactor-config-loading
```

**Format:** `create-pr/brief-descriptive-name`
- Use lowercase with hyphens
- Be specific and descriptive
- Avoid overly long names

---

## Step-by-Step Process

### Step 1: Read Refined Queue

**Note:** Session Start Procedure ensures you're on main branch before this step (STATUS.md is only updated on main).

Read `STATUS.md` to find the first TODO in "Refined" section:

```markdown
## Refined

| TODO | Location | Description | Refined Date | Notes |
|------|----------|-------------|--------------|-------|
| Add git repo sync on init | PLAN-PHASE-00-TODO.md § 0.10 | Prompt for repos during --init and clone using gh CLI | 2026-01-23 | Requires gh auth |
```

**If no refined TODOs:**
- Report completion: "No refined TODOs available for implementation"
- Exit workflow or ask user for specific task

**If multiple refined TODOs found:**
- Present using [Numbered Choice Presentation](WORKFLOWS.md#numbered-choice-presentation) so user can select by number

**If refined TODO found/selected:**
- Note the TODO description and location in phase TODO file
- Read the full refined TODO from the phase TODO file to get complete requirements, constraints, and acceptance criteria
- Keep these requirements accessible for self-review in Step 6
- Proceed to Step 2

### Step 2: Read Coding Standards

**Always read `CODING_STANDARDS.md` before implementing** to review:
- Mandatory quality standards
- Common error patterns to avoid
- Security best practices
- Language-specific conventions (Go, shell scripts)

This ensures all code meets project standards from the start and avoids recurring mistakes.

### Step 3: Implement (TDD)

1. **Create feature branch:**
   ```bash
   git checkout -b create-pr/feature-name
   ```

2. **Write failing test first** (TDD approach):
   - Create test file if needed
   - Write test that exercises the new functionality
   - Run test - should fail (red)

3. **Implement minimum code** to pass test:
   - Write just enough code to make test pass
   - Follow Go conventions and best practices
   - Keep changes focused and minimal

4. **Verify test passes** (green):
   ```bash
   go test ./...
   ```

5. **Refactor if needed** (refactor):
   - Improve code quality while keeping tests passing
   - Avoid over-engineering

### Step 4: Test

Run automated tests (no permission needed):

```bash
go test ./...
```

**Must pass before proceeding.** Fix any failures before continuing.

**Test all scenarios:**
- Valid inputs
- Invalid inputs
- Missing dependencies
- Authentication failures
- Existing state conflicts
- Network failures
- Edge cases

### Step 5: Build

Run build (no permission needed):

```bash
go build -o cal ./cmd/cal
```

**Must succeed before proceeding.** Fix any build errors before continuing.

### Step 6: Self-Review

Before creating the PR, review the implementation against the original requirements from Step 1.

**Review the 10 quality areas against requirements:**

1. **Code Quality** - Readable, maintainable, well-organized?
2. **Architecture** - Appropriate patterns, good separation of concerns?
3. **Correctness** - Handles edge cases, no logic errors, matches requirements?
4. **Error Handling** - Proper propagation, meaningful messages, recovery strategies?
5. **Security** - Input validation, no injection vulnerabilities, secrets handled?
6. **Performance** - No unnecessary operations, reasonable complexity?
7. **Testing** - All scenarios covered, test quality adequate?
8. **Documentation** - Code matches docs, user-facing changes documented?
9. **Language Conventions** - Go idioms followed, style consistent?
10. **Dependencies** - Tools checked, versions appropriate?

**For each issue found:**
- Fix the issue directly
- Re-run tests (`go test ./...`) to verify no regressions
- Re-run build (`go build -o cal ./cmd/cal`) if needed

**Self-review is complete when:**
- All 10 areas assessed against the original requirements
- All found issues are fixed
- Tests still pass
- Build still succeeds

### Step 7: Create PR

1. **Push branch to remote:**
   ```bash
   git push -u origin HEAD
   ```

2. **Create PR with `gh pr create`:**
   - Clear title describing the change
   - Body with summary and **manual testing instructions**
   - Use heredoc format to preserve formatting:

```bash
gh pr create --title "Add snapshot validation" --body "$(cat <<'EOF'
## Summary
- Adds validation for snapshot names before creation
- Prevents invalid characters in snapshot names
- Shows clear error messages for invalid names

## Manual Testing Instructions
1. Run `./scripts/cal-bootstrap --snapshot create test@invalid`
   - Expected: Error message "Invalid snapshot name"
2. Run `./scripts/cal-bootstrap --snapshot create test-valid`
   - Expected: Snapshot created successfully
3. Run `./scripts/cal-bootstrap --snapshot list`
   - Expected: Shows test-valid in list

## Automated Tests
- [x] All tests pass (`go test ./...`)
- [x] Build succeeds (`go build -o cal ./cmd/cal`)
- [x] Self-review completed (10 areas checked)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**PR Body Must Include:**
- Summary (2-4 bullet points)
- Manual Testing Instructions (step-by-step, with expected outcomes)
- Automated Tests checklist (including self-review confirmation)
- Claude Code attribution

### Step 8: Update Documentation

**IMPORTANT: All documentation updates must be done on main branch, NOT the PR branch.**

1. **Switch to main branch:**
   ```bash
   git checkout main
   ```

2. **Add new entry to `STATUS.md`** under "Needs Review" section:
   ```markdown
   | [#42](link) | create-pr/add-validation | Add input validation | 2026-01-22 |
   ```

3. **Update `PLAN.md` and phase TODO file** with current project status:
   - Note PR number in relevant TODO items in phase TODO file (e.g., `docs/PLAN-PHASE-00-TODO.md`)
   - Example: `- [ ] Add snapshot validation (PR #42 - awaiting merge)`
   - Add new TODOs discovered during implementation to appropriate phase TODO file
   - Update PLAN.md phase status if applicable
   - **Note:** Do NOT move TODOs to DONE file yet - this happens during Merge PR workflow

4. **Commit documentation updates** (on main) using [Commit Message Format](WORKFLOWS.md#commit-message-format)

5. **Suggest next workflow** by checking STATUS.md — see [Next Workflow Guidance](WORKFLOWS.md#next-workflow-guidance).

---

## PR Body Format Template

```markdown
## Summary
- Brief description of changes (2-4 bullet points)
- Why this change is needed
- Key implementation details

## Manual Testing Instructions
1. Step-by-step instructions to test the change
2. Expected outcomes for each step
3. Edge cases to verify
4. Error scenarios to test

## Automated Tests
- [x] All tests pass (`go test ./...`)
- [x] Build succeeds (`go build -o cal ./cmd/cal`)
- [x] Self-review completed (10 areas checked)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## Pre-PR Creation Checklist

Before creating PR:
- [ ] Refined TODO read from STATUS.md "Refined" section
- [ ] Full TODO details and constraints read from phase TODO file
- [ ] Coding standards reviewed (`CODING_STANDARDS.md`)
- [ ] Tests written (TDD approach)
- [ ] Tests pass (`go test ./...`)
- [ ] Build succeeds (`go build -o cal ./cmd/cal`)
- [ ] Self-review completed against original requirements (10 areas)
- [ ] All self-review issues fixed and re-tested
- [ ] Manual testing instructions included in PR body
- [ ] PR body uses heredoc format for proper formatting
- [ ] Documentation updated if user-facing changes
- [ ] Switched to main branch for doc updates
- [ ] STATUS.md updated with PR entry (on main)
- [ ] PLAN.md and phase TODO file updated with current project status (on main)
- [ ] Documentation changes committed and pushed (on main)

---

## Important Notes

### Autonomous Operation

This workflow does NOT require user approval for:
- Running tests
- Running builds
- Creating branches
- Pushing branches
- Creating PRs
- Adding PR comments

### Safety Constraints

Never perform these operations without explicit user approval:
- Commit to main branch
- Force push (`git push --force`)
- Delete branches
- Merge operations
- Destructive git operations

### PR Comments Format

See [PR Comments Format](WORKFLOWS.md#pr-comments-format) in Shared Conventions.

### Documentation Updates on Main

See [Documentation Updates on Main](WORKFLOWS.md#documentation-updates-on-main) in Shared Conventions.

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-REVIEW-PR.md](WORKFLOW-REVIEW-PR.md) - Next step: PR review & fix
- [PR-WORKFLOW-DIAGRAM.md](PR-WORKFLOW-DIAGRAM.md) - Visual workflow diagram
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
- [STATUS.md](../STATUS.md) - PR tracking
