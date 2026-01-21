# Git Workflow Reference

> Detailed procedures for commits, code review, and documentation updates.
> Read this when performing git operations.

## Workflow Modes

User specifies workflow at session start. **Default is Standard** unless Create PR or Documentation is specified.

| Mode | Use Case | Approvals | Target |
|------|----------|-----------|--------|
| **Standard** | Default for code changes | Required | main branch |
| **Create PR** | PR-based development | Not required | `create-pr/` branch → PR |
| **Review PR** | Code review of PRs | Not required | PR review + PRS.md update |
| **Update PR** | Address PR feedback | Not required | Existing PR branch → resubmit |
| **Documentation** | Docs-only changes | Commit only | main or PR |

---

## Session Startup

On new session:
1. Read AGENTS.md (core rules)
2. Ask user approval, then run `git status` and `git fetch`
3. Read `docs/PLAN.md` for current TODOs and phase status
4. Acknowledge the active workflow mode
5. Report status and suggest next steps from PLAN.md

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

Sync TODOs:
- Code TODOs must have PLAN.md entries
- Phase status must reflect actual completion

#### Step 7: Commit and Push
- Ask user approval
- Use imperative mood, add Co-Authored-By line
- Execute only after all steps complete

---

## Create PR Workflow (5-Step)

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

### Step 1: Implement (TDD)

1. Create feature branch: `git checkout -b create-pr/feature-name`
2. Write failing test first
3. Implement minimum code to pass test
4. Refactor if needed

### Step 2: Test

Run automated tests (no permission needed):
```bash
go test ./...
```
- **Must pass** before proceeding
- Fix any failures before continuing

### Step 3: Build

Run build (no permission needed):
```bash
go build -o cal ./cmd/cal
```
- **Must succeed** before proceeding
- Fix any build errors before continuing

### Step 4: Create PR

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

### Step 5: Update PRS.md

1. Add new entry to `PRS.md` under "Awaiting Review" section
2. Include PR number, branch, description, and creation date
3. Move to next task

### Create PR Pre-PR Checklist

Before creating PR:
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Manual testing instructions included
- [ ] Documentation updated if needed
- [ ] TODOs synced to PLAN.md

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

### Step 6: Update PRS.md and Return to Main

**First, switch back to main branch:**
```bash
git checkout main
```

**Then move PR entry based on review outcome:**

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

---

## Update PR Workflow (7-Step)

**Purpose:** Address review feedback on PRs that need changes. Autonomously implements fixes and resubmits for review.

**Key Principles:**
- **No permission needed** - fully autonomous operation
- **Never commit to main** - work on existing PR branches
- **Autonomous fixes** - agent analyzes review feedback and implements changes
- **Skip code review** - changes already went through PR review process
- **Clean workspace** - return to main branch after updates

### Step 1: Read Changes Queue

Read `PRS.md` to find the first PR in "Awaiting Changes" section:
```bash
# Example entry format
| #42 | create-pr/add-validation | Add input validation | 2026-01-20 | Needs validation improvements |
```

If no PRs in "Awaiting Changes", report completion and exit workflow.

### Step 2: Fetch PR Branch

Checkout the PR branch locally:
```bash
gh pr checkout <PR#>
```

Verify branch is checked out successfully before proceeding.

### Step 3: Analyze Review Feedback

Read and understand the review feedback:
```bash
gh pr view <PR#>
```

Analyze the review comments to understand:
- What changes were requested
- Which files/functions need updates
- What the expected outcome should be
- Any security or quality concerns raised

### Step 4: Implement Changes

Apply the fixes based on review feedback:
- Address each requested change systematically
- Follow TDD if adding new functionality or tests
- Make minimum changes needed to address feedback
- Ensure changes align with coding standards

### Step 5: Test

Run automated tests (no permission needed):
```bash
go test ./...
```
- **Must pass** before proceeding
- Fix any failures before continuing

### Step 6: Build

Run build (no permission needed):
```bash
go build -o cal ./cmd/cal
```
- **Must succeed** before proceeding
- Fix any build errors before continuing

### Step 7: Push Changes and Update PRS.md

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

### Update PR Pre-Push Checklist

Before pushing updates:
- [ ] Review feedback fully analyzed
- [ ] All requested changes implemented
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Changes pushed to PR branch
- [ ] Switched back to main branch
- [ ] PRS.md updated (moved from "Awaiting Changes" to "Awaiting Review")

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
- [ ] TODOs synced to PLAN.md
- [ ] User approved commit
