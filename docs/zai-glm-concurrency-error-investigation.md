# Investigation: Z.AI GLM 4.7 API Concurrency Limit Error in cal-dev VM

## Issue Summary

**Error:** `High concurrency usage of this API, please reduce concurrency or contact custome... [retrying in 3s attempt #2]`

**Context:**
- Opencode with Z.AI GLM 4.7 model works fine on host machine
- Same configuration fails in cal-dev VM with concurrency limit errors
- Error persists across multiple attempts (retrying)
- User reports error appears after a few successful requests

## Investigation Findings

### 1. Environment Comparison

**Host Machine:**
- Network: Direct connection (192.168.101.89)
- No proxy configuration needed
- Direct API calls to Z.AI GLM endpoints

**cal-dev VM:**
- Network: Virtual NAT (192.168.64.x → Gateway 192.168.64.1)
- Transparent proxy via sshuttle (if PROXY_MODE=on/auto)
- All traffic routes through host before reaching internet
- NAT shares same external IP as host

### 2. Opencode Configuration

**Location:** `~/.config/opencode/opencode.json`

**Current Config:**
```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["~/.config/opencode/security-rules.md"],
  "permission": {
    "bash": {
      "rm": "deny",
      "rmdir": "deny",
      "sudo": "deny",
      "...": "deny"
    }
  }
}
```

**No concurrency-related settings found.** Opencode does not expose API rate limiting configuration.

### 3. Network Architecture

**VM Network Topology:**
```
Host (192.168.64.1) → NAT/Internet
       ↓
VM (192.168.64.x) → sshuttle → Host → External
```

**Transparent Proxy (sshuttle):**
```bash
sshuttle --dns -r ${HOST_USER}@${HOST_GATEWAY} 0.0.0.0/0 \
  -x ${HOST_GATEWAY}/32 \      # Exclude host gateway
  -x 192.168.64.0/24        # Exclude VM network
```

- Routes ALL TCP traffic through host
- DNS queries also tunneled
- No per-application configuration needed
- Works with any TCP application

### 4. Potential Root Causes

#### Cause A: IP-Based Rate Limiting (Most Likely)
**Hypothesis:** Z.AI GLM API tracks rate limits by source IP, not by API key.

**Why this fits:**
- Both host and VM share same external IP (through NAT)
- If API provider tracks concurrent requests by IP, VM traffic adds to host's concurrent requests
- Combined traffic from host + VM exceeds per-IP concurrency limit
- Works on host alone (only one source)
- Fails when both host and VM are making requests

**Evidence:**
- Error message: "High concurrency usage" (not "rate limit exceeded")
- Works fine on host (no VM traffic competing)
- Suggests cumulative concurrent connections exceeding limit

**Counter-evidence:**
- User didn't mention concurrent usage on host
- Would need to verify if host is making API calls simultaneously

#### Cause B: SSH Connection Multiplexing
**Hypothesis:** SSH tunnel (sshuttle) creates multiple concurrent TCP connections, triggering API's concurrency detection.

**Why this fits:**
- SSHuttle maintains multiple control channels
- Each tunneled connection appears as separate TCP session
- API provider may see this as multiple concurrent API calls
- Host has no SSH tunnel, so fewer concurrent connections

**Evidence:**
- Error appears after a few requests (connection building up)
- Transparent proxy routes all traffic through SSH connection
- SSH multiplexing creates appearance of multiple concurrent connections

#### Cause C: DNS Resolution Issues
**Hypothesis:** DNS queries through tunnel cause additional concurrent connections to API endpoints.

**Why this fits:**
- `sshuttle --dns` tunnels DNS queries
- Each DNS lookup creates new TCP connection
- API provider may count DNS resolution as concurrent request
- Host DNS resolution is direct, not tunneled

**Evidence:**
- sshuttle uses `--dns` flag
- DNS lookups happen frequently during API calls

**Counter-evidence:**
- DNS lookups are typically brief
- Would expect DNS resolution errors, not concurrency errors

#### Cause D: Connection Keep-Alive Behavior
**Hypothesis:** NAT/Proxy keeps connections alive longer, causing overlap in concurrent connection counting.

**Why this fits:**
- Transparent proxy may pool connections
- Keep-alive timeouts longer in VM environment
- More connections remain "active" from API perspective
- Host connections close faster, reducing concurrency count

**Evidence:**
- NAT and SSH tunneling can alter TCP lifecycle
- "High concurrency" suggests connections not closing fast enough

### 5. Z.AI GLM API Documentation

**Unable to Access Documentation:**
- Certificate expired errors accessing zhipu.ai docs
- 429 errors on search engines (rate limiting)
- Official API documentation not accessible for investigation

**What We Know:**
- Z.AI (智谱AI) provides GLM models (Chinese AI company)
- GLM-4 is a large language model family
- API likely has concurrency limits (typical for commercial APIs)

## Recommended Fixes

### Fix 1: Bypass Proxy for Z.AI API (Recommended)
**Approach:** Exclude Z.AI API endpoints from sshuttle tunneling.

**Implementation:**
```bash
# Add Z.AI API domains to sshuttle exclusions
sshuttle --dns -r ${HOST_USER}@${HOST_GATEWAY} 0.0.0.0/0 \
  -x ${HOST_GATEWAY}/32 \
  -x 192.168.64.0/24 \
  -x api.zhipu.ai/32 \
  -x open.bigmodel.cn/32
```

**Why this works:**
- VM gets direct access to Z.AI endpoints (no proxy overhead)
- No SSH multiplexing for API calls
- Connection behavior matches host machine

**Caveats:**
- Requires knowing all API domain names
- May not work if network requires proxy for all external traffic
- Only helps if proxy is causing the issue

### Fix 2: Reduce Opencode Concurrency
**Approach:** Configure opencode to limit concurrent API requests.

**Status:** **Not supported by opencode.**
- No configuration option for rate limiting
- No environment variable for concurrency control
- Would require patching opencode source code

### Fix 3: Use Different Model/Provider
**Approach:** Switch to a model with higher concurrency limits.

**Implementation:**
- Use Claude, GPT, or other models in opencode
- Configure in `~/.config/opencode/opencode.json`

**Why this works:**
- Avoids Z.AI GLM's specific concurrency limits
- Other providers may be more lenient

**Caveats:**
- Requires valid API key for alternative provider
- May incur additional costs
- Changes model behavior/capabilities

### Fix 4: Stagger VM and Host Usage
**Approach:** Avoid concurrent API usage between host and VM.

**Implementation:**
- Stop API calls on host when using VM
- Use VM exclusively for Z.AI API work
- Or vice versa

**Why this works:**
- Reduces total concurrent connections to API
- Works if IP-based rate limiting is the cause

**Caveats:**
- Inconvenient workflow
- Manual coordination required

### Fix 5: Network Configuration Change
**Approach:** Modify VM network to use different external IP.

**Status:** **Not feasible.**
- Tart VMs share host's network (NAT)
- No option for separate public IP
- Would require alternative virtualization approach

### Fix 6: Contact Z.AI Support
**Approach:** Request increased concurrency limit for API key.

**Status:** **Recommended as temporary workaround.**

**What to ask:**
- Current concurrency limit for API key
- Reason for limit exceeded when VM is the only client
- Request for limit increase or clarification

## Investigation Log

| Date | Action | Result |
|------|--------|--------|
| 2026-01-25 | Read ADR-002 VM operational guide | Understood sshuttle proxy configuration |
| 2026-01-25 | Checked opencode config | No rate limiting options found |
| 2026-01-25 | Attempted web research | Certificate errors, 429 rate limits |
| 2026-01-25 | Compared network configs | Host direct vs VM via sshuttle |
| 2026-01-25 | Analyzed root causes | Identified 5 potential causes |

## Next Steps

1. **Test Fix 1** (API endpoint bypass) to confirm proxy is the issue
2. **Monitor network traffic** during error occurrence to identify actual concurrent connections
3. **Contact Z.AI support** for official API limits and troubleshooting
4. **Document workaround** in ADR-002 if fix is successful
5. **Update PLAN-PHASE-00-TODO.md** with known issue and resolution

## Related Documentation

- [ADR-002: Tart VM Operational Guide](../adr/ADR-002-tart-vm-operational-guide.md)
- [vm-setup.sh](../../scripts/vm-setup.sh) - Line 257: opencode installation
- [vm-auth.sh](../../scripts/vm-auth.sh) - Line 259: opencode authentication
- [PLAN-PHASE-00-TODO.md](PLAN-PHASE-00-TODO.md) - Current phase TODOs

## Appendix: Network Commands for Debugging

**Check sshuttle status:**
```bash
# On VM
proxy-status
# Or
pgrep -f sshuttle

# View routing table
netstat -rn | grep sshuttle
```

**Capture API traffic:**
```bash
# On VM - capture DNS and API calls
sudo tcpdump -i any -n host api.zhipu.ai or host open.bigmodel.cn

# On host - see forwarded traffic from VM
sudo tcpdump -i any -n src 192.168.64.0/24
```

**Test direct connectivity from VM:**
```bash
# Test without proxy (if proxy is running)
proxy-stop

# Test connectivity to Z.AI API
curl -I https://api.zhipu.ai
curl -I https://open.bigmodel.cn

# Test with proxy
proxy-start
curl -I https://api.zhipu.ai
```

---

**Investigation Date:** 2026-01-25
**Investigator:** Claude Sonnet 4.5
**Status:** Root cause analysis complete, fixes proposed (not implemented)
