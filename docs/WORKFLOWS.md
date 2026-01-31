# CAL Workflows

> Index of all workflows with quick reference

**Purpose:** This document serves as the index for all CAL workflows. Each workflow has detailed documentation in its own file.

---

## Quick Reference

| Workflow | Steps | Approvals | Target | Use Case |
|----------|-------|-----------|--------|----------|
| [Interactive](#interactive-workflow) | 8 | Required | main branch | Default for code changes |
| [Documentation](#documentation-workflow) | 3 | Required | main branch | Docs-only changes |
| [Refine](#refine-workflow) | 6 | Required | main branch | Refine PLAN.md TODOs |
| [Create PR](#create-pr-workflow) | 7 | Not required | PR branch | PR-based development |
| [Review PR](#review-pr-workflow) | 6 | Not required | PR review | Code review of PRs |
| [Update PR](#update-pr-workflow) | 8 | Not required | PR branch | Address review feedback |
| [Test PR](#test-pr-workflow) | 7 | Test confirmation | PR testing | Manual testing gate |
| [Merge PR](#merge-pr-workflow) | 8 | Required | main branch | Merge tested PRs |

---

## Default Workflow

**Interactive** is the default workflow unless:
- User specifies "refine" or "refinement" → use Refine workflow
- User specifies "create PR" → use Create PR workflow
- User specifies "review PR" → use Review PR workflow
- User specifies "update PR" → use Update PR workflow
- User specifies "test PR" → use Test PR workflow
- User specifies "merge PR" → use Merge PR workflow
- Changes are documentation-only → use Documentation workflow

**If unclear, ask user explicitly which workflow to use.**

---

## Workflow Summaries

### Interactive Workflow

**[📖 Full Documentation](WORKFLOW-INTERACTIVE.md)**

Default workflow for direct code changes to main branch with user approvals at each step.

**When to use:** Making code changes directly to main branch
**Key features:**
- User approval required before ALL commands
- Blocking checkpoints at each step
- Mandatory code review for code/script changes
- Documentation-only exception available

**Steps:** Implement → Test → Build → Code Review → Present Review → Update Docs → Commit

---

### Documentation Workflow

**[📖 Full Documentation](WORKFLOW-DOCUMENTATION.md)**

Simplified Interactive workflow for documentation-only changes on main branch.

**When to use:** Making changes exclusively to `.md` files or code comments
**Key features:**
- Always on main branch
- User approval required
- Skip tests, build, and code review
- Simplified 3-step process

**Steps:** Make Changes → Ask Approval → Commit

---

### Refine Workflow

**[📖 Full Documentation](WORKFLOW-REFINE.md)**

Refine TODOs in PLAN.md with comprehensive requirements gathering and user approvals.

**When to use:** Clarifying and detailing TODOs before implementation begins
**Key features:**
- User approval required before commit
- Gather complete requirements through Q&A
- Prefix TODOs with "REFINED" in PLAN.md
- Track in STATUS.md "Refined" section

**Steps:** Read PLAN.md → Ask Questions → Update PLAN.md → Update STATUS.md → Ask Approval → Commit

---

### Create PR Workflow

**[📖 Full Documentation](WORKFLOW-CREATE-PR.md)**

Autonomous PR-based development starting from refined TODOs.

**When to use:** Creating new pull requests from refined TODOs in STATUS.md
**Key features:**
- Start with refined TODOs from STATUS.md
- No permission needed (autonomous)
- Never commit to main (all changes via PR)
- TDD required
- Manual testing instructions in PR

**Steps:** Read Refined Queue → Read Standards → Implement (TDD) → Test → Build → Create PR → Update Docs

**Branch format:** `create-pr/feature-name`

---

### Review PR Workflow

**[📖 Full Documentation](WORKFLOW-REVIEW-PR.md)**

Autonomous code review of PRs with comprehensive quality assessment.

**When to use:** Reviewing PRs in "Needs Review" queue
**Key features:**
- No permission needed (autonomous)
- Fetch branch locally for thorough review
- Comprehensive review (10 areas)
- Submit formal GitHub review
- Update coding standards if patterns found

**Steps:** Read Queue → Fetch PR → Review Code → Update Standards → Submit Review → Update Docs

---

### Update PR Workflow

**[📖 Full Documentation](WORKFLOW-UPDATE-PR.md)**

Autonomous implementation of PR review feedback.

**When to use:** Addressing review feedback on PRs in "Needs Changes" section
**Key features:**
- No permission needed (autonomous)
- Never commit to main (work on PR branches)
- Autonomous fixes based on feedback
- Skip code review (already reviewed)

**Steps:** Read Standards → Read Queue → Fetch PR → Analyze Review → Implement Changes → Test → Build → Update Docs

---

### Test PR Workflow

**[📖 Full Documentation](WORKFLOW-TEST-PR.md)**

Manual testing gate with user confirmation before merge.

**When to use:** Testing PRs in "Needs Testing" section before merge
**Key features:**
- Autonomous until test presentation
- User approval required for test confirmation
- PR comments for failure feedback
- Conditional paths (pass/fail)

**Steps:** Read Queue → Fetch PR → Present Tests → **WAIT** → Evaluate → Success/Failure Path → Update Docs

---

### Merge PR Workflow

**[📖 Full Documentation](WORKFLOW-MERGE-PR.md)**

Merge tested PRs into main with user approvals.

**When to use:** Merging PRs from "Needs Merging" section into main branch
**Key features:**
- User approval required for all commands
- Use merge commit strategy (preserves history)
- Delete branches after merge
- Track in PRS.md "Merged" section

**Steps:** Read Queue → Fetch PR → Merge PR → Update Local Main → Delete Branch → Update PRS.md → Update PLAN.md → Commit Docs

---

## PR Workflow Cycle

Complete flow from creation to merge:

```
Create PR
    ↓
Needs Review ←─────────────────┐
    ↓                           │
Review PR                       │
    ├──────────────┐            │
    ↓              ↓            │
Needs Testing  Needs Changes    │
    ↓              ↓            │
    │         Update PR ────────┘
    ↓
Test PR
    ├─────────┐
    ↓         ↓
Needs      Needs Changes
Merging      (loop back)
    ↓
Merge PR
    ↓
Merged
```

**[📊 Visual Diagram](PR-WORKFLOW-DIAGRAM.md)** - Complete flow with all details

---

## STATUS.md Sections

Project status is tracked in these sections:

| Section | Description | Next Workflow |
|---------|-------------|---------------|
| **Refined** | TODOs refined and ready for implementation | Interactive or Create PR |
| **Needs Review** | PRs awaiting code review | Review PR |
| **Needs Changes** | PRs with review feedback | Update PR |
| **Needs Testing** | Approved PRs needing manual tests | Test PR |
| **Needs Merging** | Tested PRs ready to merge | Merge PR |
| **Merged** | Completed PRs integrated to main | (final) |
| **Closed** | PRs closed without merging | (final) |

---

## Workflow Selection Guide

### Ask Yourself:

1. **Does a TODO in PLAN.md need clarification?**
   - → Use **Refine** workflow

2. **Are you making docs-only changes?**
   - → Use **Documentation** workflow

3. **Is there a refined TODO in STATUS.md ready for implementation?**
   - → Use **Create PR** workflow

4. **Is there a PR in "Needs Review"?**
   - → Use **Review PR** workflow

5. **Is there a PR in "Needs Changes"?**
   - → Use **Update PR** workflow

6. **Is there a PR in "Needs Testing"?**
   - → Use **Test PR** workflow

7. **Is there a PR in "Needs Merging"?**
   - → Use **Merge PR** workflow

8. **Are you making direct code changes to main?**
   - → Use **Interactive** workflow

---

## Shared Conventions

These conventions apply across all workflows. Individual workflow files reference this section rather than repeating these patterns.

### Session Start Procedure

Every workflow follows this procedure at session start:

1. **Read the workflow file** - Read the appropriate `docs/WORKFLOW-*.md`
2. **Reiterate to user** - Summarize the workflow steps and key principles in your own words
3. **Confirm understanding** - Acknowledge understanding before proceeding
4. **Proceed with standard session start** - git status, PLAN.md, active phase TODO, environment check

This ensures both agent and user have shared understanding of the workflow being followed.

### Numbered Choice Presentation

When presenting items for user selection (TODOs, PRs, tasks), **always use a numbered list** so users can reply with just a number:

```
Available items:

1. Add snapshot validation (PLAN-PHASE-01-TODO.md § 1.3)
2. Fix SSH timeout handling (PLAN-PHASE-01-TODO.md § 1.5)
3. Add config file support (PLAN-PHASE-01-TODO.md § 1.7)

Enter number:
```

This applies to:
- TODO selection (Interactive, Refine workflows)
- PR queue selection (Create PR, Review PR, Update PR, Test PR, Merge PR workflows)
- Next step suggestions at workflow completion
- Any time user must choose between multiple items

### Commit Message Format

Use imperative mood with Co-Authored-By. Always use heredoc for multi-line:

```bash
git commit -m "$(cat <<'EOF'
Brief summary (imperative mood)

Detailed description of what changed and why.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### Documentation Updates on Main

**CRITICAL:** PLAN.md and STATUS.md updates must ALWAYS be done on main branch:
- Create/update PR on feature branch
- Switch to main: `git checkout main`
- Update STATUS.md and PLAN.md
- Commit and push to main
- Do NOT include these doc changes in the PR

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

### TODO → DONE Movement

**Completed items must be moved from TODO files to DONE files:**

**When to move:**
- **On merge** (Merge PR workflow) - most common scenario
  - Cut TODO from `PLAN-PHASE-XX-TODO.md`
  - Paste into `PLAN-PHASE-XX-DONE.md` with PR number and merge date
  - Example: `- [x] Add validation (PR #42, merged 2026-01-21)`

- **On PR closure** (any workflow where PR is abandoned/superseded)
  - Move to DONE file with closure reason
  - Example: `- [x] Add validation (PR #42 closed - filed as known issue)`
  - Or: `- [x] Add validation (PR #42 closed - superseded by PR #45)`

- **On direct implementation** (Interactive workflow)
  - Move to DONE file after successful commit
  - Example: `- [x] Add validation (completed 2026-01-21)`

**Never mark as `[x]` in TODO file - always move to DONE file when complete.**

---

## Related Documentation

**Core Documentation:**
- [CLAUDE.md](../CLAUDE.md) - Agent instructions and core rules
- [PR-WORKFLOW-DIAGRAM.md](PR-WORKFLOW-DIAGRAM.md) - Visual workflow diagram

**Workflow Detail Files:**
- [WORKFLOW-INTERACTIVE.md](WORKFLOW-INTERACTIVE.md) - Interactive workflow (8-step)
- [WORKFLOW-REFINE.md](WORKFLOW-REFINE.md) - Refine workflow (6-step)
- [WORKFLOW-CREATE-PR.md](WORKFLOW-CREATE-PR.md) - Create PR workflow (6-step)
- [WORKFLOW-REVIEW-PR.md](WORKFLOW-REVIEW-PR.md) - Review PR workflow (6-step)
- [WORKFLOW-UPDATE-PR.md](WORKFLOW-UPDATE-PR.md) - Update PR workflow (8-step)
- [WORKFLOW-TEST-PR.md](WORKFLOW-TEST-PR.md) - Test PR workflow (7-step)
- [WORKFLOW-MERGE-PR.md](WORKFLOW-MERGE-PR.md) - Merge PR workflow (8-step)
- [WORKFLOW-DOCUMENTATION.md](WORKFLOW-DOCUMENTATION.md) - Documentation workflow (3-step)

**Project Management:**
- [PLAN.md](../PLAN.md) - TODOs and implementation tasks (source of truth)
- [STATUS.md](../STATUS.md) - Project status tracking (refined TODOs and PRs)
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
