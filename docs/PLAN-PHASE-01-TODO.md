# Phase 1 (CLI Foundation) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Replace manual Tart commands with `cal isolation` CLI.

**Deliverable:** Working `cal isolation` CLI that wraps Tart operations.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) § Phase 1 Readiness for complete operational requirements.

---

## 1.1 **REFINED:** Package Download Caching **HIGHEST PRIORITY**

**Goal:** Cache all package downloads in host and pass through to VMs to avoid repeated downloads during development.

**Implementation Strategy:** Incremental rollout - implement one package manager at a time, starting with Homebrew (highest impact).

### Phase 1.1.1: Homebrew Cache (First Implementation) [PR #6 - VM integration added, needs review]

**Cache Location:**
- **Host:** `~/.cal-cache/homebrew/` (persistent across VM operations)
- **VM:** Symlink `~/.cal-cache/homebrew/` → `/Volumes/My Shared Files/cal-cache/homebrew/`
- **Pattern:** Same as Tart cache sharing in section 1.9 (proven approach)

**Implementation Details:**

1. **Code Location:** `internal/isolation/cache.go`
   - New `CacheManager` struct with methods for setup, status
   - Integration point: Called from VM init/setup process
   - Follows existing isolation subsystem patterns

2. **Host Cache Setup:**
   - Create `~/.cal-cache/homebrew/` on host if doesn't exist
   - No host environment configuration needed (host uses default Homebrew cache)
   - Host directory structure: `~/.cal-cache/homebrew/downloads/`, `~/.cal-cache/homebrew/Cask/`

3. **VM Cache Passthrough (Symlink Approach):**
   - Create Tart shared directory: Ensure `/Volumes/My Shared Files/cal-cache/` exists
   - Copy host cache to shared volume: `rsync -a ~/.cal-cache/homebrew/ "/Volumes/My Shared Files/cal-cache/homebrew/"`
   - Create symlink in VM: `ln -sf "/Volumes/My Shared Files/cal-cache/homebrew" ~/.cal-cache/homebrew`
   - Configure in VM: `export HOMEBREW_CACHE=~/.cal-cache/homebrew` (add to `.zshrc`)
   - Verify symlink writable from VM

4. **Error Handling (Graceful Degradation):**
   - If symlink creation fails: Log warning, continue without cache
   - If shared volume unavailable: Log warning, continue without cache
   - Bootstrap still works, just slower (no hard failure)
   - Consistent with Tart cache sharing pattern in section 1.9

5. **Cache Status Command:** `cal cache status`
   - Display information:
     - Cache sizes per package manager (e.g., "Homebrew: 450 MB")
     - Cache location path (e.g., "~/.cal-cache/homebrew/")
     - Cache availability status (✓ Homebrew cache ready, ✗ npm cache not configured)
     - Last access time (from filesystem mtime)
   - Output format: Human-readable table or list
   - Implementation: `internal/isolation/cache.go` → `Status()` method

6. **Cache Invalidation Strategy:**
   - **Let package managers handle it** - no manual invalidation logic
   - Homebrew validates cache integrity and checksums automatically
   - Invalid or outdated cache entries are re-downloaded by Homebrew
   - Simplest approach: just set `HOMEBREW_CACHE` and let Homebrew manage lifetime

**Benefits:**

- **Speed:** Saves ~5-10 minutes per bootstrap (biggest single win)
- **Reliability:** Reduces network dependency, fewer timeout failures
- **Bandwidth:** Saves hundreds of MB per bootstrap iteration
- **Development:** Faster snapshot/restore testing cycles

**Constraints:**

- Requires Tart shared directories feature (graceful degradation if unavailable)
- Disk space: ~500-800 MB for Homebrew cache
- Cache persists across VM operations (intended behavior)

**Testing Strategy:**

- **Unit Tests:** Cache setup logic, symlink creation, graceful degradation paths
- **Integration Tests (with mocks):** Mock filesystem operations, verify environment configuration
- **Manual Testing:**
  - First bootstrap: Download everything, populate cache
  - Second bootstrap: Verify cache used, measure time improvement
  - Snapshot/restore: Verify cache persists and remains functional
  - Symlink failure: Verify graceful degradation (bootstrap completes without cache)

**Acceptance Criteria (Phase 1.1.1 - Homebrew Only):**

- Homebrew cache directory created on host
- Symlink created in VM pointing to shared cache
- `HOMEBREW_CACHE` environment variable set in VM
- `cal cache status` shows Homebrew cache info (size, location, availability, last access)
- Bootstrap time reduced by at least 30% on second run (Homebrew portion)
- Graceful degradation works if symlink fails
- Unit and integration tests pass
- Documentation updated in ADR-002

**Related:**
- Section 1.9: VM lifecycle automation (Tart cache sharing pattern reference)
- BUG-006: Network timeout during bootstrap (Homebrew cache will help prevent)

---

### Phase 1.1.2: **REFINED:** npm Cache [Depends on 1.1.1 PR]

**Dependencies:** Phase 1.1.1 (Homebrew cache) must be complete first.

**Cache Location:**
- **Host:** `~/.cal-cache/npm/` (persistent across VM operations)
- **VM:** Symlink `~/.cal-cache/npm/` → `/Volumes/My Shared Files/cal-cache/npm/`
- **Pattern:** Same as Phase 1.1.1 (proven approach)

**Implementation Details:**

1. **Code Location:** `internal/isolation/cache.go` (extend existing `CacheManager`)
   - Add npm-specific setup method
   - Integrate into VM init/setup process

2. **Host Cache Setup:**
   - Create `~/.cal-cache/npm/` on host if doesn't exist
   - No host environment configuration needed

3. **VM Cache Passthrough:**
   - Create Tart shared directory: `/Volumes/My Shared Files/cal-cache/npm/`
   - Copy host cache: `rsync -a ~/.cal-cache/npm/ "/Volumes/My Shared Files/cal-cache/npm/"`
   - Create symlink in VM: `ln -sf "/Volumes/My Shared Files/cal-cache/npm" ~/.cal-cache/npm`
   - Configure in VM: `npm config set cache ~/.cal-cache/npm` (run during vm-setup.sh)
   - Verify symlink writable

4. **Error Handling:** Graceful degradation (same as Phase 1.1.1)

5. **Cache Status:** Update `cal cache status` to include npm cache info

6. **Cache Invalidation:** Let npm handle it (validates cache metadata automatically)

**Benefits:**
- **Speed:** Saves ~2-3 minutes per bootstrap
- **Bandwidth:** Saves ~50-100 MB per bootstrap
- **Packages:** claude, agent, ccs, codex CLI tools

**Constraints:**
- Disk space: ~100-200 MB for npm cache

**Testing Strategy:**
- Unit tests for npm cache setup logic
- Integration tests with mocks
- Manual: Bootstrap twice, verify npm uses cache

**Acceptance Criteria:**
- npm cache directory created on host
- Symlink created in VM
- `npm config get cache` returns `~/.cal-cache/npm` in VM
- `cal cache status` shows npm cache info
- Bootstrap time reduced by additional 15-20% with npm cache
- Graceful degradation works
- Tests pass

---

### Phase 1.1.3: **REFINED:** Go Modules Cache

**Dependencies:** Phase 1.1.2 (npm cache) must be complete first.

**Cache Location:**
- **Host:** `~/.cal-cache/go/pkg/mod/` (persistent across VM operations)
- **VM:** Symlink `~/.cal-cache/go/` → `/Volumes/My Shared Files/cal-cache/go/`
- **Pattern:** Same as Phases 1.1.1 and 1.1.2

**Implementation Details:**

1. **Code Location:** `internal/isolation/cache.go` (extend existing `CacheManager`)
   - Add Go-specific setup method

2. **Host Cache Setup:**
   - Create `~/.cal-cache/go/pkg/mod/` on host if doesn't exist
   - Create `~/.cal-cache/go/pkg/sumdb/` for checksum database

3. **VM Cache Passthrough:**
   - Create Tart shared directory: `/Volumes/My Shared Files/cal-cache/go/`
   - Copy host cache: `rsync -a ~/.cal-cache/go/ "/Volumes/My Shared Files/cal-cache/go/"`
   - Create symlink in VM: `ln -sf "/Volumes/My Shared Files/cal-cache/go" ~/.cal-cache/go`
   - Configure in VM: `export GOMODCACHE=~/.cal-cache/go/pkg/mod` (add to `.zshrc`)
   - Verify symlink writable

4. **Error Handling:** Graceful degradation (same as previous phases)

5. **Cache Status:** Update `cal cache status` to include Go cache info

6. **Cache Invalidation:** Let Go handle it (uses `go.sum` checksums for validation)

**Benefits:**
- **Speed:** Saves ~1-2 minutes per bootstrap
- **Bandwidth:** Saves ~20-50 MB per bootstrap
- **Modules:** staticcheck, goimports, delve, mockgen, air

**Constraints:**
- Disk space: ~50-150 MB for Go module cache

**Testing Strategy:**
- Unit tests for Go cache setup logic
- Integration tests with mocks
- Manual: Bootstrap twice, verify Go uses cache

**Acceptance Criteria:**
- Go cache directory created on host
- Symlink created in VM
- `go env GOMODCACHE` returns `~/.cal-cache/go/pkg/mod` in VM
- `cal cache status` shows Go cache info
- Bootstrap time reduced by additional 10-15% with Go cache
- Graceful degradation works
- Tests pass

---

### Phase 1.1.4: **REFINED:** Git Clones Cache

**Dependencies:** Phase 1.1.3 (Go modules cache) must be complete first.

**Cache Location:**
- **Host:** `~/.cal-cache/git/<repo-name>/` (persistent across VM operations)
- **VM:** Symlink per repository to `/Volumes/My Shared Files/cal-cache/git/<repo-name>/`
- **Pattern:** Selective caching for frequently cloned repos

**Implementation Details:**

1. **Code Location:** `internal/isolation/cache.go` (extend existing `CacheManager`)
   - Add git clone caching method
   - Maintain list of cached repos

2. **Host Cache Setup:**
   - Create `~/.cal-cache/git/` on host if doesn't exist
   - Cache TPM (already implemented in vm-setup.sh as reference)
   - Identify other frequently cloned repos during bootstrap

3. **VM Cache Passthrough:**
   - Create Tart shared directory: `/Volumes/My Shared Files/cal-cache/git/`
   - For each cached repo:
     - Copy to shared volume: `rsync -a ~/.cal-cache/git/tpm/ "/Volumes/My Shared Files/cal-cache/git/tpm/"`
     - Clone from cache instead of GitHub: `git clone /Volumes/My Shared Files/cal-cache/git/tpm ~/.tmux/plugins/tpm`
   - Update cached repos: `git -C <cache-path> fetch --all` before each use

4. **Error Handling:** Graceful degradation - if cache missing, clone from GitHub normally

5. **Cache Status:** Update `cal cache status` to show cached git repos and their update status

6. **Cache Invalidation:** Update cache repos via `git fetch` before each bootstrap

**Benefits:**
- **Speed:** Saves ~30-60 seconds per bootstrap (depends on repos)
- **Reliability:** Works offline after first bootstrap
- **Repos:** TPM (tmux-plugins/tpm), potentially others identified during testing

**Constraints:**
- Disk space: ~10-50 MB per cached repo
- Need to keep cache updated with `git fetch`

**Testing Strategy:**
- Unit tests for git clone caching logic
- Integration tests with mocks
- Manual: Bootstrap with/without network, verify cache works offline

**Acceptance Criteria:**
- Git cache directory created on host
- TPM cached and used during bootstrap
- Cache updated with `git fetch` before use
- `cal cache status` shows cached git repos
- Bootstrap works offline with cached repos
- Graceful degradation works if cache unavailable
- Tests pass

---

### Phase 1.1.5: **REFINED:** Cache Clear Command

**Dependencies:** Phases 1.1.1-1.1.4 must be complete first (all caches implemented).

**Command:** `cal cache clear`

**Implementation Details:**

1. **Code Location:** `internal/isolation/cache.go` (extend existing `CacheManager`)
   - Add `Clear()` method with per-cache confirmation

2. **Behavior:**
   - Prompt user to confirm clearing each cache type individually
   - Example flow:
     ```
     Clear Homebrew cache (450 MB)? [y/N]: y
     Clearing Homebrew cache...
     Clear npm cache (120 MB)? [y/N]: n
     Skipping npm cache
     Clear Go modules cache (80 MB)? [y/N]: y
     Clearing Go modules cache...
     Clear git clones cache (25 MB)? [y/N]: y
     Clearing git clones cache...

     Summary: Cleared 555 MB (3/4 caches)
     ```

3. **Implementation:**
   - For each cache type (Homebrew, npm, Go, Git):
     - Calculate cache size: `du -sh <cache-dir>`
     - Prompt user: `Clear <type> cache (<size>)? [y/N]:`
     - If confirmed: `rm -rf <cache-dir>` and recreate empty directory
     - Track cleared caches for summary
   - Display summary of total space freed

4. **Flags:**
   - `--all` or `-a`: Clear all caches without prompting (dangerous)
   - `--dry-run`: Show what would be cleared without actually clearing

5. **Safety:**
   - Default to "No" for each prompt (require explicit "y")
   - Warn if clearing will slow down next bootstrap
   - Suggest alternatives: "Consider clearing individual caches if low on disk space"

**Benefits:**
- **Disk Management:** Users can reclaim 1-2 GB when needed
- **Troubleshooting:** Clear corrupted caches
- **Flexibility:** Per-cache granularity with confirmation

**Constraints:**
- Clearing cache means next bootstrap will be slow again
- No undo (must re-download everything)

**Testing Strategy:**
- Unit tests for clear logic with mocks
- Integration tests for confirmation prompts
- Manual: Test clearing each cache individually and all together

**Acceptance Criteria:**
- `cal cache clear` prompts for each cache individually
- Each cache cleared only after user confirms "y"
- Summary shows total space freed
- `--all` flag clears all without prompting
- `--dry-run` shows what would be cleared
- Graceful handling if cache doesn't exist
- Tests pass

---

---

## 1.4 Snapshot Management

**File:** `internal/isolation/snapshot.go`

**Tasks:**
1. Implement `SnapshotManager` struct
2. Methods:
   - `Create(name)` - create snapshot via `tart clone` (stop VM first)
   - `Restore(name)` - restore from snapshot (check git, delete cal-dev, clone)
   - `List()` - list snapshots with sizes (JSON format)
   - `Delete(names, force)` - delete one or more snapshots
   - `Cleanup(olderThan, autoOnly)` - cleanup old snapshots
3. Auto-snapshot on session start (configurable)
4. Snapshot naming: user-provided exact names (no prefix)

**Key learnings from Phase 0 (ADR-002):**
- Tart "snapshots" are actually clones (copy-on-write)
- Restore must work even if cal-dev doesn't exist (create from snapshot)
- Delete supports multiple VM names in one command
- `--force` flag skips git checks and avoids booting VM (for unresponsive VMs)
- Git safety checks must run before restore and delete (see 1.7)
- Don't stop a running VM before git check - use it while running
- Snapshot names are case-sensitive, no prefix required

---

## 1.5 SSH Management

**File:** `internal/isolation/ssh.go`

**Tasks:**
1. Implement `SSHClient` struct using `golang.org/x/crypto/ssh`
2. Methods:
   - `Connect(host, user, keyPath)` - establish connection (key-based auth)
   - `ConnectPassword(host, user, password)` - password auth (initial setup)
   - `Run(command)` - execute command
   - `Shell()` - interactive shell via tmux-wrapper.sh
   - `CopyFiles(localPaths, remotePath)` - SCP equivalent
   - `Close()` - close connection
3. Connection retry logic (VM may be booting, up to 60s)
4. Key setup automation (generate ed25519, copy to VM)

**Key learnings from Phase 0 (ADR-002):**
- SSH key auth preferred after initial setup (password for bootstrap only)
- Default credentials: admin/admin
- SSH options for automation: `StrictHostKeyChecking=no`, `UserKnownHostsFile=/dev/null`, `ConnectTimeout=2`, `BatchMode=yes`
- tmux sessions via `~/scripts/tmux-wrapper.sh new-session -A -s cal`
- TERM handling: never set TERM explicitly in command environment (opencode hangs). Use tmux-wrapper.sh which sets TERM in script environment
- Helper script deployment: copy vm-setup.sh, vm-auth.sh, vm-first-run.sh, tmux-wrapper.sh to ~/scripts/
- Must check scp exit codes for all file copy operations

**Conditional tmux auto-restore (from Phase 0.11):**
- Check `~/.cal-first-run` flag before starting tmux
- If flag exists: use `tmux new-session -s cal` (fresh session, no auto-restore)
- If flag absent: use `tmux new-session -A -s cal` (attach existing or create with auto-restore)
- This prevents vm-auth authentication screen from appearing inside restored tmux session on first boot
- Flag check must happen in `cal isolation start`, `cal isolation init`, and `cal isolation restart`

---

## 1.6 CLI Commands (Cobra)

**File:** `cmd/cal/main.go` + `cmd/cal/isolation.go`

**Tasks:**
1. Root command `cal`
2. Subcommand group `cal isolation` (alias: `cal iso`)
3. Implement commands (mapped from cal-bootstrap per ADR-002):

| Command | Maps from | Description |
|---------|-----------|-------------|
| `cal isolation init [--proxy auto\|on\|off] [--yes]` | `cal-bootstrap --init` | Full VM creation and setup |
| `cal isolation start [--headless]` | `cal-bootstrap --run` | Start VM and SSH in with tmux |
| `cal isolation stop [--force]` | `cal-bootstrap --stop` | Stop cal-dev |
| `cal isolation restart` | `cal-bootstrap --restart` | Restart VM and reconnect |
| `cal isolation gui` | `cal-bootstrap --gui` | Launch with VNC experimental mode |
| `cal isolation ssh [command]` | Direct SSH | Run command or interactive shell |
| `cal isolation status` | `cal-bootstrap --status` | Show VM state, IP, size, and context-appropriate commands |
| `cal isolation destroy` | N/A | Delete VMs with safety checks |
| `cal isolation snapshot list` | `cal-bootstrap -S list` | List snapshots with sizes |
| `cal isolation snapshot create <name>` | `cal-bootstrap -S create` | Create snapshot |
| `cal isolation snapshot restore <name>` | `cal-bootstrap -S restore` | Restore snapshot (git safety) |
| `cal isolation snapshot delete <names...> [--force]` | `cal-bootstrap -S delete` | Delete snapshots |
| `cal isolation rollback` | N/A | Restore to session start |

4. Global flags: `--yes` / `-y` (skip confirmations), `--proxy auto|on|off`, `--clean` (force full script deployment)

---

## 1.7 Git Safety Checks

**File:** `internal/isolation/safety.go`

**Tasks:**
1. Implement reusable `CheckGitChanges(sshClient)` function
2. Scan VM directories for uncommitted/unpushed changes:
   - `~/workspace`, `~/projects`, `~/repos`, `~/code`
   - `~` (home directory, depth 2 only)
3. Display warnings with affected repository paths
4. Prompt for confirmation before destructive operations
5. Integration points:
   - `cal isolation init` (before deleting existing VMs)
   - `cal isolation snapshot restore` (before replacing cal-dev, skip if cal-dev doesn't exist)
   - `cal isolation snapshot delete` (before deleting, skip with `--force`)
   - `cal isolation destroy` (before deleting)

**Key learnings from Phase 0 (ADR-002):**
- Start VM if not running to perform check via SSH, stop after if it wasn't running before
- Unpushed commit detection requires upstream tracking (`git branch -u origin/main`)
- Use `git status --porcelain` for uncommitted changes
- Use `git log @{u}.. --oneline` for unpushed commits
- `--force` flag on delete skips git checks entirely (for unresponsive VMs)
- Single confirmation prompt per operation (avoid double/triple prompts)

---

## 1.8 Proxy Management

**File:** `internal/isolation/proxy.go`

**Tasks:**
1. Implement proxy mode management (auto, on, off)
2. Network connectivity testing (`curl -s --connect-timeout 2 -I https://github.com`)
3. Bootstrap SOCKS proxy (SSH -D 1080) for init phase before sshuttle installed
4. sshuttle transparent proxy lifecycle (start, stop, restart, status)
5. VM→Host SSH key setup for proxy
6. Proxy auto-start on shell initialization

**Key learnings from Phase 0 (ADR-002):**
- Bootstrap proxy solves chicken-and-egg: need network to install sshuttle
- Use `socks5h://` (not `socks5://`) for DNS resolution through proxy
- sshuttle excludes: `-x HOST_GATEWAY/32 -x 192.168.64.0/24`
- Host requirements: SSH server enabled, Python installed
- Auto-start errors suppressed to avoid spamming shell startup
- Proxy config stored in `~/.cal-proxy-config`
- Proxy logs in `~/.cal-proxy.log`, PID in `~/.cal-proxy.pid`

---

## 1.9 VM Lifecycle Automation

**Tasks:**
1. Keychain auto-unlock setup during init
   - Save VM password to `~/.cal-vm-config` (mode 600)
   - Configure `.zshrc` keychain unlock block
   - `CAL_SESSION_INITIALIZED` guard to prevent re-execution on logout cancel
2. First-run flag system
   - `~/.cal-auth-needed` flag triggers vm-auth.sh during init
   - `~/.cal-first-run` flag triggers vm-first-run.sh after restore
   - Call `sync` after creating flag files (filesystem sync timing)
3. Logout git status check
   - Configure `~/.zlogout` to scan ~/code for uncommitted/unpushed changes
   - Cancel logout starts new login shell with session flag preserved
4. Tmux session persistence on logout
   - Add tmux session save to `~/.zlogout` hook (before git status check)
   - Run `tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh` on logout
   - Ensures session state is captured even between auto-save intervals
5. VM detection setup
   - Create `~/.cal-vm-info` with VM metadata
   - Add `CAL_VM=true` to `.zshrc`
   - Install helper functions (`is-cal-vm`, `cal-vm-info`)
6. Tart cache sharing setup
   - Create symlink `~/.tart/cache -> /Volumes/My Shared Files/tart-cache`
   - Idempotent (safe to run multiple times)
   - Graceful degradation if sharing not available

**Key learnings from Phase 0 (ADR-002):**
- First-run flag reliability: set in cal-dev (running, known IP) → clone to cal-init → remove from cal-dev
- Session guard (`CAL_SESSION_INITIALIZED`) persists through `exec zsh -l` (environment variable)
- vm-first-run.sh only checks for updates, doesn't auto-pull (avoids surprise merge conflicts)

**Key learnings from Phase 0.11 (Tmux Session Persistence):**
- Session name must be `cal` (not `cal-dev`) for `cal isolation` commands
- Auto-restore on tmux start via tmux-continuum (no manual intervention needed)
- Auto-save every 15 minutes via tmux-continuum, plus manual save on logout
- Pane contents (scrollback) preserved with 50,000 line limit
- Resurrect data stored in `~/.local/share/tmux/resurrect/` (tmux-resurrect default) — survives VM restarts and snapshot/restore
- Manual save (`Ctrl+b Ctrl+s`) runs silently without confirmation message
- Manual restore keybinding: `Ctrl+b Ctrl+r`

---

## 1.10 Helper Script Deployment

**Tasks:**
1. Deploy helper scripts to VM `~/scripts/` directory (idempotent)
2. Scripts to deploy:
   - `vm-setup.sh` - Tool installation and configuration (calls vm-tmux-resurrect.sh during --init)
   - `vm-auth.sh` - Interactive agent authentication
   - `vm-first-run.sh` - Post-restore repository update checker
   - `tmux-wrapper.sh` - TERM compatibility wrapper for tmux
   - `vm-tmux-resurrect.sh` - Tmux session persistence setup (Phase 0.11)
3. Deploy comprehensive tmux.conf with:
   - **PATH environment for plugin scripts** (required for tmux-resurrect - see note below)
   - **Conditional TPM loading based on first-run flag** (prevents auth screen capture)
   - Session persistence via tmux-resurrect and tmux-continuum plugins
   - Auto-save every 15 minutes, auto-restore on tmux start
   - Pane contents (scrollback) capture with 50,000 line limit
   - Client-detached hook for save on `Ctrl+b d`
   - Keybindings: `Ctrl+b R` reload config, `Ctrl+b r` resize pane to 67%
   - Split bindings: `Ctrl+b |` horizontal, `Ctrl+b -` vertical
4. Add `~/scripts` to PATH in `.zshrc`
5. Verify deployment after SCP (check exit codes)
6. **Implement checksum-based deployment optimization:**
   - Compare MD5 checksums between host and VM scripts before copying
   - Only copy scripts that are new or changed (skip unchanged)
   - Visual feedback: `↻` (unchanged/skipped), `↑` (updated), `+` (new)
   - `--clean` flag forces full deployment (bypasses checksum optimization)
   - Saves ~2 seconds per `--run`/`--restart` when scripts are current

**Key learnings from Phase 0.11 (Tmux Session Persistence):**
- vm-tmux-resurrect.sh installs tmux-resurrect and tmux-continuum plugins via TPM
- Must be integrated into vm-setup.sh `--init` path for fresh installations
- tmux.conf is the single source for all tmux configuration and keybindings
- Session name `cal` used by `tmux-wrapper.sh new-session -A -s cal`
- Session data stored in `~/.local/share/tmux/resurrect/` (tmux-resurrect default location)
- Manual save (`Ctrl+b Ctrl+s`) runs silently; manual restore (`Ctrl+b Ctrl+r`)
- **Mouse mode must be enabled by default** (`set -g mouse on`) for tmux right-click menu functionality
  - `mouse on` = tmux context menu (Swap, Kill, Respawn, Mark, Rename, etc.)
  - `mouse off` = terminal app menu (Copy, Paste, Split, etc.)
  - See BUG-004 for regression details

**Critical: PATH requirement for tmux-resurrect (BUG-005):**
- tmux-resurrect scripts run via `tmux run-shell` which has minimal PATH (`/usr/bin:/bin:/usr/sbin:/sbin`)
- This PATH doesn't include Homebrew directories where tmux is installed (`/opt/homebrew/bin`)
- Without proper PATH, save files contain only "state state state" instead of actual session data
- **Solution:** Add `set-environment -g PATH` in tmux.conf to include Homebrew paths
- Example: `set-environment -g PATH "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"`

**TPM installation reliability (BUG-006):**
- TPM (Tmux Plugin Manager) installation can fail due to network issues
- **Solution:** Implement retry logic with 3 attempts and 5-second delay between retries
- Cache cloned TPM repository (`~/.tmux/plugins/tpm`) for reuse
- Clear error messages if all attempts fail
- Explicit cleanup on init failure (delete cal-dev to allow clean retry)

**Conditional TPM loading for first-run:**
- TPM must NOT load during first-run (while `~/.cal-first-run` flag exists)
- Prevents tmux-resurrect from capturing the vm-auth authentication screen
- Use conditional in tmux.conf: `if-shell '[ ! -f ~/.cal-first-run ]' 'run ~/.tmux/plugins/tpm/tpm'`
- After first-run completes and flag is removed, session persistence works normally

---

## 1.11 Configuration Enhancements (Future)

**Tasks (deferred to future phases):**
1. **Interactive config fixing** - When validation fails, prompt user to fix config interactively
   - Detect invalid values and offer to correct them on the spot
   - Show valid ranges and let user enter new value
   - Write corrected config back to file
2. **Environment variable overrides** - Support env vars overriding config values
   - Example: `CAL_VM_CPU=8 cal isolation init` overrides config CPU setting
   - Follow 12-factor app pattern for configuration hierarchy
   - Priority: env vars > per-VM config > global config > defaults
3. **Config validation command** - `cal config validate` to check config without running
   - Parse and validate config files
   - Report all errors (don't stop at first error)
   - Exit 0 if valid, non-zero if invalid
4. **Config schema migration** - Strategy for handling config version changes
   - Detect old config versions and migrate automatically
   - Backup old config before migration
   - Clear migration messages to user
5. **Default values documentation** - `cal config show --defaults` flag
   - Display hard-coded default values
   - Help users understand what they get without a config file
   - Show which values are from defaults vs. config files
6. **Tmux session save feedback** - Improve discoverability of tmux-resurrect functionality
   - Current: `Ctrl+b Ctrl+s` saves silently with no confirmation
   - Enhancement: Display brief confirmation message when session is saved
   - Consider: `tmux display-message "Session saved to ~/.local/share/tmux/resurrect/"` after save
   - Also consider: Status bar indicator showing last save time
   - Trade-off: More feedback vs. silent operation preference

**Notes:**
- These enhancements improve UX but are not critical for Phase 1 functionality
- Can be prioritized based on user feedback after Phase 1 completion
- Interactive fixing and env var overrides are most valuable for daily use
- Tmux save feedback is low priority (auto-save works, manual save is advanced feature)

---

## Testing Requirements

**Unit Tests:**
- Configuration parsing and validation
- Tart command generation
- SSH command building
- Git safety check logic
- Proxy mode detection

**Integration Tests:**
- VM lifecycle (create, start, stop, delete)
- Snapshot operations (create, restore, list, delete)
- SSH connectivity and command execution
- SCP file transfer
- Git change detection in VM

**Key testing lessons from Phase 0 (ADR-002):**
- BSD awk incompatibility: test on macOS, not just Linux
- `shift || true` errors in zsh: use `[[ $# -gt 0 ]] && shift`
- Double/triple confirmation prompts: ensure single prompt per operation
- scp error handling: always check exit codes
- Filesystem sync: flag files need `sync` before VM reboot
- macOS `timeout` command unavailable: use built-in timeouts

**Additional testing lessons from Phase 0.11 (ADR-002):**
- **tmux-resurrect PATH:** Scripts run via `tmux run-shell` have minimal PATH - must set `set-environment -g PATH` in tmux.conf to include Homebrew directories
- **TPM installation network failures:** Use retry logic (3 attempts, 5s delay) with caching for reliability; clear error messages on failure
- **First-run flag and session restore:** Must check flag before tmux start; use `-A` flag only when flag absent to prevent auth screen in restored session
- **Arithmetic in set -e:** `((counter++))` fails with `set -e` - use `counter=$((counter + 1))` instead
- **Tmux capturing auth screen:** Conditionally load TPM only after first-run completes; clear session data after auth if needed
