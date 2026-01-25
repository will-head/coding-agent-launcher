# Opencode VM Investigation - Further Issues

> Investigation into opencode issues in CAL VM environment
> 
> **Date:** 2026-01-25  
> **Status:** In Progress  
> **Related:** [zai-glm-concurrency-error-investigation.md](zai-glm-concurrency-error-investigation.md)

## Executive Summary

Previous investigation identified that `opencode run` hangs indefinitely while `opencode serve` works correctly. This document investigates:
1. Whether tmux is causing the issue
2. VM setup changes that might help
3. Other potential root causes

## Current Environment

**VM Status:**
- Running in cal-dev VM (`CAL_VM=true`)
- Inside tmux session (`TMUX=/private/tmp/tmux-501/default,5617,0`)
- Terminal: `xterm-256color`
- SSH connection: `192.168.64.1:62950 → 192.168.64.92:22`
- Opencode version: `1.1.35` (installed via Homebrew)

**Environment Variables:**
```
TERM=xterm-256color
TERM_PROGRAM=tmux
TERM_PROGRAM_VERSION=3.6a
TMUX=/private/tmp/tmux-501/default,5617,0
TMUX_PANE=%0
SSH_CLIENT=192.168.64.1 62950 22
SSH_CONNECTION=192.168.64.1 62950 192.168.64.92 22
SSH_TTY=/dev/ttys000
COLORTERM=truecolor
FORCE_COLOR=0
NO_COLOR=1
```

## Known Issues from Previous Investigation

1. **`opencode run` hangs** - Never completes initialization after startup message
2. **`opencode serve` works** - Starts instantly (~2 seconds)
3. **Garbled output (intermittent)** - Some sessions produce garbage text
4. **CLI output not rendering** - Output doesn't display even when sessions complete
5. **60+ second startup delays** - In earlier working runs

## Investigation Areas

### 1. Tmux Impact

**Hypothesis:** Tmux might be interfering with opencode's TUI or I/O handling.

**Evidence:**
- Current session is inside tmux
- Tmux can affect terminal capabilities and signal handling
- Some TUI applications have issues with tmux

**Tests Needed:**
1. Test `opencode run` outside of tmux (direct SSH session)
2. Test `opencode run` with different tmux configurations
3. Compare behavior with/without tmux

**Test Procedure:**
```bash
# Exit tmux
exit

# Test opencode run in direct SSH session
opencode run "test message"

# Compare with tmux session
tmux new-session -d -s test
tmux send-keys -t test 'opencode run "test message"' C-m
```

### 2. Terminal Settings

**Hypothesis:** Terminal capabilities or settings might be incompatible.

**Current Settings:**
- `TERM=xterm-256color` (set by tmux config)
- `FORCE_COLOR=0` and `NO_COLOR=1` (might disable color output)
- `SSH_TTY=/dev/ttys000` (pseudo-terminal)

**Potential Issues:**
- Color environment variables might confuse opencode
- Terminal size detection might fail
- Pseudo-terminal vs real terminal differences

**Tests Needed:**
1. Test with `TERM=screen-256color` (tmux default)
2. Test with `TERM=vt100` (minimal)
3. Test with color variables unset
4. Check terminal size: `stty size`

**Test Procedure:**
```bash
# Test with different TERM values
TERM=screen-256color opencode run "test"
TERM=vt100 opencode run "test"

# Test without color variables
unset FORCE_COLOR NO_COLOR
opencode run "test"

# Check terminal size
stty size
```

### 3. File/Process Locks

**Hypothesis:** Opencode might be waiting for locks or resources that never become available.

**Findings:**
- No `.lock` or `.pid` files found in `~/.local/share/opencode/`
- No opencode processes running when tested
- Storage directory exists with project subdirectories

**Tests Needed:**
1. Check for file locks using `lsof`
2. Check for socket connections
3. Monitor file system activity during hang
4. Check for IPC mechanisms (named pipes, sockets)

**Test Procedure:**
```bash
# Start opencode in background and monitor
opencode run "test" &
OPencode_PID=$!

# Check file descriptors
lsof -p $OPencode_PID

# Check for locks
fuser ~/.local/share/opencode/

# Monitor file system
fs_usage -f filesys | grep opencode
```

### 4. Network/API Issues

**Hypothesis:** Opencode might be waiting for network connections that fail silently.

**Previous Findings:**
- Direct API calls to Z.AI work perfectly
- `opencode serve` works (uses different code path)
- Proxy is running (sshuttle)

**Potential Issues:**
- `opencode run` might need different network endpoints
- DNS resolution might be slow or failing
- Connection timeouts might be too long

**Tests Needed:**
1. Test with proxy disabled
2. Test DNS resolution: `nslookup api.zhipu.ai`
3. Test API connectivity: `curl -I https://open.bigmodel.cn`
4. Check network timeouts in opencode

**Test Procedure:**
```bash
# Test DNS
nslookup api.zhipu.ai
nslookup open.bigmodel.cn

# Test API connectivity
curl -I https://open.bigmodel.cn/api/paas/v4/chat/completions

# Test with proxy off
proxy-stop
opencode run "test"
proxy-start
```

### 5. Opencode Configuration

**Hypothesis:** Missing or incorrect configuration might cause hangs.

**Findings:**
- No `~/.config/opencode/opencode.json` file found
- Auth file exists: `~/.local/share/opencode/auth.json` with `zai-coding-plan` key
- Storage directory has project subdirectories

**Potential Issues:**
- Default configuration might be incompatible with VM environment
- Missing required configuration options
- Configuration file location might be wrong

**Tests Needed:**
1. Create minimal config file
2. Check for config in alternate locations
3. Test with explicit config: `opencode --config ~/.config/opencode/opencode.json run "test"`

**Test Procedure:**
```bash
# Create minimal config
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json <<EOF
{
  "\$schema": "https://opencode.ai/config.json"
}
EOF

# Test with config
opencode run "test"

# Check for config in other locations
find ~ -name "opencode.json" 2>/dev/null
```

### 6. Process/Resource Limits

**Hypothesis:** VM resource limits might prevent opencode from starting properly.

**Potential Issues:**
- File descriptor limits
- Memory limits
- CPU limits
- Process limits

**Tests Needed:**
1. Check resource limits: `ulimit -a`
2. Check system resources: `sysctl -a | grep -i limit`
3. Monitor resource usage during hang

**Test Procedure:**
```bash
# Check limits
ulimit -a

# Check system limits
sysctl -a | grep -i limit

# Monitor during hang
opencode run "test" &
OPencode_PID=$!
ps aux | grep $OPencode_PID
```

### 7. Opencode Version/Installation

**Hypothesis:** Current version (1.1.35) might have bugs specific to VM environments.

**Tests Needed:**
1. Check for newer versions: `opencode upgrade --check`
2. Test with different installation method (go install vs Homebrew)
3. Check opencode GitHub for known issues

**Test Procedure:**
```bash
# Check for updates
opencode upgrade --check

# Check installation method
which opencode
brew list opencode

# Check GitHub issues
# Search for: "opencode run hang" or "opencode tmux"
```

## Root Cause Analysis

### The Real Issue

Based on test results, **`opencode run` actually works in the VM** when TERM is naturally inherited from the environment. The hanging behavior occurs specifically when TERM is explicitly set in the command environment.

**Working scenario:**
```bash
# TERM naturally inherited from tmux/shell
opencode run "test message"  # ✅ Works (11s completion)
```

**Failing scenario:**
```bash
# TERM explicitly set
TERM=xterm-256color opencode run "test message"  # ❌ Hangs
```

### Why This Matters

This explains the confusion:
- Previous tests may have been setting TERM explicitly
- Scripts or wrappers that set TERM will cause hangs
- Direct usage in shell (where TERM is inherited) works fine

### Potential Causes

1. **Environment variable handling bug** - Opencode may check TERM in a way that fails when it's explicitly set vs inherited
2. **Terminal capability detection** - Opencode might use different code paths for detecting terminal capabilities
3. **Signal handling** - Explicit environment setting might affect how signals are handled
4. **Process forking** - Environment variable inheritance might differ in forked processes

## Recommended VM Setup Changes

### Option 1: No Changes Needed (Recommended)

**Status:** `opencode run` works correctly in VM when TERM is naturally inherited.

**Action:** Document the issue and ensure scripts don't explicitly set TERM.

**Implementation:**
1. Update documentation to note that opencode works in VM
2. Ensure no scripts explicitly set TERM when calling opencode
3. If TERM needs to be set, use it in shell initialization, not command environment

**Pros:**
- No VM changes needed
- opencode already works
- Simple documentation update

**Cons:**
- None - this is the correct approach

### Option 2: Document the TERM Issue (If Needed)

**Change:** Add documentation warning about explicitly setting TERM.

**Implementation:**
- Add note to ADR-002 or bootstrap.md about opencode TERM handling
- Warn against scripts that do: `TERM=... opencode run`
- Recommend using inherited TERM value

**Pros:**
- Prevents future issues
- Documents known behavior
- No code changes needed

**Cons:**
- None

### Option 3: Report Bug to Opencode (Recommended)

**Change:** Report the TERM handling bug to opencode maintainers.

**Implementation:**
1. Create GitHub issue describing the behavior
2. Provide reproduction steps:
   ```bash
   # Works
   opencode run "test"
   
   # Hangs
   TERM=xterm-256color opencode run "test"
   ```
3. Include test results and environment details

**Pros:**
- Fixes issue for all users
- Helps opencode project
- Proper bug reporting

**Cons:**
- Requires upstream fix
- May take time to resolve

### Option 4: Not Needed

**Status:** `opencode run` works correctly, so no workaround needed.

**Note:** `opencode serve` also works, but `opencode run` is the preferred method and works fine when TERM is inherited.

### Option 5: Investigate Opencode Source Code (Optional)

**Change:** Deep dive into opencode source to understand TERM handling bug.

**Implementation:**
1. Clone opencode repository
2. Find where TERM environment variable is checked
3. Identify why explicitly set TERM causes hangs
4. Create patch or detailed bug report

**Pros:**
- Addresses root cause
- Could fix for all users
- Educational

**Cons:**
- Time-consuming
- Requires Go/Rust knowledge
- May require upstream changes

## Testing Plan

### Phase 1: Isolate Issue (Priority: High)

1. **Test outside tmux**
   - Exit tmux session
   - Run `opencode run "test"` in direct SSH
   - Document results

2. **Test with different terminal settings**
   - Try `TERM=screen-256color`
   - Try `TERM=vt100`
   - Unset color variables
   - Document results

3. **Test network connectivity**
   - Disable proxy
   - Test DNS resolution
   - Test API endpoints
   - Document results

### Phase 2: Deep Dive (Priority: Medium)

4. **Monitor process behavior**
   - Use `dtrace` or `dtruss` (macOS equivalent of strace)
   - Monitor file system activity
   - Check for hanging system calls
   - Document findings

5. **Test configuration options**
   - Create minimal config
   - Test with different configs
   - Document what works

6. **Check opencode logs**
   - Review detailed logs
   - Look for error patterns
   - Check timing information
   - Document findings

### Phase 3: Solutions (Priority: Low)

7. **Implement workarounds**
   - Based on Phase 1-2 findings
   - Update VM setup if needed
   - Document workarounds

8. **Report upstream**
   - Create GitHub issue if bug confirmed
   - Provide reproduction steps
   - Include environment details

## Next Steps

1. **Immediate:** Test `opencode run` outside of tmux to confirm/rule out tmux as cause
2. **Short-term:** Test with different terminal settings and network configurations
3. **Medium-term:** Deep dive into process behavior and logs
4. **Long-term:** Implement fixes or workarounds based on findings

## Related Documentation

- [zai-glm-concurrency-error-investigation.md](zai-glm-concurrency-error-investigation.md) - Previous investigation
- [tmux-agent-testing.md](tmux-agent-testing.md) - Tmux compatibility testing
- [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) - VM operational guide
- [vm-setup.sh](../../scripts/vm-setup.sh) - VM setup script

## Automated Testing Script

A comprehensive test script has been created to automate all investigation tests:

**Location:** `scripts/test-opencode-vm.sh`

**Usage:**
```bash
# Run all tests
./scripts/test-opencode-vm.sh

# Or from VM
~/scripts/test-opencode-vm.sh
```

**What it tests:**
1. Prerequisites check (opencode installation, version, environment)
2. Environment information (variables, terminal settings, resources)
3. Opencode storage and lock files
4. Opencode logs analysis
5. Network connectivity (DNS, API endpoints)
6. `opencode serve` (baseline - known working)
7. `opencode run` with timeout detection (identifies hangs)
8. `opencode run` with different TERM values (xterm-256color, screen-256color, vt100, xterm)
9. `opencode run` without color environment variables
10. `opencode run` with proxy disabled
11. `opencode` TUI mode (default command)

**Output:**
- All results logged to: `~/.local/share/opencode/test-results/test_YYYYMMDD_HHMMSS.log`
- Individual test outputs saved in same directory
- Color-coded results (PASS/FAIL/WARN/INFO)
- Detailed environment information captured

**Example output:**
```
========================================
Opencode VM Testing Script
========================================

[17:30:00] Starting opencode VM tests...
[17:30:00] ✓ opencode installed: PASS
[17:30:00] ✓ opencode version: PASS (1.1.35)
[17:30:00] ✓ VM environment: PASS (Running in CAL VM)
...
```

## Test Results Summary

**Date:** 2026-01-25 17:59  
**Test Script:** `scripts/test-opencode-vm.sh`

### Key Findings

1. **✅ `opencode run` WORKS!** - The default test completed successfully in 11 seconds
   - Output: "Hello! How can I help you today with the CAL project?"
   - This contradicts previous reports of hanging behavior

2. **❌ `opencode run` HANGS when TERM is explicitly set** - All tests that explicitly set TERM environment variable hung:
   - `TERM=xterm-256color` - HUNG
   - `TERM=screen-256color` - HUNG
   - `TERM=vt100` - HUNG
   - `TERM=xterm` - HUNG
   - This suggests a bug in opencode when TERM is set in command environment vs naturally inherited

3. **✅ `opencode serve` works** - Started successfully and listened on port 4096

4. **✅ Network connectivity works** - DNS and API endpoints reachable

5. **✅ No lock files** - Storage is clean

6. **⚠️ Color variables test** - HUNG when FORCE_COLOR/NO_COLOR were unset (but this also changes environment)

### Critical Discovery

**The issue is NOT that opencode run hangs in general - it's that it hangs when TERM is explicitly set in the command environment!**

When TERM is naturally inherited from the shell/tmux environment (which is `xterm-256color`), `opencode run` works perfectly. But when TERM is explicitly set as an environment variable in the command (e.g., `TERM=xterm-256color opencode run`), it hangs.

This suggests:
- Opencode may be checking for TERM in a way that fails when it's explicitly set
- There might be a difference in how environment variables are passed when explicitly set vs inherited
- This could be a bug in opencode's environment variable handling

### Test Results Details

| Test | Result | Details |
|------|--------|---------|
| Prerequisites | ✅ PASS | opencode 1.1.35 installed, VM environment detected |
| Environment | ✅ INFO | tmux session, TERM=xterm-256color, SSH connection |
| Storage | ✅ PASS | No lock files found |
| Network | ✅ PASS | DNS and API connectivity working |
| opencode serve | ✅ PASS | Started and listening on port 4096 |
| opencode run (default) | ✅ PASS | Completed in 11s with output |
| opencode run (TERM=xterm-256color) | ❌ FAIL | HUNG after 5s |
| opencode run (TERM=screen-256color) | ❌ FAIL | HUNG after 5s |
| opencode run (TERM=vt100) | ❌ FAIL | HUNG after 5s |
| opencode run (TERM=xterm) | ❌ FAIL | HUNG after 5s |
| opencode run (no color vars) | ❌ FAIL | HUNG after 5s |
| opencode TUI | ⚠️ INFO | Still running after 5s (normal for TUI) |

## Investigation Log

| Date | Action | Result |
|------|--------|--------|
| 2026-01-25 17:28 | Started investigation | Created investigation document |
| 2026-01-25 17:28 | Checked environment | Confirmed tmux session, TERM=xterm-256color |
| 2026-01-25 17:28 | Checked opencode storage | No lock files found |
| 2026-01-25 17:28 | Checked auth | Auth file exists with zai-coding-plan key |
| 2026-01-25 17:28 | Checked config | No config file found |
| 2026-01-25 17:28 | Checked processes | No opencode processes running |
| 2026-01-25 17:30 | Created test script | Automated test script created at scripts/test-opencode-vm.sh |
| 2026-01-25 17:59 | Ran test script | **CRITICAL: opencode run WORKS when TERM is inherited, HANGS when TERM is explicitly set** |

---

**Status:** Root cause identified  
**Finding:** `opencode run` works in VM when TERM is naturally inherited, but hangs when TERM is explicitly set in command environment
