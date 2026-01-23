# CAL Workflows Reference

> Personal reference guide explaining all CAL workflows

## Overview

There are **8 workflows** organized into two categories: **main branch workflows** and **PR workflows**.

---

## Main Branch Workflows

These commit directly to the main branch with user approval:

### 1. Interactive (8 steps, default)

The standard workflow for code changes:

- **When**: Making code changes directly to main
- **Key features**: User approval required before ALL commands (tests, builds, commits)
- **Steps**: Implement → Test → Build → Code Review → Present Review → Update Docs → Commit
- **Blocking checkpoints**: Each step must complete before proceeding
- **Exception**: Documentation-only changes can skip tests/build/review

### 2. Documentation (3 steps)

Simplified workflow for docs-only changes:

- **When**: Changing only `.md` files or code comments
- **Key features**: Skips tests, build, and code review
- **Steps**: Make Changes → Ask Approval → Commit
- **Fast track**: No technical validation needed

### 3. Refine (6 steps)

Clarify and detail TODOs before implementation:

- **When**: A TODO in PLAN.md needs more details to be implementation-ready
- **Key features**: Comprehensive Q&A, prefixes TODO with "REFINED", tracks in STATUS.md
- **Steps**: Read PLAN.md → Ask Questions → Update PLAN.md → Update STATUS.md → Ask Approval → Commit
- **Output**: Implementation-ready TODOs with clear acceptance criteria

---

## PR Workflows

These work through pull requests (no approval needed except Test PR and Merge PR):

### 4. Create PR (7 steps, autonomous)

Start from refined TODOs to create PRs:

- **When**: Implementing refined TODOs from STATUS.md
- **Key features**: No user approval needed, TDD required, manual test instructions in PR
- **Steps**: Read Refined Queue → Read Standards → Implement (TDD) → Test → Build → Create PR → Update Docs
- **Branch**: `create-pr/feature-name`

### 5. Review PR (6 steps, autonomous)

Comprehensive code review:

- **When**: PRs in "Needs Review" section
- **Key features**: 10-area comprehensive review, updates coding standards if patterns found
- **Steps**: Read Queue → Fetch PR → Review Code → Update Standards → Submit Review → Update Docs
- **Output**: Formal GitHub review (approve/request changes)

### 6. Update PR (8 steps, autonomous)

Address review feedback:

- **When**: PRs in "Needs Changes" section
- **Key features**: Autonomous fixes based on feedback, skips code review
- **Steps**: Read Standards → Read Queue → Fetch PR → Analyze Review → Implement Changes → Test → Build → Update Docs

### 7. Test PR (7 steps, semi-autonomous)

Manual testing gate:

- **When**: PRs in "Needs Testing" section
- **Key features**: Presents test plan, waits for user test confirmation
- **Steps**: Read Queue → Fetch PR → Present Tests → **WAIT for user** → Evaluate → Success/Failure Path → Update Docs
- **Approval**: Only for test result confirmation (pass/fail)

### 8. Merge PR (8 steps, requires approval)

Merge tested PRs into main:

- **When**: PRs in "Needs Merging" section
- **Key features**: User approval required, uses merge commit strategy
- **Steps**: Read Queue → Fetch PR → Merge PR → Update Local Main → Delete Branch → Update STATUS.md → Update PLAN.md → Commit Docs

---

## PR Flow Cycle

```
Refined TODO in STATUS.md
    ↓
Create PR → Needs Review
              ↓
         Review PR
              ↓
    ┌─────────┴─────────┐
    ↓                   ↓
Needs Testing    Needs Changes ←──┐
    ↓                   ↓          │
Test PR            Update PR ──────┘
    ↓
Needs Merging
    ↓
Merge PR
    ↓
Merged
```

---

## Key Differences

### Main Branch Workflows
- Require user approval
- Direct commits to main
- Slower but more controlled

### PR Workflows
- Mostly autonomous (except Test PR confirmation and Merge PR)
- Work through pull requests
- Faster, parallel-friendly
- Better for larger features

---

## Workflow Selection Guide

**Default**: Interactive (unless otherwise specified)

Choose based on:
- **Refining a TODO?** → Refine
- **Docs only?** → Documentation
- **Implementing refined TODO?** → Create PR
- **PR needs review?** → Review PR
- **PR has feedback?** → Update PR
- **PR needs testing?** → Test PR
- **PR ready to merge?** → Merge PR
- **Direct code change?** → Interactive

---

## Key Tracking Files

- **STATUS.md**: Tracks PRs and refined TODOs through sections:
  - Refined (ready for implementation)
  - Needs Review (awaiting code review)
  - Needs Changes (review feedback to address)
  - Needs Testing (manual testing required)
  - Needs Merging (tested and ready)
  - Merged (completed)
  - Closed (cancelled without merge)

- **PLAN.md**: Single source of truth for all TODOs
  - Phase complete only when ALL checkboxes `[x]`
  - Code TODOs must reference PLAN.md
  - Updated in every workflow

---

## Quick Reference Table

| Workflow | Steps | Approvals | Target | Use Case |
|----------|-------|-----------|--------|----------|
| Interactive | 8 | Required | main branch | Default for code changes |
| Documentation | 3 | Required | main branch | Docs-only changes |
| Refine | 6 | Required | main branch | Refine PLAN.md TODOs |
| Create PR | 7 | Not required | PR branch | PR-based development |
| Review PR | 6 | Not required | PR review | Code review of PRs |
| Update PR | 8 | Not required | PR branch | Address review feedback |
| Test PR | 7 | Test confirmation | PR testing | Manual testing gate |
| Merge PR | 8 | Required | main branch | Merge tested PRs |

---

## Important Notes

### Documentation Updates on Main

**CRITICAL**: PLAN.md and STATUS.md updates must ALWAYS be done on main branch:
1. Create/update PR on feature branch
2. Switch to main: `git checkout main`
3. Update STATUS.md and PLAN.md
4. Commit and push to main
5. Do NOT include these doc changes in the PR

### PR Comments Format

Always use heredoc format to preserve formatting:

```bash
gh pr comment <PR#> --body "$(cat <<'EOF'
Comment text here.
EOF
)"
```

### PLAN.md is Source of Truth

- All TODOs must be tracked in PLAN.md
- Phase complete only when ALL checkboxes `[x]`
- Update PLAN.md in every workflow
- Code TODOs must reference PLAN.md

---

**Related Documentation:**
- `docs/WORKFLOWS.md` - Index of all workflows with quick reference
- `docs/WORKFLOW-*.md` - Detailed workflow files
- `docs/PLAN.md` - TODOs and implementation tasks (source of truth)
- `STATUS.md` - Project status tracking (refined TODOs and PRs)
- `CODING_STANDARDS.md` - Code quality standards
