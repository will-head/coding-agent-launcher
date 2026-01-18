# Testing Instructions for Cursor Agent Login Fix

## Overview

The keychain unlock solution has been implemented. This document provides step-by-step testing instructions to verify the fix works correctly.

## What Was Implemented

1. **vm-setup.sh** - Unlocks keychain during initial VM setup
2. **cal-bootstrap** - Automatically unlocks keychain when starting or connecting to VM
3. **Documentation** - Complete guide in `docs/cursor-login-fix.md`
4. **Test script** - `scripts/test-cursor-login.sh` for verification

## Quick Test (Recommended)

### Step 1: Ensure VM is running with keychain unlocked

```bash
# Start VM (this will auto-unlock keychain)
./scripts/cal-bootstrap --run
```

You should see:
```
Unlocking keychain for SSH access...
✓ Keychain unlocked
```

### Step 2: Complete Cursor agent login via Screen Sharing

Open Screen Sharing to the VM:
```bash
open vnc://$(tart ip cal-dev)
# Password: admin
```

In the VM (via Screen Sharing):
1. Open Terminal app
2. Run: `agent`
3. Complete the OAuth flow in the browser that opens
4. Verify successful login

### Step 3: Test agent authentication via SSH

After completing Step 2, test from host machine:

```bash
ssh admin@$(tart ip cal-dev)
# In VM:
source ~/.zshrc
agent whoami
# Should show your authenticated user info
```

## Detailed Testing Checklist

### Test 1: Keychain Unlock on VM Start

- [ ] Stop VM: `./scripts/cal-bootstrap --stop`
- [ ] Start VM: `./scripts/cal-bootstrap --run`
- [ ] Verify "✓ Keychain unlocked" message appears
- [ ] Exit SSH session

### Test 2: Keychain Unlock on Already-Running VM

- [ ] VM is already running
- [ ] Connect: `./scripts/cal-bootstrap --run`
- [ ] Verify "✓ Keychain unlocked" message appears
- [ ] Exit SSH session

### Test 3: Initial Agent Authentication

- [ ] Open Screen Sharing: `open vnc://$(tart ip cal-dev)`
- [ ] Open Terminal in VM
- [ ] Run: `agent`
- [ ] Complete OAuth in browser
- [ ] Verify success message
- [ ] Run: `agent whoami` to confirm auth

### Test 4: Agent Authentication Persists via SSH

- [ ] SSH to VM: `ssh admin@$(tart ip cal-dev)`
- [ ] Run: `source ~/.zshrc && agent whoami`
- [ ] Should show authenticated user (not prompt for login)

### Test 5: Agent Authentication Persists After VM Reboot

- [ ] Stop VM: `./scripts/cal-bootstrap --stop`
- [ ] Start VM: `./scripts/cal-bootstrap --run`
- [ ] In SSH: `source ~/.zshrc && agent whoami`
- [ ] Should still be authenticated (credentials stored in keychain)

### Test 6: Screen Sharing Clipboard (Original Issue #2)

- [ ] Open Screen Sharing: `open vnc://$(tart ip cal-dev)`
- [ ] Copy text on host machine
- [ ] Paste in VM Terminal (Cmd+V)
- [ ] Verify paste works
- [ ] Copy text in VM
- [ ] Paste on host machine
- [ ] Verify paste works

Note: If clipboard sync doesn't work reliably, use the SSH/scp alternatives documented in `docs/cursor-login-fix.md`.

## Expected Results

### Successful Keychain Unlock
```
CAL Bootstrap - Run
====================

cal-dev is already running.

  Unlocking keychain for SSH access...
  ✓ Keychain unlocked

Connecting via SSH...
```

### Successful Agent Authentication (First Time)
Via Screen Sharing Terminal:
```
$ agent
Opening browser for authentication...
✓ Authentication successful!
```

### Successful Agent Status Check
Via SSH after authentication:
```
$ agent whoami
Logged in as: your-email@example.com
```

## Troubleshooting

### Keychain unlock fails
```bash
# Try manually:
ssh admin@$(tart ip cal-dev)
security unlock-keychain -p admin login.keychain
```

### Agent login hangs in SSH
This is expected - agent login requires browser interaction. Use Screen Sharing instead:
```bash
open vnc://$(tart ip cal-dev)
```

### Agent whoami hangs
The keychain may be locked or credentials not stored. Re-run the unlock:
```bash
ssh admin@$(tart ip cal-dev) "security unlock-keychain -p admin login.keychain"
```

Then try `agent` via Screen Sharing again.

### Screen Sharing shows lock screen
The auto-login feature requires a VM reboot to activate:
```bash
./scripts/cal-bootstrap --stop
./scripts/cal-bootstrap --run
```

### Clipboard paste disconnects in Screen Sharing
This is a known limitation of macOS Screen Sharing. Use SSH-based alternatives:

**Copy from host to VM:**
```bash
echo "your text" | ssh admin@$(tart ip cal-dev) "cat > /tmp/clipboard.txt"
```

**Copy from VM to host:**
```bash
ssh admin@$(tart ip cal-dev) "cat /path/to/file" | pbcopy
```

## Files Modified

1. `scripts/vm-setup.sh` - Added keychain unlock section
2. `scripts/cal-bootstrap` - Added `unlock_keychain()` function
3. `scripts/test-cursor-login.sh` - New test script
4. `docs/cursor-login-fix.md` - Complete documentation
5. `docs/PLAN.md` - Updated status and added Phase 0.8
6. `docs/bootstrap.md` - Updated troubleshooting

## Next Steps After Testing

Once testing is complete and all checks pass:

1. Update PLAN.md to mark Phase 0.8 testing items as complete
2. Consider marking Phase 0 as fully complete
3. Document any remaining issues in Known Issues section
4. Consider creating a new cal-initialised snapshot with the fixes

## Questions to Answer During Testing

1. Does agent login work via Screen Sharing after keychain unlock?
2. Do credentials persist after VM reboot?
3. Does the auto-unlock in cal-bootstrap work reliably?
4. Does Screen Sharing clipboard work better after VM reboot (auto-login active)?
5. Are there any error messages or warnings during normal operation?

## Success Criteria

✅ Phase 0.8 is complete when:
- [ ] Agent login completes successfully via Screen Sharing
- [ ] Agent authentication persists after login
- [ ] Credentials persist across VM reboots
- [ ] Keychain auto-unlocks when using cal-bootstrap --run
- [ ] No manual keychain unlock required for agent to work

---

**Ready to test?** Start with the Quick Test section above and work through each step.
