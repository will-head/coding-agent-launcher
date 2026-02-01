# PR Workflow Diagram

> Complete flow from Create PR to Merge PR, including review cycles and documentation updates

## Overview

See [PR Workflow Cycle](WORKFLOWS.md#pr-workflow-cycle) in WORKFLOWS.md for the overview diagram.

## Detailed Workflow Steps

### 1. Create PR Workflow (8-Step)

**Branch:** `create-pr/feature-name` → **End:** `main`

```
Start
  │
  ├─ Step 1: Read Refined Queue (STATUS.md + full TODO with constraints)
  ├─ Step 2: Read Coding Standards (on main)
  ├─ Step 3: Implement (create create-pr/* branch, TDD)
  ├─ Step 4: Test (go test ./...)
  ├─ Step 5: Build (go build)
  ├─ Step 6: Self-Review (10-area checklist against requirements, fix issues)
  ├─ Step 7: Create PR (push branch, gh pr create)
  │           └─ PR moves to: Needs Review
  └─ Step 8: Update Documentation
              ├─ Switch to main ✓
              ├─ Update STATUS.md (add to Needs Review) ✓
              └─ Update PLAN.md ✓
End (on main)
```

**STATUS.md Update:** Add to **Needs Review** section

---

### 2. Review & Fix PR Workflow (8-Step)

**Branch:** `main` → PR branch (read + write) → **End:** `main`

```
Start (on main)
  │
  ├─ Step 1: Read STATUS.md (Needs Review section)
  ├─ Step 2: Read Source Requirements (refined TODO from phase file)
  ├─ Step 3: Fetch PR (gh pr checkout <PR#>)
  │           └─ Now on: create-pr/* branch
  ├─ Step 4: Review Code (comprehensive review against requirements)
  │           └─ Classify issues: fixable vs. architectural
  ├─ Step 5: Fix Issues (resolve fixable issues on PR branch)
  ├─ Step 6: Test & Build (verify fixes, commit and push)
  ├─ Step 7: Submit Review (gh pr review)
  │           ├─ APPROVE → moves to: Needs Testing (common)
  │           └─ REQUEST_CHANGES → moves to: Needs Changes (rare, arch. only)
  └─ Step 8: Update Documentation
              ├─ Switch to main ✓
              ├─ Update STATUS.md ✓
              │   ├─ If approved: move to Needs Testing
              │   └─ If arch. changes: move to Needs Changes
              ├─ Update CODING_STANDARDS.md if patterns found ✓
              └─ Update PLAN.md ✓
End (on main)
```

**STATUS.md Update:** Move from **Needs Review** to:
- **Needs Testing** (if approved — common path), OR
- **Needs Changes** (if architectural changes requested — rare)

---

### 3. Update PR Workflow (8-Step) — Rare Fallback

**Branch:** `main` → PR branch (push) → **End:** `main`

**Note:** This workflow is rarely needed. Review & Fix PR resolves most issues directly. This is only for architectural issues that require rethinking the implementation approach.

```
Start (on main)
  │
  ├─ Step 1: Read Coding Standards (on main)
  ├─ Step 2: Read STATUS.md (Needs Changes section)
  ├─ Step 3: Fetch PR (gh pr checkout <PR#>)
  │           └─ Now on: create-pr/* branch
  ├─ Step 4: Analyze Review (gh pr view)
  ├─ Step 5: Implement Changes (TDD if needed)
  ├─ Step 6: Test (go test ./...)
  ├─ Step 7: Build (go build)
  └─ Step 8: Update Documentation
              ├─ Push changes (on create-pr/* branch)
              ├─ Switch to main ✓
              ├─ Update STATUS.md (move to Needs Review) ✓
              └─ Update PLAN.md ✓
End (on main)
```

**STATUS.md Update:** Move from **Needs Changes** to **Needs Review**

**Loop:** This sends the PR back through Review & Fix PR workflow

---

### 4. Test PR Workflow (7-Step)

**Branch:** `main` (stays on main)

```
Start (on main)
  │
  ├─ Step 1: Read STATUS.md (Needs Testing section)
  ├─ Step 2: Fetch PR Details (gh pr view <PR#>)
  ├─ Step 3: Present Test Instructions
  │           └─ ⏸️  WAIT for user confirmation
  ├─ Step 4: Evaluate Test Results
  │           ├─ Tests passed → Step 5
  │           └─ Tests failed → Step 6
  ├─ Step 5: Update STATUS.md - Success Path
  │           ├─ Switch to main (if needed) ✓
  │           └─ Move PR to: Needs Merging
  ├─ Step 6: Add Failure Comment & Update STATUS.md
  │           ├─ Add gh pr comment with failure details
  │           ├─ Switch to main (if needed) ✓
  │           └─ Move PR to: Needs Changes
  └─ Step 7: Update Documentation
              └─ Update PLAN.md ✓
End (on main)
```

**STATUS.md Update:** Move from **Needs Testing** to:
- **Needs Merging** (if tests pass), OR
- **Needs Changes** (if tests fail) → triggers Update PR workflow

---

### 5. Merge PR Workflow (8-Step)

**Branch:** `main` (stays on main, requires approval)

```
Start (on main)
  │
  ├─ Step 1: Read STATUS.md (Needs Merging section)
  ├─ Step 2: Fetch PR Details (gh pr view <PR#>)
  │           └─ 🔒 Ask approval
  ├─ Step 3: Merge PR (gh pr merge <PR#> --merge)
  │           └─ 🔒 Ask approval
  ├─ Step 4: Update Local Main (git pull)
  │           └─ 🔒 Ask approval
  ├─ Step 5: Delete Branch (local + remote)
  │           └─ 🔒 Ask approval
  ├─ Step 6: Update STATUS.md
  │           └─ Move PR to: Merged
  ├─ Step 7: Update PLAN.md
  │           ├─ Mark completed TODOs as [x]
  │           └─ Update phase status
  └─ Step 8: Commit Documentation
              ├─ git add STATUS.md PLAN.md
              ├─ git commit (with Co-Authored-By)
              └─ git push
              └─ 🔒 Ask approval
End (on main)
```

**STATUS.md Update:** Move from **Needs Merging** to **Merged**

---

## Complete Flow Matrix

| Workflow        | Start Branch | Working Branch      | End Branch | STATUS.md From      | STATUS.md To              | PLAN.md | Branch Switch |
|-----------------|--------------|---------------------|------------|---------------------|---------------------------|---------|---------------|
| Create PR       | main         | create-pr/*         | main       | —                   | Needs Review              | ✓       | ✓             |
| Review & Fix PR | main         | create-pr/* (r/w)   | main       | Needs Review        | Needs Testing (common) / Needs Changes (rare) | ✓ | ✓ |
| Update PR       | main         | create-pr/* (write) | main       | Needs Changes       | Needs Review              | ✓       | ✓             |
| Test PR         | main         | main (stays)        | main       | Needs Testing       | Needs Merging/Changes     | ✓       | ✓ (already)   |
| Merge PR        | main         | main (stays)        | main       | Needs Merging       | Merged                    | ✓       | ✓ (already)   |

---

## State Transition Summary

### STATUS.md Sections (PR States)

```
1. Needs Review  ──Review & Fix PR──► 2. Needs Testing (common)
                    ──Review & Fix PR──► 3. Needs Changes (rare, arch. only)
                         │                    │
                         │                    │
                         │            Update PR (rare)
                         │                    │
                         │                    ▼
                         │            1. Needs Review (loop)
                         │
                    Test PR
                         │
                         ├──► 4. Needs Merging
                         └──► 3. Needs Changes ──Update PR──► 1. (loop)

4. Needs Merging           ──Merge PR──► 5. Merged (final)
```

---

## Key Principles (All Workflows)

### Documentation Updates (Required)
- **STATUS.md**: Updated in every workflow to track PR state
- **PLAN.md**: Updated in every workflow to track project status

### Branch Management (Required)
- **Create PR**: Creates `create-pr/*` branch, ends on `main`
- **Review & Fix PR**: Checks out PR branch (reads and writes fixes), ends on `main`
- **Update PR**: Checks out PR branch (writes changes), ends on `main`
- **Test PR**: Stays on `main` throughout
- **Merge PR**: Stays on `main`, deletes PR branch after merge

### Approval Requirements
- **Create PR**: No approvals (autonomous)
- **Review & Fix PR**: No approvals (autonomous)
- **Update PR**: No approvals (autonomous)
- **Test PR**: Approval only for test confirmation (wait for user)
- **Merge PR**: Approval for all git operations

---

## Example: Complete Happy Path

```
Day 1: Create PR
├─ Developer: "Create PR for new validation feature"
├─ Agent reads refined TODO with full requirements and constraints
├─ Agent creates create-pr/add-validation branch
├─ Agent implements with TDD, tests pass, build succeeds
├─ Agent self-reviews against requirements (10 areas), fixes issues
├─ Agent creates PR with test instructions
├─ Agent updates STATUS.md → Needs Review
├─ Agent updates PLAN.md
└─ Agent switches to main ✓

Day 2: Review & Fix PR
├─ Developer: "Review PR"
├─ Agent reads source requirements from phase TODO file
├─ Agent checks out PR branch, reviews code against requirements
├─ Agent finds 3 issues: 2 fixable, 1 none (all clean)
├─ Agent fixes 2 issues directly on PR branch
├─ Agent runs tests and build (pass), commits and pushes fixes
├─ Agent approves PR: gh pr review --approve
├─ Agent updates STATUS.md → Needs Testing
├─ Agent updates PLAN.md
└─ Agent switches to main ✓

Day 2: Test PR
├─ Developer: "Test PR"
├─ Agent presents manual test instructions
├─ Developer runs tests manually: "tests passed"
├─ Agent updates STATUS.md → Needs Merging
├─ Agent updates PLAN.md
└─ Agent already on main ✓

Day 3: Merge PR
├─ Developer: "Merge PR"
├─ Agent merges PR with user approval
├─ Agent updates local main with git pull
├─ Agent deletes PR branch
├─ Agent updates STATUS.md → Merged
├─ Agent updates PLAN.md (marks TODOs complete)
├─ Agent commits docs with user approval
└─ Agent already on main ✓

Result: Feature fully integrated into main branch
```

---

## Example: Path with Architectural Issues (Rare)

```
Create PR (with self-review) → Needs Review
         ↓
Review & Fix PR → Needs Changes (architectural issue found)
  └─ Minor issues fixed directly on branch
         ↓
Update PR → Needs Review (architectural issue redesigned)
         ↓
Review & Fix PR → Needs Testing (approved, no remaining issues)
         ↓
Test PR → Needs Merging (tests passed)
         ↓
Merge PR → Merged ✓
```

**Note:** With self-review in Create PR and direct fixes in Review & Fix PR, the common path skips "Needs Changes" entirely. Multiple review cycles are now rare.

**All workflows:**
- Updated PLAN.md before completion
- Updated STATUS.md before completion
- Returned to main branch before completion
