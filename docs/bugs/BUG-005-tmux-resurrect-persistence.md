# BUG-005: tmux-resurrect Session Persistence Fails Across VM Restart

**Status:** 🔴 OPEN
**Priority:** Medium
**Discovered:** 2026-02-02
**Phase:** 0 (Bootstrap)
**Component:** tmux-resurrect, VM lifecycle

## Summary

tmux-resurrect and tmux-continuum do not successfully persist tmux sessions across VM `--stop` or `--restart` operations. While sessions persist when detaching and using `--run` (because tmux server stays running), they are lost when the VM is stopped and restarted.

## Expected Behavior

1. User creates tmux session with multiple windows/panes
2. User detaches from tmux
3. User runs `./cal-bootstrap --restart`
4. VM stops, restarts, and SSH reconnects
5. tmux-continuum auto-restore recreates the previous session layout

## Actual Behavior

1. User creates tmux session with multiple windows/panes
2. User detaches from tmux
3. User runs `./cal-bootstrap --restart`
4. VM stops, restarts, and SSH reconnects
5. Fresh tmux session is created (previous session lost)

## Root Cause Analysis

### Save Data Corruption

The primary issue is that tmux-resurrect save files contain only:
```
state
state
state
```

Instead of proper session data which should include:
- Window information
- Pane layouts
- Working directories
- Running programs
- Pane contents (scrollback)

This affects:
- **Auto-save** (tmux-continuum every 15 min): Produces corrupted data
- **Manual save** (Ctrl+b Ctrl+s): Produces corrupted data
- **Logout save** (.zlogout hook): Produces corrupted data
- **Programmatic save** (cal-bootstrap --stop/--restart): Produces corrupted data

### Investigation Timeline

#### Initial Hypothesis: Sessions Not Being Saved Before VM Stop
- **Finding:** `tart stop` sends shutdown signal but SSH sessions disconnect abruptly
- **.zlogout hook never executes** because SSH connection is killed
- **Solution attempt:** Added `save_tmux_sessions()` function to cal-bootstrap
  - Calls save script before `tart stop`
  - Function runs and reports success
  - But save file still contains corrupted data

#### Second Hypothesis: Sessions Not Being Restored After VM Start
- **Finding:** cal-bootstrap used `tmux new-session -A -s cal-dev`
- **Problem:** Creating new session immediately prevents continuum auto-restore
- **Solution attempt:** Changed to `tmux start-server; restore; attach or create`
  - Explicitly triggers restore script
  - But restore fails because save data is corrupted

#### Third Hypothesis: PATH Issues Preventing Save/Restore
- **Finding:** Homebrew not in PATH for non-login shells
- **Problem:** `tmux` command not found when running via SSH non-interactively
- **Solution:** Use full path `/opt/homebrew/bin/tmux`
- **Result:** Save now runs but still produces corrupted data

#### Fourth Hypothesis: Asynchronous Save Not Completing
- **Finding:** `tmux run-shell` is asynchronous
- **Problem:** SSH might disconnect before save completes
- **Solution attempts:**
  1. Run save script directly with environment setup
  2. Use `tmux run-shell -b` with sleep delay
- **Result:** Save completes but data still corrupted

### Current Status

**Save mechanism is broken at a fundamental level.** All save methods (auto, manual, programmatic) produce invalid data containing only "state state state" instead of actual session information.

## What Works

- ✅ Detach and `--run`: Sessions persist (tmux server stays running)
- ✅ Save is triggered successfully (files are created)
- ✅ TPM and tmux-resurrect plugins are installed
- ✅ tmux-continuum configuration is correct

## What Doesn't Work

- ❌ Save data is corrupted (only "state state state")
- ❌ Restore cannot work with corrupted data
- ❌ Sessions lost on VM restart
- ❌ Manual save (Ctrl+b Ctrl+s) produces same corrupted data

## Environment

- **VM:** cal-dev running macOS Sequoia
- **tmux version:** (from Homebrew /opt/homebrew/bin/tmux)
- **tmux-resurrect:** Installed via TPM at `~/.tmux/plugins/tmux-resurrect`
- **tmux-continuum:** Installed via TPM at `~/.tmux/plugins/tmux-continuum`
- **Save location:** `~/.local/share/tmux/resurrect/`

## Configuration

From `~/.tmux.conf`:
```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'
```

## Reproduction Steps

1. Start VM: `./cal-bootstrap --run`
2. Inside tmux, create test content:
   - Create new window: `Ctrl+b c`
   - Create another window: `Ctrl+b c`
   - Navigate between windows to verify multiple windows exist
3. Manually save: `Ctrl+b Ctrl+s` (silent, no confirmation)
4. Check save file: `ssh admin@192.168.64.142 "cat ~/.local/share/tmux/resurrect/last"`
   - **Expected:** Session data with windows, panes, directories
   - **Actual:** Only "state state state"
5. Detach: `Ctrl+b d`
6. Restart: `./cal-bootstrap --restart`
   - **Expected:** Previous session restored with multiple windows
   - **Actual:** New empty session created

## Code Changes Made (Attempted Fixes)

### 1. Added save_tmux_sessions() Function
**File:** `scripts/cal-bootstrap`
**Location:** After `stop_vm()` function (~line 166)

```bash
save_tmux_sessions() {
    local vm="$1"
    if ! vm_running "$vm"; then
        return 0
    fi

    local vm_ip
    vm_ip=$("$TART" ip "$vm" 2>/dev/null || echo "")

    if [ -z "$vm_ip" ]; then
        echo "  ⚠ Could not get VM IP to save tmux sessions"
        return 0
    fi

    echo "  Saving tmux sessions..."

    save_result=$(ssh -o ConnectTimeout=5 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$VM_USER@$vm_ip" \
        "/opt/homebrew/bin/tmux run-shell -b '~/.tmux/plugins/tmux-resurrect/scripts/save.sh'; sleep 0.5; echo done" 2>&1)

    if echo "$save_result" | grep -q "done"; then
        echo "  ✓ Tmux sessions saved"
    else
        echo "  ⚠ Could not save tmux sessions: $save_result"
    fi
}
```

### 2. Modified do_stop() to Save Before Stopping
**File:** `scripts/cal-bootstrap`
**Location:** `do_stop()` function (~line 1460)

```bash
# Save tmux sessions before stopping
save_tmux_sessions "$VM_DEV"
echo ""

echo "Stopping $VM_DEV..."
"$TART" stop "$VM_DEV"
```

### 3. Modified do_restart() to Save Before Stopping
**File:** `scripts/cal-bootstrap`
**Location:** `do_restart()` function (~line 1500)

```bash
# Stop if running
if vm_running "$VM_DEV"; then
    # Save tmux sessions before stopping
    save_tmux_sessions "$VM_DEV"
    echo ""

    echo "Stopping $VM_DEV..."
    "$TART" stop "$VM_DEV"
    sleep 2
    echo ""
fi
```

### 4. Modified Tmux Startup to Trigger Restore
**File:** `scripts/cal-bootstrap`
**Locations:** Multiple SSH tmux startup calls

Changed from:
```bash
"~/scripts/tmux-wrapper.sh new-session -A -s cal-dev"
```

To:
```bash
"~/scripts/tmux-wrapper.sh start-server; ~/scripts/tmux-wrapper.sh run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh; sleep 1; ~/scripts/tmux-wrapper.sh attach -t cal-dev 2>/dev/null || ~/scripts/tmux-wrapper.sh new-session -s cal-dev"
```

## Next Steps to Investigate

1. **Verify tmux-resurrect installation:**
   ```bash
   ssh admin@192.168.64.142 "ls -la ~/.tmux/plugins/tmux-resurrect/"
   ```

2. **Check TPM plugin loading:**
   ```bash
   ssh admin@192.168.64.142 "/opt/homebrew/bin/tmux show-environment -g | grep PLUGIN"
   ```

3. **Test tmux-resurrect directly:**
   ```bash
   # Inside VM, with tmux running
   bash ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
   # Check output and save file
   ```

4. **Check tmux version compatibility:**
   - tmux-resurrect requires tmux >= 1.9
   - Check for known issues with specific tmux versions

5. **Review tmux-resurrect logs:**
   - Check if plugin produces any error logs
   - Look for save script error messages

6. **Test with minimal tmux.conf:**
   - Remove all customizations except resurrect/continuum
   - See if save works with minimal config

7. **Check file permissions:**
   ```bash
   ls -la ~/.local/share/tmux/resurrect/
   ls -la ~/.tmux/plugins/tmux-resurrect/scripts/
   ```

8. **Verify TMUX environment variable:**
   - tmux-resurrect needs proper $TMUX environment
   - Check if variable is set correctly when save runs

## Workarounds

### Option 1: Reduce Auto-Save Interval
Change from 15 minutes to 1 minute in `~/.tmux.conf`:
```tmux
set -g @continuum-save-interval '1'
```
**Problem:** Still produces corrupted data, just more frequently

### Option 2: Never Stop VM
- Use `--run` to attach to existing session
- Avoid `--restart` and `--stop`
- Keep VM running continuously
**Problem:** Not a real solution, defeats purpose of VM lifecycle

### Option 3: Manual Workflow
Before stopping VM:
1. Note current working directories and layout
2. Recreate manually after restart
**Problem:** Tedious and error-prone

## Related Issues

- Phase 0 TODO: "Investigate tmux-resurrect persistence across VM lifecycle"
- Phase 0 TODO: "Add tmux status prompt for new shells"

## Files Modified

- `scripts/cal-bootstrap` - Added save/restore logic
- `scripts/test-tmux-restore.sh` - Created debug test script

## Files Affected But Not Modified

- `scripts/vm-tmux-resurrect.sh` - Initial tmux-resurrect setup
- `~/.tmux.conf` (in VM) - tmux configuration
- `~/.zlogout` (in VM) - Logout save hook

## Additional Notes

The corrupted save data ("state state state") suggests:
- The save script is running but not capturing session data correctly
- Possible plugin compatibility issue
- Possible tmux version incompatibility
- Possible missing dependencies for save script

This needs deeper investigation into the tmux-resurrect plugin itself, not just the cal-bootstrap integration.
