# Test PR Workflow (7-Step)

> Manual testing gate with user confirmation before merge

**Use When:** Testing PRs in "Needs Testing" section before merge

**Key Principles:**
- **Autonomous until test presentation** - no permission to fetch PR details
- **User approval required** - must wait for manual test results confirmation (always required, even when `CAL_VM=true` — the agent cannot perform manual tests)
- **PR comments for feedback** - add comment with failure details if tests fail
- **Update STATUS.md status** - move to "Needs Merging" on success or "Needs Changes" on failure
- **PLAN.md updates must be done on main branch**

---

## Overview

The Test PR workflow provides a manual testing gate before merge. The agent fetches PR details, presents manual testing instructions to the user, waits for confirmation, and updates documentation based on test results.

**Target:** Manual test + STATUS.md update
**Approvals:** Required for test confirmation only (always required, even when `CAL_VM=true`)
**Steps:** 7 (includes conditional paths)

---

## Session Start Procedure

Follow [Session Start Procedure](WORKFLOWS.md#session-start-procedure) from Shared Conventions, highlighting:
- This is the Test PR workflow (7-step manual testing gate)
- Key principles: autonomous until test presentation, user approval for confirmation, PR comments for feedback, conditional paths
- 7 steps: Read Queue → Fetch Details → Present Tests → WAIT → Evaluate → Success/Failure Path → Update Docs
- Blocking wait for user test confirmation
- STATUS.md updates happen on main branch

---

## Step-by-Step Process

### Step 1: Read Test Queue

**Note:** Session Start Procedure ensures you're on main branch before this step (STATUS.md is only updated on main).

Read `STATUS.md` to find the first PR in "Needs Testing" section:

```markdown
| #42 | create-pr/add-validation | Add input validation | Claude Sonnet 4.5 | 2026-01-21 |
```

**If no PRs in "Needs Testing":**
- Report completion: "No PRs need testing"
- Exit workflow

**If multiple PRs found:**
- Present using [Numbered Choice Presentation](WORKFLOWS.md#numbered-choice-presentation) so user can select by number

**If PR found/selected:**
- Note PR number, branch name, and description
- Proceed to Step 2

### Step 2: Fetch PR Details

Fetch PR details to retrieve manual testing instructions (no permission needed):

```bash
gh pr view <PR#>
```

Extract the "Manual Testing Instructions" section from the PR description. This was created during the Create PR workflow (Step 5).

### Step 3: Present Test Instructions

Present testing instructions to the user **one by one** following the [Sequential Question and Test Presentation](WORKFLOWS.md#sequential-question-and-test-presentation) convention:

1. Announce the PR being tested: "Manual Testing Required for PR #42: Add input validation"
2. Present the **first** test instruction with its expected outcome
3. **STOP and wait** for the user to confirm pass/fail
4. If a test fails, the user can choose to:
   - **Fix it now** - address the issue before continuing
   - **Add as a TODO** - add it to the appropriate phase TODO file for later
   - **Accept as known issue** - acknowledge and proceed
5. Only after the current test is resolved, present the **next** test instruction
6. Continue until all tests have been presented

**Example (presenting one test at a time):**
```
Manual Testing Required for PR #42: Add input validation

Test 1 of 3:
Run `./scripts/cal-bootstrap --snapshot create test@invalid`
Expected: Error message "Invalid snapshot name"

Please run this test and confirm: pass or fail?
```

After user confirms, present the next test:
```
Test 2 of 3:
Run `./scripts/cal-bootstrap --snapshot create test-valid`
Expected: Snapshot created successfully

Please run this test and confirm: pass or fail?
```

**Do not present all tests at once.** Each test must be individually confirmed before proceeding.

### Step 4: Evaluate Test Results

After all tests have been presented one by one, evaluate the overall outcome:

**If all tests passed (or failures were accepted as known issues/TODOs):**
- Proceed to Step 5 (Update STATUS.md - Success Path)

**If any tests failed and were not resolved:**
- Proceed to Step 6 (Add Failure Comment)
- Include details of which specific tests failed and how

### Step 5: Update STATUS.md - Success Path

If manual tests passed, update STATUS.md to move PR to "Needs Merging" section.

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

### Step 6: Add Failure Comment and Update STATUS.md

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

### Step 7: Update PLAN.md and Phase TODO Files

Update PLAN.md and phase TODO files with current project status:

**If tests passed (moving to "Needs Merging"):**
- Note testing outcome in phase TODO file (e.g., `- [ ] Add validation (PR #42 - tested, needs merge)`)
- **Note:** Do NOT move TODOs to DONE file yet - this happens during Merge PR workflow

**If tests failed (moving to "Needs Changes"):**
- Note testing outcome in phase TODO file (e.g., `- [ ] Add validation (PR #42 - test failed, needs fixes)`)
- **Note:** Do NOT move TODOs to DONE file yet - wait for fixes or closure

**If PR is being closed/abandoned (not proceeding):**
- **Move TODO from TODO file to DONE file** with closure note
- Example: `- [x] Add validation (PR #42 closed - test failures, filed as known issue)`
- Update PLAN.md phase status if applicable

**Always update** to keep project status current.

**Commit documentation updates** using [Commit Message Format](WORKFLOWS.md#commit-message-format). Push after commit.

**Suggest next workflow** by checking STATUS.md — see [Next Workflow Guidance](WORKFLOWS.md#next-workflow-guidance).

---

## Pre-Test Checklist

Before completing workflow:
- [ ] PR details fetched from "Needs Testing" section
- [ ] Manual testing instructions presented to user
- [ ] User confirmation received (passed or failed)
- [ ] PR comment added if tests failed (with heredoc format)
- [ ] Switched back to main branch
- [ ] STATUS.md updated ("Needs Merging" if passed, "Needs Changes" if failed)
- [ ] PLAN.md and phase TODO files updated with current project status
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

See [PR Comments Format](WORKFLOWS.md#pr-comments-format) in Shared Conventions.

### Documentation Updates on Main

See [Documentation Updates on Main](WORKFLOWS.md#documentation-updates-on-main) in Shared Conventions.

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
- [STATUS.md](../STATUS.md) - PR tracking
