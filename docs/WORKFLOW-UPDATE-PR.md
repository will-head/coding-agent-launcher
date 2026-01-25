# Update PR Workflow (8-Step)

> Autonomous implementation of PR review feedback

**Use When:** Addressing review feedback on PRs in "Needs Changes" section

**Key Principles:**
- **No permission needed** - fully autonomous operation
- **Never commit to main** - work on existing PR branches
- **Autonomous fixes** - analyze feedback and implement changes
- **Skip code review step** - changes already went through PR review
- **PLAN.md and STATUS.md updates must be done on main branch**, not PR branch

---

## Overview

The Update PR workflow autonomously addresses review feedback on PRs that need changes. The agent reads coding standards, checks out the PR branch, analyzes review comments, implements fixes, runs tests and build, pushes updates, and updates documentation.

**Target:** Existing PR branch → resubmit for review
**Approvals:** Not required (autonomous)
**Steps:** 8 (includes fix implementation)

---

## Session Start Procedure

At the start of each new session using this workflow:

1. **Read this workflow file** - Read `docs/WORKFLOW-UPDATE-PR.md` in full
2. **Reiterate to user** - Summarize the workflow in your own words:
   - Explain this is the Update PR workflow (8-step autonomous feedback implementation)
   - List the key principles (no permission needed, never commit to main, autonomous fixes, skip code review)
   - Outline the 8 steps (Read Standards → Read Queue → Fetch PR → Analyze Review → Implement Changes → Test → Build → Update Docs)
   - Mention that this addresses review feedback and resubmits for review
   - Note that STATUS.md updates happen on main branch
3. **Confirm understanding** - Acknowledge understanding of the workflow before proceeding
4. **Check environment** - Detect and display execution environment:
   - Run: `echo $CAL_VM`
   - If `CAL_VM=true`: Display "✅ **Running in cal-dev VM** (isolated environment)"
   - If `CAL_VM≠true`: Display "⚠️  **Running on HOST machine** (not isolated)"
   - This ensures awareness of execution environment before proceeding with any operations
5. **Proceed with standard session start** - Continue with git status, PLAN.md reading, etc.

This ensures both agent and user have shared understanding of the workflow being followed.

---

## Step-by-Step Process

### Step 1: Read Coding Standards

Read `CODING_STANDARDS.md` to review best practices and avoid past mistakes:
- Review mandatory quality standards
- Understand common error patterns to avoid
- Reference security best practices
- Follow language-specific conventions

This ensures fixes meet project standards and don't repeat known issues.

### Step 2: Read Changes Queue

Read `STATUS.md` to find the first PR in "Needs Changes" section:

```markdown
| #42 | create-pr/add-validation | Add input validation | 2026-01-20 | Security and quality issues |
```

**If no PRs in "Needs Changes":**
- Report completion: "No PRs needing changes"
- Exit workflow

**If PR found:**
- Note PR number, branch name, description, and reason
- Proceed to Step 3

### Step 3: Fetch PR Branch

Checkout the PR branch locally:

```bash
gh pr checkout <PR#>
```

**Verify branch checked out successfully** before proceeding.

### Step 4: Analyze Review Feedback

Read and understand the review feedback:

```bash
gh pr view <PR#>
```

Analyze the review comments to understand:
- What changes were requested
- Which files/functions need updates
- What the expected outcome should be
- Security or quality concerns raised
- Severity of each issue

**Create implementation plan:**
- List all issues to address
- Prioritize critical issues first
- Identify dependencies between fixes
- Estimate scope of changes needed

### Step 5: Implement Changes

Apply fixes based on review feedback systematically:

**For each issue:**
1. **Address requested change** with minimal code modifications
2. **Follow TDD if adding functionality** - write test first, then code
3. **Verify fix resolves the issue** - check against review comment
4. **Ensure no regressions** - related code still works

**Implementation Guidelines:**
- Make minimum changes needed to address feedback
- Follow coding standards and best practices
- Keep changes focused on review issues
- Add tests if functionality changed
- Update inline documentation if behavior changed

**Avoid:**
- Over-engineering fixes
- Adding unrequested features
- Refactoring unrelated code
- Making stylistic changes beyond feedback

### Step 6: Test

Run automated tests (no permission needed):

```bash
go test ./...
```

**Must pass before proceeding.** Fix any test failures before continuing.

**Test all affected scenarios:**
- Areas touched by fixes
- Related functionality
- Edge cases mentioned in review
- Error scenarios

### Step 7: Build

Run build (no permission needed):

```bash
go build -o cal ./cmd/cal
```

**Must succeed before proceeding.** Fix any build errors before continuing.

### Step 8: Push Changes and Update Documentation

1. **Push updated branch to remote:**
   ```bash
   git push
   ```

2. **Switch back to main branch:**
   ```bash
   git checkout main
   ```

3. **Update `STATUS.md`:**
   - Remove from "Needs Changes" section
   - Add back to "Needs Review" section:
   ```markdown
   | #42 | create-pr/add-validation | Add input validation | 2026-01-21 |
   ```

4. **Update `PLAN.md` and phase TODO file** with current project status:
   - Note update status in phase TODO file (e.g., `- [ ] Add validation (PR #42 - updates applied, needs re-review)`)
   - Add new TODOs discovered during fixes to appropriate phase TODO file
   - Update PLAN.md phase status if applicable
   - **Note:** Do NOT move TODOs to DONE file yet - this happens during Merge PR workflow

5. **Commit documentation updates:**
   ```bash
   git add STATUS.md PLAN.md docs/PLAN-PHASE-*-TODO.md docs/PLAN-PHASE-*-DONE.md
   git commit -m "$(cat <<'EOF'
   Update documentation after addressing PR #42 feedback

   Moved PR #42 back to Needs Review in STATUS.md.
   Updated phase TODO file and PLAN.md with current project status.

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
   EOF
   )"
   git push
   ```

---

## Pre-Push Checklist

Before pushing updates:
- [ ] Coding standards reviewed (`CODING_STANDARDS.md`)
- [ ] Review feedback fully analyzed
- [ ] All requested changes implemented
- [ ] Changes address root cause, not just symptoms
- [ ] Tests pass (`go test ./...`)
- [ ] Build succeeds (`go build -o cal ./cmd/cal`)
- [ ] Changes pushed to PR branch
- [ ] Switched back to main branch
- [ ] STATUS.md updated (moved to "Needs Review")
- [ ] PLAN.md and phase TODO files updated with current project status
- [ ] Documentation changes committed and pushed

---

## Important Notes

### Autonomous Operation

This workflow does NOT require user approval for:
- Running tests
- Running builds
- Implementing fixes
- Pushing changes
- Updating documentation

### Focused Changes

Only address issues raised in review:
- Don't add new features
- Don't refactor unrelated code
- Don't make stylistic improvements beyond feedback
- Stay focused on review comments

### Documentation Updates on Main

**CRITICAL:** PLAN.md and STATUS.md updates must be done on main branch:
1. Push PR updates on feature branch
2. Switch to main: `git checkout main`
3. Update STATUS.md and PLAN.md
4. Commit and push to main

### PR Comments Format

If adding clarifying comments to PR, use heredoc format:

```bash
gh pr comment <PR#> --body "$(cat <<'EOF'
Addressed all review feedback:

- Fixed command injection in vm-auth.sh
- Extracted validation to helper function
- Updated CLI documentation examples

All tests passing, ready for re-review.
EOF
)"
```

---

## Common Fix Patterns

### Security Issues
- Remove eval usage, use arrays
- Add input validation
- Escape user inputs
- Use parameterized queries
- Validate file paths

### Code Quality Issues
- Extract duplicate code
- Break up large functions
- Add error context
- Improve naming
- Add comments for complex logic

### Testing Issues
- Add missing test cases
- Test error scenarios
- Test edge cases
- Improve test naming
- Remove test duplication

### Documentation Issues
- Update outdated examples
- Add missing parameters
- Fix command syntax
- Clarify ambiguous statements
- Add usage examples

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-REVIEW-PR.md](WORKFLOW-REVIEW-PR.md) - Previous step: PR review
- [PR-WORKFLOW-DIAGRAM.md](PR-WORKFLOW-DIAGRAM.md) - Visual workflow diagram
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
- [STATUS.md](../STATUS.md) - PR tracking
