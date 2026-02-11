# Merge PR Workflow (8-Step)

> Merge tested PRs into main with user approvals

**Use When:** Merging PRs from "Needs Merging" section into main branch

**Key Principles:**
- **User approval required on HOST** - ask permission before all commands (auto-approved when `CALF_VM=true`; see [CALF_VM Auto-Approve](WORKFLOWS.md#cal_vm-auto-approve))
- **Use merge commit** - preserves full PR history with `--merge` flag
- **Delete branches after merge** - clean up both local and remote
- **Track merged PRs** - move to "Merged" section in STATUS.md
- **Update PLAN.md** - mark completed TODOs, update phase status

---

## Overview

The Merge PR workflow integrates tested PRs into the main branch. With user approval at each step on HOST (auto-approved when `CALF_VM=true`), the agent merges the PR, updates the local main branch, deletes the feature branch, and updates all documentation.

**Target:** PR → main branch (integration)
**Approvals:** Required on HOST for all commands (auto-approved when `CALF_VM=true`)
**Steps:** 8 (full merge and cleanup)

---

## Session Start Procedure

Follow [Session Start Procedure](WORKFLOWS.md#session-start-procedure) from Shared Conventions, highlighting:
- This is the Merge PR workflow (8-step with approvals)
- Key principles: user approval required on HOST (auto-approved when `CALF_VM=true`), merge commit strategy, delete branches, track merged PRs, update PLAN.md
- 8 steps: Read Queue → Fetch PR → Merge PR → Update Local Main → Delete Branch → Update STATUS.md → Update PLAN.md → Commit Docs
- Integrates tested PRs into main
- All commands require user approval on HOST (auto-approved when `CALF_VM=true`)

---

## Step-by-Step Process

### Step 1: Read Merge Queue

**Note:** Session Start Procedure ensures you're on main branch before this step (STATUS.md is only updated on main).

Read `STATUS.md` to find the first PR in "Needs Merging" section:

```markdown
| #42 | create-pr/add-validation | Add input validation | User Name | 2026-01-21 |
```

**If no PRs in "Needs Merging":**
- Report completion: "No PRs ready to merge"
- Exit workflow

**If multiple PRs found:**
- Present using [Numbered Choice Presentation](WORKFLOWS.md#numbered-choice-presentation) so user can select by number

**If PR found/selected:**
- Note PR number, branch name, description, and test details
- Proceed to Step 2

### Step 2: Fetch PR Details

**Ask user approval** (auto-approved when `CALF_VM=true`), then verify PR is ready to merge:

```bash
gh pr view <PR#>
```

**Check that:**
- PR is approved (review status shows approval)
- All checks pass (CI/tests green)
- No merge conflicts
- Target branch is main
- Branch is up to date with main

**If any issues found:**
- Report issues to user
- Stop workflow
- User must resolve before proceeding

### Step 3: Merge PR

**Ask user approval** (auto-approved when `CALF_VM=true`), then merge with merge commit strategy:

```bash
gh pr merge <PR#> --merge
```

The `--merge` flag creates a merge commit that preserves the full PR history, including all commits made during development and review cycles.

**If merge fails:**
- Check for conflicts: "merge conflict detected"
- Verify PR state: "PR not in mergeable state"
- Check permissions: "insufficient permissions"
- Report error to user
- Stop workflow

**On success:**
- GitHub merges PR to main
- PR is automatically closed
- Proceed to Step 4

### Step 4: Update Local Main

**Ask user approval** (auto-approved when `CALF_VM=true`), then update local main branch:

```bash
git checkout main
git pull
```

This ensures the local repository reflects the merged changes.

**Verify:**
- Checkout to main succeeds
- Pull completes without conflicts
- Merge commit appears in git log

### Step 5: Delete Branch

**Ask user approval** (auto-approved when `CALF_VM=true`), then delete both local and remote PR branch:

```bash
git branch -d <branch-name>
git push origin --delete <branch-name>
```

Only delete after successful merge confirmation.

**Notes:**
- Local delete (`-d`) is safe - won't delete unmerged branches
- Remote delete may fail if GitHub auto-deleted (not an error)
- If deletion fails, report but continue workflow

### Step 6: Update STATUS.md

Move PR entry from "Needs Merging" to "Merged" section with merge date.

**Remove from "Needs Merging":**
```markdown
| #42 | create-pr/add-validation | Add input validation | User Name | 2026-01-21 |
```

**Add to "Merged" section:**
```markdown
## Merged

| PR | Branch | Description | Merged |
|----|--------|-------------|--------|
| #42 | create-pr/add-validation | Add input validation | 2026-01-21 |
```

Create "Merged" section if it doesn't exist.

### Step 7: Update PLAN.md and Phase TODO Files

Update PLAN.md and phase TODO files to reflect current project status after merge:

**Move completed TODOs from TODO file to DONE file** following [TODO → DONE Movement](WORKFLOWS.md#todo--done-movement) rules from Shared Conventions.

**Update PLAN.md phase status:**
- If all TODOs in phase complete, update phase status in PLAN.md
- Update "Current Status" section if phase changed
- Add completion notes if applicable

**Add follow-up TODOs:**
- Add any issues discovered during merge to appropriate phase TODO file
- Add items for future improvements mentioned in PR

**Always update** to keep project status current.

### Step 8: Commit Documentation

**Ask user approval** (auto-approved when `CALF_VM=true`), then commit using [Commit Message Format](WORKFLOWS.md#commit-message-format). Stage STATUS.md, PLAN.md, and phase TODO/DONE files. Push after commit.

**Verify push succeeds** - ensures documentation updates are preserved.

**Suggest next workflow** by checking STATUS.md — see [Next Workflow Guidance](WORKFLOWS.md#next-workflow-guidance).

---

## Handling Aborted/Closed PRs

If a PR is closed without merging (abandoned, superseded, or filed as known issue):

1. **Close the PR on GitHub** (if not already closed):
   ```bash
   gh pr close <PR#> --comment "$(cat <<'EOF'
   Closing this PR: [reason for closure]

   [Additional context if needed]
   EOF
   )"
   ```

2. **Switch to main branch:**
   ```bash
   git checkout main
   ```

3. **Update STATUS.md:**
   - Remove from current section
   - Add to "Closed" section:
   ```markdown
   | #42 | create-pr/add-validation | Add input validation | 2026-01-21 | Filed as known issue |
   ```

4. **Move TODO to DONE file with closure note:**
   - Cut TODO from phase TODO file (e.g., `docs/PLAN-PHASE-00-TODO.md`)
   - Paste into phase DONE file (e.g., `docs/PLAN-PHASE-00-DONE.md`) with:
   - Example: `- [x] Add validation (PR #42 closed - filed as known issue in PLAN-PHASE-00-TODO.md § Known Issues)`
   - Or: `- [x] Add validation (PR #42 closed - superseded by PR #45)`
   - Or: `- [x] Add validation (PR #42 closed - approach abandoned)`

5. **Add to Known Issues section if applicable:**
   - If the issue remains but implementation was abandoned, add to phase TODO file § Known Issues
   - Reference the closed PR for context

6. **Delete branches:**
   ```bash
   git branch -d <branch-name>
   git push origin --delete <branch-name>
   ```

7. **Commit documentation** using [Commit Message Format](WORKFLOWS.md#commit-message-format). Push after commit.

---

## Pre-Merge Checklist

Before merging PR:
- [ ] PR fetched and verified as ready to merge
- [ ] User approved merge operation
- [ ] PR merged successfully with `--merge` flag
- [ ] Local main branch updated (`git pull`)
- [ ] PR branch deleted (local and remote)
- [ ] STATUS.md updated (moved to "Merged" section)
- [ ] Completed TODOs moved from phase TODO file to phase DONE file
- [ ] PLAN.md phase status updated if applicable
- [ ] New follow-up TODOs added to appropriate phase TODO file
- [ ] Documentation changes committed with Co-Authored-By
- [ ] Documentation changes pushed to remote

---

## Important Notes

### Merge Strategy

Always use `--merge` flag to create merge commits:
- Preserves full PR history
- Shows all review cycles
- Maintains commit authorship
- Enables easy revert if needed

**Never use:**
- `--squash` - loses PR history
- `--rebase` - rewrites commit history

### Branch Deletion Safety

Local branch deletion with `-d` is safe:
- Won't delete if branch has unmerged commits
- Protects against accidental data loss
- Use `-D` only if absolutely necessary (not in this workflow)

### Approval Requirements

User approval is required on HOST (auto-approved when `CALF_VM=true`) for:
- Fetching PR details (`gh pr view`)
- Merging PR (`gh pr merge`)
- Updating local main (`git checkout` + `git pull`)
- Deleting branches (`git branch -d` + `git push --delete`)
- Committing documentation (`git commit` + `git push`)

**Note:** `git push --delete` is a destructive remote operation and always requires explicit approval, even when `CALF_VM=true`.

### Documentation Commit Format

See [Commit Message Format](WORKFLOWS.md#commit-message-format) in Shared Conventions.

---

## Troubleshooting

### Merge Conflicts
**Issue:** "merge conflict detected"
**Solution:**
1. Check out PR branch
2. Merge main into PR branch
3. Resolve conflicts
4. Push updated branch
5. Retry merge

### Branch Not Mergeable
**Issue:** "PR not in mergeable state"
**Solution:**
1. Verify all checks pass
2. Ensure PR is approved
3. Check for conflicts with main
4. Resolve issues, retry merge

### Permission Denied
**Issue:** "insufficient permissions"
**Solution:**
1. Verify GitHub authentication
2. Check repository permissions
3. Ensure gh CLI is authenticated

