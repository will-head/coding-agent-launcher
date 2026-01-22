# PR Workflow Diagram

> Complete flow from Create PR to Merge PR, including review cycles and documentation updates

## Overview

```
Create PR
    ↓
Needs Review ←─────────────────┐
    ↓                             │
Review PR                         │
    ├──────────────┐              │
    ↓              ↓              │
Needs Testing   ┌─► Needs Changes   │
    ↓      │       ↓              │
    │      │  Update PR ──────────┘
    │      │
    ↓      │
Test PR ───┘
    ↓
Needs Merging
    ↓
Merge PR
    ↓
Merged
```

## Detailed Workflow Steps

### 1. Create PR Workflow (6-Step)

**Branch:** `create-pr/feature-name` → **End:** `main`

```
Start
  │
  ├─ Step 1: Read Coding Standards (on main)
  ├─ Step 2: Implement (create create-pr/* branch, TDD)
  ├─ Step 3: Test (go test ./...)
  ├─ Step 4: Build (go build)
  ├─ Step 5: Create PR (push branch, gh pr create)
  │           └─ PR moves to: Needs Review
  └─ Step 6: Update Documentation
              ├─ Switch to main ✓
              ├─ Update PRS.md (add to Needs Review) ✓
              └─ Update PLAN.md ✓
End (on main)
```

**PRS.md Update:** Add to **Needs Review** section

---

### 2. Review PR Workflow (6-Step)

**Branch:** `main` → PR branch → **End:** `main`

```
Start (on main)
  │
  ├─ Step 1: Read PRS.md (Needs Review section)
  ├─ Step 2: Fetch PR (gh pr checkout <PR#>)
  │           └─ Now on: create-pr/* branch
  ├─ Step 3: Review Code (comprehensive review)
  ├─ Step 4: Update Standards (CODING_STANDARDS.md if needed)
  ├─ Step 5: Submit Review (gh pr review)
  │           ├─ APPROVE → moves to: Needs Testing
  │           └─ REQUEST_CHANGES → moves to: Needs Changes
  └─ Step 6: Update Documentation
              ├─ Switch to main ✓
              ├─ Update PRS.md ✓
              │   ├─ If approved: move to Needs Testing
              │   └─ If changes: move to Needs Changes
              └─ Update PLAN.md ✓
End (on main)
```

**PRS.md Update:** Move from **Needs Review** to:
- **Needs Testing** (if approved), OR
- **Needs Changes** (if changes requested)

---

### 3. Update PR Workflow (8-Step)

**Branch:** `main` → PR branch (push) → **End:** `main`

```
Start (on main)
  │
  ├─ Step 1: Read Coding Standards (on main)
  ├─ Step 2: Read PRS.md (Needs Changes section)
  ├─ Step 3: Fetch PR (gh pr checkout <PR#>)
  │           └─ Now on: create-pr/* branch
  ├─ Step 4: Analyze Review (gh pr view)
  ├─ Step 5: Implement Changes (TDD if needed)
  ├─ Step 6: Test (go test ./...)
  ├─ Step 7: Build (go build)
  └─ Step 8: Update Documentation
              ├─ Push changes (on create-pr/* branch)
              ├─ Switch to main ✓
              ├─ Update PRS.md (move to Needs Review) ✓
              └─ Update PLAN.md ✓
End (on main)
```

**PRS.md Update:** Move from **Needs Changes** to **Needs Review**

**Loop:** This sends the PR back through Review PR workflow

---

### 4. Test PR Workflow (7-Step)

**Branch:** `main` (stays on main)

```
Start (on main)
  │
  ├─ Step 1: Read PRS.md (Needs Testing section)
  ├─ Step 2: Fetch PR Details (gh pr view <PR#>)
  ├─ Step 3: Present Test Instructions
  │           └─ ⏸️  WAIT for user confirmation
  ├─ Step 4: Evaluate Test Results
  │           ├─ Tests passed → Step 5
  │           └─ Tests failed → Step 6
  ├─ Step 5: Update PRS.md - Success Path
  │           ├─ Switch to main (if needed) ✓
  │           └─ Move PR to: Needs Merging
  ├─ Step 6: Add Failure Comment & Update PRS.md
  │           ├─ Add gh pr comment with failure details
  │           ├─ Switch to main (if needed) ✓
  │           └─ Move PR to: Needs Changes
  └─ Step 7: Update Documentation
              └─ Update PLAN.md ✓
End (on main)
```

**PRS.md Update:** Move from **Needs Testing** to:
- **Needs Merging** (if tests pass), OR
- **Needs Changes** (if tests fail) → triggers Update PR workflow

---

### 5. Merge PR Workflow (8-Step)

**Branch:** `main` (stays on main, requires approval)

```
Start (on main)
  │
  ├─ Step 1: Read PRS.md (Needs Merging section)
  ├─ Step 2: Fetch PR Details (gh pr view <PR#>)
  │           └─ 🔒 Ask approval
  ├─ Step 3: Merge PR (gh pr merge <PR#> --merge)
  │           └─ 🔒 Ask approval
  ├─ Step 4: Update Local Main (git pull)
  │           └─ 🔒 Ask approval
  ├─ Step 5: Delete Branch (local + remote)
  │           └─ 🔒 Ask approval
  ├─ Step 6: Update PRS.md
  │           └─ Move PR to: Merged
  ├─ Step 7: Update PLAN.md
  │           ├─ Mark completed TODOs as [x]
  │           └─ Update phase status
  └─ Step 8: Commit Documentation
              ├─ git add PRS.md docs/PLAN.md
              ├─ git commit (with Co-Authored-By)
              └─ git push
              └─ 🔒 Ask approval
End (on main)
```

**PRS.md Update:** Move from **Needs Merging** to **Merged**

---

## Complete Flow Matrix

| Workflow   | Start Branch | Working Branch      | End Branch | PRS.md From         | PRS.md To            | PLAN.md | Branch Switch |
|------------|--------------|---------------------|------------|---------------------|----------------------|---------|---------------|
| Create PR  | main         | create-pr/*         | main       | —                   | Needs Review      | ✓       | ✓             |
| Review PR  | main         | create-pr/* (read)  | main       | Needs Review     | Needs Testing/Changes     | ✓       | ✓             |
| Update PR  | main         | create-pr/* (write) | main       | Needs Changes    | Needs Review      | ✓       | ✓             |
| Test PR    | main         | main (stays)        | main       | Needs Testing            | Needs Merging/Changes       | ✓       | ✓ (already)   |
| Merge PR   | main         | main (stays)        | main       | Needs Merging              | Merged               | ✓       | ✓ (already)   |

---

## State Transition Summary

### PRS.md Sections (PR States)

```
1. Needs Review  ──Review PR──► 2. Needs Testing
                    ──Review PR──► 3. Needs Changes
                         │                    │
                         │                    │
                         │            Update PR
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

### ✅ Documentation Updates (Required)
- **PRS.md**: Updated in every workflow to track PR state
- **PLAN.md**: Updated in every workflow to track project status

### ✅ Branch Management (Required)
- **Create PR**: Creates `create-pr/*` branch, ends on `main`
- **Review PR**: Checks out PR branch (read-only), ends on `main`
- **Update PR**: Checks out PR branch (writes changes), ends on `main`
- **Test PR**: Stays on `main` throughout
- **Merge PR**: Stays on `main`, deletes PR branch after merge

### 🔒 Approval Requirements
- **Create PR**: No approvals (autonomous)
- **Review PR**: No approvals (autonomous)
- **Update PR**: No approvals (autonomous)
- **Test PR**: Approval only for test confirmation (wait for user)
- **Merge PR**: Approval for all git operations

---

## Example: Complete Happy Path

```
Day 1: Create PR
├─ Developer: "Create PR for new validation feature"
├─ Agent creates create-pr/add-validation branch
├─ Agent implements with TDD, tests pass, build succeeds
├─ Agent creates PR with test instructions
├─ Agent updates PRS.md → Needs Review
├─ Agent updates PLAN.md
└─ Agent switches to main ✓

Day 2: Review PR
├─ Developer: "Review PR"
├─ Agent checks out PR branch, reviews code
├─ Agent finds issue, gh pr review --request-changes
├─ Agent updates PRS.md → Needs Changes
├─ Agent updates PLAN.md
└─ Agent switches to main ✓

Day 2: Update PR
├─ Developer: "Update PR"
├─ Agent checks out PR branch
├─ Agent reads review feedback, implements fixes
├─ Agent runs tests, build succeeds, pushes changes
├─ Agent updates PRS.md → Needs Review
├─ Agent updates PLAN.md
└─ Agent switches to main ✓

Day 3: Review PR (again)
├─ Developer: "Review PR"
├─ Agent checks out PR branch, reviews fixes
├─ Agent approves, gh pr review --approve
├─ Agent updates PRS.md → Needs Testing
├─ Agent updates PLAN.md
└─ Agent switches to main ✓

Day 3: Test PR
├─ Developer: "Test PR"
├─ Agent presents manual test instructions
├─ Developer runs tests manually: "tests passed"
├─ Agent updates PRS.md → Needs Merging
├─ Agent updates PLAN.md
└─ Agent already on main ✓

Day 4: Merge PR
├─ Developer: "Merge PR"
├─ Agent merges PR with user approval
├─ Agent updates local main with git pull
├─ Agent deletes PR branch
├─ Agent updates PRS.md → Merged
├─ Agent updates PLAN.md (marks TODOs complete)
├─ Agent commits docs with user approval
└─ Agent already on main ✓

Result: Feature fully integrated into main branch
```

---

## Example: Path with Multiple Review Cycles

```
Create PR → Needs Review
         ↓
Review PR → Needs Changes (Issue #1 found)
         ↓
Update PR → Needs Review (Issue #1 fixed)
         ↓
Review PR → Needs Changes (Issue #2 found)
         ↓
Update PR → Needs Review (Issue #2 fixed)
         ↓
Review PR → Needs Testing (approved)
         ↓
Test PR → Needs Changes (manual tests failed)
         ↓
Update PR → Needs Review (test failures fixed)
         ↓
Review PR → Needs Testing (re-approved)
         ↓
Test PR → Needs Merging (tests passed)
         ↓
Merge PR → Merged ✓
```

**All workflows:**
- ✅ Updated PLAN.md before completion
- ✅ Updated PRS.md before completion
- ✅ Returned to main branch before completion
