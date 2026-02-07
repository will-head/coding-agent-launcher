# Testing Instructions: Cal-Cache Directory Sharing Fix

> **Status:** Requires Testing
> **Related:** PR #9 (Git clone caching) - prerequisite fix
> **Issue:** Fixes broken symlink issue blocking PR #9 testing

## What Was Fixed

Added Tart directory sharing for `~/.calf-cache` to make package caches (Homebrew, npm, Go, Git) accessible inside VMs.

**Changes:**
- `scripts/calf-bootstrap` - Added `--dir calf-cache:${HOME}/.calf-cache:rw` to both `start_vm_background()` and `do_gui()` functions

**Why Needed:**
- Package cache implementations create symlinks like `~/.calf-cache/git -> /Volumes/My Shared Files/cal-cache/git`
- Before: `/Volumes/My Shared Files/cal-cache` didn't exist (not shared) → broken symlinks
- After: `/Volumes/My Shared Files/cal-cache` exists → symlinks work

---

## Test Set 1: Existing VM Setup (Quick Update)

Tests updating an existing cal-dev VM without destroying it.

### Prerequisites
- Existing cal-dev VM
- Updated calf-bootstrap script (from this commit)

### Setup Test Script

Run this in the VM to create the test script:

```bash
cat > ~/test-cal-cache-sharing.sh << 'EOF'
#!/bin/bash
set -e

echo "=== CAL Cache Sharing Test ==="
echo ""

# Test 1: Check if cal-cache is mounted
echo "Test 1: Verify cal-cache volume is mounted"
if [ -d "/Volumes/My Shared Files/cal-cache" ]; then
    echo "  ✓ /Volumes/My Shared Files/cal-cache exists"
else
    echo "  ✗ /Volumes/My Shared Files/cal-cache NOT found"
    echo "  → VM needs restart with updated calf-bootstrap"
    exit 1
fi
echo ""

# Test 2: Check if host cache directories are visible
echo "Test 2: Verify host cache directories are visible in VM"
for cache_type in homebrew npm go git; do
    if [ -d "/Volumes/My Shared Files/cal-cache/$cache_type" ]; then
        echo "  ✓ $cache_type cache visible"
    else
        echo "  ⚠ $cache_type cache not found (may not exist on host yet)"
    fi
done
echo ""

# Test 3: Test symlink creation
echo "Test 3: Test symlink creation to shared cache"
mkdir -p ~/.calf-cache
ln -sf "/Volumes/My Shared Files/cal-cache/git" ~/.calf-cache/git 2>/dev/null || true
if [ -L ~/.calf-cache/git ]; then
    echo "  ✓ Symlink created: ~/.calf-cache/git"
    if [ -d ~/.calf-cache/git ]; then
        echo "  ✓ Symlink target exists (not broken)"
    else
        echo "  ⚠ Symlink target doesn't exist (host git cache empty)"
    fi
else
    echo "  ✗ Failed to create symlink"
    exit 1
fi
echo ""

# Test 4: Test write access
echo "Test 4: Test write access to shared cache"
test_file="/Volumes/My Shared Files/cal-cache/test-write-$$"
if echo "test" > "$test_file" 2>/dev/null; then
    echo "  ✓ Write access confirmed"
    rm -f "$test_file"
else
    echo "  ✗ No write access (should be rw, not ro)"
    exit 1
fi
echo ""

# Test 5: Verify git cache for PR #9
echo "Test 5: Check for TPM git cache (PR #9 requirement)"
if [ -d "/Volumes/My Shared Files/cal-cache/git/tpm" ]; then
    echo "  ✓ TPM git cache exists"
    echo "    Location: /Volumes/My Shared Files/cal-cache/git/tpm"
else
    echo "  ⚠ TPM git cache not found (expected - will be created by PR #9)"
fi
echo ""

echo "=== Summary ==="
echo "✓ Cal-cache sharing is working correctly"
echo "✓ Symlinks can be created and are not broken"
echo "✓ Write access confirmed"
echo ""
echo "Next: Test PR #9 with this working environment"
EOF

chmod +x ~/test-cal-cache-sharing.sh
```

### Testing Steps

1. **Ensure host has cache directory** (on host machine):
   ```bash
   mkdir -p ~/.calf-cache/{homebrew,npm,go,git}
   ls -la ~/.calf-cache
   ```

2. **Stop the current VM** (from host):
   ```bash
   ./calf-bootstrap --stop
   ```

3. **Start VM with updated calf-bootstrap** (applies new --dir flag):
   ```bash
   ./calf-bootstrap --run
   ```

4. **Inside VM, run the test script**:
   ```bash
   ~/test-cal-cache-sharing.sh
   ```

### Expected Results
- ✓ `/Volumes/My Shared Files/cal-cache` exists
- ✓ Host cache directories visible (homebrew, npm, go, git)
- ✓ Symlink creation succeeds and is not broken
- ✓ Write access confirmed
- ⚠ TPM cache not found yet (will be created by PR #9)

### Troubleshooting
If test fails:
- Check that `~/.calf-cache` exists on host
- Verify calf-bootstrap changes were saved
- Check tart process has the new `--dir` flag: `ps aux | grep tart`
- Review VM logs: `cat ~/.calf-bootstrap.log`

---

## Test Set 2: Fresh VM Initialization

Tests that a brand new `--init` creates the VM with cal-cache sharing from the start.

### Prerequisites
- No existing cal-dev, cal-init, cal-clean VMs (or use different names)
- Updated calf-bootstrap script

### Testing Steps

1. **Create host cache directory** (if not exists):
   ```bash
   mkdir -p ~/.calf-cache/{homebrew,npm,go,git}
   ```

2. **OPTIONAL: Clean slate** (CAUTION: Destroys existing VMs):
   ```bash
   # Only run if you want to test from scratch
   ./calf-bootstrap --destroy --yes  # Use with caution
   ```

3. **Initialize fresh VM**:
   ```bash
   ./calf-bootstrap --init
   ```

4. **During init, verify tart command** (from another terminal on host):
   ```bash
   ps aux | grep tart | grep cal-cache
   ```

   Should see:
   ```
   --dir calf-cache:/Users/admin/.calf-cache:rw
   ```

5. **After init completes, inside VM, run test script**:
   ```bash
   ~/test-cal-cache-sharing.sh
   ```

6. **Verify cache directories are automatically created**:
   ```bash
   ls -la /Volumes/My\ Shared\ Files/cal-cache/
   ```

### Expected Results
- ✓ Init completes successfully
- ✓ `/Volumes/My Shared Files/cal-cache` mounted during VM startup
- ✓ All test script checks pass
- ✓ No broken symlinks
- ✓ Write access works

### Additional Verification

7. **Test cache persistence across restart**:
   ```bash
   # Inside VM: Create a test file in cache
   echo "persistence test" > /Volumes/My\ Shared\ Files/cal-cache/test.txt

   # Exit VM
   exit
   ```

   From host:
   ```bash
   ./calf-bootstrap --restart
   ```

   Inside VM again:
   ```bash
   cat /Volumes/My\ Shared\ Files/cal-cache/test.txt
   # Should show: persistence test
   ```

---

## Post-Testing: Verify PR #9

After confirming cal-cache sharing works:

1. **Checkout PR #9 branch**:
   ```bash
   git fetch origin pull/9/head:pr-9-test
   git checkout pr-9-test
   ```

2. **Follow PR #9 manual testing instructions**:
   - TPM caching test (was blocked, should now work)
   - Offline bootstrap verification (was blocked, should now work)

3. **Expected PR #9 behavior**:
   - TPM clones from `/Volumes/My Shared Files/cal-cache/git/tpm/`
   - No broken symlinks
   - Bootstrap works offline after first cache population

---

## Success Criteria

**Test Set 1 (Existing VM):**
- [ ] All 5 test script checks pass
- [ ] No broken symlinks
- [ ] Write access confirmed
- [ ] Ready for PR #9 testing

**Test Set 2 (Fresh Init):**
- [ ] Init completes successfully
- [ ] Cal-cache sharing active from first boot
- [ ] Cache persists across restarts
- [ ] Ready for PR #9 testing

**PR #9 Unblocked:**
- [ ] TPM caching works
- [ ] Offline bootstrap works
- [ ] No filesystem repair needed

---

## Rollback Plan

If issues are found:

1. **Revert calf-bootstrap changes**:
   ```bash
   git revert HEAD  # Revert this commit
   ./calf-bootstrap --restart
   ```

2. **Alternative approach**:
   - Investigate why sharing failed
   - Check Tart version compatibility
   - Review virtio-fs mount options

---

## Notes

- **Time estimate:** Test Set 1: ~2-3 minutes, Test Set 2: ~10-15 minutes
- **Recommendation:** Run Test Set 1 first (faster, less destructive)
- **Test environment:** macOS with Tart VM manager
- **Related documentation:**
  - PLAN-PHASE-01-TODO.md § 1.1.4 (Git Clones Cache)
  - PR #9 (Add Git clone caching for faster VM bootstraps)
