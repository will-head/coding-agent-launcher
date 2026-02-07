# Phase 0.8 Testing - Quick Start Guide

> **TL;DR:** This guide helps you quickly test if Cursor agent authentication works with the keychain unlock solution.

---

## What You're Testing

The keychain unlock solution should enable Cursor agent authentication in the VM by automatically unlocking the macOS keychain when you connect via SSH. This fixes the "Security command failed (exit code 36)" error.

## Prerequisites Checklist

Before starting:
- [ ] Tart is installed: `brew install cirruslabs/cli/tart`
- [ ] `calf-dev` VM exists
- [ ] VM has agents installed (run `./scripts/calf-bootstrap --init` if not)
- [ ] You can access Screen Sharing (for OAuth login)

---

## Quick Test (15 minutes)

### Step 1: Start VM and Check Keychain (2 min)

```bash
# Start the VM
./scripts/calf-bootstrap --run
```

**Look for:** `✓ Keychain unlocked` message

**Verify in SSH session:**
```bash
security show-keychain-info login.keychain
```

**Expected:** No "locked" message, command completes without password prompt.

---

### Step 2: Test Cursor Agent Login (5 min)

```bash
# Open Screen Sharing
open vnc://$(tart ip calf-dev)
# Password: admin
```

**In VM GUI Terminal:**
1. Open Terminal app (Applications → Terminal)
2. Run: `agent --version` (should show version)
3. Run: `agent` (should open browser for OAuth)
4. Complete OAuth flow in browser
5. Verify: `agent whoami` (should show your username)

**Expected:** OAuth completes, no keychain errors, credentials stored successfully.

---

### Step 3: Test Persistence After Reconnect (3 min)

**In your host terminal (where you have the SSH session):**
```bash
# Exit SSH
exit

# Reconnect
./scripts/calf-bootstrap --run

# Check if still authenticated
agent whoami
```

**Expected:** Authentication persists, no re-login needed.

---

### Step 4: Test Persistence After Reboot (5 min) ⭐ **CRITICAL**

```bash
# Stop VM
exit
./scripts/calf-bootstrap --stop

# Wait 5 seconds, then restart
./scripts/calf-bootstrap --run

# Check authentication
agent whoami
```

**Expected:** Credentials persist across reboot.

**⚠️ If this fails:** It may be expected behavior. Keychain unlocks successfully but OAuth tokens may not survive reboot. Document the behavior.

---

## Quick Test Results

Fill this out:

- [ ] ✅ Step 1: Keychain unlocks automatically
- [ ] ✅ Step 2: Agent login works via Screen Sharing
- [ ] ✅ Step 3: Credentials persist after SSH reconnect
- [ ] ✅ Step 4: Credentials persist after VM reboot

**If all checks pass:** Phase 0.8 is complete! 🎉

**If any fail:** See [TESTING.md](TESTING.md) for detailed troubleshooting.

---

## Update PLAN.md After Testing

Once tests pass, update `PLAN.md`:

```markdown
- [x] Test agent login via Screen Sharing
- [x] Verify credential persistence
- [x] Test across VM reboots
- [x] Verify auto-unlock on connection
```

Change Phase 0.8 status:
```markdown
**Phase 0.8:** Complete ✅
```

---

## What If Tests Fail?

### Keychain Won't Unlock (Step 1)
- Check VM password: `echo $VM_PASSWORD` (should be empty or "admin")
- Try manual unlock: `security unlock-keychain -p admin login.keychain`
- Check vm-setup.sh ran correctly: look for auto-login settings

### Agent Login Fails (Step 2)
- Verify agent installed: `which agent`
- Check PATH: `echo $PATH` (should include `~/.local/bin`)
- Try from GUI Terminal instead of SSH
- Check browser opens for OAuth

### Credentials Lost After Reconnect (Step 3)
- This suggests keychain locked again
- Re-run keychain unlock manually
- Check if keychain timeout settings applied

### Credentials Lost After Reboot (Step 4)
- **This may be expected behavior**
- Document if consistent
- Users may need to re-authenticate after reboot
- Consider this acceptable for Phase 0.8

---

## Next Steps After Testing

### If Tests Pass
1. Mark Phase 0.8 complete in PLAN.md
2. Update roadmap.md
3. Commit changes: `git add PLAN.md docs/roadmap.md && git commit`
4. Move to Phase 0.9 improvements

### If Tests Fail
1. Review full [TESTING.md](TESTING.md) troubleshooting
2. Check [cursor-login-fix.md](cursor-login-fix.md) for solution details
3. Verify keychain commands work manually
4. Consider alternative approaches in cursor-login-fix.md

---

## Need More Details?

See comprehensive testing guide: [TESTING.md](TESTING.md)

Includes:
- 6 detailed test cases
- Complete troubleshooting steps
- All keychain and agent commands
- Expected outputs for each test
- Issue reporting template

---

## Testing Reminders

- **Screen Sharing required** for OAuth login (browser-based)
- **SSH access sufficient** for checking credentials after login
- **First login always requires OAuth** (browser interaction)
- **Subsequent access should work** without re-authentication
- **Document any unusual behavior** for Phase 0.9 planning
