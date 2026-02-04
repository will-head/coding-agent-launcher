# BUG-009: gh repo clone during --init doesn't persist to snapshot

**Status:** Open
**Severity:** High
**Component:** Bootstrap
**Phase:** 0 (Bootstrap)
**Opened:** 2026-02-04

---

## Summary

Repositories cloned during `cal-bootstrap --init` authentication (Step 9) are not saved to the cal-init snapshot. After first boot, `~/code` is empty even though vm-auth.sh reported successful clones. Running vm-auth again after first boot works - repositories appear in ~/code.

## Symptoms

1. **During --init:** vm-auth.sh shows successful repository clones to ~/code
2. **After first login:** `~/code` directory is empty (or only contains the github.com structure without repos)
3. **After re-running vm-auth:** Repositories clone successfully and persist
4. **No error messages:** Initial clone appears to succeed, no indication of data loss

## Expected Behavior

- Repositories cloned during --init should persist to cal-init snapshot
- After first boot, cloned repositories should be present in ~/code
- User should not need to re-run vm-auth to get repositories

## Actual Behavior

```
Step 9: Agent Authentication
============================================

Opening login shell in VM (vm-auth.sh will run automatically)...

[vm-auth.sh runs, shows successful gh repo clone]
    → Cloning owner/repo...
    ✓ Cloned to: /Users/admin/code/github.com/owner/repo

  Summary: 1 cloned, 0 skipped, 0 failed

[exited]

Step 10: Create cal-init snapshot
  Stopping cal-dev...
  Creating cal-init from cal-dev...
  cal-init created

[later, after first boot]
admin@VM ~ % ls ~/code/github.com/owner/
[empty or repo directory missing]
```

## Root Cause

**Filesystem sync timing issue:**

In `scripts/cal-bootstrap`:

```bash
# Step 9: Agent authentication (line 1317-1333)
ssh -t ... "~/scripts/tmux-wrapper.sh new-session -A -s setup 'zsh -l'"
# vm-auth.sh runs here, clones repos to ~/code

echo ""
echo "Continuing with setup..."

# Step 10: Create cal-init snapshot (line 1352-1368)
echo "  Stopping $VM_DEV..."
"$TART" stop "$VM_DEV" 2>/dev/null || true  # IMMEDIATE STOP - NO SYNC
kill "$TART_PID" 2>/dev/null || true
sleep 2

echo "  Creating $VM_INIT from $VM_DEV..."
"$TART" clone "$VM_DEV" "$VM_INIT"
```

**The issue:**
1. vm-auth.sh clones repositories via `gh repo clone` (writes to disk)
2. SSH session exits immediately after vm-auth.sh completes
3. Bootstrap script continues without waiting for filesystem sync
4. VM is stopped 2 seconds after SSH exit (`tart stop`)
5. Filesystem buffers may not be flushed to disk yet
6. cal-init snapshot is cloned from cal-dev **before writes are persisted**
7. Result: cal-init snapshot has empty ~/code, cloned data lost

## Why Re-running vm-auth Works

After first boot:
- VM starts from cal-init snapshot (has empty ~/code)
- User manually runs vm-auth
- Repositories clone successfully
- User exits normally (giving time for sync)
- OR user creates their own snapshot later (after data is synced)
- Repositories persist because there's no immediate forced shutdown

## Impact

**User Impact:**
- High: Repositories cloned during --init are lost
- Confusing: No error message, appears to work
- Manual workaround needed: Re-run vm-auth after first boot
- Data loss: Any custom setup done during initial auth is lost

**Frequency:**
- Affects every --init with repository cloning
- 100% reproducible

## Workarounds

### Workaround #1: Re-run vm-auth after first boot
```bash
# After cal-bootstrap --init completes and you log in for the first time
vm-auth
# Clone repositories again
```

### Workaround #2: Don't clone during --init
- Skip repository cloning during initial vm-auth
- Clone repositories manually after first boot
- Create your own snapshot after setup

## Potential Fixes

### Fix #1: Explicit sync after vm-auth (RECOMMENDED)

```bash
# In cal-bootstrap, after Step 9 (line 1336)
echo ""
echo "Continuing with setup..."

# ADD THIS:
echo "  Syncing filesystem to disk..."
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "${VM_USER}@${VM_IP}" "sync && sleep 2" 2>> "$CAL_LOG"
echo "  ✓ Filesystem synced"

# Step 9.5: Verify first-run flag exists
...
```

**Why this fix:**
- Ensures all writes are flushed before snapshot
- Simple, proven pattern (already used for flag files)
- Low risk, high confidence
- 2-second sleep gives buffer flush time

### Fix #2: Add sync to vm-auth.sh exit

```bash
# At end of vm-auth.sh (line 469)
echo ""
echo "💡 Proxy commands:"
...
echo ""

# ADD THIS:
echo "Syncing filesystem..."
sync
sleep 2
```

**Why this might not be enough:**
- SSH session exit may still race with sync completion
- Bootstrap script continues immediately after SSH exits
- Still need delay in cal-bootstrap

### Fix #3: Delay before tart stop

```bash
# In cal-bootstrap Step 10 (line 1358)
echo "  Stopping $VM_DEV..."
sleep 5  # Give filesystem time to sync
"$TART" stop "$VM_DEV" 2>/dev/null || true
```

**Why this is less reliable:**
- Magic number delay (how long is enough?)
- No guarantee sync completed
- Less explicit than calling sync

### Fix #4: Combine all three (BELT AND SUSPENDERS)

1. Call sync in vm-auth.sh before exit
2. Call sync from cal-bootstrap after SSH exit
3. Add sleep before tart stop

**Why overkill:**
- Probably unnecessary
- Adds latency to bootstrap
- Fix #1 alone should be sufficient

## Recommended Solution

**Implement Fix #1: Explicit sync after vm-auth**

This is the most reliable and explicit solution:
- Calls `sync` command over SSH after vm-auth completes
- Waits 2 seconds for buffer flush
- Mirrors the pattern already used for flag files (see line 1262, 1348)
- Low risk: sync is idempotent and safe
- Clear: User sees "Syncing filesystem" message

## Testing Plan

1. **Fresh --init with repository cloning:**
   - Run `cal-bootstrap --init`
   - Clone a test repository during vm-auth
   - Complete bootstrap
   - SSH into cal-dev after first boot
   - Verify: `ls ~/code/github.com/owner/repo` shows cloned files

2. **Verify sync doesn't break anything:**
   - Confirm sync command completes without error
   - Confirm bootstrap time increase is acceptable (~2-3 seconds)
   - Confirm no other side effects

3. **Regression test:**
   - Test --init without repository cloning
   - Confirm sync doesn't cause issues when ~/code is empty

## Related Issues

- Similar to first-run flag timing issues resolved in earlier bugs
- Pattern already established: sync critical writes before VM operations
- This is the same class of bug (filesystem sync timing)

## Notes

- This is a data loss bug (cloned repos disappear)
- Silent failure (no error indication)
- Workaround exists but shouldn't be necessary
- Fix is straightforward and follows existing patterns

---

**Next Steps:**
1. Implement Fix #1 (explicit sync after vm-auth)
2. Test with fresh --init including repository cloning
3. Verify repositories persist to cal-init snapshot
4. Update bootstrap to prevent data loss
