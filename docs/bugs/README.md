# Bug Index

Complete index of all CAL project bugs (open, resolved, closed, won't fix).

This file is for human browsing only. Agents should not read this file.

## Severity Definitions

| Severity | Description |
|----------|-------------|
| Critical | Blocks core functionality, no workaround |
| High     | Major feature broken, workaround exists |
| Medium   | Feature degraded, acceptable workarounds |
| Low      | Minor issue, cosmetic, or edge case |

## Status Definitions

| Status    | Description |
|-----------|-------------|
| Open      | Confirmed, not yet being worked on |
| In Progress | Actively being investigated or fixed |
| Blocked   | Waiting on external dependency |
| Resolved  | Fix applied and verified |
| Closed    | Not a bug or duplicate |
| Won't Fix | Acknowledged but will not be fixed |

## All Bugs

| ID | Summary | Severity | Status | Component | Phase | Opened | Resolved |
|----|---------|----------|--------|-----------|-------|--------|----------|
| [BUG-007](BUG-007-session-restore-broken-after-restart.md) | Session restore broken after restart (first-run flag regression) | Critical | Resolved | Bootstrap | 0 (Bootstrap) | 2026-02-02 | 2026-02-02 |
| [BUG-006](BUG-006-tmux-mouse-mode-re-regression.md) | vm-tmux-resurrect.sh fails silently on network timeout during --init | High | Resolved | Bootstrap | 0 (Bootstrap) | 2026-02-02 | 2026-02-02 |
| [BUG-005](BUG-005-tmux-resurrect-persistence.md) | tmux-resurrect session persistence fails across VM restart | Medium | Resolved | tmux/VM | 0 (Bootstrap) | 2026-02-02 | 2026-02-02 |
| [BUG-004](BUG-004-tmux-mouse-mode-regression.md) | Tmux mouse mode disabled by default after incorrect BUG-003 fix | Medium | Resolved | Bootstrap | 0 (Bootstrap) | 2026-02-01 | 2026-02-01 |
| BUG-003 | Tmux mouse mode breaks terminal copy-on-select and right-click menu | Medium | Closed | Bootstrap | 0 (Bootstrap) | 2026-02-01 | 2026-02-01 |
| BUG-002 | vm-tmux-resurrect.sh not deployed to VM during --init | High | Resolved | Bootstrap | 0 (Bootstrap) | 2026-02-01 | 2026-02-01 |
| [BUG-001](BUG-001-ccs-auth-clipboard.md) | CCS auth create clipboard keybinding failure | Medium | Won't Fix | CCS/VM | 0 (Bootstrap) | 2026-01-31 | 2026-01-31 |
