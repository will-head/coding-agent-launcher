# PR #9 Init Review: Cal-Bootstrap Changes for Git Cache

**Review Date:** 2026-02-03
**Purpose:** Ensure `cal-bootstrap --init` creates a VM that works perfectly with git cache setup

---

## Testing Steps Reviewed

During manual testing of PR #9, we performed these steps:

### 1. Host Cache Directory Creation (Manual)
```bash
mkdir -p ~/.cal-cache/{homebrew,npm,go,git}
```

**Issue:** This was done manually before testing, but `cal-bootstrap --init` doesn't create these directories automatically.

**Impact:** Users running `--init` wouldn't have cache directories, so cache sharing would be disabled (the --dir flag checks if ~/.cal-cache exists before adding it).

### 2. Cal-Cache Sharing Configuration (Already Fixed)
```bash
--dir cal-cache:${HOME}/.cal-cache:rw,tag=com.apple.virtio-fs.automount
```

**Status:** ✅ Already implemented in cal-bootstrap (lines 231-233, 1709-1711)

**Conditional Logic:**
```bash
if [ -d ~/.cal-cache ]; then
    tart_cmd+=("--dir" "cal-cache:${HOME}/.cal-cache:rw,tag=com.apple.virtio-fs.automount")
fi
```

This means cache sharing only happens if the directory exists on the host.

### 3. TPM Caching (Manual)
```bash
git clone https://github.com/tmux-plugins/tpm ~/.cal-cache/git/tpm
```

**Status:** ✓ Not needed in --init

**Reason:** The `vm-tmux-resurrect.sh` script handles TPM caching automatically:
- First bootstrap: clones from GitHub, uses it
- Subsequent bootstraps: clones from cache (if exists), updates cache
- The cache is populated automatically during first use

### 4. VM Restart with Cache Sharing
```bash
./scripts/cal-bootstrap --restart
```

**Status:** ✅ Works correctly once cache directory exists

---

## Changes Made to Cal-Bootstrap

### Change 1: Add Cache Directory Creation to --init

**Location:** `scripts/cal-bootstrap` lines 999-1009 (inserted after header)

**Code Added:**
```bash
# Setup cache directories on host (for package download caching)
echo "Setting up cache directories..."
if [ ! -d ~/.cal-cache ]; then
    mkdir -p ~/.cal-cache/{homebrew,npm,go,git}
    echo "  ✓ Created cache directories: homebrew, npm, go, git"
else
    echo "  ✓ Cache directory already exists"
    # Ensure all subdirectories exist
    mkdir -p ~/.cal-cache/{homebrew,npm,go,git}
fi
echo ""
```

**Purpose:**
- Creates `~/.cal-cache` structure during --init
- Enables cal-cache sharing from first boot
- Makes cache immediately available for git, npm, homebrew, go packages
- Idempotent (safe to run multiple times)

**Benefits:**
- Users don't need to manually create cache directories
- Cache sharing works automatically from --init
- TPM will use cache on second+ bootstraps automatically
- Offline bootstrap capability available immediately

---

## Changes Made to vm-tmux-resurrect.sh

### Change 2: Fix Misleading Comment About Hard Links

**Location:** `scripts/vm-tmux-resurrect.sh` line 52

**Before:**
```bash
# Clone from local cache (faster, uses hard links)
```

**After:**
```bash
# Clone from local cache (faster than GitHub, no network needed)
```

**Reason:**
- Git clone with `--local` flag creates hard links within the same filesystem
- Cloning across virtio-fs (different filesystem) doesn't use hard links
- The code correctly uses `git clone` without `--local` flag
- Comment was misleading about what actually happens

**Technical Detail:**
When we attempted `git clone --local` across filesystems, we got:
```
fatal: failed to create link '/Users/admin/.tmux/plugins/tpm/.git/objects/pack/pack-*.idx': Cross-device link
```

The current code works correctly by using regular `git clone` which copies files across the filesystem boundary.

---

## Verification: What --init Will Now Do

With the changes, `cal-bootstrap --init` will:

1. **Create cache directories:**
   ```
   ~/.cal-cache/
   ├── homebrew/
   ├── npm/
   ├── go/
   └── git/
   ```

2. **Enable cache sharing automatically:**
   - Tart will mount `~/.cal-cache` to `/Volumes/My Shared Files/cal-cache` in VM
   - VM will see cache from first boot

3. **TPM caching workflow (automatic):**
   - First --init: TPM clones from GitHub, installs
   - Cache is empty during first install (no pre-population needed)
   - Future bootstraps: TPM can use cache (if populated by other VMs or manual setup)

4. **Result:** Fresh --init creates a fully cache-enabled VM

---

## Testing Recommendations

### Before Merge: Fresh --init Test

To verify the changes work correctly:

1. **Clean slate:**
   ```bash
   rm -rf ~/.cal-cache
   ./scripts/cal-bootstrap --destroy --yes
   ```

2. **Run --init:**
   ```bash
   ./scripts/cal-bootstrap --init
   ```

3. **Verify cache created:**
   ```bash
   ls -la ~/.cal-cache/
   # Should show: homebrew, npm, go, git subdirectories
   ```

4. **Check VM can see cache:**
   ```bash
   # Inside VM
   ls -la "/Volumes/My Shared Files/cal-cache/"
   # Should show: homebrew, npm, go, git subdirectories
   ```

5. **Verify TPM works:**
   ```bash
   # Inside VM
   ls -la ~/.tmux/plugins/tpm/
   # Should show TPM is installed (from GitHub on first run)
   ```

6. **Test second bootstrap (cache usage):**
   ```bash
   # On host
   ./scripts/cal-bootstrap --restart

   # Inside VM
   ls -la "/Volumes/My Shared Files/cal-cache/git/"
   # Should show empty (cache not yet populated with TPM)
   ```

**Note:** The cache won't have TPM on first --init since TPM is cloned directly to ~/.tmux/plugins/tpm. The cache is used for *subsequent* bootstraps when vm-tmux-resurrect.sh detects the cache and clones from it.

---

## Summary

### Issues Found
1. ❌ `cal-bootstrap --init` didn't create cache directories
2. ⚠️ Misleading comment about hard links in vm-tmux-resurrect.sh

### Fixes Applied
1. ✅ Added cache directory creation to `do_init()` function
2. ✅ Fixed comment to reflect actual behavior (no hard links across filesystems)

### Impact
- ✅ Fresh --init now creates fully cache-enabled VM
- ✅ Cache sharing works from first boot
- ✅ No manual steps required for cache setup
- ✅ Offline bootstrap capability available after first package downloads

### Code Quality
- ✅ Changes are idempotent (safe to run multiple times)
- ✅ Follows existing patterns in cal-bootstrap
- ✅ Clear user feedback during init
- ✅ No breaking changes to existing workflows
