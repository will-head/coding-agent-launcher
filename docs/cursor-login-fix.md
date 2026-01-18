# Cursor Agent Login Fix - Keychain Solution

## Problem

The Cursor agent (`agent` command) fails to authenticate in the VM when accessed via SSH with the error:
```
Security command failed (exit code 36)
```

This occurs because:
1. The macOS keychain is locked in SSH sessions
2. Cursor agent needs keychain access to store OAuth tokens
3. Headless/SSH sessions don't automatically unlock the keychain

## Solution

Based on the [official Tart FAQ](https://tart.run/faq/), we unlock the login keychain programmatically:

```bash
security unlock-keychain -p 'admin' login.keychain
```

This is now implemented in:
1. `vm-setup.sh` - Unlocks keychain during initial VM setup
2. `cal-bootstrap` - Unlocks keychain when starting/connecting to VM

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

## Known Limitations

1. **Manual OAuth Required:** The first `agent login` still requires browser interaction
2. **Session-based Unlock:** Keychain unlock doesn't persist across VM reboots
3. **Password in Scripts:** The unlock command requires the keychain password (default: `admin`)

## Alternative Approaches

### Option A: Create New Keychain (from Tart FAQ)

```bash
# Create a new keychain with empty password
security create-keychain -p '' login.keychain
security unlock-keychain -p '' login.keychain
security login-keychain -s login.keychain
```

**Pros:** No password needed in scripts
**Cons:** May break existing keychain items

### Option B: GUI-only Login

Always use Screen Sharing for initial agent login:
1. Complete OAuth via GUI Terminal
2. Credentials persist across SSH sessions
3. No keychain unlock needed for subsequent use

### Option C: API Key Authentication

If Cursor supports API key auth (check with `agent --help`):
```bash
agent --api-key YOUR_API_KEY
```

Store key in environment variable or secure file.

## Troubleshooting

### "Security command failed" persists

1. Verify keychain is unlocked:
   ```bash
   security show-keychain-info login.keychain
   ```

2. Try unlocking manually:
   ```bash
   security unlock-keychain login.keychain
   # Enter password: admin
   ```

3. Check keychain exists:
   ```bash
   ls -la ~/Library/Keychains/
   ```

### Agent login hangs

The `agent login` command opens a browser. In SSH sessions, this may hang. Use:
- Screen Sharing (VNC) for GUI access
- `NO_OPEN_BROWSER=1` environment variable (if supported)

### Keychain locks after sleep

After VM sleep/wake, re-unlock:
```bash
./scripts/cal-bootstrap --run  # Auto-unlocks
# Or manually:
ssh admin@$(tart ip cal-dev) "security unlock-keychain -p admin login.keychain"
```

## References

- [Tart FAQ - Keychain Access](https://tart.run/faq/)
- [PLAN.md Line 38](../docs/PLAN.md#L38) - Known Issues section
- [Cursor Agent Documentation](https://cursor.com/loginDeepControl)

## Next Steps

**User Testing Required:** Complete Phase 0.8 testing checklist in [TESTING.md](TESTING.md):
- [ ] Test agent login after keychain unlock via Screen Sharing
- [ ] Verify credentials persist across SSH reconnects
- [ ] Verify credentials persist after VM reboot
- [ ] Verify auto-unlock works consistently

**Future Enhancements:**
- [ ] Document credential storage location
- [ ] Consider implementing API key auth as alternative
- [ ] Investigate if keychain timeout can be extended
