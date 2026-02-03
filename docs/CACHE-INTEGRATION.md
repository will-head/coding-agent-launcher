# Package Download Cache Integration

**Date:** 2026-02-03
**Purpose:** Integrate package download caching into cal-bootstrap and vm-setup.sh

---

## Problem

The cache infrastructure (PRs #6-9) existed but wasn't being used:
- Cache directories created but empty
- Packages downloaded during `--init` didn't use cache
- Every `--init` re-downloaded everything from scratch
- VM downloads didn't populate host cache

---

## Solution

Integrated cache into bootstrap scripts so downloads are cached and reused.

### Host Behavior (cal-bootstrap)

**Scope:** Temporary (only during script execution)

**Implementation:**
```bash
# In cal-bootstrap (lines 37-44)
if [ -d "$HOME/.cal-cache" ]; then
    export HOMEBREW_CACHE="$HOME/.cal-cache/homebrew"
    export npm_config_cache="$HOME/.cal-cache/npm"
    export GOMODCACHE="$HOME/.cal-cache/go"
fi
```

**Effect:**
- ✅ Brew installs during `--init` use cache
- ✅ npm installs during `--init` use cache
- ✅ Go module downloads during `--init` use cache
- ✅ Host's normal package manager use unaffected (cache only active during script)

### VM Behavior (vm-setup.sh)

**Scope:** Permanent (persists in ~/.zshrc)

**Implementation:**
```bash
# Set for script execution
export HOMEBREW_CACHE="/Volumes/My Shared Files/cal-cache/homebrew"
export npm_config_cache="/Volumes/My Shared Files/cal-cache/npm"
export GOMODCACHE="/Volumes/My Shared Files/cal-cache/go"

# Create symlinks
ln -sf "/Volumes/My Shared Files/cal-cache/homebrew" ~/.cal-cache/homebrew
ln -sf "/Volumes/My Shared Files/cal-cache/npm" ~/.cal-cache/npm
ln -sf "/Volumes/My Shared Files/cal-cache/go" ~/.cal-cache/go
ln -sf "/Volumes/My Shared Files/cal-cache/git" ~/.cal-cache/git

# Make persistent (only if not already present)
echo 'export HOMEBREW_CACHE="$HOME/.cal-cache/homebrew"' >> ~/.zshrc
echo 'export npm_config_cache="$HOME/.cal-cache/npm"' >> ~/.zshrc
echo 'export GOMODCACHE="$HOME/.cal-cache/go"' >> ~/.zshrc
```

**Effect:**
- ✅ All VM package downloads use shared cache
- ✅ Downloads appear on host at `~/.cal-cache/*`
- ✅ Cache persists across VM restarts
- ✅ Future `--init` runs reuse cached downloads

---

## Cache Flow

### First --init

```
Host:
  brew install sshuttle → ~/.cal-cache/homebrew/ ✓ cached
                           ↓ (shared to VM)
VM:
  /Volumes/My Shared Files/cal-cache/homebrew/
  brew install tart → uses empty cache, downloads
                    → stores in shared cache ✓
                    ↓ (appears on host)
Host:
  ~/.cal-cache/homebrew/ now has tart downloads ✓
```

### Second --init

```
Host:
  brew install sshuttle → ~/.cal-cache/homebrew/ ✓ reuses cache
                           ↓ (already shared)
VM:
  /Volumes/My Shared Files/cal-cache/homebrew/
  brew install tart → finds cached downloads ✓
                    → skips download, uses cache ✓
                    → much faster!
```

---

## Files Modified

### 1. scripts/vm-setup.sh

**Location:** After Homebrew PATH setup, before package installs (lines 19-47)

**Changes:**
- Check if shared cache is available
- Set cache environment variables (HOMEBREW_CACHE, npm_config_cache, GOMODCACHE)
- Create symlinks from ~/.cal-cache to shared volume
- Add cache exports to ~/.zshrc (persistent)
- Graceful degradation if cache unavailable

**User Feedback:**
```
📦 Configuring package download cache...
  ✓ Cache configured (shared from host)
    Homebrew: /Volumes/My Shared Files/cal-cache/homebrew
    npm: /Volumes/My Shared Files/cal-cache/npm
    Go: /Volumes/My Shared Files/cal-cache/go
```

### 2. scripts/cal-bootstrap

**Location:** After proxy settings, before log file (lines 43-48)

**Changes:**
- Check if ~/.cal-cache exists on host
- Set cache environment variables temporarily (script scope only)
- No modifications to user's ~/.zshrc or permanent config
- Silent (no user feedback needed - transparent behavior)

---

## Testing Verification

### Before Integration

```bash
# First --init
brew install tart  # Downloads 73MB

# Second --init
brew install tart  # Downloads 73MB again (no cache)
```

### After Integration

```bash
# First --init
brew install tart  # Downloads 73MB → cache populated
ls ~/.cal-cache/homebrew/  # Shows cached downloads ✓

# Second --init
brew install tart  # Uses cache, skips download ✓
# Much faster!
```

### Verification Commands

**Host:**
```bash
# Check cache is populated
ls -lh ~/.cal-cache/homebrew/
ls -lh ~/.cal-cache/npm/
ls -lh ~/.cal-cache/go/
```

**VM:**
```bash
# Check cache is accessible
ls -la "/Volumes/My Shared Files/cal-cache/"

# Check symlinks exist
ls -la ~/.cal-cache/

# Verify environment variables are set
echo $HOMEBREW_CACHE
echo $npm_config_cache
echo $GOMODCACHE
```

---

## Design Decisions

### Why temporary on host?

**Decision:** Set cache variables only during cal-bootstrap execution, don't modify ~/.zshrc

**Rationale:**
- Avoids unexpected changes to user's system
- User's normal `brew install` outside CAL uses default cache
- Cache is opt-in for CAL operations only
- No conflicts with other tools or workflows

### Why permanent in VM?

**Decision:** Add cache variables to ~/.zshrc in VM

**Rationale:**
- VM is isolated and dedicated to CAL
- We control the VM environment completely
- Consistent cache behavior across all VM operations
- No risk of conflicts (VM is clean slate)

### Why symlinks in VM?

**Decision:** Create symlinks from ~/.cal-cache to /Volumes/My Shared Files/cal-cache

**Rationale:**
- Shorter paths in environment variables ($HOME/.cal-cache vs /Volumes/...)
- Consistent with host paths (both use ~/.cal-cache)
- Easier to remember and debug
- Works if shared volume mount point changes

---

## Performance Impact

### Estimated Savings per --init

**Packages typically installed:**
- Homebrew: sshuttle, jq, tart, ghostty, opencode (~200MB)
- npm: Claude Code CLI (~50MB)
- Git: TPM (~200KB)

**First --init:**
- Download time: ~2-5 minutes (depending on connection)
- Cache populated: ~250MB

**Second --init:**
- Download time: ~5-10 seconds (cache hits)
- Savings: ~2-5 minutes per run
- Network data saved: ~250MB per run

**For developers doing frequent --init:**
- 10 --init runs saved: ~20-50 minutes
- Network data saved: ~2.5GB

---

## Fallback Behavior

### If cache unavailable

**vm-setup.sh:**
```
  ⚠ Shared cache not available, using default locations
```
- Script continues normally
- Package managers use default cache locations
- No failures, just no cache benefits

**cal-bootstrap:**
- Silently skips cache setup if ~/.cal-cache doesn't exist
- Script behavior unchanged
- Graceful degradation

---

## Future Enhancements

1. **Cache size limits:** Implement automatic cache cleanup when size exceeds threshold
2. **Cache stats:** Add `cal cache stats` to show hit rate, size, savings
3. **Selective caching:** Allow users to disable specific caches (e.g., only Homebrew)
4. **Host opt-in:** Add `cal cache enable-host` to make cache permanent on host too
5. **Cache compression:** Compress old cache entries to save disk space

---

## Related Documentation

- [PR-9-TEST-RESULTS.md](PR-9-TEST-RESULTS.md) - Testing results for git cache
- [PR-9-INIT-REVIEW.md](PR-9-INIT-REVIEW.md) - Review findings and --init changes
- [PLAN-PHASE-01-TODO.md](PLAN-PHASE-01-TODO.md) § 1.1 - Package download caching
- PR #6 - Homebrew cache implementation
- PR #7 - npm cache implementation
- PR #8 - Go modules cache implementation
- PR #9 - Git clone cache implementation
