# Phase 5 (TUI & Polish) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Full terminal UI experience.

**Deliverable:** Complete TUI for CAL.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) for VM state information and operational details.

---

## 5.1 Workspace Selector

**Tasks:**
1. Interactive list of workspaces
2. Show status (running/stopped)
3. Quick actions (start, stop, ssh, run, gui)

---

## 5.2 Real-time Status

**Tasks:**
1. VM resource usage
2. Active processes
3. Git status (uncommitted changes, unpushed commits across ~/code repos)
4. Environment status
5. Proxy status (running/stopped, mode, connectivity)
6. Agent authentication status
7. **Tmux session persistence status:**
   - Last auto-save timestamp (from `~/.local/share/tmux/resurrect/last` symlink)
   - Number of saved sessions/windows/panes
   - Session data directory size
   - TPM plugin status (loaded/not loaded based on first-run flag)
   - Indicator if session restore is available

---

## 5.3 Log Streaming

**Tasks:**
1. `cal isolation logs <workspace> --follow`
2. Build log capture
3. Agent output capture
4. Proxy log streaming (`~/.cal-proxy.log`)

---

## 5.4 Multiple VMs

**Tasks:**
1. Support running multiple VMs simultaneously
2. Apple limits: max 2 concurrent VMs
3. VM switching in TUI

---

## 5.5 Session State Management

**Goal:** Enable seamless session recovery and continuation across interruptions.

**Tasks:**
1. Implement constant context state persistence
2. Write context to file after every operation
3. Enable seamless session recovery on crash or usage limits
4. Allow session continuation across Claude Code restarts

**Note:** Moved from Phase 0 (originally section 0.11) to Phase 5 as this is a polish/UX enhancement rather than bootstrap requirement.

**Existing VM-level session persistence (Phase 0.11):**
- tmux-resurrect already provides VM-level session persistence for terminal sessions
- Auto-saves every 15 minutes, auto-restores on tmux start
- Pane contents (scrollback) preserved with 50,000 line limit
- Session data in `~/.local/share/tmux/resurrect/` survives VM restarts and snapshot/restore
- This task focuses on **host-level CAL state** (which VMs exist, their configurations, active workspaces)
- Consider integration: CAL session state could trigger tmux session save before VM stop/snapshot
