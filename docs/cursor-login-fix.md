# Cursor Agent Authentication in VMs - Investigation Results

**Status: FIXED** - Cursor CLI now works with automatic keychain unlock (January 2026)

## Problem (SOLVED)

The Cursor agent (`agent` command) previously failed to authenticate in Tart VMs accessed via SSH.

**Initial hypothesis:** Keychain access issues (exit code 36)

**Root cause (identified and fixed - January 2026):**
- OAuth flows require keychain access for browser credential storage
- SSH sessions don't automatically unlock the macOS keychain
- Without unlocked keychain, OAuth browser authentication cannot complete

**Solution:**
- Automatic keychain unlock on every SSH login (via .zshrc)
- First-run automation triggers vm-auth.sh after init
- VM password stored securely in ~/.cal-vm-config (mode 600)

## Solution Implemented

### Automatic Keychain Unlock (EFFECTIVE)

Based on the [official Tart FAQ](https://tart.run/faq/), we implemented automatic keychain unlock on every SSH login:

```bash
# In .zshrc - runs on every login
if [ -f ~/.cal-vm-config ]; then
    source ~/.cal-vm-config
    security unlock-keychain -p "${VM_PASSWORD:-admin}" login.keychain 2>/dev/null
fi
```

**Result:** ✅ OAuth browser authentication now works correctly. The keychain is unlocked before Cursor agent attempts OAuth, allowing browser credentials to be accessed.

### First-Run Automation (EFFECTIVE)

Added automatic vm-auth.sh execution on first login after init:

```bash
# In .zshrc - runs once after init
if [ -f ~/.cal-first-run ]; then
    rm -f ~/.cal-first-run
    CAL_FIRST_RUN=1 zsh ~/scripts/vm-auth.sh
    exit 0
fi
```

**Result:** ✅ Users no longer need to manually run vm-auth.sh after init - it runs automatically.

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

## Testing Results (January 2026)

**Cursor CLI authentication NOW WORKS in Tart VM environments:**

1. **OAuth Browser Flow** - ✅ Works with automatic keychain unlock
2. **Authentication Persistence** - ✅ Survives SSH reconnect and VM reboots
3. **First-Run Automation** - ✅ vm-auth.sh runs automatically after init

**Environment Details:**
- Cursor CLI Version: 2026.01.17-d239e66
- Host: macOS with working authentication
- VM: Tart macOS VM via SSH with automatic keychain unlock
- Network: Verified working (can reach api.cursor.com)

## Supported Agents

All coding agents now work in VM environments with automatic keychain unlock:

### Cursor (agent command)

Cursor CLI authentication works with automatic keychain unlock:

```bash
# Authenticate (runs automatically on first login)
agent
# Works over SSH after initial auth
```

**Status:** ✅ Working in VMs (as of January 2026)

### Claude Code

Claude Code CLI works reliably in VM environments:

```bash
# Authenticate once
claude
# Works over SSH after initial auth
```

**Status:** ✅ Working in VMs

### Opencode

Opencode authentication works in VM environments:

```bash
# Authenticate
opencode auth login
# Works over SSH after initial auth
```

**Status:** ✅ Working in VMs

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

**Cursor CLI authentication NOW WORKS in Tart VM environments** with automatic keychain unlock (January 2026).

**Solution Summary:**
- Automatic keychain unlock on every SSH login via .zshrc
- First-run automation triggers vm-auth.sh after init
- VM password stored securely in ~/.cal-vm-config (mode 600)
- OAuth flows complete successfully with unlocked keychain

**All agents work:** Cursor, Claude Code, and Opencode all authenticate reliably over SSH after initial setup.

**Security Note:** VM password is stored in plaintext (protected by mode 600 permissions). This is an acceptable trade-off given the VM isolation architecture and enables seamless OAuth authentication.
