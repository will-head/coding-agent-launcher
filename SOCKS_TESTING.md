# SOCKS Proxy Testing Guide

This document provides test procedures to verify SOCKS proxy functionality works correctly in both scenarios: when proxy IS needed and when it's NOT needed.

## Summary of Changes

The SOCKS proxy system has been redesigned to:
1. **Start SOCKS tunnel BEFORE vm-setup.sh during --init** (so Homebrew/curl/etc can use it)
2. **Pass proxy environment variables explicitly** to vm-setup.sh when SOCKS is active
3. **Set proxy vars dynamically** only when SOCKS tunnel is actually running
4. **Smart network detection** in vm-auth.sh that tries direct connection first
5. **Clear feedback** about which connection method is being used

## Test Scenario 1: SOCKS NOT Needed (Direct Connection Works)

**Environment:** Home network, direct internet access from VM

### Test Steps:

1. **Clean slate:**
   ```bash
   # Delete VMs if they exist
   tart delete cal-dev 2>/dev/null || true
   tart delete cal-init 2>/dev/null || true
   tart delete cal-clean 2>/dev/null || true
   ```

2. **Run init with SOCKS in auto mode (default):**
   ```bash
   cd /Users/willhead/code/will-head/coding-agent-launcher
   ./scripts/cal-bootstrap --init
   ```

3. **Expected behavior:**
   - Step 5 should test connectivity and report: "→ Network OK, SOCKS tunnel not needed"
   - Step 7 (Install tools) should proceed WITHOUT proxy environment variables
   - Homebrew update should work directly
   - Tool installations (node, gh, claude, cursor, opencode, gost) should all succeed
   - vm-auth.sh should detect "✓ Direct connection working"

4. **Verify inside VM:**
   ```bash
   # SSH into cal-dev
   tart run cal-dev  # Wait for boot, then SSH
   
   # Check that proxy vars are NOT set
   echo "HTTP_PROXY=$HTTP_PROXY"  # Should be empty
   echo "HTTPS_PROXY=$HTTPS_PROXY"  # Should be empty
   
   # Check SOCKS status
   socks_status
   # Should show: "Status: ✗ Not running"
   
   # Test direct connectivity
   curl -I https://github.com
   # Should work WITHOUT needing SOCKS
   
   # Verify tools work
   gh --version
   claude --version
   opencode --version
   ```

5. **Expected result:** ✅ Everything works without SOCKS tunnel

---

## Test Scenario 2: SOCKS IS Needed (Direct Connection Fails)

**Environment:** Corporate network with restrictive proxy

### Test Steps:

1. **Clean slate:**
   ```bash
   # Delete VMs if they exist
   tart delete cal-dev 2>/dev/null || true
   tart delete cal-init 2>/dev/null || true
   tart delete cal-clean 2>/dev/null || true
   ```

2. **Enable Remote Login on host (required for SOCKS):**
   ```bash
   # Check if SSH is already enabled
   sudo launchctl list | grep com.openssh.sshd
   
   # If not enabled:
   sudo systemsetup -setremotelogin on
   
   # Verify
   nc -z 192.168.64.1 22 && echo "✓ SSH ready"
   ```

3. **Run init with SOCKS in ON mode (to simulate corporate environment):**
   ```bash
   cd /Users/willhead/code/will-head/coding-agent-launcher
   ./scripts/cal-bootstrap --init --socks on
   ```

4. **Expected behavior:**
   - Step 5 should report: "SOCKS mode: on (forced)"
   - SOCKS tunnel should start successfully with the celebratory cow
   - Step 7 (Install tools) should show: "🌐 Using SOCKS proxy for network access"
   - Proxy environment variables should be shown:
     ```
     HTTP_PROXY=http://localhost:8080
     HTTPS_PROXY=http://localhost:8080
     ```
   - Homebrew update should work THROUGH the proxy
   - All tool installations should succeed using the SOCKS tunnel
   - vm-auth.sh should detect proxy and report: "✓ Using SOCKS proxy"

5. **Verify inside VM:**
   ```bash
   # SSH into cal-dev
   ssh admin@$(tart ip cal-dev)
   
   # Check that proxy vars ARE set
   echo "HTTP_PROXY=$HTTP_PROXY"  # Should be: http://localhost:8080
   echo "HTTPS_PROXY=$HTTPS_PROXY"  # Should be: http://localhost:8080
   echo "ALL_PROXY=$ALL_PROXY"  # Should be: socks5://localhost:1080
   
   # Check SOCKS status
   socks_status
   # Should show:
   #   Status: ✓ Running (PID: XXXX)
   #   Connectivity: ✓ Working
   #   Proxy vars: ✓ Set
   #   HTTP Bridge: ✓ Running (PID: XXXX)
   
   # Test connectivity through SOCKS
   curl -I https://github.com
   # Should work using the proxy
   
   # Verify tools work
   gh --version
   claude --version
   opencode --version
   
   # Test SOCKS functions
   stop_socks
   # Proxy vars should be unset
   echo "HTTP_PROXY=$HTTP_PROXY"  # Should now be empty
   
   start_socks
   # Proxy vars should be set again
   echo "HTTP_PROXY=$HTTP_PROXY"  # Should be: http://localhost:8080
   ```

6. **Test vm-auth.sh with proxy:**
   ```bash
   # Inside VM
   ~/scripts/vm-auth.sh
   
   # Should show:
   # "🌐 Checking network connectivity..."
   # "  ✓ Using SOCKS proxy (HTTP_PROXY=http://localhost:8080)"
   # Then proceed with authentication
   ```

7. **Expected result:** ✅ Everything works THROUGH SOCKS tunnel

---

## Test Scenario 3: Auto Mode (Default Behavior)

This tests that auto mode correctly detects when SOCKS is needed.

### Test A: Auto with Direct Access

```bash
# Clean slate
tart delete cal-dev 2>/dev/null || true

# Run with auto mode (default)
./scripts/cal-bootstrap --init
# Should behave like Scenario 1 (no SOCKS)
```

### Test B: Auto with No Direct Access

```bash
# Clean slate
tart delete cal-dev 2>/dev/null || true

# Simulate restricted network by running with --socks auto
# but in an environment where github.com is blocked
# (This is hard to test without actual network restrictions)

# Alternative: Force SOCKS on to simulate
./scripts/cal-bootstrap --init --socks on
# Should behave like Scenario 2 (SOCKS enabled)
```

---

## Test Scenario 4: SOCKS Mode Switching

Test that changing SOCKS mode works correctly.

```bash
# Start VM without SOCKS
./scripts/cal-bootstrap --run --socks off

# Inside VM - should have NO proxy
ssh admin@$(tart ip cal-dev)
echo "HTTP_PROXY=$HTTP_PROXY"  # Empty

# Exit and restart with SOCKS on
./scripts/cal-bootstrap --restart --socks on

# Inside VM - should have proxy
ssh admin@$(tart ip cal-dev)
echo "HTTP_PROXY=$HTTP_PROXY"  # Should be set
socks_status  # Should show running
```

---

## Common Issues and Solutions

### Issue: Homebrew update fails during --init

**Symptom:** `brew update` fails with network errors even though SOCKS is enabled

**Check:**
```bash
# During init, vm-setup.sh should show:
🌐 Using SOCKS proxy for network access
   HTTP_PROXY=http://localhost:8080
   HTTPS_PROXY=http://localhost:8080
```

**Fix:** Verify SOCKS tunnel started before vm-setup.sh ran (Step 5 before Step 7)

### Issue: Direct connection works but SOCKS is still enabled

**Symptom:** Auto mode enables SOCKS even though direct access works

**Check:**
```bash
# During init Step 5, should show:
Testing VM network connectivity to github.com...
✓ VM can reach github.com directly
→ Network OK, SOCKS tunnel not needed
```

**Fix:** Check if github.com is actually reachable from VM

### Issue: Proxy vars not set inside VM after SOCKS starts

**Symptom:** `socks_status` shows "Running" but `echo $HTTP_PROXY` is empty

**Check:**
```bash
# Inside VM
socks_status
# Look for: "Proxy vars: ⚠ Not set (run: source ~/.zshrc)"
```

**Fix:** 
```bash
# Option 1: Reload shell config
source ~/.zshrc

# Option 2: Manually run
start_socks

# Option 3: Restart shell
exec zsh
```

### Issue: Tools can't reach internet even with SOCKS running

**Symptom:** SOCKS tunnel running but `curl https://github.com` fails

**Check:**
```bash
# Test SOCKS directly
curl --socks5-hostname localhost:1080 -I https://www.google.com

# Test HTTP bridge
curl --proxy http://localhost:8080 -I https://www.google.com

# Check tunnel status
socks_status
```

**Fix:**
```bash
restart_socks
```

---

## Quick Verification Commands

### On Host Mac:

```bash
# Check if Remote Login is enabled (required for SOCKS)
sudo launchctl list | grep com.openssh.sshd

# Check SSH is reachable from VM network
nc -z 192.168.64.1 22 && echo "✓ SSH ready"

# View cal-bootstrap logs
tail -50 ~/.cal-bootstrap.log
```

### Inside VM:

```bash
# Check SOCKS status
socks_status

# Check proxy environment variables
env | grep -i proxy

# Test direct connectivity
curl -s --connect-timeout 5 -I https://github.com | head -1

# Test SOCKS connectivity
curl -s --connect-timeout 5 --socks5-hostname localhost:1080 -I https://github.com | head -1

# View SOCKS logs
tail -50 ~/.cal-socks.log
tail -50 ~/.cal-http-proxy.log

# Manually control SOCKS
start_socks    # Start tunnel
stop_socks     # Stop tunnel
restart_socks  # Restart tunnel
```

---

## Success Criteria

### ✅ SOCKS NOT Needed (Scenario 1):
- [ ] --init completes successfully without SOCKS tunnel
- [ ] brew update works without proxy
- [ ] All tools install successfully
- [ ] vm-auth.sh reports "Direct connection working"
- [ ] Inside VM: `HTTP_PROXY` is empty
- [ ] Inside VM: `socks_status` shows "Not running"
- [ ] curl works without proxy

### ✅ SOCKS IS Needed (Scenario 2):
- [ ] --init detects need for SOCKS (or forced with --socks on)
- [ ] SOCKS tunnel starts before vm-setup.sh
- [ ] vm-setup.sh shows "Using SOCKS proxy"
- [ ] brew update works through proxy
- [ ] All tools install successfully through proxy
- [ ] vm-auth.sh reports "Using SOCKS proxy"
- [ ] Inside VM: `HTTP_PROXY=http://localhost:8080`
- [ ] Inside VM: `socks_status` shows "Running" and "Working"
- [ ] curl works through proxy

### ✅ Proxy Control:
- [ ] `start_socks` sets proxy variables
- [ ] `stop_socks` unsets proxy variables
- [ ] Shell auto-start works correctly based on SOCKS_MODE
- [ ] Switching modes (--socks on/off/auto) works correctly

---

## Next Steps

1. Run Test Scenario 1 (SOCKS NOT needed) - most users
2. Run Test Scenario 2 (SOCKS IS needed) - corporate users
3. Verify all success criteria are met
4. Report any issues found
