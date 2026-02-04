# ADR-003: Package Download Caching

## Host-to-VM Cache Sharing for Package Managers

**ADR:** 003
**Status:** Accepted
**Created:** 2026-02-03
**Purpose:** Cache package downloads on the host and share them with VMs via Tart directory mounts to eliminate redundant downloads during bootstrap

---

## Context

CAL's bootstrap process (`cal-bootstrap --init`) creates a fresh VM from a base image and installs all required tools: Homebrew packages, npm CLI tools, Go modules, and git repositories (e.g., TPM for tmux plugins). Each `--init` downloads hundreds of megabytes from the internet, taking 5-10 minutes even on a fast connection.

During development, `--init` runs frequently (testing changes, recovering from broken VMs, creating snapshots). Repeated downloads waste time, bandwidth, and introduce failure points from network timeouts.

The three-tier VM architecture (cal-clean -> cal-dev -> cal-init) means that every `--init` starts from a pristine base, so no package state carries over between invocations.

---

## Decision

We implement a host-persistent cache at `~/.cal-cache/` shared with VMs via Tart's virtio-fs directory mount. Each package manager gets its own subdirectory, and VMs access the cache through symlinks to the Tart mount point.

### Architecture

```
Host Machine                              VM (cal-dev)
~/.cal-cache/                             /Volumes/My Shared Files/cal-cache/
├── homebrew/                             (Tart virtio-fs mount, read-write)
│   ├── downloads/                                    |
│   └── Cask/                                         v
├── npm/                                  ~/.cal-cache/
├── go/                                   ├── homebrew -> /Volumes/My Shared Files/cal-cache/homebrew
│   └── pkg/                              ├── npm -> /Volumes/My Shared Files/cal-cache/npm
│       ├── mod/                          ├── go -> /Volumes/My Shared Files/cal-cache/go
│       └── sumdb/                        └── git -> /Volumes/My Shared Files/cal-cache/git
└── git/
    └── tpm/
```

### Tart Mount Specification

```
--dir cal-cache:${HOME}/.cal-cache:rw,tag=com.apple.virtio-fs.automount
```

- **Label:** `cal-cache`
- **Host path:** `~/.cal-cache`
- **Mode:** Read-write (both host and VM can populate cache)
- **Filesystem:** virtio-fs with automount tag

### Cache Types

| Cache | Host Path | VM Environment | Packages |
|-------|-----------|----------------|----------|
| Homebrew | `~/.cal-cache/homebrew/` | `HOMEBREW_CACHE` | sshuttle, python, git, etc. |
| npm | `~/.cal-cache/npm/` | `npm config set cache` | claude, ccs, codex CLI tools |
| Go modules | `~/.cal-cache/go/` | `GOMODCACHE` | staticcheck, goimports, delve |
| Git clones | `~/.cal-cache/git/` | Direct path reference | TPM (tmux plugin manager) |

---

## Implementation

### Go Code

**File:** `internal/isolation/cache.go`

The `CacheManager` struct provides methods for each cache type:

- **Host setup** (`Setup*Cache()`): Creates cache directories on the host. Called during `cal-bootstrap --init`.
- **VM setup** (`SetupVM*Cache()`): Returns shell commands to create symlinks and configure environment variables in the VM. Executed via SSH during vm-setup.sh.
- **Cache info** (`Get*CacheInfo()`): Returns path, size, availability, and last access time. Used by `cal cache status`.
- **Git operations** (`CacheGitRepo()`, `UpdateGitRepos()`): Clone repositories to cache and update with `git fetch --all`.

### Shell Integration

**cal-bootstrap (host side):**
- Sets cache environment variables temporarily during script execution (lines 43-49)
- Creates `~/.cal-cache/{homebrew,npm,go,git}` directories during `--init`
- Passes `--dir cal-cache:...` to all `tart run` invocations

**vm-setup.sh (VM side):**
- Detects shared cache at `/Volumes/My Shared Files/cal-cache/`
- Sets temporary environment variables for script execution
- Creates `~/.cal-cache/` symlinks to mount point
- Adds permanent exports to `~/.zshrc` (idempotent, checks before appending)
- Configures npm cache via `npm config set cache`

**vm-tmux-resurrect.sh:**
- Uses cached TPM from `~/.cal-cache/git/tpm/` when available
- Falls back to GitHub clone if cache unavailable

### CLI Command

```
$ cal cache status

Cache Status:

Homebrew:
  Location: /Users/admin/.cal-cache/homebrew
  Status: Ready
  Size: 1.5 GB
  Last access: 2026-02-03T12:34:56Z

npm:
  Location: /Users/admin/.cal-cache/npm
  Status: Ready
  Size: 256 MB

Go:
  Location: /Users/admin/.cal-cache/go
  Status: Ready
  Size: 512 MB

Git:
  Location: /Users/admin/.cal-cache/git
  Status: Ready
  Size: 38 MB
  Cached repos: 1
    - tpm
```

---

## Host vs VM Configuration Scope

A deliberate design decision separates host and VM cache configuration:

| Aspect | Host (cal-bootstrap) | VM (vm-setup.sh) |
|--------|---------------------|-------------------|
| **Scope** | Temporary (script execution only) | Permanent (`~/.zshrc`) |
| **Rationale** | Avoid unexpected changes to user's system | VM is isolated, controlled environment |
| **Effect** | Only CAL operations use cache | All VM package installs use cache |
| **User impact** | Normal `brew install` outside CAL uses default cache | Consistent cache behavior across all operations |

---

## Graceful Degradation

The cache system is designed to never block bootstrap:

1. **Missing home directory**: Warns to stderr, returns nil, continues
2. **Missing cache directory**: VM setup returns nil, package managers use defaults
3. **Unavailable Tart mount**: Symlink creation skipped, no cache sharing
4. **Corrupted cache entries**: Package managers validate integrity themselves (checksums, metadata)

Bootstrap always completes. Without cache, it downloads everything from the internet (slower but functional).

---

## Cache Invalidation

Each package manager handles its own cache validation:

- **Homebrew**: Validates checksums automatically; re-downloads invalid entries
- **npm**: Checks cache metadata; falls back to network on mismatch
- **Go**: Uses `go.sum` checksums; re-fetches on integrity failure
- **Git**: Repositories updated with `git fetch --all` before use

No custom invalidation logic is needed. The cache clear command (`cal cache clear`) provides manual cache management for troubleshooting or disk space recovery.

---

## Performance Impact

| Metric | First Bootstrap | Subsequent Bootstrap |
|--------|-----------------|---------------------|
| **Duration** | ~2-5 minutes (network download) | ~5-10 seconds (cache hits) |
| **Network** | ~250 MB downloaded | ~0 MB (offline capable) |
| **Per-run savings** | N/A | ~2-5 minutes |

After the first bootstrap populates the cache, subsequent runs are almost entirely local. The VM can bootstrap offline once all packages are cached.

---

## Testing

**Unit tests** (`internal/isolation/cache_test.go`, 1045 lines):
- Directory creation and idempotency
- Cache info retrieval (size, availability, modification time)
- VM command generation correctness
- Graceful degradation paths
- Mount specification format
- Git repository operations
- Byte formatting

**Manual testing** (documented in `docs/PR-9-TEST-RESULTS.md`):
- First bootstrap populates cache
- Second bootstrap uses cache (time reduction verified)
- Offline bootstrap works with populated cache
- Snapshot/restore preserves cache
- Graceful degradation when cache unavailable

---

## Implementation History

| PR | Cache Type | Merged |
|----|-----------|--------|
| #6 | Homebrew | 2026-02-03 |
| #7 | npm | 2026-02-03 |
| #8 | Go modules | 2026-02-03 |
| #9 | Git clones + full bootstrap integration | 2026-02-03 |

---

## Bug Fixes Post-Integration

Bugs discovered and resolved after the cache integration PRs (#6-#9) were merged on 2026-02-03. All fixes relate to bootstrap and VM lifecycle issues encountered during cache integration testing.

### BUG-008: Cursor agent command not found after --init

**Severity:** High | **Resolved:** 2026-02-04

Cursor CLI installed as `cursor-agent` but docs and verification referenced `agent`. Bootstrap reported `agent: not found` despite successful installation.

**Root Cause:** Homebrew Cask only installs the `cursor-agent` binary. No alias was created during bootstrap.

**Fix (4 iterations):**
1. Added `alias agent='cursor-agent'` to ~/.zshrc in vm-setup.sh
2. Sourced ~/.zshrc in vm-auth.sh to load alias during --init
3. Added error handling for .zshrc sourcing failures
4. **Final:** Create alias directly in vm-auth.sh (avoids sourcing side effects like early tmux-resurrect loading)

**Files:** `scripts/vm-setup.sh`, `scripts/vm-auth.sh`

### BUG-009: Repository clones lost during --init

**Severity:** High | **Resolved:** 2026-02-04

Repositories cloned during vm-auth (Step 9) were lost when cal-init snapshot was created. Silent data loss — no error messages.

**Root Cause:** cal-bootstrap stopped the VM immediately after vm-auth exited without flushing filesystem buffers. Clone data in write buffers was lost before snapshot creation.

**Fix:** Added explicit `sync && sleep 2` SSH call after vm-auth completes, before VM stop. Mirrors existing sync pattern used for flag files. Adds 2-3 seconds to --init for data integrity.

**Files:** `scripts/cal-bootstrap` (line ~1338)

### BUG-005 Edge Cases: tmux-resurrect Session Persistence

**Severity:** High | **Resolved:** 2026-02-04

Two edge cases discovered in the tmux-resurrect session persistence feature (originally resolved 2026-02-02 with PATH fix) during post-cache-integration testing.

**Edge Case 1: Auth screens captured during --init**

Save hooks ran unconditionally during --init, capturing authentication screens into session data. On first user login, stale auth prompts appeared instead of a clean shell.

- **Root Cause:** Save triggers (detach hook, logout hook) not gated by first-run flag
- **Fix:** Gate all save triggers on `~/.cal-first-run` flag. Architectural change: vm-auth.sh handles auth only, vm-first-run.sh enables persistence after first login
- **Commit:** `823059a`

**Edge Case 2: Stale state after --restart**

Detach with 3 windows, immediate --restart, only 2 windows restored. Most recent save was lost.

- **Root Cause:** Explicit save in cal-bootstrap used `tmux run-shell -b` (background) with 0.5s wait. VM stop killed the background save mid-write, corrupting the save file. Restore fell back to the previous (stale) save
- **Fix:** Removed explicit saves from --stop/--restart/--gui (detach hook already saves). Added 10-second delay before VM stop to let detach hook save complete
- **Commit:** `fc2a4a4`

**Files:** `scripts/cal-bootstrap`, `scripts/vm-tmux-resurrect.sh`, `scripts/vm-auth.sh`, `scripts/vm-first-run.sh`

### Additional Minor Fixes

| Commit | Fix |
|--------|-----|
| `7453dd0` | tmux-resurrect clearing: use `rm -rf` to delete subdirectories |
| `bf17a90` | Keep first-run flag until auth completes + fix Ctrl+C handling |
| `e7e2bef` | Clear tmux session data at end of vm-auth.sh |
| `2574804` | Move tmux session clearing to cal-bootstrap Step 10 |

### Summary

- **3 major bugs** resolved (BUG-005 edge cases, BUG-008, BUG-009)
- **4 minor fixes** for flag timing and cleanup
- **12 total commits** over 2026-02-04
- All bugs were Phase 0 (Bootstrap) issues affecting agent auth, data persistence, and session restore
- **No active bugs remaining** as of 2026-02-04

---

## Cache Clear Command

The `cal cache clear` command (implemented in PR #10) provides manual cache management:

```bash
# Interactive mode - prompts for each cache
cal cache clear

# Clear all caches without confirmation
cal cache clear --all

# Preview what would be cleared
cal cache clear --dry-run
```

**Features:**
- Per-cache confirmation prompts with size display
- Handles read-only Go module cache files automatically
- Recreates cache directories after clearing
- Summary of space freed and caches cleared
- Warnings about slower next bootstrap

---

## Future Work

- **Cache size monitoring**: Warn when cache exceeds configurable threshold
- **Additional git repositories**: Cache more frequently-cloned repos beyond TPM

---

## Related Documents

- [ADR-002](ADR-002-tart-vm-operational-guide.md) - Tart VM operational guide (Tart cache sharing pattern)
- [CACHE-INTEGRATION.md](../CACHE-INTEGRATION.md) - Detailed integration guide
- [PLAN-PHASE-01-TODO.md](../PLAN-PHASE-01-TODO.md) - Cache clear command TODO (1.1.5)
- [PLAN-PHASE-01-DONE.md](../PLAN-PHASE-01-DONE.md) - Completed cache PRs
