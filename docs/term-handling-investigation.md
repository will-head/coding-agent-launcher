# TERM Environment Variable Handling Investigation

> **Status:** ✅ Resolved
> **Date:** 2026-01-25
> **Issue:** Conflict between tmux compatibility and opencode TERM handling
> **Solution:** Wrapper script approach implemented and verified

## Problem Statement

Cal-bootstrap has conflicting requirements for TERM environment variable handling:

1. **Tmux requires known TERM** - Terminals like Ghostty set `TERM=xterm-ghostty`, which isn't in macOS VM terminfo database, causing tmux to fail with "missing or unsuitable terminal"
2. **Opencode hangs with explicit TERM** - When TERM is explicitly set in command environment (e.g., `TERM=xterm-256color command`), opencode run hangs indefinitely

## Current Implementation

**Before fix (original code):**
```bash
ssh -t ... "${VM_USER}@${VM_IP}" "TERM=xterm-256color /opt/homebrew/bin/tmux ..."
```

**Problems:**
- ✅ Works with Ghostty and other exotic terminals (sets safe TERM for tmux)
- ❌ Causes opencode run to hang (explicit TERM in command environment)

**After fix attempt:**
```bash
ssh -t ... "${VM_USER}@${VM_IP}" "/opt/homebrew/bin/tmux ..."
```

**Problems:**
- ❌ Fails with Ghostty: "missing or unsuitable terminal: xterm-ghostty"
- ✅ Would fix opencode hang (if tmux worked)

## Test Results

### Test 1: SSH with TERM Removed (Current WIP)

**Command:**
```bash
ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    admin@192.168.64.92 "/opt/homebrew/bin/tmux new-session -A -s test"
```

**From Ghostty terminal:**
```
Warning: Permanently added '192.168.64.92' (ED25519) to the list of known hosts.
missing or unsuitable terminal: xterm-ghostty
Connection to 192.168.64.92 closed.
```

**Result:** ❌ FAIL - tmux cannot start because xterm-ghostty terminfo not available in VM

## Root Cause Analysis

### Why Explicit TERM Was Added

Git history shows TERM was added for "TERM compatibility fixes for modern terminals (Ghostty, etc.)" in commit 304ddd1. The reasoning was correct - modern terminals use TERM values that don't exist in VM terminfo database.

### Why This Breaks Opencode

Opencode has a bug where it hangs when TERM is explicitly set in command environment but works when TERM is naturally inherited. This suggests opencode checks environment variables differently depending on how they're passed.

### The Core Conflict

- **SSH + tmux needs:** TERM value that exists in VM terminfo database
- **Opencode needs:** TERM inherited naturally, not explicitly set in command
- **Modern terminals send:** Exotic TERM values (xterm-ghostty, etc.)

## Potential Solutions

### Option 1: Set TERM in SSH Environment (Recommended)

Use SSH's `-o SetEnv` to set TERM before command execution:

```bash
ssh -t -o SetEnv=TERM=xterm-256color ... "${VM_USER}@${VM_IP}" "/opt/homebrew/bin/tmux ..."
```

**Pros:**
- TERM set in session environment, not command environment
- Should work with both tmux and opencode
- Clean separation of concerns

**Cons:**
- Requires VM sshd to allow SetEnv (AcceptEnv TERM)
- Need to verify VM sshd configuration

**Test Required:**
1. Check VM sshd_config for `AcceptEnv TERM`
2. Test with Ghostty terminal
3. Test opencode run inside session

### Option 2: Set TERM via SSH RequestTTY + Environment

Let SSH pass TERM through terminal negotiation, then override in shell:

```bash
# In VM's ~/.zshrc (already done)
export TERM=xterm-256color

# SSH command
ssh -t ... "${VM_USER}@${VM_IP}" "/opt/homebrew/bin/tmux ..."
```

**Pros:**
- Already partially implemented
- TERM set by shell initialization, not command environment

**Cons:**
- Race condition: tmux might start before .zshrc sets TERM
- Doesn't help if tmux is launched directly (before shell init)

**Test Required:**
1. Test if .zshrc runs before tmux command
2. May need to source .zshrc explicitly before tmux

### Option 3: Wrapper Script in VM

Create a wrapper script in VM that sets TERM then launches tmux:

```bash
# In VM: ~/scripts/tmux-wrapper.sh
#!/bin/zsh
export TERM=xterm-256color
exec /opt/homebrew/bin/tmux "$@"

# SSH command
ssh -t ... "${VM_USER}@${VM_IP}" "~/scripts/tmux-wrapper.sh new-session -A -s cal"
```

**Pros:**
- TERM set in script environment (inherited naturally)
- Clean separation between TERM setup and tmux launch
- No sshd configuration changes needed

**Cons:**
- Additional script to maintain
- Need to deploy script during vm-setup.sh

**Test Required:**
1. Create wrapper script
2. Test with Ghostty
3. Test opencode run inside session

### Option 4: Fix Terminal Compatibility in VM

Install terminfo for exotic terminals in VM:

```bash
# During vm-setup.sh
# Install Ghostty terminfo if available
curl -L https://ghostty.org/terminfo/xterm-ghostty.terminfo | tic -x -
```

**Pros:**
- Fixes root cause (missing terminfo)
- No SSH command changes needed
- Works with all terminals that provide terminfo

**Cons:**
- Need to maintain list of supported terminals
- Terminfo might not be available for all terminals
- Doesn't fix opencode explicit TERM issue

**Test Required:**
1. Research terminfo availability
2. Test installation process
3. Test with multiple terminals

### Option 5: Source .zshrc Before Command

Explicitly source .zshrc to set TERM before launching tmux:

```bash
ssh -t ... "${VM_USER}@${VM_IP}" "source ~/.zshrc && /opt/homebrew/bin/tmux ..."
```

**Pros:**
- Ensures TERM is set from .zshrc
- TERM inherited naturally (not explicit in command)
- No VM changes needed

**Cons:**
- Sources entire .zshrc (might have side effects)
- Redundant sourcing if shell auto-sources

**Test Required:**
1. Test with Ghostty
2. Test opencode run
3. Check for .zshrc side effects

## Recommended Approach

**Preference order:**

1. **Option 3: Wrapper Script** (Most reliable)
   - Clean, maintainable, no configuration dependencies
   - Best separation of TERM setup from command execution

2. **Option 1: SSH SetEnv** (Cleanest if supported)
   - Requires VM sshd configuration check
   - Most "proper" solution if available

3. **Option 5: Source .zshrc** (Quick fix)
   - Immediate solution, no VM changes
   - Slight risk of .zshrc side effects

## Next Steps

1. **Test Option 3 (Wrapper Script)** - Most likely to succeed
   - Create ~/scripts/tmux-wrapper.sh in VM
   - Test from Ghostty terminal
   - Test opencode run inside session

2. **If Option 3 fails, test Option 1 (SSH SetEnv)**
   - Check VM sshd_config
   - Add AcceptEnv TERM if needed
   - Test with Ghostty and opencode

3. **If both fail, test Option 5 (Source .zshrc)**
   - Simplest fallback
   - Test thoroughly for side effects

## Test Plan

### Test Matrix

| Test | Terminal | Method | Expected |
|------|----------|--------|----------|
| 1 | Ghostty | Wrapper script | ✅ Connects, tmux starts |
| 2 | Ghostty | SSH SetEnv | ✅ Connects, tmux starts |
| 3 | Ghostty | Source .zshrc | ✅ Connects, tmux starts |
| 4 | iTerm2 | All methods | ✅ Connects, tmux starts |
| 5 | Terminal.app | All methods | ✅ Connects, tmux starts |

### Opencode Tests (Inside Each Session)

```bash
# Test 1: opencode run (critical)
opencode run "test message"
# Expected: ✅ Completes in ~10-15s, no hanging

# Test 2: Check TERM value
echo $TERM
# Expected: screen-256color (inside tmux)

# Test 3: Terminal capabilities
# Test colors, delete key, arrow keys
# Expected: ✅ All work correctly
```

### Test Procedure

1. **Implement solution** (wrapper script, SetEnv, or source .zshrc)
2. **Test from multiple terminals** (Ghostty, iTerm2, Terminal.app)
3. **Test opencode in each session**
4. **Verify terminal capabilities**
5. **Test cal-bootstrap commands** (run, ssh, login)

## Open Questions

1. Does VM sshd allow `AcceptEnv TERM`? (Check /etc/ssh/sshd_config)
2. Does .zshrc sourcing have side effects? (Check .zshrc contents)
3. Are there other terminals with exotic TERM values to consider?
4. Should we report the opencode TERM bug upstream?

## Related Documentation

- [opencode-vm-investigation.md](opencode-vm-investigation.md) - Opencode TERM handling bug
- [opencode-vm-summary.md](opencode-vm-summary.md) - Quick reference
- [ssh-alternatives-investigation.md](ssh-alternatives-investigation.md) - Original tmux implementation

## Implemented Solution

**Date:** 2026-01-25  
**Approach:** Option 3 - Wrapper Script (Recommended)

### Implementation Details

1. **Created wrapper script** (`scripts/tmux-wrapper.sh`):
   ```bash
   #!/bin/zsh
   export TERM=xterm-256color
   exec /opt/homebrew/bin/tmux "$@"
   ```

2. **Updated cal-bootstrap**:
   - Modified `setup_scripts_folder()` to copy `tmux-wrapper.sh` to VM's `~/scripts/`
   - Updated all SSH tmux calls in `do_run()` and `do_restart()` to use `~/scripts/tmux-wrapper.sh`
   - Added `setup_scripts_folder()` calls before SSH connections to ensure wrapper exists

3. **Key Design Decision**:
   - TERM is set in the script environment (via `export`), not in the command environment
   - This allows opencode to inherit TERM naturally (avoids hang)
   - Tmux receives a known TERM value that exists in VM terminfo database

### Test Results

| Test | Terminal | Result | Notes |
|------|----------|--------|-------|
| cal-bootstrap --run | Ghostty | ✅ PASS | Connects successfully, no "missing terminal" error |
| cal-bootstrap --run | Terminal.app | ✅ PASS | Connects successfully |
| opencode run | Inside tmux | ✅ PASS | Completes in ~11s, no hanging |
| Wrapper script | VM deployment | ✅ PASS | Script exists and is executable |

### Verification

- ✅ Ghostty terminal: `cal-bootstrap --run` works without errors
- ✅ Terminal.app: `cal-bootstrap --run` works correctly
- ✅ Opencode: `opencode run "test message"` completes successfully (~11s), no hang
- ✅ Wrapper script: Deployed to `~/scripts/tmux-wrapper.sh` in VM, executable

### Why This Solution Works

1. **Script environment vs command environment**: By setting TERM via `export` in the wrapper script, it becomes part of the script's environment. When opencode runs, it inherits TERM naturally (not explicitly set in command), which avoids the hang.

2. **Tmux compatibility**: Tmux receives `TERM=xterm-256color` which exists in the VM's terminfo database, so it works with all terminals regardless of their native TERM value.

3. **No configuration dependencies**: Unlike SSH SetEnv, this doesn't require sshd configuration changes. The wrapper script is deployed during normal VM setup.

### Files Changed

- `scripts/tmux-wrapper.sh` (new file)
- `scripts/cal-bootstrap` (updated `setup_scripts_folder()`, `do_run()`, `do_restart()`)

---

**Status:** ✅ Resolved - Wrapper script approach implemented and verified  
**Priority:** HIGH - Was blocking both Ghostty users and opencode functionality  
**Completion Date:** 2026-01-25
