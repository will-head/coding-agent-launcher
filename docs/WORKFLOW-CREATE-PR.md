# Create PR Workflow (6-Step)

> Autonomous PR-based development with automated checks and no user approvals

**Use When:** Creating new pull requests for code review before merging to main

**Key Principles:**
- **No permission needed** - fully autonomous operation for tests, builds, and PR creation
- **Never commit to main** - all changes via PR on `create-pr/feature-name` branch
- **No destructive operations** - no force pushes, branch deletions, or dangerous git operations
- **TDD required** - write test first, then implementation
- **PLAN.md and PRS.md updates must be done on main branch**, not PR branch

---

## Overview

The Create PR workflow enables autonomous PR-based development. The agent creates a feature branch, implements changes with TDD, runs tests and build, creates a PR with manual testing instructions, and updates documentation—all without requiring user approval.

**Target:** `create-pr/` branch → PR (will merge to main later)
**Approvals:** Not required (autonomous)
**Steps:** 6 (streamlined for autonomy)

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

### Step 1: Read Coding Standards

**Always read `CODING_STANDARDS.md` before implementing** to review:
- Mandatory quality standards
- Common error patterns to avoid
- Security best practices
- Language-specific conventions (Go, shell scripts)

This ensures all code meets project standards from the start and avoids recurring mistakes.

### Step 2: Implement (TDD)

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

### Step 3: Test

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

### Step 4: Build

Run build (no permission needed):

```bash
go build -o cal ./cmd/cal
```

**Must succeed before proceeding.** Fix any build errors before continuing.

### Step 5: Create PR

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

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**PR Body Must Include:**
- Summary (2-4 bullet points)
- Manual Testing Instructions (step-by-step, with expected outcomes)
- Automated Tests checklist
- Claude Code attribution

### Step 6: Update Documentation

**IMPORTANT: All documentation updates must be done on main branch, NOT the PR branch.**

1. **Switch to main branch:**
   ```bash
   git checkout main
   ```

2. **Add new entry to `PRS.md`** under "Needs Review" section:
   ```markdown
   | [#42](link) | create-pr/add-validation | Add input validation | 2026-01-22 |
   ```

3. **Update `PLAN.md`** with current project status:
   - Mark any completed TODOs as `[x]`
   - Add new TODOs discovered during implementation
   - Update phase status if applicable
   - Note PR number in relevant TODO items

4. **Commit documentation updates** (on main):
   ```bash
   git add PRS.md docs/PLAN.md
   git commit -m "$(cat <<'EOF'
   Update documentation for PR #42

   Added PR #42 to Needs Review section in PRS.md.
   Updated PLAN.md to reflect current project status.

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
   EOF
   )"
   git push
   ```

5. Move to next task

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

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## Pre-PR Creation Checklist

Before creating PR:
- [ ] Coding standards reviewed (`CODING_STANDARDS.md`)
- [ ] Tests written (TDD approach)
- [ ] Tests pass (`go test ./...`)
- [ ] Build succeeds (`go build -o cal ./cmd/cal`)
- [ ] Manual testing instructions included in PR body
- [ ] PR body uses heredoc format for proper formatting
- [ ] Documentation updated if user-facing changes
- [ ] Switched to main branch for doc updates
- [ ] PRS.md updated with PR entry (on main)
- [ ] PLAN.md updated with current project status (on main)
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

When adding PR comments, always use heredoc format to preserve formatting:

```bash
gh pr comment <PR#> --body "$(cat <<'EOF'
Comment text here with proper formatting.

- Bullet points
- Multiple lines
- Proper structure

EOF
)"
```

### Documentation Updates on Main

**CRITICAL:** PLAN.md and PRS.md updates must be done on the main branch:
1. Create PR on feature branch
2. Switch to main: `git checkout main`
3. Update PRS.md and PLAN.md
4. Commit and push to main
5. Do NOT include these doc changes in the PR

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-REVIEW-PR.md](WORKFLOW-REVIEW-PR.md) - Next step: PR review
- [PR-WORKFLOW-DIAGRAM.md](PR-WORKFLOW-DIAGRAM.md) - Visual workflow diagram
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
- [PRS.md](../PRS.md) - PR tracking
