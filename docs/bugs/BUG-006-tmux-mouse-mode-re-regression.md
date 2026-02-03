# BUG-006: vm-tmux-resurrect.sh fails silently on network timeout during --init

**Status:** Resolved
**Severity:** High
**Component:** Bootstrap
**Phase:** 0 (Bootstrap)
**Opened:** 2026-02-02
**Resolved:** 2026-02-02

---

## Summary

The `vm-tmux-resurrect.sh` script fails during `cal-bootstrap --init` when network connectivity is slow or timing out, leaving the VM without tmux configuration. The script exits silently on error (due to `set -e`) and `vm-setup.sh` doesn't detect the failure, resulting in an incomplete installation.

## Symptoms

1. **No ~/.tmux.conf file** - Fresh `--init` completes but tmux config file missing
2. **Keybindings not working** - Custom tmux keybindings (`Ctrl+b r`, `Ctrl+b -`, etc.) don't function
3. **No tmux plugins** - TPM (Tmux Plugin Manager) not installed
4. **Silent failure** - Bootstrap reports success despite missing tmux setup
5. **No session persistence** - tmux-resurrect and tmux-continuum not configured

## Expected Behavior

- `vm-tmux-resurrect.sh` should handle network failures gracefully with retries
- `vm-setup.sh` should detect when tmux setup fails and report error
- User should be notified if network issues prevent tmux configuration
- Script should provide manual recovery instructions on failure

## Root Cause

**Network timeout during TPM installation:**

From user's `--init` log:
```
🖥️  Configuring tmux with session persistence...
============================================
Tmux Session Persistence Setup
============================================

Installing Tmux Plugin Manager (TPM)...
Cloning into '/Users/admin/.tmux/plugins/tpm'...
fatal: unable to access 'https://github.com/tmux-plugins/tpm/': Recv failure: Operation timed out
```

**Why it fails silently:**

1. `vm-tmux-resurrect.sh` has `set -e` (exit on any error)
2. Git clone to github.com times out (line 35: `git clone https://github.com/tmux-plugins/tpm`)
3. Script exits immediately without creating `~/.tmux.conf`
4. `vm-setup.sh` calls the script (line 740) but doesn't check exit code
5. Bootstrap continues as if tmux setup succeeded

## Timeline

- **2026-02-02 ~21:00** - User runs `cal-bootstrap --init`
- **During init** - Network timeout while cloning TPM from GitHub
- **After init** - User discovers tmux config missing, keybindings don't work
- **21:25** - User manually runs `vm-tmux-resurrect.sh`, encounters same TPM error
- **21:26** - User reloads tmux config and manually installs plugins successfully

## Impact

**High severity** - Incomplete bootstrap:
- Missing tmux configuration on fresh installations
- No session persistence (defeats purpose of feature)
- Custom keybindings unavailable
- Silent failure means user doesn't know setup is incomplete
- Network timing issues are unpredictable (may affect other users)

## Why Network Timed Out

**Investigation needed:**

1. **Timing** - Network test passed in Step 5, but failed during tmux setup (several minutes later)
2. **GitHub rate limiting?** - Multiple git operations during init (brew, go tools, TPM)
3. **VM networking instability** - Fresh VM network stack may need settling time
4. **DNS issues?** - Direct curl worked but git clone failed

## Resolution Plan

1. **Add retry logic to vm-tmux-resurrect.sh:**
   - Retry git clone 3 times with 5-second delays
   - Provide clear error message if all retries fail
   - Don't exit on TPM failure - continue to create tmux.conf

2. **Check exit codes in vm-setup.sh:**
   - Capture exit code from `vm-tmux-resurrect.sh` (line 740)
   - Display warning if tmux setup fails
   - Provide recovery instructions to user

3. **Graceful degradation:**
   - Create basic `~/.tmux.conf` even if TPM fails
   - Allow manual plugin installation later
   - Document recovery: `~/scripts/vm-tmux-resurrect.sh`

4. **Network resilience:**
   - Add connection test before TPM clone
   - Consider fallback to GitHub mirror or local cache
   - Log network failures for debugging

## Prevention

- Add retry logic to all network operations during bootstrap
- Check exit codes for all critical setup scripts
- Test bootstrap under poor network conditions
- Provide clear failure messages and recovery paths

## Resolution

**Resolved:** 2026-02-02

**Changes implemented:**

1. **vm-tmux-resurrect.sh - Network resilience:**
   - Added retry logic for TPM git clone (3 attempts, 5s delay)
   - Implemented TPM caching in `~/.cal-cache/tpm/` to avoid repeated downloads
   - Set `PATH=/opt/homebrew/bin:$PATH` in tmux.conf so TPM commands work
   - Set `TMUX_PLUGIN_MANAGER_PATH` environment variable for plugin installation
   - Improved error visibility (capture and show errors instead of hiding with `/dev/null`)

2. **vm-setup.sh - Exit code checking:**
   - Added exit code verification after calling vm-tmux-resurrect.sh
   - Fatal error on tmux setup failure (stops bootstrap)
   - Clear error messages when setup fails

3. **cal-bootstrap - Cleanup on failure:**
   - Explicit cleanup call in do_init when vm-setup.sh fails
   - Ensures cal-dev is deleted on failed --init

**Testing:**
- ✅ Cleanup on failure verified
- ✅ Fresh --init with network timeout handling
- ✅ TPM installation with retry logic
- ✅ Plugin installation with proper environment

## Technical Notes

**TPM Installation Requirements:**
1. **TPM auto-install is a myth** - The `tpm/tpm` script only LOADS plugins, doesn't INSTALL them. Must call `install_plugins` explicitly with proper environment.
2. **Environment matters** - Plugin installation requires both `PATH=/opt/homebrew/bin:$PATH` AND `TMUX_PLUGIN_MANAGER_PATH=$HOME/.tmux/plugins/`
3. **Error visibility is critical** - Redirecting to `/dev/null` with `set -e` hides failures. Always capture output and show on error.
4. **Verify operations** - When critical operations complete (like flag removal), verify success before proceeding. Prevents silent failures.

**Cleanup Best Practices:**
- EXIT traps exist but may not show output
- Explicit cleanup() calls ensure visibility and proper deletion
- Test cleanup logic by adding fake failures during development

## Related

- **scripts/vm-tmux-resurrect.sh** - Script that needs retry logic (line 35)
- **scripts/vm-setup.sh** - Caller that needs exit code checking (line 740)
- **docs/PLAN-PHASE-01-TODO.md § 1.10** - Documentation mentions this script
