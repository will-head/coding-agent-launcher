# Phase 0.8 Testing Checklist

> **Goal:** Verify that the keychain unlock solution enables Cursor agent authentication in the VM.

## Prerequisites

Before starting these tests, ensure:
- [ ] You have completed Phase 0.7 (VM setup with auto-login)
- [ ] `cal-dev` VM exists and is accessible
- [ ] You can run `./scripts/calf-bootstrap --run` successfully
- [ ] Screen Sharing is available: `open vnc://$(tart ip cal-dev)`

## Test Environment

Run these tests from a clean state:

```bash
# Stop the VM if running
./scripts/calf-bootstrap --stop

# Start fresh
./scripts/calf-bootstrap --run
```

---

## Test 1: Keychain Unlock via calf-bootstrap

**What this tests:** Keychain is automatically unlocked when connecting to the VM.

### Steps

1. Start the VM using calf-bootstrap:
   ```bash
   ./scripts/calf-bootstrap --run
   ```

2. Verify keychain unlock message appears:
   ```
   ✓ Keychain unlocked
   ```

3. Inside the VM SSH session, verify keychain status:
   ```bash
   security show-keychain-info login.keychain
   ```

### Expected Result

- [ ] calf-bootstrap shows "✓ Keychain unlocked"
- [ ] Keychain shows it's unlocked (no "locked" message)
- [ ] Command completes without asking for password

### Troubleshooting

If keychain is still locked:
- Check VM_PASSWORD environment variable: `echo $VM_PASSWORD`
- Try manual unlock: `security unlock-keychain -p admin login.keychain`
- Verify password: default should be `admin`

---

## Test 2: Cursor Agent Login via Screen Sharing

**What this tests:** Agent can authenticate and store credentials with unlocked keychain.

### Steps

1. Ensure VM is running and keychain is unlocked (Test 1)

2. Open Screen Sharing to the VM:
   ```bash
   open vnc://$(tart ip cal-dev)
   ```
   - **Password:** `admin`

3. In the VM GUI, open Terminal (not SSH):
   - Click Applications → Terminal
   - Or use Spotlight: Cmd+Space, type "Terminal"

4. Verify agent is installed:
   ```bash
   agent --version
   ```

5. Start agent login:
   ```bash
   agent
   ```

6. Complete OAuth flow:
   - Browser should open automatically
   - Sign in with your Cursor/GitHub account
   - Authorize the application
   - Return to Terminal

7. Verify authentication:
   ```bash
   agent whoami
   ```

### Expected Result

- [ ] `agent --version` shows version (e.g., `0.x.x`)
- [ ] `agent` command opens browser for OAuth
- [ ] OAuth completes successfully without keychain errors
- [ ] Credentials are stored (no "Security command failed" error)
- [ ] `agent whoami` shows your username/email
- [ ] No error messages about keychain access

### Troubleshooting

If you see "Security command failed (exit code 36)":
- Keychain is still locked - go back to Test 1
- Try manual unlock in VM Terminal: `security unlock-keychain -p admin login.keychain`

If browser doesn't open:
- Try with: `NO_OPEN_BROWSER=1 agent login`
- Follow the URL printed in terminal

---

## Test 3: Credential Persistence After SSH Reconnect

**What this tests:** Credentials remain accessible across SSH sessions.

### Steps

1. Complete Test 2 successfully (agent is logged in)

2. Exit the VM SSH session:
   ```bash
   exit
   ```

3. Reconnect via calf-bootstrap:
   ```bash
   ./scripts/calf-bootstrap --run
   ```

4. Verify agent authentication persists:
   ```bash
   agent whoami
   ```

5. Try starting a coding session:
   ```bash
   cd ~/workspace
   mkdir test-persistence
   cd test-persistence
   agent
   ```
   - Give it a simple task: "create a hello.txt file with 'Hello World'"
   - Verify it works without re-authentication

### Expected Result

- [ ] Keychain unlocked automatically on reconnect
- [ ] `agent whoami` works without re-login
- [ ] Agent can execute tasks without authentication errors
- [ ] No keychain prompts during normal operation

### Troubleshooting

If authentication is lost:
- Check if keychain locked: `security show-keychain-info login.keychain`
- Re-run agent login from Screen Sharing (Test 2)

---

## Test 4: Credential Persistence Across VM Reboots

**What this tests:** Credentials survive VM restart (most critical test).

### Steps

1. Complete Test 3 successfully

2. Stop the VM gracefully:
   ```bash
   exit  # from SSH session
   ./scripts/calf-bootstrap --stop
   ```

3. Wait for VM to stop completely (5-10 seconds)

4. Start the VM again:
   ```bash
   ./scripts/calf-bootstrap --run
   ```

5. Verify keychain unlock happens automatically:
   - Look for "✓ Keychain unlocked" message

6. Check agent authentication:
   ```bash
   agent whoami
   ```

7. Test agent functionality:
   ```bash
   cd ~/workspace/test-persistence
   agent
   ```
   - Give it another task: "create a goodbye.txt file"
   - Verify it works

### Expected Result

- [ ] VM restarts successfully
- [ ] Keychain unlocked on startup
- [ ] `agent whoami` works immediately
- [ ] Agent can execute tasks without re-login
- [ ] No "Security command failed" errors

### Critical Success Criteria

**This is the most important test.** If credentials persist across reboots:
✅ Phase 0.8 is complete and working correctly.

### Troubleshooting

If credentials are lost after reboot:
- This is expected behavior - keychain unlocks but OAuth tokens may not persist
- Re-authenticate via Screen Sharing (Test 2)
- Document if this happens consistently

---

## Test 5: Auto-Unlock on calf-bootstrap --run

**What this tests:** Every connection attempt unlocks keychain automatically.

### Steps

1. Ensure VM is running

2. Exit SSH session if connected:
   ```bash
   exit
   ```

3. Connect multiple times using calf-bootstrap:
   ```bash
   ./scripts/calf-bootstrap --run
   # Verify keychain unlock message
   exit

   ./scripts/calf-bootstrap --run
   # Verify keychain unlock message again
   exit
   ```

4. Each time, verify:
   ```bash
   security show-keychain-info login.keychain
   agent whoami
   ```

### Expected Result

- [ ] Every `--run` shows "✓ Keychain unlocked"
- [ ] Keychain is unlocked every time
- [ ] Agent credentials remain accessible
- [ ] Process is automatic (no manual intervention)

---

## Test 6: Test Script Verification

**What this tests:** Automated test script reports correct status.

### Steps

1. Ensure VM is running

2. Get VM IP:
   ```bash
   tart ip cal-dev
   ```

3. Run test script:
   ```bash
   ./scripts/test-cursor-login.sh $(tart ip cal-dev)
   ```

4. Review output for each check:
   - Keychain status
   - Keychain unlock
   - Agent installation
   - Agent authentication

### Expected Result

- [ ] Keychain is unlocked successfully
- [ ] Agent is installed and version shown
- [ ] `agent whoami` shows authentication (or timeout if not logged in)
- [ ] No unexpected errors

---

## Success Criteria Summary

Phase 0.8 is **COMPLETE** when:

- ✅ Test 1: Keychain unlocks automatically via calf-bootstrap
- ✅ Test 2: Agent authentication works via Screen Sharing
- ✅ Test 3: Credentials persist across SSH reconnects
- ✅ Test 4: **Credentials persist across VM reboots** (critical)
- ✅ Test 5: Auto-unlock works consistently
- ✅ Test 6: Test script reports success

## Recording Results

Update `PLAN.md` after completing each test:

```markdown
- [x] Test agent login via Screen Sharing
- [x] Verify credential persistence
- [x] Test across VM reboots
- [x] Verify auto-unlock on connection
```

## Known Limitations

Document any issues found:

1. **OAuth Requirement:** First-time login always requires browser (Screen Sharing)
2. **Session-based Unlock:** Keychain must be unlocked on each SSH connection
3. **Password in Script:** unlock command uses cleartext password (VM_PASSWORD)

## Next Steps After Testing

Once all tests pass:

1. Update PLAN.md to mark Phase 0.8 complete
2. Update roadmap.md to reflect completion
3. Proceed to Phase 0.9 (VM Management Improvements)
4. Consider any enhancements based on test findings

---

## Additional Testing (Optional)

### Test with Claude Code

```bash
# In VM
claude --version
claude
# Test if credentials work
```

### Test with opencode

```bash
# In VM
opencode --version
opencode auth login  # if not logged in
opencode
# Test functionality
```

### Test Keychain Lock After Sleep

1. Let VM go to sleep (or force sleep if possible)
2. Wake VM
3. Verify keychain status
4. Reconnect via calf-bootstrap
5. Check if auto-unlock still works

---

## Troubleshooting Reference

### Keychain Commands

```bash
# Check keychain status
security show-keychain-info login.keychain

# Unlock keychain manually
security unlock-keychain -p admin login.keychain

# List keychains
security list-keychains

# Check default keychain
security default-keychain
```

### Agent Commands

```bash
# Check version
agent --version

# Check authentication
agent whoami

# Login (if needed)
agent login

# Logout
agent logout
```

### VM Commands

```bash
# Get VM IP
tart ip cal-dev

# Check VM status
tart list

# Stop VM
./scripts/calf-bootstrap --stop

# Start VM
./scripts/calf-bootstrap --run

# Screen Sharing
open vnc://$(tart ip cal-dev)
```

---

## Questions to Answer During Testing

1. **Do credentials persist across reboots?**
   - Yes / No / Partially

2. **How long do credentials remain valid?**
   - After SSH reconnect?
   - After VM restart?
   - After VM sleep/wake?

3. **Are there any error messages during normal operation?**
   - List any errors seen

4. **Does the OAuth flow work smoothly?**
   - Any issues with browser opening?
   - Any issues with redirect?

5. **Are there any security warnings?**
   - Keychain prompts?
   - Certificate warnings?
   - Permission requests?

---

## Reporting Issues

If tests fail, provide:

1. **Which test failed** (Test 1-6)
2. **Exact error message**
3. **Steps to reproduce**
4. **VM state** (running/stopped, fresh/rebooted)
5. **Agent version** (`agent --version`)
6. **macOS version** (in VM: `sw_vers`)
7. **Keychain status output**

Create a new issue or update PLAN.md with findings.
