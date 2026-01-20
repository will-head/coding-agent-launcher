# SOCKS Proxy Homebrew Fix

## Problem
When SOCKS proxy was enabled, Homebrew update and package downloads were failing even though the SOCKS tunnel was running.

## Root Cause
We were setting `HTTP_PROXY=http://localhost:8080` and `HTTPS_PROXY=http://localhost:8080`, pointing to the gost HTTP bridge. However:

1. **gost isn't installed yet** - It's installed BY vm-setup.sh via Homebrew
2. **HTTP bridge doesn't exist** during init when we need to install packages
3. **Chicken-and-egg problem** - Need proxy to install gost, but need gost for proxy

## Solution
Use **SOCKS5 directly** in HTTP_PROXY and HTTPS_PROXY variables instead of the HTTP bridge.

### Why This Works
- Modern tools (curl, git, npm, brew) support `socks5://` URLs in HTTP_PROXY
- SOCKS tunnel (port 1080) IS running during init
- No dependency on gost being installed first
- HTTP bridge (port 8080) only needed later for legacy tools

### Changes Made

**1. cal-bootstrap: Use SOCKS5 URLs**
```bash
# OLD (broken):
HTTP_PROXY='http://localhost:8080'
HTTPS_PROXY='http://localhost:8080'

# NEW (works):
HTTP_PROXY='socks5://localhost:1080'
HTTPS_PROXY='socks5://localhost:1080'
```

**2. vm-setup.sh: Export lowercase + test connectivity**
- Export both uppercase and lowercase proxy vars (tool compatibility)
- Set NO_PROXY to avoid proxying localhost addresses
- Test proxy before proceeding with installations
- Show brew update errors for debugging

## How It Works Now

### During --init with SOCKS enabled:

```
1. cal-bootstrap starts SOCKS tunnel on port 1080 ✓
2. Passes proxy vars to vm-setup.sh:
   ALL_PROXY=socks5://localhost:1080
   HTTP_PROXY=socks5://localhost:1080
   HTTPS_PROXY=socks5://localhost:1080

3. vm-setup.sh receives vars and:
   - Exports uppercase versions (HTTP_PROXY, etc.)
   - Exports lowercase versions (http_proxy, etc.)
   - Sets NO_PROXY for localhost
   - Tests connectivity: curl https://github.com
   - Shows "✓ Proxy is working"

4. Homebrew uses proxy vars:
   brew update → uses SOCKS5 → works ✓
   brew install node → uses SOCKS5 → works ✓
   brew install gost → uses SOCKS5 → works ✓

5. After gost is installed:
   HTTP bridge starts on port 8080
   Available for tools that don't support SOCKS5
```

## Tool Compatibility

### ✅ Support socks5:// in HTTP_PROXY:
- curl (7.21.7+)
- git (2.0+)
- npm (modern versions)
- Homebrew
- Python pip
- wget (1.15+)

### ⚠️ May need HTTP bridge:
- Some older Node.js tools
- Java applications
- Some legacy tools

## Testing

### Test proxy is working:
```bash
# Inside VM with SOCKS enabled
echo $HTTP_PROXY  # Should be: socks5://localhost:1080

# Test connectivity
curl -I https://github.com

# Test Homebrew
brew update
brew install hello
```

### Verify proxy environment:
```bash
env | grep -i proxy
# Should show:
# ALL_PROXY=socks5://localhost:1080
# HTTP_PROXY=socks5://localhost:1080
# HTTPS_PROXY=socks5://localhost:1080
# NO_PROXY=localhost,127.0.0.1,::1,192.168.64.0/24
# (and lowercase versions)
```

## Benefits

1. **No chicken-and-egg problem** - Proxy works before gost is installed
2. **Simpler** - Direct SOCKS5, no intermediate HTTP bridge needed during init
3. **More reliable** - One less moving part to fail
4. **Better compatibility** - Modern tools prefer SOCKS5
5. **Faster** - No extra HTTP-to-SOCKS translation

## Fallback

If a tool doesn't support SOCKS5 in HTTP_PROXY:
1. It will fail with clear error
2. You can manually use the HTTP bridge (port 8080) after gost is installed
3. Most modern tools support SOCKS5, so this is rare

## Files Modified

- `scripts/cal-bootstrap` - Changed proxy vars to use `socks5://` URLs
- `scripts/vm-setup.sh` - Added lowercase exports, NO_PROXY, connectivity test
