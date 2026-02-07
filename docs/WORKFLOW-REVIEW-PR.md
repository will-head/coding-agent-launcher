# Review & Fix PR Workflow (8-Step)

> Autonomous code review of PRs with direct issue resolution

**Use When:** Reviewing PRs in the "Needs Review" queue

**Key Principles:**
- **No permission needed** - fully autonomous operation
- **Fetch branch locally** - review actual code files for thoroughness
- **Review against requirements** - check implementation matches the refined TODO
- **Fix issues directly** - resolve minor and moderate issues on the PR branch
- **Request changes only for architectural issues** - minimize review cycles
- **Update standards** - add new patterns to CODING_STANDARDS.md when recurring issues found
- **PLAN.md and STATUS.md updates must be done on main branch**, not PR branch

---

## Overview

The Review & Fix PR workflow performs autonomous, comprehensive code reviews of PRs in the review queue. Unlike a review-only workflow, this workflow fixes minor and moderate issues directly on the PR branch, reducing the number of review cycles. Only architectural or design issues that require the original author's judgment are sent back as change requests. The agent reads the original requirements, checks out the PR branch, reviews code quality, fixes issues found, re-tests, submits a formal GitHub review, and updates documentation.

**Target:** PR review + direct fixes + STATUS.md update
**Approvals:** Not required (autonomous)
**Steps:** 8 (review with integrated fix cycle)

---

## Session Start Procedure

Follow [Session Start Procedure](WORKFLOWS.md#session-start-procedure) from Shared Conventions, highlighting:
- This is the Review & Fix PR workflow (8-step autonomous code review with direct fixes)
- Key principles: no permission needed, fetch branch, review against requirements, fix issues directly, request changes only for architectural issues
- 8 steps: Read Queue → Read Source Requirements → Fetch PR → Review Code → Fix Issues → Test & Build → Submit Review → Update Docs
- 10 comprehensive quality review areas
- Fixes minor/moderate issues directly; only architectural issues go back as change requests
- STATUS.md updates happen on main branch

---

## What to Fix vs. What to Request Changes For

### Fix Directly (on PR branch)

- Code quality issues (naming, duplication, organization)
- Missing error handling or validation
- Security vulnerabilities (injection, missing input checks)
- Test gaps (missing scenarios, weak assertions)
- Documentation mismatches (code doesn't match docs)
- Performance issues (unnecessary operations, poor patterns)
- Style and convention violations
- Missing dependency checks
- Minor logic errors with clear fixes

### Request Changes (architectural issues only)

- Fundamental design approach is wrong (e.g., wrong pattern, wrong abstraction level)
- Major structural reorganization needed (e.g., feature should be in a different package)
- Requirements misunderstood (implementation doesn't match what was asked for)
- Breaking changes to public interfaces that need design discussion
- Trade-offs that require the original author's judgment

**Rule of thumb:** If you can fix it confidently without changing the overall design, fix it. If fixing it would change the fundamental approach, request changes.

---

## Step-by-Step Process

### Step 1: Read Review Queue

**Note:** Session Start Procedure ensures you're on main branch before this step (STATUS.md is only updated on main).

Read `STATUS.md` to find the first PR in "Needs Review" section:

```markdown
| #42 | create-pr/add-validation | Add input validation | 2026-01-20 |
```

**If no PRs in "Needs Review":**
- Report completion: "No PRs awaiting review"
- Exit workflow

**If multiple PRs found:**
- Present using [Numbered Choice Presentation](WORKFLOWS.md#numbered-choice-presentation) so user can select by number

**If PR found/selected:**
- Note PR number, branch name, and description
- Note the location reference (phase TODO file section) if available
- Proceed to Step 2

### Step 2: Read Source Requirements

Read the original refined TODO from the phase TODO file to understand what was requested:

- Find the TODO item that corresponds to the PR (from STATUS.md location reference or PR description)
- Read the full requirements, constraints, and acceptance criteria
- Keep these requirements accessible for reviewing the implementation against them

This ensures the review checks whether the implementation actually matches what was asked for, not just whether the code is clean.

### Step 3: Fetch PR Branch

Checkout the PR branch locally for thorough review:

```bash
gh pr checkout <PR#>
```

**Verify branch checked out successfully** before proceeding.

This allows reading actual code files with Read tool for comprehensive review.

### Step 4: Review Code

Perform comprehensive code review against the source requirements and software engineering best practices.

**Review Areas:**

1. **Code Quality**
   - Readability and maintainability
   - Modularity and abstraction levels
   - Code organization and structure
   - Naming conventions
   - Comment quality and necessity

2. **Architecture**
   - Design patterns appropriateness
   - Separation of concerns
   - Dependency management
   - Interface design
   - Coupling and cohesion

3. **Correctness**
   - Logic errors
   - Edge cases handling
   - Race conditions
   - Off-by-one errors
   - Null/nil pointer issues
   - **Requirements match** - does the implementation satisfy the original TODO?

4. **Error Handling**
   - Proper error propagation
   - Meaningful error messages
   - Recovery strategies
   - Error wrapping with context

5. **Security**
   - Input validation
   - Injection vulnerabilities (SQL, command, XSS)
   - Authentication and authorization
   - Secrets management
   - OWASP Top 10 considerations

6. **Performance**
   - Algorithmic complexity
   - Resource usage (memory, CPU)
   - Unnecessary operations
   - Caching opportunities
   - Database query efficiency

7. **Testing**
   - Test coverage (all scenarios)
   - Test quality and maintainability
   - Missing test scenarios
   - Test data appropriateness
   - Mock usage correctness

8. **Documentation**
   - Accuracy (code matches docs)
   - Completeness
   - Clarity
   - Examples provided
   - User-facing changes documented

9. **Language Conventions**
   - Go idioms and best practices
   - Shell script best practices
   - Style consistency
   - Standard library usage

10. **Dependencies**
    - Appropriate tool usage
    - Version management
    - Missing dependency checks
    - External tool availability validation

**Document Findings:**
- File and line references for each issue
- Severity: critical (blocks merge), moderate (should fix), minor (nice to have)
- Classification: fixable (will fix directly) or architectural (request changes)
- Specific recommendations for fixes
- Positive observations for good patterns
- Context and rationale for suggestions

### Step 5: Fix Issues

For all issues classified as fixable (not architectural), fix them directly on the PR branch.

**For each fixable issue:**
1. Make the code change to resolve the issue
2. Verify the fix addresses the root cause, not just the symptom
3. Follow coding standards and best practices

**Implementation Guidelines:**
- Fix issues methodically, one at a time
- Follow TDD if adding new test coverage
- Keep fixes focused on the identified issues
- Add tests for any new functionality or fixed edge cases
- Update inline documentation if behavior changed

**Track what was fixed:**
- Maintain a list of issues fixed for the review summary
- Note any issues that turned out to be more complex than expected

**If a "fixable" issue turns out to be architectural:**
- Stop fixing it and reclassify as architectural
- Note it for the change request in Step 7

### Step 6: Test & Build

After fixing issues, verify everything still works.

**Run tests:**
```bash
go test ./...
```

**Run build:**
```bash
go build -o calf ./cmd/calf
```

**Both must pass before proceeding.** If fixes introduced regressions, fix them before continuing.

**Commit fixes on the PR branch:**
```bash
git add -A && git commit -m "$(cat <<'EOF'
Address review findings

Fix issues identified during code review:
- [list key fixes]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

### Step 7: Submit Review

Submit formal GitHub review based on findings using heredoc format.

**Determine review outcome:**

**If all issues were fixed directly (APPROVE):**

```bash
gh pr review --approve --body "$(cat <<'EOF'
Code review complete. Issues found and fixed directly on the branch.

## Issues Fixed
- [List each issue that was fixed with file:line references]

## Quality Assessment
✅ Code quality meets standards
✅ Architecture appropriate
✅ Error handling correct
✅ Security practices followed
✅ Tests comprehensive
✅ Build passes
✅ Requirements satisfied

All fixes verified with passing tests and build. Ready for testing phase.
EOF
)"
```

**If architectural issues remain (REQUEST_CHANGES):**

```bash
gh pr review --request-changes --body "$(cat <<'EOF'
Code review complete. Minor/moderate issues fixed directly on the branch. Architectural issues require author attention.

## Issues Fixed (on branch)
- [List each issue that was fixed]

## Architectural Issues (require changes)
### [Issue Title] - Critical
**File:** path/to/file.go:123
**Issue:** Description of the architectural problem
**Recommendation:** Suggested approach to resolve

Please address the architectural issues above and update the PR.
EOF
)"
```

**Review Body Format:**
- Clear separation between fixed issues and remaining issues
- File:line references for remaining issues
- Severity ratings for remaining issues (Critical/Moderate)
- Specific fix recommendations for remaining issues
- Use heredoc format to preserve formatting

### Step 8: Update Documentation and Return to Main

**CRITICAL: Switch back to main branch first:**

```bash
git checkout main
```

**Then update documentation based on review outcome:**

**Update STATUS.md:**

**If approved (all issues fixed or no issues found):**
- Remove from "Needs Review" section
- Add to "Needs Testing" section:
```markdown
| #42 | create-pr/add-validation | Add input validation | Claude Opus 4.5 | 2026-01-21 |
```

**If architectural changes requested:**
- Remove from "Needs Review" section
- Add to "Needs Changes" section:
```markdown
| #42 | create-pr/add-validation | Add input validation | 2026-01-21 | Architectural issues - [brief description] |
```

**Identify New Patterns for CODING_STANDARDS.md:**

Review findings to determine if new error patterns should be added:

**Add to CODING_STANDARDS.md if:**
- Pattern is recurring or likely to recur across multiple PRs
- New category of mistake not currently documented
- Security vulnerability in code pattern discovered
- Best practice emerged from this implementation that others should follow

**Do NOT add for:**
- One-off mistakes unlikely to repeat
- Trivial style preferences
- Project-specific implementation details

**If adding to CODING_STANDARDS.md:**
1. Follow process in `docs/UPDATE_CODING_STANDARDS.md`
2. Update CLAUDE.md summary if adding new categories
3. Commit changes to main

**Update PLAN.md and phase TODO files if PR relates to tracked work:**
- Note review status in phase TODO file (e.g., `- [ ] Add validation (PR #42 - approved, needs testing)`)
- Update PLAN.md phase status if applicable
- Add any issues discovered that need follow-up to phase TODO file
- **Note:** Do NOT move TODOs to DONE file yet - this happens during Merge PR workflow

**Commit documentation updates** using [Commit Message Format](WORKFLOWS.md#commit-message-format). Push after commit.

**Suggest next workflow** by checking STATUS.md — see [Next Workflow Guidance](WORKFLOWS.md#next-workflow-guidance).

---

## Pre-Review Checklist

Before completing review:
- [ ] Source requirements read from phase TODO file
- [ ] PR branch checked out and reviewed locally
- [ ] Comprehensive review completed (all 10 areas assessed against requirements)
- [ ] Findings documented with file:line references, severity, and classification
- [ ] All fixable issues resolved directly on PR branch
- [ ] Tests pass after fixes (`go test ./...`)
- [ ] Build succeeds after fixes (`go build -o calf ./cmd/calf`)
- [ ] Fixes committed and pushed to PR branch
- [ ] Recurring patterns added to CODING_STANDARDS.md if applicable
- [ ] CLAUDE.md updated if new standard categories added
- [ ] Review submitted via `gh pr review` with heredoc format
- [ ] Switched back to main branch
- [ ] STATUS.md updated with correct section and details
- [ ] PLAN.md and phase TODO files updated if PR relates to tracked work
- [ ] Documentation changes committed and pushed

---

## Important Notes

### Review Quality Standards

Ensure reviews are:
- **Thorough** - Check all 10 review areas against requirements
- **Specific** - Provide file:line references
- **Actionable** - Fix issues directly when possible
- **Balanced** - Note both issues and good patterns
- **Contextual** - Explain rationale for suggestions

### PR Comments Format

See [PR Comments Format](WORKFLOWS.md#pr-comments-format) in Shared Conventions.

### Documentation Updates on Main

See [Documentation Updates on Main](WORKFLOWS.md#documentation-updates-on-main) in Shared Conventions.

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-UPDATE-PR.md](WORKFLOW-UPDATE-PR.md) - Rare fallback for architectural issues
- [WORKFLOW-TEST-PR.md](WORKFLOW-TEST-PR.md) - Next step if approved
- [UPDATE_CODING_STANDARDS.md](UPDATE_CODING_STANDARDS.md) - How to update standards
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
- [STATUS.md](../STATUS.md) - PR tracking
