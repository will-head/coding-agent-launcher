# CALF Workflows

> Index of all workflows with quick reference

**Purpose:** This document serves as the index for all CAL workflows. Each workflow has detailed documentation in its own file.

---

## Quick Reference

| # | Workflow | Steps | Approvals | Target | Use Case |
|---|----------|-------|-----------|--------|----------|
| 1 | [Interactive](#interactive-workflow) | 10 | Required on HOST | main branch | Default for code changes |
| 2 | [Documentation](#documentation-workflow) | 3 | Required on HOST | main branch | Docs-only changes |
| 3 | [Bug Cleanup](#bug-cleanup-workflow) | 11 | Required on HOST | main branch | Fix tracked bugs from BUGS.md |
| 4 | [Refine](#refine-workflow) | 6 | Required on HOST | main branch | Refine PLAN.md TODOs and bugs |
| 5 | [Create PR](#create-pr-workflow) | 8 | Not required | PR branch | PR-based development |
| 6 | [Review & Fix PR](#review--fix-pr-workflow) | 8 | Not required | PR review + fix | Code review with direct fixes |
| 7 | [Update PR](#update-pr-workflow) | 8 | Not required | PR branch | Architectural issue fixes (rare) |
| 8 | [Test PR](#test-pr-workflow) | 7 | Test confirmation (always) | PR testing | Manual testing gate |
| 9 | [Merge PR](#merge-pr-workflow) | 8 | Required on HOST | main branch | Merge tested PRs |

### Number Shortcuts

Users can enter a workflow number (1-9) at the start of a session to skip the menu and launch that workflow directly. For example, entering `5` launches the Create PR workflow immediately.

When the user enters `.`, present the numbered workflow list and wait for selection.

---

## Default Workflow

**Interactive** is the default workflow unless:
- User specifies "bug cleanup" → use Bug Cleanup workflow
- User specifies "refine" or "refinement" → use Refine workflow
- User specifies "create PR" → use Create PR workflow
- User specifies "review PR" → use Review & Fix PR workflow
- User specifies "update PR" → use Update PR workflow (rare fallback for architectural issues)
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
- User approval required on HOST before ALL commands (auto-approved when `CALF_VM=true`)
- Blocking checkpoints at each step
- Mandatory code review for code/script changes
- Documentation-only exception available

**Steps:** Implement → Test → Build → Code Review → Present Review → User Testing → Final Review → Update Docs → Commit → Complete

---

### Documentation Workflow

**[📖 Full Documentation](WORKFLOW-DOCUMENTATION.md)**

Simplified Interactive workflow for documentation-only changes on main branch.

**When to use:** Making changes exclusively to `.md` files or code comments
**Key features:**
- Always on main branch
- User approval required on HOST (auto-approved when `CALF_VM=true`)
- Skip tests, build, and code review
- Simplified 3-step process

**Steps:** Make Changes → Ask Approval → Commit

---

### Bug Cleanup Workflow

**[📖 Full Documentation](WORKFLOW-BUG-CLEANUP.md)**

Interactive workflow variant for resolving tracked bugs from BUGS.md.

**When to use:** Fixing bugs tracked in `docs/BUGS.md`
**Key features:**
- Work items sourced from `docs/BUGS.md`
- **Analyze and propose solution before implementing** — no quick fixes or hacks
- User approvals on HOST (auto-approved when `CALF_VM=true`)
- **Prove fix is sound before asking user to test** — tests pass, evidence, reasoning
- Bug lifecycle: resolved bugs move from BUGS.md to bugs/README.md
- TDD with bug reproduction tests

**Steps:** Select Bug → Analyze & Propose → Implement → Test → Build → Code Review → Present Review → Prove & User Testing → Final Review → Update Docs → Commit → Complete

---

### Refine Workflow

**[📖 Full Documentation](WORKFLOW-REFINE.md)**

Refine TODOs and bugs with comprehensive requirements gathering and user approvals.

**When to use:** Clarifying and detailing TODOs or bugs before implementation begins
**Key features:**
- User approval required on HOST before commit (auto-approved when `CALF_VM=true`)
- Gather complete requirements through Q&A
- Offers both phase TODOs and active bugs from `docs/BUGS.md`
- Prefix TODOs with "REFINED" in PLAN.md
- Track in STATUS.md "Refined" section

**Steps:** Read PLAN.md & BUGS.md → Ask Questions → Update PLAN.md/Bug Report → Update STATUS.md → Ask Approval → Commit

---

### Create PR Workflow

**[📖 Full Documentation](WORKFLOW-CREATE-PR.md)**

Autonomous PR-based development starting from refined TODOs with self-review before submission.

**When to use:** Creating new pull requests from refined TODOs in STATUS.md
**Key features:**
- Start with refined TODOs from STATUS.md (read full requirements and constraints)
- No permission needed (autonomous)
- Never commit to main (all changes via PR)
- TDD required
- Self-review against requirements before PR creation
- Manual testing instructions in PR

**Steps:** Read Refined Queue → Read Standards → Implement (TDD) → Test → Build → Self-Review → Create PR → Update Docs

**Branch format:** `create-pr/feature-name`

---

### Review & Fix PR Workflow

**[📖 Full Documentation](WORKFLOW-REVIEW-PR.md)**

Autonomous code review of PRs with direct issue resolution — fixes most issues on the spot.

**When to use:** Reviewing PRs in "Needs Review" queue
**Key features:**
- No permission needed (autonomous)
- Fetch branch locally for thorough review
- Read source requirements to review against original TODO
- Comprehensive review (10 areas)
- Fix minor/moderate issues directly on PR branch
- Request changes only for architectural issues
- Submit formal GitHub review
- Update coding standards if patterns found

**Steps:** Read Queue → Read Source Requirements → Fetch PR → Review Code → Fix Issues → Test & Build → Submit Review → Update Docs

---

### Update PR Workflow

**[📖 Full Documentation](WORKFLOW-UPDATE-PR.md)**

Rare fallback for architectural issues that couldn't be resolved during Review & Fix PR.

**When to use:** Addressing **architectural** review feedback on PRs in "Needs Changes" section (rare — most issues are fixed during Review & Fix PR)
**Key features:**
- No permission needed (autonomous)
- Never commit to main (work on PR branches)
- Autonomous fixes based on architectural feedback
- Skip code review (already reviewed)
- Only needed when Review & Fix PR identified fundamental design issues

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
- User approval required on HOST for all commands (auto-approved when `CALF_VM=true`)
- Use merge commit strategy (preserves history)
- Delete branches after merge
- Track in STATUS.md "Merged" section

**Steps:** Read Queue → Fetch PR → Merge PR → Update Local Main → Delete Branch → Update STATUS.md → Update PLAN.md → Commit Docs

---

## PR Workflow Cycle

Complete flow from creation to merge:

```
Create PR (with self-review)
    ↓
Needs Review ←─────────────────┐
    ↓                           │
Review & Fix PR                 │
    ├──────────────┐            │
    ↓              ↓            │
Needs Testing  Needs Changes    │
(common path)  (rare - arch.)   │
    ↓              ↓            │
    │         Update PR ────────┘
    ↓         (rare fallback)
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
| **Needs Review** | PRs awaiting code review | Review & Fix PR |
| **Needs Changes** | PRs with architectural review feedback (rare) | Update PR |
| **Needs Testing** | Approved PRs needing manual tests | Test PR |
| **Needs Merging** | Tested PRs ready to merge | Merge PR |
| **Merged** | Completed PRs integrated to main | (final) |
| **Closed** | PRs closed without merging | (final) |

---

## Workflow Selection Guide

### Ask Yourself:

1. **Does a TODO or bug need clarification?**
   - → Use **Refine** workflow

2. **Are you making docs-only changes?**
   - → Use **Documentation** workflow

3. **Is there an active bug in BUGS.md to fix?**
   - → Use **Bug Cleanup** workflow

4. **Is there a refined TODO in STATUS.md ready for implementation?**
   - → Use **Create PR** workflow

5. **Is there a PR in "Needs Review"?**
   - → Use **Review & Fix PR** workflow

6. **Is there a PR in "Needs Changes"?**
   - → Use **Update PR** workflow (rare — only for architectural issues from Review & Fix PR)

7. **Is there a PR in "Needs Testing"?**
   - → Use **Test PR** workflow

8. **Is there a PR in "Needs Merging"?**
   - → Use **Merge PR** workflow

9. **Are you making direct code changes to main?**
   - → Use **Interactive** workflow

---

## Shared Conventions

These conventions apply across all workflows. Individual workflow files reference this section rather than repeating these patterns.

### Session Start Procedure

Every workflow follows this procedure at session start:

1. **Read the workflow file** - Read the appropriate `docs/WORKFLOW-*.md`
2. **Reiterate to user** - Summarize the workflow steps and key principles in your own words
3. **Confirm understanding** - Acknowledge understanding before proceeding
4. **Proceed with standard session start:**
   - Run `echo $CALF_VM` to check environment (must happen before any approval-gated step)
   - Run `git status` to see current branch
   - **CRITICAL:** If not on main branch, switch to main with `git checkout main && git pull` before reading STATUS.md or PLAN.md
   - Run `git fetch` to get latest remote state
   - Read PLAN.md for overview and current phase status
   - Read active phase TODO file (e.g., `docs/PLAN-PHASE-01-TODO.md`) for current tasks
   - Report status and suggest next steps

**Why main branch first?** STATUS.md and PLAN.md are the source of truth and only updated on main (per [Documentation Updates on Main](#documentation-updates-on-main)). Reading them from a feature branch may show stale data.

This ensures both agent and user have shared understanding of the workflow being followed.

### CALF_VM Auto-Approve

#### VM Verification

The agent **MUST** verify VM status at session start by running `echo $CALF_VM`:
- `CALF_VM=true` → Display "Running in calf-dev VM (isolated environment)" → auto-approve enabled
- Any other value (empty, unset, `false`, etc.) → Display "Running on HOST machine (not isolated)" → require all approvals
- **Fail-safe:** If the check cannot be performed or returns unexpected output, default to HOST (require approval)
- **Never assume VM status** — always verify explicitly

#### Approval Behavior

When `CALF_VM=true` (confirmed via explicit check), individual workflow approval steps are skipped — operations proceed automatically without user confirmation.

**Exception:** Destructive remote git operations always require approval, even when `CALF_VM=true`:
- `push --force` (overwrites remote history)
- `push --delete` / deleting remote branches

Local-only operations (reset, checkout, clean, etc.) are allowed without approval since GitHub is the restore point.

**When in doubt, require approval.**

This applies to ALL workflows. See [CLAUDE.md § CALF_VM Auto-Approve](../CLAUDE.md#cal_vm-auto-approve) for the authoritative definition.

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
- PR queue selection (Create PR, Review & Fix PR, Update PR, Test PR, Merge PR workflows)
- Next step suggestions at workflow completion
- Any time user must choose between multiple items

### Next Workflow Guidance

At the end of workflows 4-9, read STATUS.md and suggest the next workflow based on what's actually queued. Check sections in **priority order** (items further along the pipeline should be completed first):

| Priority | STATUS.md Section | Suggested Workflow |
|----------|-------------------|--------------------|
| 1 (highest) | Needs Merging (has entries) | **9** (Merge PR) |
| 2 | Needs Testing (has entries) | **8** (Test PR) |
| 3 | Needs Changes (has entries) | **7** (Update PR) |
| 4 | Needs Review (has entries) | **6** (Review & Fix PR) |
| 5 | Refined (has entries) | **5** (Create PR) |
| 6 (lowest) | Nothing queued | **4** (Refine) to prepare more TODOs |

**How to apply:**

1. Read STATUS.md after the workflow completes (already on main branch at this point)
2. Find the highest-priority non-empty section from the table above
3. Display: `Next: run workflow X (Workflow Name) — N items in queue`
4. If multiple sections have entries, mention them: `Also: N PRs in Needs Testing, N refined TODOs ready`

**Example output:**
```
Next: run workflow 8 (Test PR) — 1 PR in Needs Testing
Also: 3 refined TODOs ready for Create PR
```

### Sequential Question and Test Presentation

When gathering information or presenting testing instructions, **present items one by one** rather than as a batch list.

**For multi-part questions (e.g., "1. this 2. that 3. other"):**
1. Present question #1 only
2. Wait for user's answer
3. Ask any follow-up questions needed to fully understand
4. When fully satisfied with #1, present question #2
5. Repeat until all questions answered

**For manual test instructions:**
1. Present test step #1 only
2. Wait for user to confirm pass/fail
3. If failed: user can choose to fix now, add as TODO, or accept as known issue
4. When step #1 is resolved (passed or handled), present step #2
5. Repeat until all tests complete

**Never present a batch list like:**
- ❌ "Answer these questions: 1) X? 2) Y? 3) Z?"
- ❌ "Run these tests: 1. Test A, 2. Test B, 3. Test C"

**Always present sequentially:**
- ✅ "Question 1: X?" → wait → follow-ups → satisfied → "Question 2: Y?" → etc.
- ✅ "Test 1: Do A" → wait for result → handle → "Test 2: Do B" → etc.

This applies to:
- Requirements gathering questions (Refine, Interactive workflows)
- User testing instructions (Interactive workflow Step 6, Test PR workflow)
- Any multi-step user interaction requiring sequential confirmation

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
- [WORKFLOW-INTERACTIVE.md](WORKFLOW-INTERACTIVE.md) - Interactive workflow (10-step)
- [WORKFLOW-BUG-CLEANUP.md](WORKFLOW-BUG-CLEANUP.md) - Bug Cleanup workflow (10-step)
- [WORKFLOW-REFINE.md](WORKFLOW-REFINE.md) - Refine workflow (6-step)
- [WORKFLOW-CREATE-PR.md](WORKFLOW-CREATE-PR.md) - Create PR workflow (8-step)
- [WORKFLOW-REVIEW-PR.md](WORKFLOW-REVIEW-PR.md) - Review & Fix PR workflow (8-step)
- [WORKFLOW-UPDATE-PR.md](WORKFLOW-UPDATE-PR.md) - Update PR workflow (8-step, rare fallback)
- [WORKFLOW-TEST-PR.md](WORKFLOW-TEST-PR.md) - Test PR workflow (7-step)
- [WORKFLOW-MERGE-PR.md](WORKFLOW-MERGE-PR.md) - Merge PR workflow (8-step)
- [WORKFLOW-DOCUMENTATION.md](WORKFLOW-DOCUMENTATION.md) - Documentation workflow (3-step)

**Project Management:**
- [PLAN.md](../PLAN.md) - TODOs and implementation tasks (source of truth)
- [STATUS.md](../STATUS.md) - Project status tracking (refined TODOs and PRs)
- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
