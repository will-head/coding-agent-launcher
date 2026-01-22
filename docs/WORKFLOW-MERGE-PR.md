# Merge PR Workflow (8-Step)

> Merge tested PRs into main with user approvals

**Use When:** Merging PRs from "Needs Merging" section into main branch

**Key Principles:**
- **User approval required** - ask permission before all commands
- **Use merge commit** - preserves full PR history with `--merge` flag
- **Delete branches after merge** - clean up both local and remote
- **Track merged PRs** - move to "Merged" section in PRS.md
- **Update PLAN.md** - mark completed TODOs, update phase status

---

## Overview

The Merge PR workflow integrates tested PRs into the main branch. With user approval at each step, the agent merges the PR, updates the local main branch, deletes the feature branch, and updates all documentation.

**Target:** PR → main branch (integration)
**Approvals:** Required for all commands
**Steps:** 8 (full merge and cleanup)

---

## Step-by-Step Process

### Step 1: Read Merge Queue

Read `PRS.md` to find the first PR in "Needs Merging" section:

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

### Step 6: Update PRS.md

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

### Step 7: Update PLAN.md

Update PLAN.md to reflect current project status after merge:

**Mark completed tasks:**
- Find TODOs related to this PR
- Mark as `[x]` completed
- Example: `- [x] Add snapshot validation (PR #42)`

**Update phase status:**
- If all TODOs in phase complete, update phase status
- Update "Current Status" section if phase changed
- Add completion notes if applicable

**Remove obsolete items:**
- Remove "Pending" or "In Progress" labels
- Clean up temporary notes

**Add follow-up TODOs:**
- Note any issues discovered during merge
- Add items for future improvements mentioned in PR

**Always update** to keep project status current.

### Step 8: Commit Documentation

**Ask user approval**, then commit the updated PRS.md and PLAN.md:

```bash
git add PRS.md docs/PLAN.md
git commit -m "$(cat <<'EOF'
Update documentation after merging PR #42

Moved PR #42 to Merged section in PRS.md.
Updated PLAN.md: marked snapshot validation complete.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

**Verify push succeeds** - ensures documentation updates are preserved.

---

## Pre-Merge Checklist

Before merging PR:
- [ ] PR fetched and verified as ready to merge
- [ ] User approved merge operation
- [ ] PR merged successfully with `--merge` flag
- [ ] Local main branch updated (`git pull`)
- [ ] PR branch deleted (local and remote)
- [ ] PRS.md updated (moved to "Merged" section)
- [ ] PLAN.md updated with current project status
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
PLAN.md updates summary.

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
- [PRS.md](../PRS.md) - PR tracking
- [PLAN.md](PLAN.md) - Project status
