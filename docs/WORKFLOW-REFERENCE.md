# CALF Workflow Reference

> Detailed summaries of all workflows — consult when choosing a workflow or understanding the PR pipeline

**Note:** This is reference material. For the quick reference table and shared conventions used during every session, see [WORKFLOWS.md](WORKFLOWS.md).

---

## Workflow Summaries

### Interactive Workflow

**[Full Documentation](WORKFLOW-INTERACTIVE.md)**

Default workflow for direct code changes to main branch with user approvals at each step.

**When to use:** Making code changes directly to main branch
**Key features:**
- User approval required on HOST before ALL commands (auto-approved when `CALF_VM=true`)
- Blocking checkpoints at each step
- Mandatory code review for code/script changes
- Documentation-only exception available

**Steps:** Implement > Test > Build > Code Review > Present Review > User Testing > Final Review > Update Docs > Commit > Complete

---

### Documentation Workflow

**[Full Documentation](WORKFLOW-DOCUMENTATION.md)**

Simplified Interactive workflow for documentation-only changes on main branch.

**When to use:** Making changes exclusively to `.md` files or code comments
**Key features:**
- Always on main branch
- User approval required on HOST (auto-approved when `CALF_VM=true`)
- Skip tests, build, and code review
- Simplified 3-step process

**Steps:** Make Changes > Ask Approval > Commit

---

### Bug Cleanup Workflow

**[Full Documentation](WORKFLOW-BUG-CLEANUP.md)**

Interactive workflow variant for resolving tracked bugs from BUGS.md.

**When to use:** Fixing bugs tracked in `docs/BUGS.md`
**Key features:**
- Work items sourced from `docs/BUGS.md`
- **Analyze and propose solution before implementing** — no quick fixes or hacks
- User approvals on HOST (auto-approved when `CALF_VM=true`)
- **Prove fix is sound before asking user to test** — tests pass, evidence, reasoning
- Bug lifecycle: resolved bugs move from BUGS.md to bugs/README.md
- TDD with bug reproduction tests

**Steps:** Select Bug > Analyze & Propose > Implement > Test > Build > Code Review > Present Review > Prove & User Testing > Final Review > Update Docs > Commit > Complete

---

### Refine Workflow

**[Full Documentation](WORKFLOW-REFINE.md)**

Refine TODOs and bugs with comprehensive requirements gathering and user approvals.

**When to use:** Clarifying and detailing TODOs or bugs before implementation begins
**Key features:**
- User approval required on HOST before commit (auto-approved when `CALF_VM=true`)
- Gather complete requirements through Q&A
- Offers both phase TODOs and active bugs from `docs/BUGS.md`
- Prefix TODOs with "REFINED" in PLAN.md
- Track in STATUS.md "Refined" section

**Steps:** Read PLAN.md & BUGS.md > Ask Questions > Update PLAN.md/Bug Report > Update STATUS.md > Ask Approval > Commit

---

### Create PR Workflow

**[Full Documentation](WORKFLOW-CREATE-PR.md)**

Autonomous PR-based development starting from refined TODOs with self-review before submission.

**When to use:** Creating new pull requests from refined TODOs in STATUS.md
**Key features:**
- Start with refined TODOs from STATUS.md (read full requirements and constraints)
- No permission needed (autonomous)
- Never commit to main (all changes via PR)
- TDD required
- Self-review against requirements before PR creation
- Manual testing instructions in PR

**Steps:** Read Refined Queue > Read Standards > Implement (TDD) > Test > Build > Self-Review > Create PR > Update Docs

**Branch format:** `create-pr/feature-name`

---

### Review & Fix PR Workflow

**[Full Documentation](WORKFLOW-REVIEW-PR.md)**

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

**Steps:** Read Queue > Read Source Requirements > Fetch PR > Review Code > Fix Issues > Test & Build > Submit Review > Update Docs

---

### Update PR Workflow

**[Full Documentation](WORKFLOW-UPDATE-PR.md)**

Rare fallback for architectural issues that couldn't be resolved during Review & Fix PR.

**When to use:** Addressing **architectural** review feedback on PRs in "Needs Changes" section (rare — most issues are fixed during Review & Fix PR)
**Key features:**
- No permission needed (autonomous)
- Never commit to main (work on PR branches)
- Autonomous fixes based on architectural feedback
- Skip code review (already reviewed)
- Only needed when Review & Fix PR identified fundamental design issues

**Steps:** Read Standards > Read Queue > Fetch PR > Analyze Review > Implement Changes > Test > Build > Update Docs

---

### Test PR Workflow

**[Full Documentation](WORKFLOW-TEST-PR.md)**

Manual testing gate with user confirmation before merge.

**When to use:** Testing PRs in "Needs Testing" section before merge
**Key features:**
- Autonomous until test presentation
- User approval required for test confirmation
- PR comments for failure feedback
- Conditional paths (pass/fail)

**Steps:** Read Queue > Fetch PR > Present Tests > **WAIT** > Evaluate > Success/Failure Path > Update Docs

---

### Merge PR Workflow

**[Full Documentation](WORKFLOW-MERGE-PR.md)**

Merge tested PRs into main with user approvals.

**When to use:** Merging PRs from "Needs Merging" section into main branch
**Key features:**
- User approval required on HOST for all commands (auto-approved when `CALF_VM=true`)
- Use merge commit strategy (preserves history)
- Delete branches after merge
- Track in STATUS.md "Merged" section

**Steps:** Read Queue > Fetch PR > Merge PR > Update Local Main > Delete Branch > Update STATUS.md > Update PLAN.md > Commit Docs

---

## PR Workflow Cycle

Complete flow from creation to merge:

```
Create PR (with self-review)
    |
Needs Review <-----------------+
    |                           |
Review & Fix PR                 |
    +--------------+            |
    |              |            |
Needs Testing  Needs Changes    |
(common path)  (rare - arch.)   |
    |              |            |
    |         Update PR --------+
    |         (rare fallback)
Test PR
    +---------+
    |         |
Needs      Needs Changes
Merging      (loop back)
    |
Merge PR
    |
Merged
```

**[Visual Diagram](PR-WORKFLOW-DIAGRAM.md)** - Complete flow with all details

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
   - Use **Refine** workflow

2. **Are you making docs-only changes?**
   - Use **Documentation** workflow

3. **Is there an active bug in BUGS.md to fix?**
   - Use **Bug Cleanup** workflow

4. **Is there a refined TODO in STATUS.md ready for implementation?**
   - Use **Create PR** workflow

5. **Is there a PR in "Needs Review"?**
   - Use **Review & Fix PR** workflow

6. **Is there a PR in "Needs Changes"?**
   - Use **Update PR** workflow (rare — only for architectural issues from Review & Fix PR)

7. **Is there a PR in "Needs Testing"?**
   - Use **Test PR** workflow

8. **Is there a PR in "Needs Merging"?**
   - Use **Merge PR** workflow

9. **Are you making direct code changes to main?**
   - Use **Interactive** workflow
