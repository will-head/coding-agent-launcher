# Merge PR Workflow (8-Step)

> Merge tested PRs into main with user approvals

**Use When:** Merging PRs from "Needs Merging" section into main branch

**Key Principles:**
- **User approval required** - ask permission before all commands
- **Use merge commit** - preserves full PR history with `--merge` flag
- **Delete branches after merge** - clean up both local and remote
- **Track merged PRs** - move to "Merged" section in STATUS.md
- **Update PLAN.md** - mark completed TODOs, update phase status

---

## Overview

The Merge PR workflow integrates tested PRs into the main branch. With user approval at each step, the agent merges the PR, updates the local main branch, deletes the feature branch, and updates all documentation.

**Target:** PR → main branch (integration)
**Approvals:** Required for all commands
**Steps:** 8 (full merge and cleanup)

---

## Session Start Procedure

At the start of each new session using this workflow:

1. **Read this workflow file** - Read `docs/WORKFLOW-MERGE-PR.md` in full
2. **Reiterate to user** - Summarize the workflow in your own words:
   - Explain this is the Merge PR workflow (8-step with approvals)
   - List the key principles (user approval required, merge commit strategy, delete branches, track merged PRs, update PLAN.md)
   - Outline the 8 steps (Read Queue → Fetch PR → Merge PR → Update Local Main → Delete Branch → Update STATUS.md → Update PLAN.md → Commit Docs)
   - Mention that this integrates tested PRs into main
   - Note that all commands require user approval
3. **Confirm understanding** - Acknowledge understanding of the workflow before proceeding
4. **Proceed with standard session start** - Continue with git status, PLAN.md reading, etc.

This ensures both agent and user have shared understanding of the workflow being followed.

---

## Step-by-Step Process

### Step 1: Read Merge Queue

Read `STATUS.md` to find the first PR in "Needs Merging" section:

```markdown
| #42 | create-pr/add-validation | Add input validation | User Name | 2026-01-21 |
```

**If no PRs in "Needs Merging":**
- Report completion: "No PRs ready to merge"
- Exit workflow

**If PR found:**
- Note PR number, branch name, description, and test details
- Proceed to Step 2

### Step 2: Fetch PR Details

**Ask user approval**, then verify PR is ready to merge:

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

**Ask user approval**, then merge with merge commit strategy:

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

**Ask user approval**, then update local main branch:

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

**Ask user approval**, then delete both local and remote PR branch:

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

**Move completed TODOs from TODO file to DONE file:**
- Find TODOs related to this PR in active phase TODO file (e.g., `docs/PLAN-PHASE-00-TODO.md`)
- **Cut the completed TODO** from the TODO file
- **Paste into the DONE file** (e.g., `docs/PLAN-PHASE-00-DONE.md`) with:
  - `[x]` checkbox
  - PR number reference
  - Completion date
  - Example: `- [x] Add snapshot validation (PR #42, merged 2026-01-21)`

**Update PLAN.md phase status:**
- If all TODOs in phase complete, update phase status in PLAN.md
- Update "Current Status" section if phase changed
- Add completion notes if applicable

**Add follow-up TODOs:**
- Add any issues discovered during merge to appropriate phase TODO file
- Add items for future improvements mentioned in PR

**Always update** to keep project status current.

### Step 8: Commit Documentation

**Ask user approval**, then commit the updated STATUS.md, PLAN.md, and phase TODO files:

```bash
git add STATUS.md PLAN.md docs/PLAN-PHASE-*-TODO.md docs/PLAN-PHASE-*-DONE.md
git commit -m "$(cat <<'EOF'
Update documentation after merging PR #42

Moved PR #42 to Merged section in STATUS.md.
Moved completed TODO from PLAN-PHASE-00-TODO.md to PLAN-PHASE-00-DONE.md.
Updated PLAN.md: phase status reflects completion.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

**Verify push succeeds** - ensures documentation updates are preserved.

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

7. **Commit documentation:**
   ```bash
   git add STATUS.md docs/PLAN-PHASE-*-TODO.md docs/PLAN-PHASE-*-DONE.md
   git commit -m "$(cat <<'EOF'
   Update documentation after closing PR #42

   Moved PR #42 to Closed section in STATUS.md.
   Moved TODO from PLAN-PHASE-00-TODO.md to PLAN-PHASE-00-DONE.md with closure note.
   [Added to Known Issues if applicable]

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
   EOF
   )"
   git push
   ```

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

User approval is required for:
- Fetching PR details (`gh pr view`)
- Merging PR (`gh pr merge`)
- Updating local main (`git checkout` + `git pull`)
- Deleting branches (`git branch -d` + `git push --delete`)
- Committing documentation (`git commit` + `git push`)

### Documentation Commit Format

```bash
git commit -m "$(cat <<'EOF'
Update documentation after merging PR #<number>

Brief description of what was merged.
Phase TODO file updates summary (completed TODOs marked).
PLAN.md updates summary (phase status if changed).

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

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

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-TEST-PR.md](WORKFLOW-TEST-PR.md) - Previous step: PR testing
- [PR-WORKFLOW-DIAGRAM.md](PR-WORKFLOW-DIAGRAM.md) - Visual workflow diagram
- [STATUS.md](../STATUS.md) - PR tracking
- [PLAN.md](../PLAN.md) - Project status
