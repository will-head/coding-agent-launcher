# Documentation Workflow

> Simplified workflow for documentation-only changes

**Use When:** Making changes **only** to `.md` files or code comments

**Key Principles:**
- **Skip tests, build, and code review** - not needed for docs
- **Still require approval to commit** - depends on parent workflow mode
- **Can use Interactive or Create PR** - choose based on preference

---

## Overview

The Documentation workflow provides a streamlined process for documentation-only changes. It skips automated testing, build verification, and code review steps since these aren't applicable to markdown files or comments.

**Target:** main branch (Interactive) or PR (Create PR)
**Approvals:** Required (Interactive) or Not required (Create PR)
**Steps:** 3 (simplified)

---

## When to Use

Use Documentation workflow for changes **exclusively** to:
- Markdown files (`.md`)
- Code comments (inline documentation)
- README files
- Documentation in `docs/` folder

**Do NOT use for:**
- Code changes (even with documentation)
- Script changes (even minor)
- Configuration file changes
- Build file changes

---

## Interactive Mode (Direct to Main)

### Step 1: Make Changes

Edit documentation files:
- Update markdown files
- Fix typos and formatting
- Improve clarity and examples
- Add new sections or documentation

**Ensure:**
- Proper markdown formatting
- Internal links work
- Code examples are accurate
- Consistent style with existing docs

### Step 2: Ask Approval

Present changes to user:
- Summarize what was changed
- Explain why changes were made
- List affected files

**Wait for explicit approval** before committing.

### Step 3: Commit and Push

**Ask user approval**, then commit:

```bash
git add <files>
git commit -m "$(cat <<'EOF'
Update documentation: [brief description]

- Specific change 1
- Specific change 2
- Specific change 3

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

**Done!** No tests, build, or code review needed.

---

## Create PR Mode (Via Pull Request)

### Step 1: Create Branch and Make Changes

```bash
git checkout -b create-pr/update-docs-[topic]
```

Edit documentation files as needed.

### Step 2: Create PR

```bash
git push -u origin HEAD

gh pr create --title "Update documentation: [topic]" --body "$(cat <<'EOF'
## Summary
- Documentation changes for [topic]
- Fixed typos and improved clarity
- Added missing examples

## Changes
- Updated docs/[file].md
- Fixed broken links
- Improved formatting

## Manual Testing
- [x] All internal links work
- [x] Code examples are accurate
- [x] Formatting renders correctly

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 3: Update Documentation

```bash
git checkout main

# Update PRS.md
# Add to "Needs Review" section

# Update PLAN.md
# Mark documentation TODOs as complete

git add PRS.md docs/PLAN.md
git commit -m "$(cat <<'EOF'
Update documentation for PR #[number]

Added documentation PR to Needs Review.
Updated PLAN.md with current status.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

**Note:** Documentation PRs still go through Review/Test/Merge workflows but those workflows will be faster since code review focuses on documentation quality only.

---

## Documentation Quality Checklist

Before committing:
- [ ] Spelling and grammar correct
- [ ] Markdown formatting proper
- [ ] Code examples tested and accurate
- [ ] Internal links work
- [ ] External links valid
- [ ] Consistent style with project
- [ ] Clear and concise language
- [ ] Appropriate level of detail
- [ ] No sensitive information exposed

---

## Important Notes

### What Counts as Documentation-Only

**Documentation-only means:**
- ✅ Markdown file changes
- ✅ Comment changes in code
- ✅ README updates
- ✅ Example updates (if only docs)

**NOT documentation-only:**
- ❌ Code changes with updated comments
- ❌ Script changes (even small)
- ❌ Configuration updates
- ❌ Example code that runs

### When in Doubt

If you're unsure whether changes are documentation-only:
- **Use full workflow** (Interactive or Create PR)
- Better safe than sorry
- Tests and build won't hurt

### PLAN.md Updates

Even for docs-only changes:
- Update PLAN.md if completing TODOs
- Mark documentation tasks as complete
- Update "Current Status" if relevant

---

## Examples

### Example 1: Fix Typos

**Changes:**
- Fixed typos in README.md
- Updated broken link in docs/architecture.md

**Workflow:**
1. Fix typos in both files
2. Ask user approval
3. Commit: "Fix typos and broken link in documentation"
4. Push

**Skipped:** Tests, build, code review

### Example 2: Add New Doc Section

**Changes:**
- Added "Troubleshooting" section to docs/bootstrap.md

**Workflow:**
1. Write new troubleshooting section
2. Ask user approval
3. Commit: "Add troubleshooting section to bootstrap guide"
4. Push

**Skipped:** Tests, build, code review

### Example 3: Update Command Examples

**Changes:**
- Updated CLI examples in docs/cli.md

**Workflow:**
1. Update command examples
2. Verify examples are accurate
3. Ask user approval
4. Commit: "Update CLI examples to match current syntax"
5. Push

**Skipped:** Tests, build, code review

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-INTERACTIVE.md](WORKFLOW-INTERACTIVE.md) - Full Interactive workflow
- [WORKFLOW-CREATE-PR.md](WORKFLOW-CREATE-PR.md) - Full Create PR workflow
- [PLAN.md](PLAN.md) - Project status
