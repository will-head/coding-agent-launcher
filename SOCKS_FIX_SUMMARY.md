# SOCKS Proxy Fix Summary

## Problem Statement

SOCKS proxy was not working correctly:
1. When SOCKS was NOT needed (direct connection worked), proxy was still being configured
2. When SOCKS WAS needed (direct connection failed), proxy wasn't available to tools during installation
3. Homebrew update, opencode, and Claude installations were failing

## Root Cause

The proxy environment variables were not being set at the right time or in the right conditions:
- Originally: Proxy vars were always set in `.cal-socks-config` regardless of whether SOCKS was running
- During my first fix attempt: I moved SOCKS config to the end of vm-setup.sh, so it wasn't available when tools needed it

## Solution

Implemented a **smart proxy detection and activation** strategy across all scripts:

### 1. cal-bootstrap (orchestration)

**Flow:**
1. Test VM connectivity to github.com
2. **If direct connection works**: Don't start SOCKS, don't set proxy vars
3. **If direct connection fails** (or `--socks on`): 
   - Start SOCKS tunnel
   - Export proxy env vars (`HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`)
   - Pass those vars to vm-setup.sh when executing it

**Key changes:**
- `should_enable_socks()` function determines if SOCKS is needed
- `run_vm_setup()` accepts `use_proxy` parameter
- When `use_proxy=true`, proxy vars are passed to SSH command that runs vm-setup.sh

### 2. vm-setup.sh (tool installation)

**Flow:**
1. **At startup**: Check if proxy env vars are set (passed from cal-bootstrap)
2. **If proxy vars set**: Show "Using SOCKS proxy" message
3. **If no proxy vars**: Show "Direct connection" message  
4. **Run all installations**: Tools automatically use proxy vars if they're set (via environment)
5. **At the end**: Configure SOCKS functions in `.zshrc` for future shell sessions

**Key changes:**
- Detects proxy vars at the top and shows clear message
- Removed all complex proxy logic from installation sections
- Installations just work - they use proxy if `HTTP_PROXY` is set, direct otherwise
- SOCKS configuration (functions) only affects future shells, not current installation

### 3. vm-auth.sh (agent authentication)

**Flow:**
1. **Always start clean**: Unset all proxy vars
2. **Test direct connection first**
3. **If direct works**: Use it (no proxy)
4. **If direct fails**:
   - Load SOCKS config
   - Check if tunnel is running
   - If not running, try to start it (`start_socks`)
   - Set proxy vars ONLY if tunnel is working
   - Test connectivity again with proxy
   - If proxy doesn't work, unset vars and warn user

**Key changes:**
- Always tests direct connection FIRST (proxy OFF)
- Only enables proxy if direct connection fails AND SOCKS works
- Comprehensive error handling and user feedback
- Never leaves broken proxy vars set

## How It Works Now

### Scenario 1: Direct Connection Works (Home Network)

```
cal-bootstrap --init
  └─> Test github.com → ✓ Works directly
      └─> Don't start SOCKS tunnel
          └─> vm-setup.sh runs WITHOUT proxy vars
              └─> Homebrew, claude, opencode all use direct connection
                  └─> SOCKS functions configured in .zshrc for future (but not active)
```

Later when you run `vm-auth.sh`:
```
vm-auth.sh
  └─> Test github.com → ✓ Works directly
      └─> Use direct connection (no proxy)
          └─> Agent authentication uses direct connection
```

### Scenario 2: Direct Connection Fails (Corporate Network)

```
cal-bootstrap --init --socks on
  └─> Force SOCKS mode ON
      └─> Start SOCKS tunnel (VM→Host)
          └─> Export HTTP_PROXY, HTTPS_PROXY, ALL_PROXY
              └─> Pass proxy vars to vm-setup.sh via SSH
                  └─> vm-setup.sh sees proxy vars set
                      └─> Shows "Using SOCKS proxy"
                          └─> Homebrew, claude, opencode all use proxy
                              └─> SOCKS functions configured in .zshrc
```

Later when you run `vm-auth.sh`:
```
vm-auth.sh
  └─> Test github.com → ✗ Fails
      └─> Load SOCKS config
          └─> Check tunnel status → ✓ Running
              └─> Set proxy vars
                  └─> Test github.com again → ✓ Works via proxy
                      └─> Agent authentication uses proxy
```

## Key Principles

1. **Direct First**: Always try direct connection before using proxy
2. **Proxy Only When Needed**: SOCKS is only enabled if direct connection fails
3. **Environment Variables Control Everything**: Tools use proxy if `HTTP_PROXY` is set, direct otherwise
4. **No Interference**: When proxy is not needed, it's completely absent (not just disabled)
5. **Smart Detection**: Each script independently tests connectivity and decides
6. **Clear Feedback**: User always knows which connection method is being used

## Files Modified

1. **scripts/cal-bootstrap**
   - Modified `run_vm_setup()` to pass proxy vars when SOCKS is enabled
   - Modified `do_init()` to start SOCKS before vm-setup.sh if needed
   - Passes `socks_enabled` flag based on connectivity test

2. **scripts/vm-setup.sh**
   - Detects proxy vars at startup
   - Shows clear message about connection method
   - All installations use proxy automatically if vars are set
   - SOCKS config at the end only affects future shells
   - Simplified opencode install (no Go fallback)
   - Added brew shellenv reload before Claude install

3. **scripts/vm-auth.sh**
   - Complete rewrite of network detection logic
   - Always tests direct first
   - Only enables proxy if direct fails and SOCKS works
   - Attempts to start SOCKS if not running
   - Comprehensive error handling and feedback

4. **Created: SOCKS_TESTING.md**
   - Comprehensive test procedures for both scenarios
   - Verification commands
   - Troubleshooting guide

## Testing Required

### Test 1: SOCKS NOT Needed (Direct Connection)
```bash
./scripts/cal-bootstrap --init
```
**Expected:**
- "Network OK, SOCKS tunnel not needed"
- "Network: Direct connection"
- All tools install without proxy
- `echo $HTTP_PROXY` in VM is empty

### Test 2: SOCKS IS Needed (Forced On)
```bash
./scripts/cal-bootstrap --init --socks on
```
**Expected:**
- SOCKS tunnel starts before vm-setup.sh
- "Using SOCKS proxy for network access"
- All tools install through proxy
- `echo $HTTP_PROXY` in VM shows `http://localhost:8080`

## Success Criteria

✅ **When direct connection works:**
- No SOCKS tunnel started
- No proxy environment variables set
- All installations work directly
- No "Using SOCKS proxy" messages

✅ **When direct connection fails:**
- SOCKS tunnel starts BEFORE installations
- Proxy environment variables set
- All installations use proxy
- Clear "Using SOCKS proxy" message shown

✅ **Both scenarios:**
- Homebrew update succeeds
- opencode installs successfully
- Claude Code installs successfully
- All other tools install successfully
- vm-auth.sh detects correct connection method

## Next Steps

1. Test Scenario 1 (SOCKS not needed) - Most common case
2. Test Scenario 2 (SOCKS needed) - Corporate networks
3. Verify all tools install in both scenarios
4. Confirm proxy is only used when actually needed
