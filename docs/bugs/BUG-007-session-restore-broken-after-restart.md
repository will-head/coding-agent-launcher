# BUG-007: Session restore broken after restart (critical regression)

**Status:** Resolved
**Severity:** Critical
**Component:** Bootstrap
**Phase:** 0 (Bootstrap)
**Opened:** 2026-02-02
**Resolved:** 2026-02-02

---

## Summary

Tmux sessions no longer restore after VM restart. This is a critical regression introduced while fixing BUG-006. The `~/.calf-first-run` flag is persisting in cal-dev after bootstrap completion, preventing TPM/tmux-resurrect from loading.

## Symptoms

1. **No session restoration with `calf-bootstrap --restart`** - After `--restart`, tmux creates fresh session instead of restoring previous state (HUGELY FRUSTRATING - sessions are saved but never restored)
2. **TPM not loading** - tmux-resurrect and tmux-continuum plugins not active
3. **Affects cal-dev** - The primary development VM is broken
4. **User data loss** - All pane contents, window layouts, and working state lost on restart
5. **Regression** - Session persistence worked before BUG-006 fix, now completely broken

## Expected Behavior

- Tmux sessions should auto-restore on VM restart
- All windows, panes, and scrollback should be preserved
- Last working state should be recovered
- TPM plugins should load normally in cal-dev

## Root Causes

### Root Cause #1: First-run flag left in cal-dev after bootstrap completes

In BUG-006 fix, we changed Step 10.5 of `calf-bootstrap` from "remove flag" to "verify flag exists":

```bash
# OLD (correct for cal-dev):
echo "  Removing first-run flag from $VM_DEV..."
ssh ... "rm -f ~/.calf-first-run && sync"

# NEW (broken - leaves flag in cal-dev):
echo "  Verifying first-run flag in $VM_DEV..."
if ssh ... "[ -f ~/.calf-first-run ] && echo 'exists'"
```

**Why this breaks session restore:**

1. Flag persists in cal-dev after bootstrap completes
2. User runs `calf-bootstrap --restart` or starts tmux in cal-dev
3. tmux.conf has: `run-shell 'if [ ! -f ~/.calf-first-run ]; then ~/.tmux/plugins/tpm/tpm; fi'`
4. Flag exists → TPM doesn't load
5. No TPM → no tmux-resurrect → no session restore
6. **Even though `--restart` explicitly saves sessions before stopping, they never restore!**

**The confusion:**

- **cal-init** SHOULD have the flag (for first login after restore)
- **cal-dev** should NOT have the flag (it's the working VM, not a snapshot)

### Root Cause #2: Race condition in `--restart` logic (CRITICAL!)

**The `do_restart()` function has a race condition:**

From `scripts/calf-bootstrap:1603`:
```bash
start-server; run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh; sleep 1; attach...
```

**Why this fails:**
1. `start-server` starts tmux and begins loading TPM **asynchronously**
2. `run-shell restore.sh` runs **immediately** (no wait for TPM)
3. TPM hasn't finished loading resurrect plugin yet → restore fails
4. Even with Root Cause #1 fixed (flag removed), this race condition breaks restore

**Additional issue:**
- Auto-restore is configured (`@continuum-restore 'on'`)
- Explicit `restore.sh` call may interfere with auto-restore
- Need to either wait for TPM or rely solely on auto-restore

## Timeline

- **2026-02-02 ~22:30** - BUG-006 fixed with first-run flag timing changes
- **Step 6.5 added** - Set flag before vm-setup creates tmux config (correct)
- **Step 9.5 changed** - Verify flag instead of set (correct - flag already set)
- **Step 10.5 changed** - Verify flag instead of remove (WRONG - breaks cal-dev)
- **Step 10** - cal-init cloned with flag (correct)
- **Result** - cal-init works, cal-dev broken

## Impact

**Critical severity** - Complete loss of core functionality:
- Session persistence completely broken in cal-dev
- **`calf-bootstrap --restart` is broken** - saves sessions but never restores them (hugely frustrating!)
- User loses all working state on restart
- Manual work required to recreate window/pane layouts
- Scrollback history lost
- This defeats the entire purpose of Phase 0.11 (session persistence)
- Development workflow severely disrupted

## Changes Made for BUG-006

### Files Modified

1. **scripts/vm-tmux-resurrect.sh**
   - Added retry logic + caching for TPM download
   - Removed manual plugin installation (auto-install on first tmux start)
   - Added TPM cache in `~/.calf-cache/tpm/`

2. **scripts/calf-bootstrap**
   - **Step 6.5 (NEW)**: Set first-run flag BEFORE vm-setup
   - **Step 9.5**: Changed from "set" to "verify" flag
   - **Step 10.5**: Changed from "remove" to "verify" flag ⚠️ **THIS BROKE IT**
   - Added `CLEANUP_DELETE_CALDEV` for failed init cleanup

3. **scripts/vm-setup.sh**
   - Move first-run flag removal to AFTER vm-first-run.sh completes
   - Suppress tmux message when first-run flag exists
   - Added exit code checking for vm-tmux-resurrect.sh

4. **scripts/vm-first-run.sh**
   - Removed unnecessary tmux message
   - Added keychain status display after clear

## Resolution Plan

**Fix #1: Remove first-run flag from cal-dev (DONE in uncommitted changes)**

1. **Step 10.5**: Remove flag from cal-dev (restore original behavior)
   ```bash
   echo "  Removing first-run flag from $VM_DEV..."
   ssh ... "rm -f ~/.calf-first-run && sync"
   echo "  ✓ $VM_DEV ready (TPM will load normally)"
   ```

2. **Step 10**: Keep flag in cal-init (already correct)
   - cal-init is cloned WITH the flag
   - Flag persists through snapshot
   - First login after restore triggers vm-first-run.sh

**Fix #2: Fix race condition in `--restart` (IMPLEMENTED - Option B)**

**Option A: Wait for TPM before restore (safer)**
```bash
# In do_restart(), line ~1603
~/scripts/tmux-wrapper.sh start-server
sleep 2  # Give TPM time to load plugins
~/scripts/tmux-wrapper.sh run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
sleep 1
~/scripts/tmux-wrapper.sh attach -t cal-dev 2>/dev/null || ~/scripts/tmux-wrapper.sh new-session -s cal-dev
```

**Option B: Rely on auto-restore (cleaner)**
```bash
# In do_restart(), line ~1603
# Remove explicit restore call, let tmux-continuum auto-restore handle it
~/scripts/tmux-wrapper.sh new-session -A -s cal-dev
# -A attaches if exists, creates if not
# Auto-restore will happen automatically via tmux-continuum
```

**Option C: Proper TPM initialization check (most reliable)**
```bash
# In do_restart(), line ~1603
~/scripts/tmux-wrapper.sh start-server
# Wait for TPM to finish loading (check for plugin marker)
for i in {1..10}; do
  if ~/scripts/tmux-wrapper.sh show-option -gv @plugin >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done
~/scripts/tmux-wrapper.sh run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
sleep 1
~/scripts/tmux-wrapper.sh attach -t cal-dev 2>/dev/null || ~/scripts/tmux-wrapper.sh new-session -s cal-dev
```

**IMPLEMENTATION: Option B (simplest, most reliable)**
- Implemented in `scripts/calf-bootstrap` for all modes (--init, --run, --restart)
- Option C documented as inline comment in do_restart() for future reference if auto-restore proves unreliable

**The Correct Flow:**

- **During --init:**
  - Step 6.5: Set flag in cal-dev
  - Step 7: vm-setup creates tmux config (TPM won't load due to flag)
  - Step 8: Reboot, vm-auth runs in tmux (TPM still disabled)
  - Step 9.5: Verify flag exists (still there)
  - Step 10: Clone cal-init WITH flag
  - **Step 10.5: REMOVE flag from cal-dev** ← Critical!
  - Step 11: Start cal-dev (TPM loads, session persistence works)

- **After restore from cal-init:**
  - VM starts with flag (from snapshot)
  - First login runs vm-first-run.sh
  - Flag removed after first-run completes
  - TPM loads on next tmux start

## Testing Required

1. **Test `calf-bootstrap --restart` session restore (CRITICAL):**
   - Create windows/panes in cal-dev
   - Add scrollback content
   - Run `calf-bootstrap --restart`
   - **Verify all state restored** (windows, panes, scrollback)
   - Verify no manual intervention needed

2. **Test VM restart session restore:**
   - Create windows/panes in cal-dev
   - Add scrollback content
   - Stop and start cal-dev manually (not via --restart)
   - Verify all state restored

3. **Test cal-init first-run:**
   - Restore from cal-init
   - Verify vm-first-run.sh executes
   - Verify TPM loads after first-run
   - Verify session persistence works going forward

4. **Test auth screen not captured:**
   - Fresh --init
   - Verify vm-auth screen not in resurrect data
   - Verify only real work sessions are saved

## Prevention

- Test both cal-dev AND cal-init behavior after flag changes
- Document which VMs should have flag at each stage
- Add explicit comments about cal-dev vs cal-init flag states
- Test session restore as part of bootstrap verification

## Resolution

**Resolved:** 2026-02-02

**Changes implemented:**

1. **calf-bootstrap Step 10.5 - Flag removal with verification:**
   - Restored flag removal from cal-dev (was incorrectly changed to "verify" during BUG-006 fix)
   - Added verification that flag was actually removed
   - Provides warning if removal fails

2. **calf-bootstrap - Conditional auto-restore based on first-run flag:**
   - Before starting tmux in do_init(), do_run(), and do_restart(), check if first-run flag exists
   - **If flag exists:** Use `tmux new-session -s cal-dev` (NO auto-restore)
     - Allows vm-first-run.sh to run cleanly before any session restoration
     - Prevents vm-auth screen from appearing inside tmux
   - **If flag absent:** Use `tmux new-session -A -s cal-dev` (WITH auto-restore)
     - Normal operation with session persistence via continuum
   - Defense in depth: Even if flag removal fails, conditional logic prevents issues

3. **Root cause #3 discovered and fixed:**
   - Auto-restore was starting before vm-first-run.sh completed
   - Resulted in vm-auth authentication screen appearing inside tmux session
   - Conditional auto-restore ensures vm-auth runs BEFORE tmux restoration

**Testing:**
- ✅ Fresh --init completes successfully
- ✅ vm-auth runs outside tmux (not captured by resurrect)
- ✅ Session restore works on --run (subsequent connections)
- ✅ Session restore works on --restart (VM restart with saved sessions)
- ✅ No unintended consequences for normal operation

**The correct flow:**
- During --init: Flag set → vm-setup runs → flag removed → TPM loads → sessions persist
- During first boot after restore: Flag exists → vm-first-run runs → flag removed → TPM loads
- During normal use: Flag absent → auto-restore works → sessions restored

## Technical Notes

**Conditional Auto-Restore Pattern:**
- Check for first-run flag BEFORE starting tmux
- If flag exists: Use `tmux new-session -s cal-dev` (no `-A`) to prevent auto-restore
- If flag absent: Use `tmux new-session -A -s cal-dev` (with `-A`) for normal auto-restore
- This prevents vm-first-run.sh (authentication) from running inside tmux session restoration

**Flag State Correlation:**
- Flag EXISTS = first boot = no saved sessions to restore anyway
- Flag ABSENT = normal operation = saved sessions available for restore
- These states never overlap in normal operation

**Session Restore Verification:**
- Normal --restart (no flag) → auto-restore works via `-A` flag
- First boot scenarios (flag exists) → no auto-restore needed (nothing saved yet)
- After first boot, flag removed → subsequent restarts work normally

## Related

- **BUG-006** - The bug we were fixing (tmux config deployment failure)
- **Phase 0.11** - Session persistence feature (now working correctly)
- **scripts/calf-bootstrap** - Step 10.5 fixed, conditional auto-restore added
- **scripts/vm-setup.sh** - Flag removal logic (correct)
- **scripts/vm-tmux-resurrect.sh** - TPM conditional loading (correct)
