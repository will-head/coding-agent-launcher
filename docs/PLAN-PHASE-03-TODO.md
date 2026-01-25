# Phase 3 (GitHub Workflow) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Complete git workflow from VM.

**Deliverable:** Clone → Edit → Commit → PR workflow working.

---

## 3.1 GitHub Authentication

**File:** `internal/github/gh.go`

**Tasks:**
1. Wrap `gh auth login` for VM
2. Support token-based auth
3. Auth status checking
4. Secure token storage (encrypted in host config or re-auth each session)

---

## 3.2 Repository Cloning

**Tasks:**
1. `cal isolation clone <workspace> --repo owner/repo`
2. Support `--branch` for existing branch
3. Support `--new-branch` with prefix (default: `agent/`)
4. Clone into `~/workspace/{repo}` in VM

---

## 3.3 Commit and Push

**Tasks:**
1. `cal isolation commit <workspace> --message "msg"`
2. Optional `--push` flag
3. Show git diff before commit
4. Handle uncommitted changes on exit

---

## 3.4 Pull Request Creation

**Tasks:**
1. `cal isolation pr <workspace> --title "title"`
2. Support `--body` and `--base` flags
3. Use `gh pr create` in VM
4. Return PR URL

---

## 3.5 Status Display

**Tasks:**
1. Enhanced `cal isolation status <workspace>`
2. Show git status of cloned repos
3. Show uncommitted changes
4. Show current branch
