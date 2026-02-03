# Phase 1 (CLI Foundation) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Replace manual Tart commands with `cal isolation` CLI.

**Deliverable:** Working `cal isolation` CLI that wraps Tart operations.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) § Phase 1 Readiness for complete operational requirements.

---

## 1.1 Package Download Caching **HIGHEST PRIORITY**

**Goal:** Cache all package downloads in host and pass through to VMs to avoid repeated downloads during development.

**Scope:** Comprehensive caching for all package managers used during bootstrap.

**Cache Location:**
- **Host:** `~/.cal-cache/` (persistent across VM operations)
- **VM:** `~/.cal-cache/` (symlinked or mounted from host via Tart shared directories)

**Package Managers to Cache:**

1. **Homebrew** (biggest win)
   - Location: `~/.cal-cache/homebrew/`
   - Configure: `export HOMEBREW_CACHE=~/.cal-cache/homebrew`
   - Caches: Bottles (precompiled binaries), downloads, formula sources
   - Impact: Saves ~5-10 minutes per bootstrap, hundreds of MB of downloads

2. **npm** 
   - Location: `~/.cal-cache/npm/`
   - Configure: `npm config set cache ~/.cal-cache/npm`
   - Caches: Packages for claude, agent, ccs, codex
   - Impact: Saves ~2-3 minutes per bootstrap

3. **Go modules**
   - Location: `~/.cal-cache/go/pkg/mod/`
   - Configure: `export GOMODCACHE=~/.cal-cache/go/pkg/mod`
   - Caches: Modules for staticcheck, goimports, delve, mockgen, air
   - Impact: Saves ~1-2 minutes per bootstrap

4. **Git clones** (selective caching)
   - Location: `~/.cal-cache/git/<repo-name>/`
   - Manual implementation for frequently cloned repos
   - Already implemented: TPM (tmux-plugins/tpm)
   - Consider: Other repos cloned during setup

**Implementation Tasks:**

1. **Host cache setup (cal-bootstrap)**
   - Create `~/.cal-cache/` on host if doesn't exist
   - Configure environment variables in host shell
   - Document cache location and cleanup in ADR-002

2. **VM cache passthrough**
   - Mount host `~/.cal-cache/` into VM via Tart `--dir` flag
   - Or: Create symlink in VM to shared Tart cache directory
   - Ensure cache directory is writable from VM

3. **Update vm-setup.sh**
   - Configure `HOMEBREW_CACHE` in VM environment
   - Configure npm cache via `npm config set cache`
   - Configure `GOMODCACHE` in VM environment
   - Add cache configuration to `.zshrc`

4. **Update cal-bootstrap**
   - Pass cache directory to VM on all `tart run` operations
   - Example: `--dir=cal-cache:~/.cal-cache` (if supported)
   - Fallback: Manual file sync if Tart sharing not available

5. **Cache maintenance**
   - Add `cal cache clear` command to clear all caches
   - Add `cal cache status` command to show cache sizes
   - Document cache location and cleanup procedures

**Benefits:**

- **Speed:** Bootstrap time reduced from ~15 minutes to ~5 minutes (after first run)
- **Reliability:** Reduced network dependency, fewer timeout failures
- **Development:** Snapshot/restore operations become near-instant
- **Bandwidth:** Save hundreds of MB per bootstrap iteration

**Constraints:**

- Cache directory must persist across VM operations
- Cache must be accessible from both host and VM
- Cache invalidation strategy needed (version changes)
- Disk space consideration (~1-2 GB for full cache)

**Testing:**

- First bootstrap: Download everything, populate cache
- Second bootstrap: Use cache, verify speed improvement
- Snapshot/restore: Verify cache persists
- Cache clearing: Verify cleanup works correctly

**Related:**
- BUG-006: Network timeout during bootstrap (this will help prevent)
- Section 1.9: VM lifecycle automation (cache passthrough setup)

**Acceptance Criteria:**

- All package managers use shared cache
- Cache persists across VM snapshots/restores
- Bootstrap time reduced by at least 50% on second run
- Cache maintenance commands available
- Documentation updated in ADR-002

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
