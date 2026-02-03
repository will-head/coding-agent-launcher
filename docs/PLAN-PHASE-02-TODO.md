# Phase 2 (Agent Integration & UX) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Seamless agent launching with safety UI.

**Deliverable:** `cal isolation run <workspace>` launches agent with full UX.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) for agent installation, authentication, and TERM handling details.

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
4. Show proxy status indicator (from ADR-002 proxy management)

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
       IsAuthenticated(ssh *SSHClient) bool
       AuthCommand() string
   }
   ```
2. Implement for all supported agents:

   | Agent | Binary | Install | Auth Detection |
   |-------|--------|---------|----------------|
   | Claude Code | `claude` | `npm install -g @anthropic-ai/claude-code` | settings.json has content (not empty `{}`) |
   | opencode | `opencode` | `brew install anomalyco/tap/opencode` | `opencode auth list` has non-zero credentials |
   | Cursor CLI | `agent` | `curl -fsSL https://cursor.com/install \| bash` | `agent whoami` not "Not logged in" |
   | CCS | `ccs` | `npm install -g @kaitranntt/ccs` | N/A (uses Claude Code auth) |
   | Codex CLI | `codex` | `npm install -g @openai/codex` | OpenAI credentials |

3. Agent installation in VM
4. Agent configuration management
5. Authentication flow with Ctrl+C trap handlers (from ADR-002)

**Key learnings from Phase 0 (ADR-002):**
- Claude Code auth: must check settings.json *content*, not just file existence. Empty `{}` = not authenticated
- Claude Code OAuth URL: press `c` to copy (mouse-select includes line breaks)
- Cursor CLI: requires keychain unlock for OAuth credential storage
- opencode: hangs when TERM explicitly set in command environment (use tmux-wrapper.sh)
- `gh api user -q .login` for locale-independent username extraction
- Smart gate prompt: `[Y/n]` if any not authenticated, `[y/N]` if all authenticated

---

## 2.5 SSH Tunnel with Banner Overlay

**Tasks:**
1. Establish SSH tunnel to VM
2. Overlay status banner at top of terminal
3. Pass through agent terminal output
4. Capture hotkey inputs (S, C, P, R, Q)
5. Clean exit handling

**Key learnings from Phase 0 (ADR-002):**
- Use tmux-wrapper.sh for TERM compatibility (never set TERM explicitly in command)
- tmux sessions: `~/scripts/tmux-wrapper.sh new-session -A -s cal`
- Sessions survive SSH disconnects (agents keep running)

**Key learnings from Phase 0.11 (Tmux Session Persistence):**
- Session name must be `cal` (not `cal-dev`) — matches `cal isolation` command naming
- Sessions auto-restore on tmux start via tmux-continuum (pane layouts + scrollback preserved)
- Auto-save every 15 minutes plus manual save on logout via `.zlogout` hook
- Resurrect data in `~/.local/share/tmux/resurrect/` survives VM restarts and snapshot/restore
- Manual save (`Ctrl+b Ctrl+s`) runs silently; manual restore (`Ctrl+b Ctrl+r`)
- Mouse mode enabled by default (`set -g mouse on`) for tmux right-click menu (see BUG-004)

**Tmux status prompt for new shells:**
- When users open a new shell inside tmux, display helpful reminder:
  `💡 tmux: Sessions saved automatically - use Ctrl+b d to detach`
- Dynamically detect current tmux prefix key using `tmux show-options -gv prefix`
- Convert tmux prefix notation to human-readable format (e.g., `C-b` → `Ctrl+b`, `C-a` → `Ctrl+a`, `M-b` → `Alt+b`)
- Only display when `TMUX` environment variable is set (inside tmux session)
- Graceful fallback to `Ctrl+b` if tmux command unavailable
- Improves discoverability of session persistence and detach functionality
