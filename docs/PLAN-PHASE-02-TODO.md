# Phase 2 (Agent Integration & UX) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Seamless agent launching with safety UI.

**Deliverable:** `cal isolation run <workspace>` launches agent with full UX.

---

## 2.1 TUI Framework Setup

**Files:** `internal/tui/app.go`, `internal/tui/styles.go`

**Tasks:**
1. Create bubbletea application scaffold
2. Define lipgloss styles for:
   - Status banner (green/yellow/red backgrounds)
   - Confirmation screen
   - Hotkey bar
3. Implement view switching

---

## 2.2 Status Banner

**File:** `internal/tui/banner.go`

**Tasks:**
1. Render status banner:
   ```
   🔒 CAL ISOLATION ACTIVE │ VM: <name> │ Env: <envs> │ Safe Mode
   ```
2. Dynamic color based on VM state
3. Update banner in real-time during session

---

## 2.3 Launch Confirmation Screen

**File:** `internal/tui/confirm.go`

**Tasks:**
1. Display workspace info before launch
2. Show isolation status
3. Handle user input: Enter (launch), B (backup), Q (quit)
4. Optional: `--yes` flag to skip confirmation

---

## 2.4 Agent Management

**File:** `internal/agent/agent.go`

**Tasks:**
1. Define `Agent` interface:
   ```go
   type Agent interface {
       Name() string
       InstallCommand() string
       ConfigDir() string
       LaunchCommand(prompt string) string
       IsInstalled(ssh *SSHClient) bool
   }
   ```
2. Implement for Claude Code, opencode, Cursor CLI
3. Agent installation in VM
4. Agent configuration management

---

## 2.5 SSH Tunnel with Banner Overlay

**Tasks:**
1. Establish SSH tunnel to VM
2. Overlay status banner at top of terminal
3. Pass through agent terminal output
4. Capture hotkey inputs (S, C, P, R, Q)
5. Clean exit handling
