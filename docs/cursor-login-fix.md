# Cursor Agent Authentication in VMs - Investigation Results

**Status: NOT FIXABLE** - Cursor CLI is not compatible with VM/SSH-only environments.

## Problem

The Cursor agent (`agent` command) fails to authenticate in Tart VMs accessed via SSH.

**Initial hypothesis:** Keychain access issues (exit code 36)

**Actual root cause (confirmed via testing - January 2026):**
1. **OAuth Polling Failure** - Browser authentication succeeds but CLI never detects completion
2. **API Key Dependency** - API keys require OAuth-downloaded user configuration to function
3. **Dependency Cycle** - Cannot get config without OAuth, OAuth doesn't work in VMs

## Attempted Solutions

### Keychain Unlock (Ineffective)

Based on the [official Tart FAQ](https://tart.run/faq/), we attempted to unlock the login keychain programmatically:

```bash
security unlock-keychain -p 'admin' login.keychain
```

**Result:** Keychain unlock doesn't solve the problem because the issue occurs before keychain access is needed. The OAuth polling mechanism fails to detect browser authentication completion in VM environments.

### API Key Authentication (Ineffective)

We attempted to use Cursor's API key authentication as an alternative:

```bash
export CURSOR_API_KEY=your_key
agent -p "test"
```

**Result:** API keys require user configuration that only OAuth can provide. Since OAuth fails in VMs, API keys cannot function either.

## Implementation Details

### vm-setup.sh

Added keychain unlock after auto-login configuration:

```bash
# Configure keychain for SSH/headless access
echo ""
echo "🔐 Configuring keychain for SSH access..."
if security unlock-keychain -p "${VM_PASSWORD:-admin}" login.keychain 2>/dev/null; then
    echo "  ✓ Login keychain unlocked"
else
    echo "  ⚠ Could not unlock keychain (may need manual unlock)"
fi
```

### cal-bootstrap

Added `unlock_keychain()` function that's called when:
- Starting a stopped VM (`--run`)
- Connecting to an already-running VM (`--run`)

```bash
unlock_keychain() {
    local vm_ip="$1"
    echo "  Unlocking keychain for SSH access..."
    if ssh "${VM_USER}@${vm_ip}" "security unlock-keychain -p '${VM_PASSWORD}' login.keychain"; then
        echo "  ✓ Keychain unlocked"
    fi
}
```

## Usage

### Automated (via cal-bootstrap)

The keychain is automatically unlocked when you connect:

```bash
./scripts/cal-bootstrap --run
```

### Manual (via SSH)

If you connect directly via SSH:

```bash
ssh admin@$(tart ip cal-dev)
# Then unlock keychain:
security unlock-keychain -p admin login.keychain
```

### One-time Agent Login

After keychain is unlocked, complete the Cursor agent login:

**Option 1: Via Screen Sharing (Recommended)**
```bash
open vnc://$(tart ip cal-dev)
# In VM Terminal:
agent
# Complete OAuth flow in browser
```

**Option 2: Via SSH** (if NO_OPEN_BROWSER works)
```bash
ssh admin@$(tart ip cal-dev)
source ~/.zshrc
NO_OPEN_BROWSER=1 agent login
# Follow the instructions to complete auth
```

## Security Considerations

### Keychain Password

The default Tart VM password is `admin`. This is stored in:
- VM login password: `admin/admin`
- Keychain password: `admin`

**For production use**, consider:
1. Changing the VM password after initial setup
2. Using `VM_PASSWORD` environment variable in scripts
3. Creating a new keychain with a stronger password

### Keychain Lock Timeout

We attempted to set a 24-hour timeout with:
```bash
security set-keychain-settings -t 86400 -l login.keychain
```

However, this requires GUI access and fails in SSH sessions with:
```
User interaction is not allowed
```

**Workaround:** The keychain stays unlocked for the current session. You need to re-unlock after:
- VM reboot
- Keychain auto-lock (default: after sleep/screen lock)

## Testing

**Complete Testing Checklist:** See [TESTING.md](TESTING.md) for comprehensive step-by-step testing guide.

**Quick Test Script:** Use the test script to verify basic functionality:

```bash
./scripts/test-cursor-login.sh [vm-ip] [vm-user]
```

This checks:
1. Keychain status
2. Keychain unlock
3. Agent installation
4. Agent authentication status

## Confirmed Limitations (January 2026 Testing)

**Cursor CLI authentication does not work in Tart VM environments:**

1. **OAuth Browser Flow Fails** - Browser authentication succeeds but CLI cannot detect completion (polling mechanism fails)
2. **API Key Cannot Function Standalone** - Requires OAuth-downloaded user configuration (~166KB) that only successful OAuth can provide
3. **No Workaround Available** - Both authentication methods are broken due to fundamental CLI limitations

**Environment Details:**
- Cursor CLI Version: 2026.01.17-d239e66
- Host: macOS with working authentication
- VM: Tart macOS VM via SSH
- Network: Verified working (can reach api.cursor.com)

## Recommended Alternatives

Since Cursor CLI authentication is not functional in VM environments, use these alternatives:

### Option A: Claude Code (Recommended)

Claude Code CLI works reliably in VM environments:

```bash
# Authenticate once
claude
# Works over SSH after initial auth
```

**Status:** ✅ Working in VMs

### Option B: Opencode

Opencode authentication works in VM environments:

```bash
# Authenticate
opencode auth login
# Works over SSH after initial auth
```

**Status:** ✅ Working in VMs

### Option C: Install Cursor Desktop App (Untested)

**Theory:** Installing the full Cursor desktop application in the VM (via Screen Sharing) might allow OAuth to complete successfully, making the CLI usable.

**Status:** ⚠️ Untested - adds complexity and requires GUI access

### Not Viable: Cursor CLI Only

Cursor CLI cannot authenticate in VM-only environments. Both OAuth and API key methods fail.

## Diagnostic Information

### Testing Cursor Authentication

If you want to verify the issue yourself:

```bash
# In VM via SSH:
export CURSOR_API_KEY=your_key
agent -p "test"
# Result: Silent failure (exit code 1)

# Or try OAuth:
agent login
# Result: Browser succeeds, CLI never detects completion
```

### Check Configuration State

```bash
# Check config file size
ls -lh ~/.cursor/cli-config.json
# Working host: ~166KB (full user profile)
# Failed VM: 424B (minimal defaults only)

# Check for user data
cat ~/.cursor/cli-config.json | grep -i user
# Working: Contains user profile
# Failed: No user data present
```

## Testing Summary (January 2026)

**Environment Tested:**
- Cursor CLI Version: 2026.01.17-d239e66
- Host Mac: Authentication works correctly
- Tart VM: Both OAuth and API key fail
- Network: Verified working (can reach api.cursor.com)

**OAuth Testing:**
- Browser authentication completes successfully
- CLI remains stuck on "Waiting for browser authentication..."
- User configuration never downloaded (file stays at 424 bytes vs 166KB on host)

**API Key Testing:**
- API key works on host Mac
- Same key fails silently in VM (exit code 1)
- Root cause: Requires user config that only OAuth can provide

## References

- [Tart FAQ - Keychain Access](https://tart.run/faq/) - Original keychain unlock approach
- [Cursor Forum - SSH Authentication Issue](https://forum.cursor.com/t/cursor-agent-cannot-authenticate-over-ssh/136991) - Confirmed bug report
- [Cursor Docs - Authentication](https://cursor.com/docs/cli/reference/authentication) - Official API key documentation
- [PLAN.md Phase 0.8](PLAN.md) - Project status tracking

## Conclusion

**Cursor CLI authentication is not compatible with Tart VM environments.** Both OAuth and API key authentication methods fail due to fundamental limitations in the CLI's OAuth polling mechanism.

**Recommendation:** Use Claude Code or Opencode for coding agent workflows in CAL VMs. Both work reliably over SSH after initial authentication.

**For Cursor Users:** Consider filing a bug report or voting for existing issues on the Cursor forum to prioritize SSH/VM compatibility.
