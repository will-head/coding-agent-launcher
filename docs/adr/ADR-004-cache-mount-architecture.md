# ADR-004: Cache Mount Architecture

## Direct virtio-fs Mounting to Eliminate Symlink Fragility

**ADR:** 004
**Status:** Accepted
**Created:** 2026-02-07
**Tested:** 2026-02-07
**Supersedes:** Symlink-based approach in ADR-003
**Purpose:** Replace fragile per-cache symlinks with direct virtio-fs mounts to create a robust, self-healing cache architecture that cannot be accidentally deleted

### Test Results (2026-02-07)

| Test | Result | Notes |
|------|--------|-------|
| Custom tag syntax | ✅ Pass | `--dir=${HOME}/test-calf-cache:tag=test-cache` works with Tart 2.30.1 |
| mount_virtiofs | ✅ Pass | `mount_virtiofs test-cache ~/test-mount` mounts successfully |
| Bidirectional sync | ✅ Pass | Files created in VM appear on host immediately |
| Permission inheritance | ✅ Pass | Files owned by `admin` in VM, host user on host |

---

## Context

### Current Architecture (ADR-003)

The current cache sharing implementation uses symlinks inside the VM:

```
Host Machine                              VM (cal-dev)
~/.calf-cache/                             /Volumes/My Shared Files/cal-cache/
├── homebrew/                             (Tart virtio-fs automount)
├── npm/                                              │
├── go/                                               ▼
└── git/                                  ~/.calf-cache/
                                          ├── homebrew → /Volumes/.../homebrew
                                          ├── npm → /Volumes/.../npm
                                          ├── go → /Volumes/.../go
                                          └── git → /Volumes/.../git
```

### Problem Statement

**4 symlinks = 4 points of failure.** These symlinks are:

1. **Easily deleted** - User or coding agent can accidentally `rm -rf ~/.calf-cache`
2. **Not self-healing** - Once deleted, cache breaks until manual intervention
3. **Confusing for debugging** - Symlink chains obscure where data actually lives
4. **Not protectable** - macOS `chflags schg` does not work on symlinks (only regular files)

### Requirements

1. Cache paths **cannot be accidentally deleted** by user or coding agent
2. Architecture must be **self-healing** if disrupted
3. Must support **future mount points** (e.g., iOS code signing)
4. Must handle **migration** from current symlink-based VMs
5. Clean paths without spaces for maximum tool compatibility

---

## Decision

**Replace symlinks with direct virtio-fs mounts using custom mount tags and a LaunchDaemon for boot-time persistence.**

### New Architecture

```
Host (calf-bootstrap)                      VM (cal-dev)
────────────────────                      ─────────────
tart run \                                LaunchDaemon runs at boot:
  --dir=${HOME}/.calf-cache:               ┌─────────────────────────────┐
        tag=cal-cache \                   │ /usr/local/bin/             │
  --dir=${HOME}/signing:                  │   calf-mount-shares.sh       │
        tag=cal-signing \                 │ ├─ mount cal-cache          │
  vm-name                                 │ ├─ mount cal-signing        │
                                          │ └─ (future mounts)          │
                                          └─────────────────────────────┘
                                                      │
                                                      ▼
                                          ~/.calf-cache (direct mount)
                                          ~/signing (direct mount)
```

### Why This Approach

| Property | Symlinks (Current) | Direct Mount (Proposed) |
|----------|-------------------|------------------------|
| Can be deleted by `rm` | Yes | No (mount, not file) |
| Self-healing | No | Yes (boot + shell) |
| Failure points | 4 (one per cache) | 1 (mount script) |
| Path clarity | Obscured by symlinks | Direct and obvious |
| Future extensibility | Add more symlinks | Add to mount script |
| Tool compatibility | Good | Best (no spaces) |

---

## Implementation

### 1. Host-Side Changes (calf-bootstrap)

**Change Tart `--dir` flag to use custom mount tag:**

```bash
# Before (automount to /Volumes/My Shared Files/):
--dir calf-cache:${HOME}/.calf-cache:rw,tag=com.apple.virtio-fs.automount

# After (custom tag for manual mount):
--dir=${HOME}/.calf-cache:tag=cal-cache
```

### 2. VM-Side Mount Script

**Create `/usr/local/bin/calf-mount-shares.sh`:**

```bash
#!/bin/bash
# CAL Cache Mount Script
# Mounts virtio-fs shares to their target locations
# Called by LaunchDaemon at boot and can be run manually

set -e
LOG_FILE="/tmp/cal-mount.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "$(date): Starting CAL mount script"

# Maximum retries for mount operations (virtio-fs may not be ready immediately)
MAX_RETRIES=5
RETRY_DELAY=2

mount_share() {
    local tag="$1"
    local mountpoint="$2"
    local retries=0

    # Handle migration: remove old symlink-based structure
    if [ -L "$mountpoint" ]; then
        echo "Removing old symlink at $mountpoint"
        rm -f "$mountpoint"
    elif [ -d "$mountpoint" ] && ! mountpoint -q "$mountpoint" 2>/dev/null; then
        # Directory exists but isn't a mount - check if it's old symlink structure
        if [ -L "$mountpoint/homebrew" ] || [ -L "$mountpoint/npm" ]; then
            echo "Removing old symlink-based structure at $mountpoint"
            rm -rf "$mountpoint"
        fi
    fi

    # Create mount point if needed
    mkdir -p "$mountpoint"

    # Skip if already mounted
    if mountpoint -q "$mountpoint" 2>/dev/null; then
        echo "Already mounted: $mountpoint"
        return 0
    fi

    # Attempt mount with retries
    while [ $retries -lt $MAX_RETRIES ]; do
        if mount_virtiofs "$tag" "$mountpoint" 2>/dev/null; then
            echo "Mounted $tag to $mountpoint"
            return 0
        fi
        retries=$((retries + 1))
        echo "Mount attempt $retries failed, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    done

    echo "ERROR: Failed to mount $tag to $mountpoint after $MAX_RETRIES attempts"
    return 1
}

# Mount CAL cache
mount_share "cal-cache" "$HOME/.calf-cache" || true

# Future: iOS code signing
# mount_share "cal-signing" "$HOME/Library/MobileDevice" || true

# Future: Additional mounts
# mount_share "cal-workspace" "$HOME/workspace" || true

echo "$(date): CAL mount script complete"
```

### 3. LaunchDaemon Configuration

**Create `/Library/LaunchDaemons/com.cal.mount-shares.plist`:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cal.mount-shares</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/calf-mount-shares.sh</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>/tmp/cal-mount.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/cal-mount.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>/Users/admin</string>
        <key>USER</key>
        <string>admin</string>
    </dict>
</dict>
</plist>
```

### 4. Self-Healing Fallback in .zshrc

**Add to VM's `~/.zshrc` as belt-and-suspenders:**

```bash
# CAL Cache Mount Check (self-healing fallback)
# Runs on every shell start to ensure cache is available
# Primary mount is handled by LaunchDaemon; this is backup
if ! mountpoint -q ~/.calf-cache 2>/dev/null; then
    # Not mounted - try to mount (works if virtio-fs tag exists)
    if mount_virtiofs cal-cache ~/.calf-cache 2>/dev/null; then
        echo "📦 CAL cache mounted (recovered)"
    fi
fi
```

### 5. Deployment via vm-setup.sh

**Add to `scripts/vm-setup.sh`:**

```bash
# Deploy CAL mount infrastructure
echo "📦 Setting up CAL cache mount infrastructure..."

# Deploy mount script
sudo cp ~/scripts/calf-mount-shares.sh /usr/local/bin/
sudo chmod 755 /usr/local/bin/calf-mount-shares.sh

# Deploy LaunchDaemon
sudo cp ~/scripts/com.cal.mount-shares.plist /Library/LaunchDaemons/
sudo chmod 644 /Library/LaunchDaemons/com.cal.mount-shares.plist
sudo chown root:wheel /Library/LaunchDaemons/com.cal.mount-shares.plist

# Load LaunchDaemon
sudo launchctl load /Library/LaunchDaemons/com.cal.mount-shares.plist

echo "  ✓ CAL cache mount infrastructure installed"
```

---

## Alternatives Considered

### Option 1: Single Symlink (Rejected)

**Approach:** Replace 4 symlinks with 1 symlink at parent level.

```
~/.calf-cache → /Volumes/My Shared Files/cal-cache
```

| Pros | Cons |
|------|------|
| Minimal code change | Still a symlink (can be deleted) |
| Reduces failure points 4→1 | No self-healing |
| Easier to understand | Agent could still `rm -rf ~/.calf-cache` |

**Rejection reason:** Does not meet requirement #1 (cannot be accidentally deleted).

---

### Option 3: Self-Healing Symlinks in .zshrc (Rejected)

**Approach:** Keep symlinks but auto-repair on every shell start.

```bash
# In .zshrc - recreate symlinks if missing
for cache in homebrew npm go git; do
    ln -sf "/Volumes/My Shared Files/cal-cache/$cache" ~/.calf-cache/$cache
done
```

| Pros | Cons |
|------|------|
| Self-healing on shell start | Still uses symlinks |
| No additional services | Only heals when shell starts |
| Works with current Tart config | Agent could delete between commands |

**Rejection reason:** Window of vulnerability between deletion and next shell. Does not meet requirement #1.

---

### Option 4: Environment Variables Only (Rejected)

**Approach:** Point env vars directly to mount path, no symlinks.

```bash
export HOMEBREW_CACHE="/Volumes/My Shared Files/cal-cache/homebrew"
```

| Pros | Cons |
|------|------|
| No symlinks at all | Path has spaces (tool compatibility) |
| Cannot be deleted | Git cache has no env var option |
| Simplest architecture | Some build tools break with spaces |

**Rejection reason:** Space in path (`/Volumes/My Shared Files/`) causes compatibility issues with some tools, Makefiles, and scripts.

---

### Option 5: Hybrid (Deferred)

**Approach:** Custom mount primary, self-healing symlinks as fallback.

| Pros | Cons |
|------|------|
| Most robust (two layers) | Most complex |
| Handles all edge cases | More code to maintain |

**Status:** Elements incorporated into chosen approach (.zshrc fallback), but full hybrid complexity not needed.

---

## Edge Cases and Mitigations

### Boot Timing

**Issue:** LaunchDaemon might run before virtio-fs is ready.

**Mitigation:** Mount script has retry logic (5 attempts, 2s delay). LaunchDaemon has `KeepAlive` on failure.

### Migration from Current Architecture

**Issue:** Existing VMs have `~/.calf-cache` as directory with symlinks.

**Mitigation:** Mount script detects and removes old symlink-based structure before mounting.

### Manual Unmount

**Issue:** User could run `umount ~/.calf-cache`.

**Mitigation:** .zshrc fallback remounts on next shell start. Full self-healing requires reboot or manual `calf-mount-shares.sh`.

### Snapshot/Restore

**Issue:** Mounts don't persist in snapshots (runtime state).

**Mitigation:** LaunchDaemon remounts at boot. For running VMs, .zshrc fallback handles it.

### Permission Issues

**Issue:** LaunchDaemon runs as root.

**Mitigation:** Set `HOME` and `USER` environment variables in plist. Mount point created with correct ownership.

**Testing required:** Verify file access as admin user after mount.

### Multiple Future Mounts

**Issue:** Need to support iOS signing and other mounts.

**Mitigation:** Architecture designed for extensibility - add new `mount_share` calls to script.

---

## Testing Requirements

### Pre-Implementation Tests

1. **Verify Tart custom tag syntax:**
   ```bash
   # On host:
   mkdir -p ~/test-cal-cache
   tart run --dir=${HOME}/test-calf-cache:tag=test-cache vm-name

   # In VM:
   mkdir -p ~/test-mount
   mount_virtiofs test-cache ~/test-mount
   ls ~/test-mount  # Should show host directory contents
   ```

2. **Verify permission inheritance:**
   ```bash
   # In VM after mount:
   touch ~/test-mount/testfile
   ls -la ~/test-mount/testfile  # Should be owned by admin
   ```

3. **Verify mount detection:**
   ```bash
   mountpoint -q ~/test-mount && echo "Mounted" || echo "Not mounted"
   ```

### Post-Implementation Tests

1. **Boot persistence:** Reboot VM, verify cache is mounted automatically
2. **Self-healing:** Unmount cache, open new shell, verify remount
3. **Migration:** Start with old symlink structure, run setup, verify mount works
4. **Snapshot/restore:** Create snapshot, restore, verify cache works

---

## Migration Path

### For New VMs (--init)

No migration needed. New architecture deployed during vm-setup.sh.

### For Existing VMs

1. Update scripts on host (calf-bootstrap changes)
2. SSH into VM and run updated vm-setup.sh
3. Mount script handles cleanup of old symlinks automatically
4. Reboot to activate LaunchDaemon

### Rollback Plan

If issues discovered:
1. Remove LaunchDaemon: `sudo launchctl unload /Library/LaunchDaemons/com.cal.mount-shares.plist`
2. Remove mount script: `sudo rm /usr/local/bin/calf-mount-shares.sh`
3. Recreate symlinks manually or re-run old vm-setup.sh

---

## Related Documents

- [ADR-003](ADR-003-package-download-caching.md) - Original cache implementation (symlink-based)
- [ADR-002](ADR-002-tart-vm-operational-guide.md) - Tart VM operational guide
- [PLAN-PHASE-01-TODO.md](../PLAN-PHASE-01-TODO.md) - Critical issue #3 (Shared Cache Symlink Fragility)

---

## References

- [Tart Quick Start - Directory Sharing](https://tart.run/quick-start/)
- [Tart Issue #517 - Change path for passthrough directories](https://github.com/cirruslabs/tart/issues/517)
- [mount_virtiofs(8) man page](https://keith.github.io/xcode-man-pages/mount_virtiofs.8.html)
- [macOS chflags - File flags](https://ss64.com/mac/chflags.html) (symlinks cannot have flags)
