# BUG-004: Tmux mouse mode disabled by default after incorrect BUG-003 fix

**Status:** Resolved
**Severity:** Medium
**Component:** Bootstrap
**Phase:** 0 (Bootstrap)
**Opened:** 2026-02-01
**Resolved:** 2026-02-01

---

## Summary

Fresh `calf-bootstrap --init` installations had tmux mouse mode disabled (`set -g mouse off`), causing right-click to show the terminal app menu instead of the tmux context menu. This was a regression introduced by commit 02a0081 which incorrectly "fixed" BUG-003.

## Root Cause

Commit 02a0081 (2026-02-01 18:58) changed `vm-tmux-resurrect.sh` from `mouse on` to `mouse off`, claiming to match the behavior of the cal-dev-authed snapshot from Jan 30. However, this was based on incorrect assumptions:

**Timeline:**
- **Jan 30 23:31** - cal-dev-authed created with `mouse on` (from vm-setup.sh)
- **Feb 1 17:32** - vm-tmux-resurrect.sh added with `mouse on` (commit a832acb)
- **Feb 1 18:58** - Changed to `mouse off` in commit 02a0081 (incorrect "fix")

The cal-dev-authed snapshot actually had `mouse on`, not `mouse off`.

## Impact

**With `mouse off` (broken behavior):**
- Right-click shows macOS terminal app menu (Copy, Paste, Split Right/Left/Down/Up, Reset Terminal, etc.)
- No access to tmux window management via right-click
- Confusing UX inconsistency between fresh installs and restored snapshots

**With `mouse on` (correct behavior):**
- Right-click shows tmux context menu (Swap Left/Right, Kill, Respawn, Mark, Rename, New After/At End)
- Proper tmux mouse integration for pane selection, resizing, and scrolling
- Consistent with historical cal-dev-authed behavior

## Fix

Changed `scripts/vm-tmux-resurrect.sh` line 63:
```diff
-# Default: off (preserves terminal copy-paste behavior)
-# To enable mouse mode: change 'off' to 'on' and reload config (Ctrl+b R)
-set -g mouse off
+# Default: on (provides tmux context menu functionality)
+# To disable mouse mode: change 'on' to 'off' and reload config (Ctrl+b R)
+set -g mouse on
```

Also updated comments to accurately describe behavior:
- `mouse on` = tmux right-click menu
- `mouse off` = terminal app menu

## Prevention

**For future development:**
1. Always verify behavior against actual snapshots, not assumptions
2. Test both fresh installations and restored snapshots
3. Document expected UX behavior with screenshots when fixing UI/interaction issues
4. Add this to Phase 1 and Phase 2 tmux deployment learnings

## Related

- **BUG-003** - Original bug report (closed, incorrect diagnosis)
- **Commit a832acb** - Original correct implementation with `mouse on`
- **Commit 02a0081** - Incorrect "fix" that introduced this regression
- **Phase 1 TODO Section 1.10** - Helper script deployment includes tmux configuration
