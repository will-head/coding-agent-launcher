# PR Process Review: Findings and Recommendations

> Analysis of PR #3 to identify process inefficiencies and propose improvements

**Date:** 2026-01-31
**PR Analyzed:** [#3 - Add project scaffolding for CALF CLI](https://github.com/will-head/coding-agent-launcher/pull/3)
**Scope:** 4 new files (go.mod, .gitignore, Makefile, cmd/cal/main.go) + directory structure

---

## Executive Summary

PR #3 (a simple scaffolding PR) required ~84 workflow steps across ~12 agent sessions due to repeated review-update cycles. The current PR workflow design creates significant overhead, particularly when reviews are incomplete or contradictory. The minimum happy-path cost is 34 steps across 5 sessions. Several structural changes could reduce this substantially.

---

## What Happened: PR #3 Timeline

| Time | Action | Issues Found |
|------|--------|-------------|
| 18:06 | Create PR (commit 1) | - |
| 18:20 | Review 1 | Unused viper dep, cobra marked indirect, empty init() |
| 18:25 | Update 1 (commit 2) | Ran go mod tidy, removed init() |
| 18:50 | Review 2 | Missing .gitkeep files, AGENTS.md references golangci-lint |
| 18:54 | Update 2 (commit 3) | Added .gitkeep, updated AGENTS.md |
| 18:59 | Review 3 | Missing tests, missing staticcheck dep check, install target |
| 19:30 | Review 4 | staticcheck vs golangci-lint "unjustified", dep check, install |
| 19:35 | Update 3 (commit 4) | Added dep check, install error handling |
| 19:45 | Review 5 | Viper now MISSING (contradicts Review 1), PLAN.md references |
| 19:52 | Update 4 (commit 5) | Re-added viper, updated PLAN.md |
| 20:02 | Review 6 | Approved |

**Result:** 5 commits, 6 review passes, 4 update cycles, ~2 hours elapsed.

---

## Problems Identified

### Problem 1: Incomplete Reviews Create Unnecessary Cycles

Each review found only 2-3 issues, requiring another full update+review cycle. The Review PR workflow prescribes a comprehensive 10-area review, but in practice reviews were shallow and incremental.

**Impact:** 4 update cycles instead of 1. Each cycle costs ~14 workflow steps (6 review + 8 update).

### Problem 2: Contradictory Feedback

Review 1 effectively said "remove viper (it's unused)." The update complied (go mod tidy). Review 5 then said "viper is missing per the TODO requirements." This wasted an entire cycle on a contradiction the reviewer caused.

**Root cause:** The reviewer didn't distinguish between "dependency unused in code" and "dependency required by project plan." The first review was technically correct (tidy removes unused imports) but contradicted the TODO specification.

### Problem 3: Reviewer Didn't Read Requirements First

Multiple reviews flagged staticcheck as an issue, but `PLAN-PHASE-01-TODO.md` § 1.1 explicitly states: *"Use staticcheck for linting, not golangci-lint."* The Review PR workflow (Step 3) doesn't include reading the source TODO/requirements, so the reviewer had no context for intentional design decisions.

**Impact:** At least 2 reviews wasted on a non-issue.

### Problem 4: Heavy Per-Cycle Overhead

Each Review-Update round-trip requires ~14 workflow steps:
- Review: Read queue → fetch branch → review code → identify patterns → submit review → update docs (6 steps)
- Update: Read standards → read queue → fetch branch → analyze → implement → test → build → update docs (8 steps)

Plus STATUS.md commits on main for each transition (Needs Review ↔ Needs Changes).

### Problem 5: STATUS.md Churn

Every review→update transition requires updating STATUS.md on main. PR #3 generated ~8 STATUS.md-related commits for back-and-forth moves between sections. This adds noise to the git history for what is essentially bookkeeping.

### Problem 6: Five Separate Sessions Required (Happy Path)

Even with zero review issues, the prescribed flow requires 5 separate agent sessions:
1. Refine (6 steps)
2. Create PR (7 steps)
3. Review PR (6 steps)
4. Test PR (7 steps)
5. Merge PR (8 steps)

Each session has startup overhead (read workflow, check environment, read PLAN.md, read STATUS.md, read TODO).

### Problem 7: No Self-Fix Capability During Review

When a reviewer finds a minor issue (missing .gitkeep, small dependency fix), the only option is to request changes and wait for a full Update PR cycle. There's no mechanism for the reviewer to make trivial fixes directly.

---

## Recommendations

### Recommendation 1: Add Requirements Reading to Review PR Workflow

**Change:** Add a step between "Fetch PR" and "Review Code" in the Review PR workflow:

> **Step 2.5: Read Source Requirements** - Read the refined TODO from the phase TODO file that the PR implements. Understand what was asked for, including constraints and intentional decisions, before reviewing.

**Expected impact:** Eliminates reviews that flag intentional decisions as issues (staticcheck flagged 3 times).

### Recommendation 2: Enforce Single Comprehensive Review

**Change:** Add a review completeness gate to the Review PR workflow. Before submitting the review, the reviewer must confirm they've systematically checked all 10 areas and documented findings for each. The current checklist exists but isn't enforced.

Possible addition to Step 3:
> Before proceeding to Step 4, verify you have written findings (even "no issues") for ALL 10 review areas. Submitting a partial review that requires follow-up reviews wastes cycles.

**Expected impact:** Reduces review passes from ~5 to 1-2 per PR.

### Recommendation 3: Allow Reviewer to Fix Minor Issues Directly

**Change:** When the reviewer finds minor issues (severity: minor) that are mechanical fixes (missing files, small config changes, typos), allow the reviewer to fix them directly on the PR branch and push, instead of requesting changes.

Rules:
- Only for **minor** severity issues
- Only for **mechanical** fixes (not architectural or design changes)
- Reviewer pushes fix commit with clear message
- Reviewer continues review on the updated code
- If only minor issues found, can approve after fixing them

**Expected impact:** Eliminates 1-2 update cycles for typical PRs.

### Recommendation 4: Combine Review + Update for Agent-Only PRs

**Change:** Create a **"Review & Fix" workflow** that combines Review PR and Update PR into a single session. When an agent reviews an agent-generated PR, it can identify issues and fix them in the same session without the Needs Changes → Update PR → Needs Review round-trip.

Steps: Read Queue → Fetch PR → Read Requirements → Review Code → Fix Issues → Test → Build → Submit Approval → Update Docs

**Expected impact:** Replaces the multi-session review-update loop with a single session. Would have reduced PR #3 from ~12 sessions to ~3.

### Recommendation 5: Defer STATUS.md Updates During Rapid Cycles

**Change:** When a PR transitions between "Needs Review" and "Needs Changes" within the same session (i.e., reviewer finds issues and immediately starts Update PR), skip the intermediate STATUS.md commits. Only commit the final state.

**Expected impact:** Reduces git history noise, saves ~4 commits per PR with review issues.

### Recommendation 6: Collapse Happy-Path Workflows

**Change:** For `CALF_VM=true` environments (where approvals are auto-granted), allow combining sequential workflows in a single session. For example:

- **Create + Review:** Create PR, then immediately self-review before submitting
- **Test + Merge:** If manual tests pass, immediately proceed to merge

This doesn't remove steps, but removes session startup overhead (workflow reading, environment checks, PLAN.md reading) by running sequentially.

**Expected impact:** Reduces happy-path from 5 sessions to 2-3.

### Recommendation 7: Pre-Review Automated Checks

**Change:** Add automated pre-review checks to the Create PR workflow (before the PR is submitted for review):

- Run `go mod tidy` and check for changes (catches dependency issues)
- Verify all external tools referenced in Makefile have dependency checks
- Run `staticcheck`/linter
- Verify .gitkeep in empty directories
- Cross-reference docs against code (e.g., AGENTS.md build commands match Makefile)

**Expected impact:** Catches mechanical issues before review, reducing review findings to substantive architectural/design concerns.

---

## Impact Summary

| Recommendation | Cycles Saved (PR #3) | Complexity |
|---------------|----------------------|------------|
| 1. Read requirements in review | 2 review cycles | Low - add one step |
| 2. Enforce comprehensive review | 3 review cycles | Low - strengthen existing step |
| 3. Reviewer fixes minor issues | 1-2 update cycles | Medium - new capability |
| 4. Combined Review & Fix workflow | 4+ sessions eliminated | Medium - new workflow |
| 5. Defer STATUS.md updates | ~4 commits saved | Low - modify convention |
| 6. Collapse happy-path workflows | 2-3 sessions eliminated | Medium - workflow changes |
| 7. Pre-review automated checks | 1-2 review cycles | Medium - new automation |

If recommendations 1-4 were implemented, PR #3 could have been:
- **Create PR** (1 session) → **Review & Fix** (1 session) → **Test PR** (1 session) → **Merge PR** (1 session)
- ~30 steps across 4 sessions instead of ~84 steps across ~12 sessions

---

## Questions for Consideration

1. **Should agent-generated PRs use a different review process than human PRs?** The current workflow assumes an adversarial review model (separate reviewer can't modify code), but when both creator and reviewer are agents, this separation adds overhead without proportional benefit.

2. **Is the 5-session minimum (Refine → Create → Review → Test → Merge) justified for all PR sizes?** A scaffolding PR with 4 files may not need the same process as a complex feature PR.

3. **Should STATUS.md tracking be simplified?** The current Needs Review → Needs Changes → Needs Review → Needs Testing → Needs Merging → Merged pipeline creates many small state transitions. Could a simpler model (Open → Testing → Merged) work for agent-managed PRs?
