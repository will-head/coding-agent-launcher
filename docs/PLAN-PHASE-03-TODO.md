# Phase 3 (GitHub Workflow) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Complete git workflow from VM.

**Deliverable:** Clone -> Edit -> Commit -> PR workflow working.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) for authentication patterns, repository structure, and git safety checks.

---

## 3.1 GitHub Authentication

**File:** `internal/github/gh.go`

**Tasks:**
1. Wrap `gh auth login` for VM
2. Support token-based auth
3. Auth status checking via `gh auth status`
4. Secure token storage (encrypted in host config or re-auth each session)
5. Username extraction via `gh api user -q .login` (locale-independent)

**Key learnings from Phase 0 (ADR-002):**
- `gh auth status` output is locale-dependent; use `gh api user -q .login` for username
- Ctrl+C trap handlers needed during interactive auth flows
- Network connectivity check before auth (auto-start proxy if needed)

---

## 3.2 Repository Cloning

**Tasks:**
1. `cal isolation clone <workspace> --repo owner/repo`
2. Support `--branch` for existing branch
3. Support `--new-branch` with prefix (default: `agent/`)
4. Clone into `~/code/github.com/[owner]/[repo]` in VM (matches Phase 0 convention)
5. **Support multiple GitHub servers** (github.com, enterprise)
   - Allow specifying GitHub server in repo format: `server:owner/repo`
   - Default to github.com if no server specified
   - Support enterprise GitHub instances
   - Store server configuration in CAL config

**Key learnings from Phase 0 (ADR-002):**
- Repository directory structure: `~/code/github.com/[owner]/[repo]`
- Support both `owner/repo` and bare `repo` format (assumes authenticated user for bare)
- Skip if repository already exists at target path
- Network connectivity required (proxy auto-start if needed)

---

## 3.3 Commit and Push

**Tasks:**
1. `cal isolation commit <workspace> --message "msg"`
2. Optional `--push` flag
3. Show git diff before commit
4. Handle uncommitted changes on exit

**Key learnings from Phase 0 (ADR-002):**
- Logout git check (`~/.zlogout`) already warns about uncommitted/unpushed changes
- Unpushed commit detection requires upstream tracking
- Search locations: ~/workspace, ~/projects, ~/repos, ~/code, ~ (depth 2)

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
5. Show unpushed commits (when upstream tracking configured)
