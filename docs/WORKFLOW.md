# Git Workflow Reference

> Detailed procedures for commits, code review, and documentation updates.
> Read this when performing git operations.

## Workflow Modes

User specifies workflow at session start. **Default is Standard** unless Create PR or Documentation is specified.

| Mode | Use Case | Approvals | Target |
|------|----------|-----------|--------|
| **Standard** | Default for code changes (8-step) | Required | main branch |
| **Create PR** | PR-based development (6-step) | Not required | `create-pr/` branch → PR |
| **Review PR** | Code review of PRs (6-step) | Not required | PR review + PRS.md update |
| **Update PR** | Address PR feedback (8-step) | Not required | Existing PR branch → resubmit |
| **Merge PR** | Merge reviewed PRs (8-step) | Required | PR → main branch |
| **Documentation** | Docs-only changes | Commit only | main or PR |

---

## Session Startup

On new session:
1. Read AGENTS.md (core rules)
2. **Determine workflow** - If user hasn't specified or it's unclear which workflow to use, ask explicitly:
   - Standard (8-step with approvals)
   - Create PR (6-step, autonomous, PR-based)
   - Review PR (6-step, autonomous review)
   - Update PR (8-step, autonomous fixes)
   - Merge PR (8-step with approvals)
   - Documentation (docs-only)
3. Ask user approval, then run `git status` and `git fetch`
4. Read `docs/PLAN.md` for current TODOs and phase status
5. Acknowledge the active workflow mode
6. Report status and suggest next steps from PLAN.md

---

## Standard Workflow (8-Step)

### Documentation-Only Changes

For changes **only** to `.md` files or code comments:
1. Make changes
2. Ask user approval to commit
3. Commit and push

Skip tests, build, and code review for docs-only changes.

### Code/Script Changes (Full 8-Step Workflow)

**Each step is a blocking checkpoint.**

#### Step 1: Implement
- Use TDD: write failing test, implement, verify pass
- Follow Go conventions and shell script best practices
- Make minimum changes needed

#### Step 2: Test
- Ask user approval before running
- Execute: `go test ./...`
- Stop if tests fail

#### Step 3: Build
- Ask user approval before running
- Execute: `go build -o cal ./cmd/cal`
- Stop if build fails

#### Step 4: Code Review
Review for:
- Code quality, test coverage, security, performance
- Go conventions, shell script best practices
- New TODOs (must add to PLAN.md)

#### Step 5: Present Review
- Always present review findings
- **STOP and wait for explicit user approval**
- "approved", "looks good", "proceed" = approved

#### Step 6: Update Documentation
Update if affected:
- `README.md`, `AGENTS.md`, `docs/SPEC.md`, `docs/PLAN.md`
- `docs/architecture.md`, `docs/cli.md`, `docs/bootstrap.md`
- `docs/plugins.md`, `docs/roadmap.md`
- Inline comments in changed files

**Never modify `docs/adr/*`** - ADRs are immutable.

Update PLAN.md with current project status:
- Mark completed TODOs as [x]
- Add new TODOs discovered during implementation
- Update phase status to reflect actual completion
- Update "Current Status" section if phase completion changed
- Ensure code TODOs have PLAN.md entries

#### Step 7: Commit and Push
- Ask user approval
- Use imperative mood, add Co-Authored-By line
- Execute only after all steps complete

---

## Create PR Workflow (6-Step)

**Purpose:** PR-based development with automated checks. All changes go through pull requests.

**Key Principles:**
- **No permission needed** for tests, builds, or PR creation
- **No destructive operations** without explicit user approval
- **Never commit to main** - all changes via PR
- **TDD required** - write test first, then implementation

### Branch Naming

Use `create-pr/feature-name` format:
```bash
git checkout -b create-pr/add-snapshot-validation
git checkout -b create-pr/fix-ssh-timeout
```

### Step 1: Read Coding Standards

Read `CODING_STANDARDS.md` to review best practices and avoid past mistakes:
- Review mandatory quality standards
- Understand common error patterns to avoid
- Reference security best practices
- Follow language-specific conventions

This ensures all code meets project standards from the start.

### Step 2: Implement (TDD)

1. Create feature branch: `git checkout -b create-pr/feature-name`
2. Write failing test first
3. Implement minimum code to pass test
4. Refactor if needed

### Step 3: Test

Run automated tests (no permission needed):
```bash
go test ./...
```
- **Must pass** before proceeding
- Fix any failures before continuing

### Step 4: Build

Run build (no permission needed):
```bash
go build -o cal ./cmd/cal
```
- **Must succeed** before proceeding
- Fix any build errors before continuing

### Step 5: Create PR

1. Push branch to remote:
   ```bash
   git push -u origin HEAD
   ```

2. Create PR with `gh pr create`:
   - Clear title describing the change
   - Body with summary and **manual testing instructions**

**PR Body Format:**
```markdown
## Summary
- Brief description of changes
- Why this change is needed

## Manual Testing Instructions
1. Step-by-step instructions to test the change
2. Expected outcomes for each step
3. Edge cases to verify

## Automated Tests
- [ ] All tests pass (`go test ./...`)
- [ ] Build succeeds (`go build -o cal ./cmd/cal`)
```

### Step 6: Update Documentation

1. Add new entry to `PRS.md` under "Awaiting Review" section
2. Include PR number, branch, description, and creation date
3. Update PLAN.md with current project status:
   - Mark any completed TODOs as [x]
   - Add new TODOs discovered during implementation
   - Update phase status if applicable
4. Move to next task

### Create PR Pre-PR Checklist

Before creating PR:
- [ ] Coding standards reviewed
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Manual testing instructions included
- [ ] Documentation updated if needed
- [ ] PRS.md updated with PR entry
- [ ] PLAN.md updated with current project status

---

## Review PR Workflow (6-Step)

**Purpose:** Autonomous code review of PRs in the review queue. Agent performs comprehensive review and updates PR status.

**Key Principles:**
- **No permission needed** - fully autonomous operation
- **Fetch branch locally** - review actual code files for thoroughness
- **Comprehensive review** - assess code quality, architecture, security, and best practices
- **Submit formal review** - REQUEST_CHANGES or APPROVE via `gh pr review`
- **Update standards** - add new patterns to CODING_STANDARDS.md when recurring issues found
- **Clean workspace** - return to main branch after review

### Step 1: Read Review Queue

Read `PRS.md` to find the first PR in "Awaiting Review" section:
```bash
# Example entry format
| #42 | create-pr/add-validation | Add input validation | 2026-01-20 |
```

If no PRs in "Awaiting Review", report completion and exit workflow.

### Step 2: Fetch PR Branch

Checkout the PR branch locally for review:
```bash
gh pr checkout <PR#>
```

Verify branch is checked out successfully before proceeding.

### Step 3: Review Code

Perform comprehensive code review based on software engineering best practices:

**Review areas:**
- **Code quality** - Readability, maintainability, modularity, abstraction levels
- **Architecture** - Design patterns, separation of concerns, dependency management
- **Correctness** - Logic errors, edge cases, race conditions, off-by-one errors
- **Error handling** - Proper propagation, meaningful messages, recovery strategies
- **Security** - Input validation, injection vulnerabilities, authentication, authorization
- **Performance** - Algorithmic complexity, resource usage, unnecessary operations
- **Testing** - Coverage, test quality, missing scenarios, test maintainability
- **Documentation** - Accuracy, completeness, clarity, examples
- **Language conventions** - Go idioms, shell script best practices, style consistency
- **Dependencies** - Appropriate usage, version management, missing checks

**Document findings:**
- File and line references for each issue
- Severity (critical, moderate, minor)
- Specific recommendations for fixes
- Positive observations for good patterns
- Context and rationale for suggestions

### Step 4: Identify New Patterns

Review findings to determine if new error patterns should be added to CODING_STANDARDS.md.

**Add to CODING_STANDARDS.md if:**
- Pattern is recurring or likely to recur
- New category of mistake not currently documented
- Security vulnerability in code pattern
- Best practice emerged from this implementation

**Do NOT add for:**
- One-off mistakes unlikely to repeat
- Trivial style preferences
- Project-specific details

Follow the process in `docs/UPDATE_CODING_STANDARDS.md`:
1. Generalize the pattern (remove specific file/line refs)
2. Write prescriptive standards (Must/Never/Always)
3. Provide code examples (Bad/Good/Better)
4. Update CLAUDE.md summary if adding new categories

### Step 5: Submit Review

Submit formal GitHub review based on findings:

**If no changes required:**
```bash
gh pr review --approve --body "Code review complete. All standards met.

✅ No duplicate code
✅ Dependencies properly checked
✅ Documentation accurate
✅ Error handling correct
✅ Validation in place
✅ Security practices followed
✅ Tests comprehensive
✅ Build passes"
```

**If changes required:**
```bash
gh pr review --request-changes --body "Code review findings require updates before merge.

## Issues Found

### [Category] - [Severity]
**File:** path/to/file.go:line
**Issue:** Description of the problem
**Fix:** Specific recommendation

[Additional issues...]

Please address these findings and update the PR."
```

### Step 6: Update Documentation and Return to Main

**First, switch back to main branch:**
```bash
git checkout main
```

**Then update documentation based on review outcome:**

**Update PRS.md:**

**If approved (no changes required):**
- Remove from "Awaiting Review" section
- Add to "Reviewed" section with reviewer and date
```markdown
| #42 | create-pr/add-validation | Add input validation | Claude Sonnet 4.5 | 2026-01-21 |
```

**If changes requested:**
- Remove from "Awaiting Review" section
- Add to "Awaiting Changes" section (create if not exists)
```markdown
| #42 | create-pr/add-validation | Add input validation | 2026-01-21 | Needs validation improvements |
```

**Update PLAN.md if PR relates to tracked work:**
- Mark any completed TODOs as [x]
- Update phase status if applicable
- Note any issues discovered that need follow-up

### Review PR Pre-Review Checklist

Before completing review:
- [ ] PR branch checked out and reviewed locally
- [ ] Comprehensive review completed (quality, architecture, security, best practices)
- [ ] Findings documented with file:line references and severity
- [ ] Recurring patterns added to CODING_STANDARDS.md (per UPDATE_CODING_STANDARDS.md)
- [ ] CLAUDE.md updated if new standard categories added
- [ ] Review submitted via `gh pr review` (APPROVE or REQUEST_CHANGES)
- [ ] Switched back to main branch
- [ ] PRS.md updated with correct section and details
- [ ] PLAN.md updated if PR relates to tracked work

---

## Update PR Workflow (8-Step)

**Purpose:** Address review feedback on PRs that need changes. Autonomously implements fixes and resubmits for review.

**Key Principles:**
- **No permission needed** - fully autonomous operation
- **Never commit to main** - work on existing PR branches
- **Autonomous fixes** - agent analyzes review feedback and implements changes
- **Skip code review** - changes already went through PR review process
- **Clean workspace** - return to main branch after updates

### Step 1: Read Coding Standards

Read `CODING_STANDARDS.md` to review best practices and avoid past mistakes:
- Review mandatory quality standards
- Understand common error patterns to avoid
- Reference security best practices
- Follow language-specific conventions

This ensures fixes meet project standards and don't repeat known issues.

### Step 2: Read Changes Queue

Read `PRS.md` to find the first PR in "Awaiting Changes" section:
```bash
# Example entry format
| #42 | create-pr/add-validation | Add input validation | 2026-01-20 | Needs validation improvements |
```

If no PRs in "Awaiting Changes", report completion and exit workflow.

### Step 3: Fetch PR Branch

Checkout the PR branch locally:
```bash
gh pr checkout <PR#>
```

Verify branch is checked out successfully before proceeding.

### Step 4: Analyze Review Feedback

Read and understand the review feedback:
```bash
gh pr view <PR#>
```

Analyze the review comments to understand:
- What changes were requested
- Which files/functions need updates
- What the expected outcome should be
- Any security or quality concerns raised

### Step 5: Implement Changes

Apply the fixes based on review feedback:
- Address each requested change systematically
- Follow TDD if adding new functionality or tests
- Make minimum changes needed to address feedback
- Ensure changes align with coding standards

### Step 6: Test

Run automated tests (no permission needed):
```bash
go test ./...
```
- **Must pass** before proceeding
- Fix any failures before continuing

### Step 7: Build

Run build (no permission needed):
```bash
go build -o cal ./cmd/cal
```
- **Must succeed** before proceeding
- Fix any build errors before continuing

### Step 8: Push Changes and Update Documentation

1. Push updated branch to remote:
   ```bash
   git push
   ```

2. Switch back to main branch:
   ```bash
   git checkout main
   ```

3. Update `PRS.md`:
   - Remove from "Awaiting Changes" section
   - Add back to "Awaiting Review" section
   ```markdown
   | #42 | create-pr/add-validation | Add input validation | 2026-01-21 |
   ```

4. Update PLAN.md with current project status:
   - Mark any completed TODOs as [x]
   - Add new TODOs discovered during fixes
   - Update phase status if applicable

### Update PR Pre-Push Checklist

Before pushing updates:
- [ ] Coding standards reviewed
- [ ] Review feedback fully analyzed
- [ ] All requested changes implemented
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Changes pushed to PR branch
- [ ] Switched back to main branch
- [ ] PRS.md updated (moved from "Awaiting Changes" to "Awaiting Review")
- [ ] PLAN.md updated with current project status

---

## Merge PR Workflow (8-Step)

**Purpose:** Merge reviewed and approved PRs into the main branch. Integrates completed work and updates documentation.

**Key Principles:**
- **User approval required** - ask permission before all commands
- **Use merge commit** - preserves full PR history with `--merge` flag
- **Delete branches after merge** - clean up both local and remote
- **Track merged PRs** - move to "Merged" section in PRS.md
- **Clean workspace** - ensure main is up to date after merge

### Step 1: Read Merge Queue

Read `PRS.md` to find the first PR in "Reviewed" section:
```bash
# Example entry format
| #42 | create-pr/add-validation | Add input validation | Claude Sonnet 4.5 | 2026-01-21 |
```

If no PRs in "Reviewed", report completion and exit workflow.

### Step 2: Fetch PR Details

Ask user approval, then verify PR is ready to merge:
```bash
gh pr view <PR#>
```

Check that:
- PR is approved
- All checks pass
- No merge conflicts
- Target branch is main

### Step 3: Merge PR

Ask user approval, then merge with merge commit strategy:
```bash
gh pr merge <PR#> --merge
```

The `--merge` flag creates a merge commit that preserves the full PR history.

If merge fails:
- Check for conflicts and resolve if needed
- Verify PR is in mergeable state
- Check GitHub permissions

### Step 4: Update Local Main

Ask user approval, then update local main branch:
```bash
git checkout main
git pull
```

Verify the merge commit appears in local history.

### Step 5: Delete Branch

Ask user approval, then delete both local and remote PR branch:
```bash
git branch -d <branch-name>
git push origin --delete <branch-name>
```

Only delete after successful merge confirmation. If branch deletion fails, it may have already been deleted by GitHub auto-delete feature.

### Step 6: Update PRS.md

Move PR entry from "Reviewed" to "Merged" section with merge date:

**Remove from "Reviewed":**
```markdown
| #42 | create-pr/add-validation | Add input validation | Claude Sonnet 4.5 | 2026-01-21 |
```

**Add to "Merged" section:**
```markdown
| #42 | create-pr/add-validation | Add input validation | 2026-01-21 |
```

Create "Merged" section if it doesn't exist:
```markdown
## Merged

| PR# | Branch | Description | Merged Date |
|-----|--------|-------------|-------------|
```

### Step 7: Update PLAN.md

Update PLAN.md to reflect current project status after merge:
- Mark completed tasks as `[x]`
- Update phase status if phase is now complete
- Update "Current Status" section if phase completion changed
- Remove obsolete TODOs if applicable
- Add any new follow-up TODOs discovered during merge

Always update PLAN.md to keep project status current, even if just confirming no changes needed.

### Step 8: Commit Documentation

Ask user approval, then commit the updated PRS.md and PLAN.md:
```bash
git add PRS.md docs/PLAN.md
git commit -m "$(cat <<'EOF'
Update documentation after merging PR #<number>

Moved PR #<number> to Merged section in PRS.md.
Updated PLAN.md to reflect completed work.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

### Merge PR Pre-Merge Checklist

Before merging PR:
- [ ] PR fetched and verified as ready to merge
- [ ] User approved merge operation
- [ ] PR merged successfully with `--merge` flag
- [ ] Local main branch updated
- [ ] PR branch deleted (local and remote)
- [ ] PRS.md updated (moved to "Merged" section)
- [ ] PLAN.md updated with current project status
- [ ] Documentation changes committed and pushed

---

## TODO Tracking

**PLAN.md is the single source of truth for all TODOs.**

Rules:
- All phase-affecting TODOs must be in PLAN.md
- Phase complete only when ALL checkboxes are `[x]`
- Code TODOs are notes only, must also be in PLAN.md
- roadmap.md derives from PLAN.md (keep in sync)

Before commit:
```bash
grep -r "TODO" scripts/ --include="*.sh"
```
Verify each TODO has a PLAN.md entry.

---

## Code Review Checklist

**Review areas:**
- Code quality and maintainability
- Test coverage
- Security (especially shell scripts)
- Performance implications
- Go conventions
- Shell script best practices (quoting, error handling)
- Error handling
- Concurrency safety

**Format:**
- Structured findings with file:line references
- Severity ratings
- Recommendations

---

## Commit Message Format

```
Brief summary (imperative mood)

Detailed description of what changed and why.

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

---

## Pre-Commit Checklist

Before every commit:
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Code review presented and approved (for code changes)
- [ ] Documentation updated
- [ ] PLAN.md updated with current project status
- [ ] User approved commit
