# BUG-008: Cursor agent command not found after --init

**Status:** Resolved
**Severity:** High
**Component:** Bootstrap / VM Setup
**Phase:** 0 (Bootstrap)
**Opened:** 2026-02-03

---

## Summary

The `agent` command (Cursor CLI) is not available after `calf-bootstrap --init` completes, despite the Cursor CLI installation succeeding. The verification step shows "✗ agent: not found (may need to restart shell)" even though `cursor-agent` was successfully installed via Homebrew Cask.

## Symptoms

1. **Cursor CLI installed successfully** - Homebrew Cask installation completes: `✓ Cursor CLI installed`
2. **Verification fails** - `✗ agent: not found (may need to restart shell)`
3. **Other agents work** - Claude Code, opencode, and codex all verify successfully
4. **May affect agent authentication** - User cannot run `agent` to authenticate Cursor

## Expected Behavior

- After `calf-bootstrap --init`, the `agent` command should be available
- Verification should show: `✓ agent: <version>` (similar to other agents)
- User should be able to run `agent` for Cursor authentication

## Actual Behavior

```
🖱️  Installing Cursor CLI...
==> Downloading https://downloads.cursor.com/lab/2026.01.28-fd13201/darwin/arm64/agent-cli-package.tar.gz
==> Installing Cask cursor-cli
==> Linking Binary 'cursor-agent' to '/opt/homebrew/bin/cursor-agent'
🍺  cursor-cli was successfully installed!
  ✓ Cursor CLI installed

...

🔍 Verifying installations...
  ✓ claude: 2.1.30 (Claude Code)
  ✗ agent: not found (may need to restart shell)
  ✓ opencode: 1.1.49
  ✓ codex: codex-cli 0.94.0
```

## Root Cause (Confirmed)

**Binary name mismatch - no alias created:**

Testing in fresh VM confirms:
```bash
admin@Manageds-Virtual-Machine ~ % agent
zsh: command not found: agent

admin@Manageds-Virtual-Machine ~ % cursor-agent
Tip: You can start the Cursor CLI with `agent` (same as `cursor-agent`).
 Signing in
 If your browser didn't open, click this link to log in:
```

**Analysis:**
- Homebrew Cask installs only `cursor-agent` binary at `/opt/homebrew/bin/cursor-agent`
- Cursor CLI itself suggests using `agent` as an alias (shown in tip message)
- **vm-setup.sh does not create the `agent` alias**
- Verification step checks for `agent` command, which doesn't exist
- This is a gap in the bootstrap setup, not a PATH or timing issue

## Investigation Complete

Fresh VM testing confirms the root cause. No further investigation needed.

## Workarounds

### Workaround #1: Use cursor-agent directly
```bash
cursor-agent <args>
```

### Workaround #2: Create alias in ~/.zshrc
```bash
alias agent='cursor-agent'
```

### Workaround #3: Reload shell after bootstrap
```bash
exec zsh
agent --version
```

## Impact

**User Impact:**
- High: Agent authentication step in documentation mentions `agent` command
- Users following docs will encounter error
- Must discover `cursor-agent` command on their own

**Workaround Difficulty:**
- Easy: Can use `cursor-agent` directly
- Documented: Error message suggests "may need to restart shell"

**Frequency:**
- Affects every fresh `--init`
- Does not affect existing VMs (already authenticated)

## Recommended Fix

**Add `agent` alias in vm-setup.sh shell configuration section:**

```bash
# In shell configuration section (around line 300+)
if ! grep -q "alias agent=" ~/.zshrc 2>/dev/null; then
    echo "alias agent='cursor-agent'" >> ~/.zshrc
    echo "  ✓ Added agent alias for Cursor CLI"
fi
```

**Why this fix:**
- Matches Cursor's own recommendation (shown in tip message)
- Consistent with user expectations (docs say `agent`)
- Minimal change, follows existing pattern
- Idempotent (checks before adding)

**Alternative fixes considered:**

### Alt #1: Symlink approach
```bash
if [ ! -e /opt/homebrew/bin/agent ] && [ -e /opt/homebrew/bin/cursor-agent ]; then
    ln -s /opt/homebrew/bin/cursor-agent /opt/homebrew/bin/agent
fi
```
**Rejected:** Modifies Homebrew's bin directory; alias is cleaner

### Alt #2: Update verification only
```bash
cursor-agent --version 2>/dev/null || echo "not found"
```
**Rejected:** Doesn't fix the actual user-facing issue (agent command unavailable)

### Alt #3: Update documentation
**Rejected:** Documentation already says `agent` per Cursor's recommendation; setup should match

## Related Issues

- BUG-007: Shell configuration timing issues
- Phase 0 goal: All agents should authenticate successfully

## Notes

- Other agents (claude, opencode, codex) all verify successfully
- Only Cursor CLI affected
- Homebrew Cask installation itself succeeds
- Issue is command name visibility/aliasing

---

## Resolution

**Resolved:** 2026-02-04

**Fix Applied:**
Added `alias agent='cursor-agent'` to enable the agent command after Cursor CLI installation.

**Changes:**
1. Modified `scripts/vm-setup.sh` line ~620 to add agent alias check and configuration
   - Alias is added after Cursor CLI installation and before shell config reload
   - Idempotent check prevents duplicate entries on subsequent runs

2. Modified `scripts/vm-auth.sh` line ~7-10 to create agent alias on the fly
   - Checks if `agent` command exists, creates alias if not
   - Avoids sourcing ~/.zshrc (which would trigger tmux-resurrect to start early)
   - Clean, localized solution without side effects

3. **Session Persistence Architecture** (2026-02-04 evening):
   - Redesigned first-run flag and tmux history initialization
   - **vm-auth.sh**: ONLY handles authentication, no state management
     - Removed first-run flag logic
     - Removed tmux session clearing
   - **vm-first-run.sh**: Handles session persistence enablement
     - Checks git repositories for updates
     - Loads TPM to enable tmux history: `~/.tmux/plugins/tpm/tpm`
     - Removes first-run flag AFTER tmux history is enabled
   - **vm-setup.sh**: Updated comments to reflect new flow

**Why this architecture:**
- tmux history never starts during `--init` (no setup script touches it)
- tmux history only starts on first user login (via vm-first-run.sh)
- vm-auth.sh can be run anytime without affecting system state
- cal-init snapshot includes first-run flag, so restores enable session persistence correctly

**Verification:**
After this fix, the flow is:
1. `calf-bootstrap --init`: Sets first-run flag, runs vm-auth (auth only), creates cal-init
2. Restore from cal-init: First login triggers vm-first-run.sh
3. vm-first-run.sh: Checks git, enables tmux history, removes flag
4. Session persistence active for all subsequent logins

**Testing Status:**
Code review and syntax validation complete. VM testing pending next bootstrap run.
