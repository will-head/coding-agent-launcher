# Test PR Workflow (7-Step)

> Manual testing gate with user confirmation before merge

**Use When:** Testing PRs in "Needs Testing" section before merge

**Key Principles:**
- **Autonomous until test presentation** - no permission to fetch PR details
- **User approval required** - must wait for manual test results confirmation
- **PR comments for feedback** - add comment with failure details if tests fail
- **Update PRS.md status** - move to "Needs Merging" on success or "Needs Changes" on failure
- **PLAN.md updates must be done on main branch**

---

## Overview

The Test PR workflow provides a manual testing gate before merge. The agent fetches PR details, presents manual testing instructions to the user, waits for confirmation, and updates documentation based on test results.

**Target:** Manual test + PRS.md update
**Approvals:** Required for test confirmation only
**Steps:** 7 (includes conditional paths)

---

## Step-by-Step Process

### Step 1: Read Test Queue

Read `PRS.md` to find the first PR in "Needs Testing" section:

```markdown
| #42 | create-pr/add-validation | Add input validation | Claude Sonnet 4.5 | 2026-01-21 |
```

**If no PRs in "Needs Testing":**
- Report completion: "No PRs need testing"
- Exit workflow

**If PR found:**
- Note PR number, branch name, and description
- Proceed to Step 2

### Step 2: Fetch PR Details

Fetch PR details to retrieve manual testing instructions (no permission needed):

```bash
gh pr view <PR#>
```

Extract the "Manual Testing Instructions" section from the PR description. This was created during the Create PR workflow (Step 5).

### Step 3: Present Test Instructions

Present the full manual testing instructions to the user in clear, actionable format:

**Format:**
```
Manual Testing Required for PR #42: Add input validation

## Test Instructions
1. Run `./scripts/cal-bootstrap --snapshot create test@invalid`
   - Expected: Error message "Invalid snapshot name"

2. Run `./scripts/cal-bootstrap --snapshot create test-valid`
   - Expected: Snapshot created successfully

3. Run `./scripts/cal-bootstrap --snapshot list`
   - Expected: Shows test-valid in list

## Expected Outcomes
- Invalid characters rejected with clear error
- Valid names accepted and snapshot created
- New snapshot appears in list

Please run these tests and respond with:
- "tests passed" or "pass" - if all tests succeed
- "tests failed: [details]" - if any tests fail, include what went wrong
```

**STOP and wait for user response.** Do not proceed until user confirms test results.

### Step 4: Evaluate Test Results

Based on user response:

**If tests passed:**
- User said: "tests passed", "pass", "all good", "works", "success", etc.
- Proceed to Step 5 (Update PRS.md - Success Path)

**If tests failed:**
- User said: "tests failed", "fail", "doesn't work", "error", etc.
- Proceed to Step 6 (Add Failure Comment)

### Step 5: Update PRS.md - Success Path

If manual tests passed, update PRS.md to move PR to "Needs Merging" section.

1. **Switch to main branch** (if not already):
   ```bash
   git checkout main
   ```

2. **Remove from "Needs Testing" section**

3. **Add to "Needs Merging" section:**
   ```markdown
   ## Needs Merging

   | PR | Branch | Description | Tested By | Tested Date |
   |----|--------|-------------|-----------|-------------|
   | #42 | create-pr/add-validation | Add input validation | User Name | 2026-01-21 |
   ```

4. **Proceed to Step 7** (Update PLAN.md)

### Step 6: Add Failure Comment and Update PRS.md

If manual tests failed:

1. **Add comment to PR** with failure details (no permission needed):
   ```bash
   gh pr comment <PR#> --body "$(cat <<'EOF'
   Manual testing failed.

   ## Test Failure Details
   Step 2 failed: Snapshot created but name contained invalid characters.
   Expected error message was not shown.

   ## Issue
   Validation logic not catching special characters properly.

   Please address these issues and resubmit for review.
   EOF
   )"
   ```

2. **Switch to main branch:**
   ```bash
   git checkout main
   ```

3. **Remove from "Needs Testing" section**

4. **Add back to "Needs Changes" section:**
   ```markdown
   | #42 | create-pr/add-validation | Add input validation | 2026-01-21 | Manual test failure: validation incomplete |
   ```

5. **Proceed to Step 7** (Update PLAN.md)

### Step 7: Update PLAN.md

Update PLAN.md with current project status:
- Mark any completed TODOs as `[x]` if the PR relates to tracked work
- Update phase status if applicable
- Note testing outcome in relevant sections

**Always update PLAN.md** to keep project status current.

**Commit documentation updates:**
```bash
git add PRS.md docs/PLAN.md
git commit -m "$(cat <<'EOF'
Update documentation after testing PR #42

Moved PR #42 to [Needs Merging/Needs Changes] in PRS.md.
Updated PLAN.md with current project status.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

---

## Pre-Test Checklist

Before completing workflow:
- [ ] PR details fetched from "Needs Testing" section
- [ ] Manual testing instructions presented to user
- [ ] User confirmation received (passed or failed)
- [ ] PR comment added if tests failed (with heredoc format)
- [ ] Switched back to main branch
- [ ] PRS.md updated ("Needs Merging" if passed, "Needs Changes" if failed)
- [ ] PLAN.md updated with current project status
- [ ] Documentation changes committed and pushed

---

## Important Notes

### Test Instruction Clarity

When presenting tests, ensure:
- Step-by-step instructions are clear
- Expected outcomes are explicit
- Commands are copy-pasteable
- Edge cases are included
- Error scenarios are tested

### User Response Interpretation

Accept various phrasings:
- **Pass:** "tests passed", "pass", "all good", "works", "success", "✓", "✅"
- **Fail:** "tests failed", "fail", "doesn't work", "error", "broken", "✗", "❌"

When ambiguous, ask for clarification.

### Failure Comment Format

Always use heredoc format for PR comments:

```bash
gh pr comment <PR#> --body "$(cat <<'EOF'
Manual testing failed.

## Test Failure Details
[User's description of what failed]

## Issue
[Analysis of the problem]

Please address these issues and resubmit for review.
EOF
)"
```

### Documentation Updates on Main

All PRS.md and PLAN.md updates must be done on main branch:
1. Stay on main throughout workflow (no branch checkout needed)
2. Update PRS.md based on test results
3. Update PLAN.md
4. Commit and push to main

---

## Test Failure Loop

If tests fail, PR goes back through the workflow:
1. Test PR → Needs Changes (this workflow)
2. Update PR → Needs Review (autonomous fixes)
3. Review PR → Needs Testing (re-approval)
4. Test PR → Needs Merging (retry tests)
5. Merge PR → Merged (final)

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-MERGE-PR.md](WORKFLOW-MERGE-PR.md) - Next step if tests pass
- [WORKFLOW-UPDATE-PR.md](WORKFLOW-UPDATE-PR.md) - Next step if tests fail
- [PR-WORKFLOW-DIAGRAM.md](PR-WORKFLOW-DIAGRAM.md) - Visual workflow diagram
- [PRS.md](../PRS.md) - PR tracking
