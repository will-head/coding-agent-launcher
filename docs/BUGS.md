# Active Bugs

Active bugs for the CAL project. Agents should only read this file when specifically asked about bugs.

When bugs are resolved, remove the entry from this file and update `bugs/README.md`.

## Severity Definitions

| Severity | Description |
|----------|-------------|
| Critical | Blocks core functionality, no workaround |
| High     | Major feature broken, workaround exists |
| Medium   | Feature degraded, acceptable workarounds |
| Low      | Minor issue, cosmetic, or edge case |

## Status Definitions

| Status      | Description |
|-------------|-------------|
| Open        | Confirmed, not yet being worked on |
| In Progress | Actively being investigated or fixed |
| Blocked     | Waiting on external dependency |

## Active Bugs

| ID | Summary | Severity | Status | Component | Phase | Opened |
|----|---------|----------|--------|-----------|-------|--------|
| [BUG-005](bugs/BUG-005-tmux-resurrect-persistence.md) | tmux-resurrect session persistence fails across VM restart | Medium | Open | tmux/VM | 0 (Bootstrap) | 2026-02-02 |

---

### BUG-005: tmux-resurrect Session Persistence Fails Across VM Restart

**Status:** 🔴 OPEN
**Priority:** Medium
**Component:** tmux-resurrect, VM lifecycle

**Problem:**
tmux sessions are lost when VM is stopped and restarted via `--stop` or `--restart`. Save files contain only "state state state" instead of proper session data.

**Impact:**
- Sessions persist on detach + `--run` (tmux server stays running) ✅
- Sessions lost on detach + `--restart` (VM stops/starts) ❌

**Root Cause:**
tmux-resurrect save mechanism produces corrupted data. All save methods affected (auto-save, manual Ctrl+b Ctrl+s, logout hook, programmatic).

**Workarounds:**
1. Avoid stopping VM - use `--run` to attach to existing sessions
2. Note working directories/layout manually before restart
3. Keep VM running continuously

**Next Steps:**
- Verify tmux-resurrect plugin installation
- Check tmux version compatibility
- Test with minimal tmux.conf
- Consider plugin reinstall or alternative session persistence approach

**Full Details:** [BUG-005-tmux-resurrect-persistence.md](bugs/BUG-005-tmux-resurrect-persistence.md)
