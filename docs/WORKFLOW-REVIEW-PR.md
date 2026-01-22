# Review PR Workflow (6-Step)

> Autonomous code review of PRs with comprehensive quality assessment

**Use When:** Reviewing PRs in the "Needs Review" queue

**Key Principles:**
- **No permission needed** - fully autonomous operation
- **Fetch branch locally** - review actual code files for thoroughness
- **Comprehensive review** - assess quality, architecture, security, best practices
- **Submit formal review** - REQUEST_CHANGES or APPROVE via `gh pr review`
- **Update standards** - add new patterns to CODING_STANDARDS.md when recurring issues found
- **PLAN.md and PRS.md updates must be done on main branch**, not PR branch

---

## Overview

The Review PR workflow performs autonomous, comprehensive code reviews of PRs in the review queue. The agent checks out the PR branch, reviews code quality and architecture, identifies issues, optionally updates coding standards, submits a formal GitHub review, and updates documentation.

**Target:** PR review + PRS.md update
**Approvals:** Not required (autonomous)
**Steps:** 6 (streamlined for autonomous review)

---

## Step-by-Step Process

### Step 1: Read Review Queue

Read `PRS.md` to find the first PR in "Needs Review" section:

```markdown
| #42 | create-pr/add-validation | Add input validation | 2026-01-20 |
```

**If no PRs in "Needs Review":**
- Report completion: "No PRs awaiting review"
- Exit workflow

**If PR found:**
- Note PR number, branch name, and description
- Proceed to Step 2

### Step 2: Fetch PR Branch

Checkout the PR branch locally for thorough review:

```bash
gh pr checkout <PR#>
```

**Verify branch checked out successfully** before proceeding.

This allows reading actual code files with Read tool for comprehensive review.

### Step 3: Review Code

Perform comprehensive code review based on software engineering best practices.

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
- Specific recommendations for fixes
- Positive observations for good patterns
- Context and rationale for suggestions

### Step 4: Identify New Patterns

Review findings to determine if new error patterns should be added to CODING_STANDARDS.md.

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
1. Switch to main branch
2. Follow process in `docs/UPDATE_CODING_STANDARDS.md`:
   - Generalize the pattern (remove specific file/line refs)
   - Write prescriptive standards (Must/Never/Always)
   - Provide code examples (Bad/Good/Better)
3. Update CLAUDE.md summary if adding new categories
4. Commit changes to main
5. Return to PR branch for review submission

### Step 5: Submit Review

Submit formal GitHub review based on findings using heredoc format.

**If no changes required (APPROVE):**

```bash
gh pr review --approve --body "$(cat <<'EOF'
Code review complete. All standards met.

✅ No duplicate code
✅ Dependencies properly checked
✅ Documentation accurate
✅ Error handling correct
✅ Validation in place
✅ Security practices followed
✅ Tests comprehensive
✅ Build passes

Ready for testing phase.
EOF
)"
```

**If changes required (REQUEST_CHANGES):**

```bash
gh pr review --request-changes --body "$(cat <<'EOF'
Code review findings require updates before merge.

## Issues Found

### Security - Critical
**File:** scripts/vm-auth.sh:45
**Issue:** Command injection vulnerability in eval usage
**Fix:** Remove eval and use array for command construction

### Code Quality - Moderate
**File:** internal/config/config.go:123
**Issue:** Duplicated validation logic across Load() and Validate()
**Fix:** Extract common validation to helper function

### Documentation - Minor
**File:** docs/cli.md
**Issue:** Command examples don't match current flags
**Fix:** Update examples to use --headless instead of -h

Please address these findings and update the PR.
EOF
)"
```

**Review Body Format:**
- Clear structure with sections
- File:line references for each issue
- Severity ratings (Critical/Moderate/Minor)
- Specific fix recommendations
- Use heredoc format to preserve formatting

### Step 6: Update Documentation and Return to Main

**CRITICAL: Switch back to main branch first:**

```bash
git checkout main
```

**Then update documentation based on review outcome:**

**Update PRS.md:**

**If approved (no changes required):**
- Remove from "Needs Review" section
- Add to "Needs Testing" section:
```markdown
| #42 | create-pr/add-validation | Add input validation | Claude Sonnet 4.5 | 2026-01-21 |
```

**If changes requested:**
- Remove from "Needs Review" section
- Add to "Needs Changes" section:
```markdown
| #42 | create-pr/add-validation | Add input validation | 2026-01-21 | Security and quality issues |
```

**Update PLAN.md if PR relates to tracked work:**
- Mark any completed TODOs as `[x]`
- Update phase status if applicable
- Note any issues discovered that need follow-up

**Commit documentation updates:**
```bash
git add PRS.md docs/PLAN.md
git commit -m "$(cat <<'EOF'
Update documentation after reviewing PR #42

Moved PR #42 to [Needs Testing/Needs Changes] in PRS.md.
Updated PLAN.md with current project status.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

---

## Pre-Review Checklist

Before completing review:
- [ ] PR branch checked out and reviewed locally
- [ ] Comprehensive review completed (all 10 areas assessed)
- [ ] Findings documented with file:line references and severity
- [ ] Recurring patterns added to CODING_STANDARDS.md if applicable
- [ ] CLAUDE.md updated if new standard categories added
- [ ] Review submitted via `gh pr review` with heredoc format
- [ ] Switched back to main branch
- [ ] PRS.md updated with correct section and details
- [ ] PLAN.md updated if PR relates to tracked work
- [ ] Documentation changes committed and pushed

---

## Important Notes

### Review Quality Standards

Ensure reviews are:
- **Thorough** - Check all 10 review areas
- **Specific** - Provide file:line references
- **Actionable** - Give clear fix recommendations
- **Balanced** - Note both issues and good patterns
- **Contextual** - Explain rationale for suggestions

### PR Comments Format

Always use heredoc format for proper formatting:

```bash
gh pr review --approve --body "$(cat <<'EOF'
Review content here.
EOF
)"
```

### Documentation Updates on Main

All PRS.md and PLAN.md updates must be done on main branch:
1. Finish review on PR branch
2. Switch to main: `git checkout main`
3. Update PRS.md and PLAN.md
4. Commit and push to main

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-UPDATE-PR.md](WORKFLOW-UPDATE-PR.md) - Next step if changes requested
- [WORKFLOW-TEST-PR.md](WORKFLOW-TEST-PR.md) - Next step if approved
- [UPDATE_CODING_STANDARDS.md](UPDATE_CODING_STANDARDS.md) - How to update standards
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
- [PRS.md](../PRS.md) - PR tracking
