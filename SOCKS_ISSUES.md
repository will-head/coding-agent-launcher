# SOCKS Proxy Issues and Solutions

This document tracks all issues encountered with SOCKS proxy implementation and the solutions attempted.

## Issues Encountered

### 1. SOCKS Tunnel Not Running When Needed ✅ FIXED

**Problem:** SOCKS tunnel was started in Step 5 but died by Step 7 when vm-setup.sh needed it.

**Root Cause:** `StrictHostKeyChecking=yes` was failing silently.

**Solution:** Changed to `StrictHostKeyChecking=no` for tunnel (minimal security risk on localhost network).

**Commit:** `6b28cfa`

---

### 2. Homebrew Extremely Slow with SOCKS5 ⚠️ PARTIAL FIX

**Problem:** Homebrew hangs or is extremely slow (5-10+ minutes) when using `socks5://` URLs in HTTP_PROXY.

**Root Cause:** Homebrew doesn't fully support SOCKS5 proxies efficiently. HTTP proxies work much better.

**Attempted Solutions:**

#### Attempt 1: Use SOCKS5 directly in HTTP_PROXY ❌ TOO SLOW
```bash
HTTP_PROXY=socks5://localhost:1080
HTTPS_PROXY=socks5://localhost:1080
```
- **Result:** Works but extremely slow (5-10+ minutes per operation)
- **Why:** Homebrew's networking layer not optimized for SOCKS5

#### Attempt 2: Install gost first, then use HTTP bridge ⚠️ CHICKEN-AND-EGG
```bash
1. Install gost via Homebrew (using SOCKS5)
2. Start HTTP bridge (gost port 8080)
3. Switch to HTTP_PROXY=http://localhost:8080
4. All subsequent installs use fast HTTP proxy
```
- **Result:** gost installation itself is slow/hangs with SOCKS5
- **Why:** Can't use HTTP bridge until gost is installed, but installing gost is slow

#### Attempt 3: Add timeout to gost install ❌ TIMEOUT NOT AVAILABLE
```bash
timeout 120 brew install gost
```
- **Result:** Timeout fires immediately - command not available or incompatible
- **Why:** macOS may not have GNU `timeout` command, or zsh syntax different

#### Current Status: ⚠️ WORKS BUT SLOW
- Install gost without timeout (let it complete, 5-10 minutes)
- If successful: Use HTTP bridge for everything else (fast!)
- If fails: Continue with SOCKS5 (slow but functional)
- User can Ctrl+C to abort if desired

---

### 3. Function Ordering Errors ✅ FIXED

**Problem:** `command_exists` and `brew` used before they were defined.

**Solution:** Restructured script to define functions before proxy setup code.

**Commit:** `d1b6798`

---

### 4. Opencode Installation Failures ✅ FIXED

**Problem:** Shell script install from opencode.ai was failing.

**Solution:** Changed to Homebrew installation:
```bash
brew install anomalyco/tap/opencode
```

**Commit:** `6186d46` (earlier)

---

## Current Architecture

### When SOCKS is NOT needed (direct connection works):
```
No tunnel → No proxy vars → Direct installs → Fast ✅
```

### When SOCKS IS needed (corporate network):
```
1. Start SOCKS tunnel (VM→Host:1080) ✅
2. Export ALL_PROXY=socks5://localhost:1080 ✅
3. Export HTTP_PROXY=socks5://localhost:1080 ✅
4. Test connectivity ✅
5. Install gost (SLOW - 5-10 min) ⚠️
6. IF gost succeeds:
   - Start HTTP bridge (port 8080)
   - Switch to HTTP_PROXY=http://localhost:8080
   - All subsequent installs FAST ✅
7. IF gost fails:
   - Continue with SOCKS5
   - All installs SLOW but work ⚠️
```

---

## Proposed Solutions (Not Yet Implemented)

### Option A: Pre-install gost in base image
- Include gost in the `macos-sequoia-base` image or `cal-clean`
- **Pros:** No slow install during init
- **Cons:** Need to build custom base image or modify cal-clean

### Option B: Binary distribution of gost
- Download pre-compiled gost binary from GitHub releases
- Place in `~/bin` and add to PATH
- **Pros:** Faster than Homebrew, no build required
- **Cons:** Need to manage binary updates, architecture detection

### Option C: Use different proxy tool
- Try `privoxy` or `polipo` instead of gost
- **Pros:** Might be faster to install
- **Cons:** Need to test compatibility, may have same issue

### Option D: curl-based installation script
```bash
# Download gost binary directly using curl (supports SOCKS5)
curl --socks5-hostname localhost:1080 -L \
  https://github.com/ginuerzh/gost/releases/download/vX.X.X/gost-linux-amd64.tar.gz \
  -o /tmp/gost.tar.gz

tar -xzf /tmp/gost.tar.gz -C ~/bin/
```
- **Pros:** Bypass Homebrew entirely for gost
- **Cons:** Manual version management, architecture detection needed

### Option E: Accept slowness, optimize user experience
- Keep current approach but improve messaging
- Show progress bar or animated spinner
- Clearly set expectations: "This will take 5-10 minutes"
- **Pros:** No technical changes needed
- **Cons:** Still slow

---

## Testing Status

### ✅ Tested and Working:
- SOCKS OFF (direct connection): All tools install fast
- SOCKS tunnel starts and stays running
- curl with SOCKS5 works perfectly
- SOCKS5 proxy functional for all tools (just slow for Homebrew)

### ⚠️ Partially Working:
- SOCKS ON + gost success: Fast (but gost install itself is slow)
- SOCKS ON + gost failure: Slow but completes

### ❌ Not Working:
- timeout command (not available or incompatible)
- Fast gost installation through SOCKS5

---

## Recommended Next Steps

### Immediate (Low-Hanging Fruit):
1. **Improve messaging** - Make it clear this is expected and takes time
2. **Test Option D** - Try direct binary download for gost
3. **Add progress indicators** - Show user something is happening

### Short-term:
1. **Pre-install gost** in base image or cal-clean snapshot
2. **Create optimized "corporate" init path** specifically for SOCKS scenarios

### Long-term:
1. **Investigate Homebrew SOCKS5 performance** - Why is it so slow?
2. **Build custom base image** with all proxy tools pre-installed
3. **Alternative proxy solutions** - Research faster HTTP-to-SOCKS bridges

---

## Relevant Commits

- `6b28cfa` - Fix tunnel persistence with StrictHostKeyChecking=no
- `6186d46` - Fix Homebrew slowness (install gost first)
- `d1b6798` - Fix function ordering errors
- `12984f0` - Add timeout and fallback (timeout didn't work)
- Latest - Remove timeout, accept slowness with clear messaging

---

## Environment Details

- **macOS Version:** macOS Sequoia (in Tart VM)
- **Shell:** zsh
- **Homebrew:** ARM64 (/opt/homebrew)
- **SOCKS Port:** 1080
- **HTTP Bridge Port:** 8080
- **Network:** 192.168.64.x (Tart VM network)

---

## Related Documentation

- `SOCKS_FIX_SUMMARY.md` - Overview of SOCKS proxy fixes
- `SOCKS_HOMEBREW_FIX.md` - Details on Homebrew SOCKS5 issues
- `DEBUG_SOCKS.md` - Debugging commands and diagnostics
- `SOCKS_TESTING.md` - Test procedures for both scenarios

---

## TODOs

- [ ] Test Option D: Direct binary download for gost
- [ ] Measure actual gost install time with SOCKS5
- [ ] Investigate why Homebrew is so slow with SOCKS5
- [ ] Research if timeout command exists on macOS (gtimeout from coreutils?)
- [ ] Consider pre-installing gost in cal-clean snapshot
- [ ] Add progress indicator for long-running operations
- [ ] Test alternative HTTP-to-SOCKS bridges (privoxy, polipo)
