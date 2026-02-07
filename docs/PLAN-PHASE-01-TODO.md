# Phase 1 (CLI Foundation) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Replace manual Tart commands with `calf isolation` CLI.

**Deliverable:** Working `calf isolation` CLI that wraps Tart operations.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) § Phase 1 Readiness for complete operational requirements.

---

## Critical Issues - HIGHEST PRIORITY

### 1. CLI Command Name Collision — SOLUTION ACCEPTED

**Problem:** The `cal` command clashes with the system calendar command (also called `cal`), requiring users to use `./cal` instead.

**Solution:** [ADR-005](adr/ADR-005-cli-rename-cal-to-calf.md) — Rename to `calf` (**C**oding **A**gent **L**oader **F**oundation)

**Status:** Accepted (2026-02-07). Ready for implementation.

**Mascot:** The ASCII cow from transparent proxy success message becomes the official CALF mascot (a calf is a young cow).

```
 ___________________________
< Transparent proxy works! >
 ---------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

**Implementation Tasks (in order):**

#### 1.1 Go Source Code Updates

- [ ] **1.1.1 Rename cmd/cal/ to cmd/calf/** — Move directory and update imports
- [ ] **1.1.2 Update cmd/calf/main.go** — Change `Use: "cal"` to `Use: "calf"`, update descriptions
- [ ] **1.1.3 Update cmd/calf/cache.go** — Update command references
- [ ] **1.1.4 Update cmd/calf/config.go** — Update "CAL Configuration" to "CALF Configuration"
- [ ] **1.1.5 Update internal/config/config.go** — Update package docs and comments
- [ ] **1.1.6 Update internal/isolation/cache.go** — Change `cal-cache` paths to `calf-cache`
- [ ] **1.1.7 Update internal/isolation/cache_test.go** — Update test paths and assertions
- [ ] **1.1.8 Update internal/isolation/tart.go** — Update package docs
- [ ] **1.1.9 Update internal/isolation/tart_test.go** — Update package docs and VM names

#### 1.2 Shell Script Updates

- [ ] **1.2.1 Rename scripts/cal-bootstrap to scripts/calf-bootstrap**
- [ ] **1.2.2 Update calf-bootstrap** — All internal references:
  - VM names: `cal-dev` → `calf-dev`, `cal-init` → `calf-init`, `cal-clean` → `calf-clean`
  - Environment: `CAL_LOG` → `CALF_LOG`
  - Paths: `~/.cal-cache` → `~/.calf-cache`, `cal-cache` mount tag → `calf-cache`
  - Config files: `~/.cal-*` → `~/.calf-*`
  - Tmux session: `cal` → `calf`
- [ ] **1.2.3 Update scripts/vm-setup.sh** — Cache paths and VM detection
- [ ] **1.2.4 Update scripts/vm-auth.sh** — Flag file paths
- [ ] **1.2.5 Update scripts/vm-first-run.sh** — Flag file paths
- [ ] **1.2.6 Update scripts/vm-tmux-resurrect.sh** — Cache paths and session name
- [ ] **1.2.7 Update scripts/tmux-wrapper.sh** — Session name if referenced

#### 1.3 Config/Flag File Renames

- [ ] **1.3.1 Host paths:**
  - `~/.cal-cache/` → `~/.calf-cache/`
- [ ] **1.3.2 VM paths (in scripts):**
  - `~/.cal-cache/` → `~/.calf-cache/`
  - `~/.cal-proxy-config` → `~/.calf-proxy-config`
  - `~/.cal-proxy.log` → `~/.calf-proxy.log`
  - `~/.cal-proxy.pid` → `~/.calf-proxy.pid`
  - `~/.cal-vm-config` → `~/.calf-vm-config`
  - `~/.cal-vm-info` → `~/.calf-vm-info`
  - `~/.cal-auth-needed` → `~/.calf-auth-needed`
  - `~/.cal-first-run` → `~/.calf-first-run`
- [ ] **1.3.3 Shared volume paths:**
  - `/Volumes/My Shared Files/cal-cache/` → `/Volumes/My Shared Files/calf-cache/`

#### 1.4 Environment Variable Updates

- [ ] **1.4.1 `CAL_VM` → `CALF_VM`** — In vm-setup.sh, CLAUDE.md, workflow docs
- [ ] **1.4.2 `CAL_LOG` → `CALF_LOG`** — In calf-bootstrap
- [ ] **1.4.3 `CAL_SESSION_INITIALIZED` → `CALF_SESSION_INITIALIZED`** — In scripts

#### 1.5 Build System Updates

- [ ] **1.5.1 Update Makefile** — Change `go build -o cal` to `go build -o calf`, update install target

#### 1.6 Documentation Updates

- [ ] **1.6.1 Update CLAUDE.md** — All references, structure section, commands, CAL_VM section
- [ ] **1.6.2 Update README.md** — Project name, build commands, usage examples
- [ ] **1.6.3 Update PLAN.md** — Project description and references
- [ ] **1.6.4 Update docs/cli.md** — All command references
- [ ] **1.6.5 Update docs/bootstrap.md** — Script name and usage
- [ ] **1.6.6 Update docs/architecture.md** — Directory structure and references
- [ ] **1.6.7 Update docs/SPEC.md** — Command references
- [ ] **1.6.8 Update docs/WORKFLOWS.md** — CAL_VM references
- [ ] **1.6.9 Update all docs/WORKFLOW-*.md files** — CAL_VM and command references
- [ ] **1.6.10 Update docs/vm-detection.md** — Environment variable references
- [ ] **1.6.11 Update docs/proxy.md** — Config file references
- [ ] **1.6.12 Update docs/PLAN-PHASE-*.md files** — Command and path references
- [ ] **1.6.13 Update AGENTS.md** — References to cal-dev and commands
- [ ] **1.6.14 Update CODING_STANDARDS.md** — If any cal references exist

#### 1.7 Testing

- [ ] **1.7.1 Run go test ./...** — Verify all tests pass with new paths
- [ ] **1.7.2 Build and test calf binary** — Verify `calf --help` works
- [ ] **1.7.3 Test calf cache commands** — Verify cache operations work
- [ ] **1.7.4 Full integration test** — `calf-bootstrap --init` on fresh system

**Impact:** High - affects all user interactions with the CLI

**Reference:** [ADR-005](adr/ADR-005-cli-rename-cal-to-calf.md) for full decision record

---

### 2. Cache Clear Confirmation UX

**Problem:** `calf cache clear --all` currently clears all caches without any confirmation, which is dangerous.

**Required Changes:**
1. `calf cache clear --all` should present one final y/N confirmation before clearing
2. Add `--force` flag to skip all confirmations (for automation/scripts)
3. Behavior should be:
   - `calf cache clear` → prompt for each cache (current behavior)
   - `calf cache clear --all` → show warning + one final y/N confirmation (NEW)
   - `calf cache clear --all --force` → no prompts at all (NEW)

**Impact:** Medium - prevents accidental data loss

---

### 3. Shared Cache Symlink Fragility — SOLUTION ACCEPTED

**Problem:** Current architecture uses individual symlinks for each cache type (`~/.calf-cache/homebrew` → `/Volumes/My Shared Files/calf-cache/homebrew`, etc.). These symlinks are:
- Easily deleted during cache clear operations
- Confusing for testing and troubleshooting
- Not automatically repaired if broken

**Solution:** [ADR-004](adr/ADR-004-cache-mount-architecture.md) — Direct virtio-fs mounting with custom tags

**Status:** Accepted and tested (2026-02-07). Ready for implementation.

**Implementation Tasks (in order):**

- [ ] **3.1 Update calf-bootstrap Tart flags** — Change `--dir` to use custom mount tag
  - From: `--dir calf-cache:${HOME}/.calf-cache:rw,tag=com.apple.virtio-fs.automount`
  - To: `--dir=${HOME}/.calf-cache:tag=calf-cache`
  - Update all `tart run` invocations in calf-bootstrap

- [ ] **3.2 Create calf-mount-shares.sh script** — Mount script with retry logic
  - Deploy to `/usr/local/bin/calf-mount-shares.sh`
  - Include migration logic (remove old symlinks before mount)
  - Retry logic for boot timing (5 attempts, 2s delay)
  - Logging to `/tmp/calf-mount.log`
  - Extensible for future mounts (iOS signing, etc.)

- [ ] **3.3 Create LaunchDaemon plist** — Boot-time mount persistence
  - Deploy to `/Library/LaunchDaemons/com.calf.mount-shares.plist`
  - RunAtLoad with KeepAlive on failure
  - Set HOME/USER environment for admin user

- [ ] **3.4 Update vm-setup.sh deployment** — Install mount infrastructure
  - Copy calf-mount-shares.sh to /usr/local/bin/
  - Copy LaunchDaemon plist to /Library/LaunchDaemons/
  - Load LaunchDaemon with launchctl
  - Remove old symlink creation code

- [ ] **3.5 Add .zshrc self-healing fallback** — Belt-and-suspenders recovery
  - Quick mount check on shell start (<10ms)
  - Remount if unmounted (handles manual unmount edge case)

- [ ] **3.6 Update cache.go VM setup methods** — Remove symlink generation
  - Update `SetupVMHomebrewCache()`, `SetupVMNpmCache()`, `SetupVMGoCache()`, `SetupVMGitCache()`
  - Remove symlink creation commands
  - Add mount verification commands instead

- [ ] **3.7 End-to-end testing** — Verify full implementation
  - Test fresh `--init` creates working mounts
  - Test reboot persistence (LaunchDaemon)
  - Test self-healing after manual unmount
  - Test migration from existing symlink-based VM
  - Test snapshot/restore behavior

**Impact:** High - affects cache reliability and user experience

**Reference:** [ADR-004](adr/ADR-004-cache-mount-architecture.md) for full implementation details

---

## New Features - Normal Priority

### 4. CLI Proxy Utility for VM↔Host Command Transport

**Goal:** Enable VM-based applications to execute CLI commands on the host transparently.

**Use Case:** 1Password's `op` CLI requires communication with the 1Password desktop app, which runs on the host and is not accessible from within the VM.

**Concept:**
1. Alias commands in VM (e.g., `op` → `cli-proxy op`)
2. `cli-proxy` securely transports command and arguments from VM to host
3. Host executes actual command against host resources (e.g., 1Password desktop app)
4. Results returned securely to VM
5. Transparent to user - feels like native command execution

**Requirements:**
- Secure transport mechanism (SSH-based, encrypted)
- Verbatim command/response passing
- Low latency for interactive commands
- Error handling and exit code preservation
- Support for stdin/stdout/stderr
- Configurable command allowlist for security

**Potential Implementation:**
- SSH-based command forwarding
- Host-side daemon/service to receive and execute commands
- VM-side client wrapper (`cli-proxy`)
- Configuration file for allowed commands

---

### 5. Screenshot Drag-and-Drop Support for VM-based Coding Agents

**Goal:** Enable drag-and-drop of screenshots from host into coding agents running in the VM.

**Current Limitation:** On the host system, users can drag and drop screenshots directly into coding agents. This functionality doesn't work when the coding agent runs in the VM.

**Required Investigation:**
1. How do coding agents currently receive drag-and-drop screenshots?
   - Clipboard integration?
   - File path passing?
   - Direct image data?
2. What's the technical barrier in the VM?
   - Clipboard isolation?
   - File system isolation?
   - GUI application integration?
3. Potential solutions:
   - Shared clipboard between host and VM
   - Automatic screenshot sync to VM filesystem
   - VNC/remote desktop integration improvements
   - Custom bridge application

**Acceptance Criteria:**
- User can drag screenshot from host desktop
- Screenshot appears in coding agent running in VM
- Works with common coding agents (Claude Code, Cursor, etc.)
- Minimal latency (feels instant)

---

## 1.1 **REFINED:** Package Download Caching **HIGHEST PRIORITY**

**Goal:** Cache all package downloads in host and pass through to VMs to avoid repeated downloads during development.

**Implementation Strategy:** Incremental rollout - implement one package manager at a time, starting with Homebrew (highest impact).

**Phase 1.1.1 (Homebrew Cache) completed:** See [PLAN-PHASE-01-DONE.md](PLAN-PHASE-01-DONE.md) § 1.1.1 (PR #6, merged 2026-02-03)

**Phase 1.1.2 (npm Cache) completed:** See [PLAN-PHASE-01-DONE.md](PLAN-PHASE-01-DONE.md) § 1.1.2 (PR #7, merged 2026-02-03)

**Phase 1.1.3 (Go Modules Cache) completed:** See [PLAN-PHASE-01-DONE.md](PLAN-PHASE-01-DONE.md) § 1.1.3 (PR #8, merged 2026-02-03)

---


---

## 1.4 Snapshot Management

**File:** `internal/isolation/snapshot.go`

**Tasks:**
1. Implement `SnapshotManager` struct
2. Methods:
   - `Create(name)` - create snapshot via `tart clone` (stop VM first)
   - `Restore(name)` - restore from snapshot (check git, delete calf-dev, clone)
   - `List()` - list snapshots with sizes (JSON format)
   - `Delete(names, force)` - delete one or more snapshots
   - `Cleanup(olderThan, autoOnly)` - cleanup old snapshots
3. Auto-snapshot on session start (configurable)
4. Snapshot naming: user-provided exact names (no prefix)

**Key learnings from Phase 0 (ADR-002):**
- Tart "snapshots" are actually clones (copy-on-write)
- Restore must work even if calf-dev doesn't exist (create from snapshot)
- Delete supports multiple VM names in one command
- `--force` flag skips git checks and avoids booting VM (for unresponsive VMs)
- Git safety checks must run before restore and delete (see 1.7)
- Don't stop a running VM before git check - use it while running
- Snapshot names are case-sensitive, no prefix required
- **Filesystem sync before snapshot creation** (BUG-009): Call `sync && sleep 2` via SSH before stopping VM for snapshot. Without this, data written by SSH operations (e.g., repo clones during vm-auth) may be lost due to unflushed filesystem buffers

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
- tmux sessions via `~/scripts/tmux-wrapper.sh new-session -A -s calf`
- TERM handling: never set TERM explicitly in command environment (opencode hangs). Use tmux-wrapper.sh which sets TERM in script environment
- Helper script deployment: copy vm-setup.sh, vm-auth.sh, vm-first-run.sh, tmux-wrapper.sh to ~/scripts/
- Must check scp exit codes for all file copy operations

**Conditional tmux auto-restore (from Phase 0.11):**
- Check `~/.calf-first-run` flag before starting tmux
- If flag exists: use `tmux new-session -s calf` (fresh session, no auto-restore)
- If flag absent: use `tmux new-session -A -s calf` (attach existing or create with auto-restore)
- This prevents vm-auth authentication screen from appearing inside restored tmux session on first boot
- Flag check must happen in `calf isolation start`, `calf isolation init`, and `calf isolation restart`

---

## 1.6 CLI Commands (Cobra)

**File:** `cmd/calf/main.go` + `cmd/calf/isolation.go`

**Tasks:**
1. Root command `calf`
2. Subcommand group `calf isolation` (alias: `calf iso`)
3. Implement commands (mapped from calf-bootstrap per ADR-002):

| Command | Maps from | Description |
|---------|-----------|-------------|
| `calf isolation init [--proxy auto\|on\|off] [--yes]` | `calf-bootstrap --init` | Full VM creation and setup |
| `calf isolation start [--headless]` | `calf-bootstrap --run` | Start VM and SSH in with tmux |
| `calf isolation stop [--force]` | `calf-bootstrap --stop` | Stop calf-dev |
| `calf isolation restart` | `calf-bootstrap --restart` | Restart VM and reconnect |
| `calf isolation gui` | `calf-bootstrap --gui` | Launch with VNC experimental mode |
| `calf isolation ssh [command]` | Direct SSH | Run command or interactive shell |
| `calf isolation status` | `calf-bootstrap --status` | Show VM state, IP, size, and context-appropriate commands |
| `calf isolation destroy` | N/A | Delete VMs with safety checks |
| `calf isolation snapshot list` | `calf-bootstrap -S list` | List snapshots with sizes |
| `calf isolation snapshot create <name>` | `calf-bootstrap -S create` | Create snapshot |
| `calf isolation snapshot restore <name>` | `calf-bootstrap -S restore` | Restore snapshot (git safety) |
| `calf isolation snapshot delete <names...> [--force]` | `calf-bootstrap -S delete` | Delete snapshots |
| `calf isolation rollback` | N/A | Restore to session start |

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
   - `calf isolation init` (before deleting existing VMs)
   - `calf isolation snapshot restore` (before replacing calf-dev, skip if calf-dev doesn't exist)
   - `calf isolation snapshot delete` (before deleting, skip with `--force`)
   - `calf isolation destroy` (before deleting)

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
- Proxy config stored in `~/.calf-proxy-config`
- Proxy logs in `~/.calf-proxy.log`, PID in `~/.calf-proxy.pid`

---

## 1.9 VM Lifecycle Automation

**Tasks:**
1. Keychain auto-unlock setup during init
   - Save VM password to `~/.calf-vm-config` (mode 600)
   - Configure `.zshrc` keychain unlock block
   - `CALF_SESSION_INITIALIZED` guard to prevent re-execution on logout cancel
2. First-run flag system
   - `~/.calf-auth-needed` flag triggers vm-auth.sh during init
   - `~/.calf-first-run` flag triggers vm-first-run.sh after restore
   - Call `sync` after creating flag files (filesystem sync timing)
3. Logout git status check
   - Configure `~/.zlogout` to scan ~/code for uncommitted/unpushed changes
   - Cancel logout starts new login shell with session flag preserved
4. Tmux session persistence on logout
   - Add tmux session save to `~/.zlogout` hook (before git status check)
   - **Must gate save on first-run flag** (BUG-005): only save if `~/.calf-first-run` does NOT exist
   - Prevents capturing auth screens during --init into session data
   - Run `tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh` on logout
   - Ensures session state is captured even between auto-save intervals
5. Filesystem sync before VM stop (BUG-009)
   - Call `sync && sleep 2` via SSH after vm-auth or any critical write operation completes
   - Must happen before VM stop or snapshot creation
   - Prevents data loss from unflushed filesystem buffers
   - Mirrors existing sync pattern used for flag files
6. Delay before VM stop for session save (BUG-005)
   - Add 10-second delay before `tart stop` in stop/restart/gui operations
   - Allows detach hook saves to complete before VM shutdown
   - **Do NOT add explicit tmux saves** in stop/restart/gui — detach hook already saves
   - Explicit background saves can corrupt save files if VM stops mid-write
7. VM detection setup
   - Create `~/.calf-vm-info` with VM metadata
   - Add `CALF_VM=true` to `.zshrc`
   - Install helper functions (`is-calf-vm`, `calf-vm-info`)
8. Tart cache sharing setup
   - Create symlink `~/.tart/cache -> /Volumes/My Shared Files/tart-cache`
   - Idempotent (safe to run multiple times)
   - Graceful degradation if sharing not available

**Key learnings from Phase 0 (ADR-002):**
- First-run flag reliability: set in calf-dev (running, known IP) → clone to calf-init → remove from calf-dev
- Session guard (`CALF_SESSION_INITIALIZED`) persists through `exec zsh -l` (environment variable)
- vm-first-run.sh only checks for updates, doesn't auto-pull (avoids surprise merge conflicts)

**Key learnings from Phase 0.11 (Tmux Session Persistence):**
- Session name must be `calf` (not `calf-dev`) for `calf isolation` commands
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
     - Must create `alias agent='cursor-agent'` in ~/.zshrc (idempotent check) (BUG-008)
   - `vm-auth.sh` - Interactive agent authentication **ONLY** (no state management) (BUG-008)
     - Creates agent alias directly if `agent` command missing (not by sourcing ~/.zshrc — avoids side effects like early tmux-resurrect loading)
     - Does NOT manage first-run flag or tmux session state
   - `vm-first-run.sh` - Post-restore initialization (BUG-005/BUG-008 architecture)
     - Checks git repositories for updates
     - Loads TPM to enable tmux session persistence: `~/.tmux/plugins/tpm/tpm`
     - Removes `~/.calf-first-run` flag AFTER tmux history is enabled
     - Session persistence only starts on first user login, never during --init
   - `tmux-wrapper.sh` - TERM compatibility wrapper for tmux
   - `vm-tmux-resurrect.sh` - Tmux session persistence setup (Phase 0.11)
3. Deploy comprehensive tmux.conf with:
   - **PATH environment for plugin scripts** (required for tmux-resurrect - see note below)
   - **Conditional TPM loading based on first-run flag** (prevents auth screen capture)
   - Session persistence via tmux-resurrect and tmux-continuum plugins
   - Auto-save every 15 minutes, auto-restore on tmux start
   - Pane contents (scrollback) capture with 50,000 line limit
   - Client-detached hook for save on `Ctrl+b d` — **must gate on first-run flag** (BUG-005): `if [ ! -f ~/.calf-first-run ]; then save; fi`
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
- Session name `calf` used by `tmux-wrapper.sh new-session -A -s calf`
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
- Explicit cleanup on init failure (delete calf-dev to allow clean retry)

**Conditional TPM loading for first-run:**
- TPM must NOT load during first-run (while `~/.calf-first-run` flag exists)
- Prevents tmux-resurrect from capturing the vm-auth authentication screen
- Use conditional in tmux.conf: `if-shell '[ ! -f ~/.calf-first-run ]' 'run ~/.tmux/plugins/tpm/tpm'`
- After first-run completes and flag is removed, session persistence works normally

---

## 1.11 Configuration Enhancements (Future)

**Tasks (deferred to future phases):**
1. **Interactive config fixing** - When validation fails, prompt user to fix config interactively
   - Detect invalid values and offer to correct them on the spot
   - Show valid ranges and let user enter new value
   - Write corrected config back to file
2. **Environment variable overrides** - Support env vars overriding config values
   - Example: `CALF_VM_CPU=8 calf isolation init` overrides config CPU setting
   - Follow 12-factor app pattern for configuration hierarchy
   - Priority: env vars > per-VM config > global config > defaults
3. **Config validation command** - `calf config validate` to check config without running
   - Parse and validate config files
   - Report all errors (don't stop at first error)
   - Exit 0 if valid, non-zero if invalid
4. **Config schema migration** - Strategy for handling config version changes
   - Detect old config versions and migrate automatically
   - Backup old config before migration
   - Clear migration messages to user
5. **Default values documentation** - `calf config show --defaults` flag
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

**Key testing lessons from post-cache-integration bugs (ADR-003 § Bug Fixes):**
- **Agent alias (BUG-008):** Never source ~/.zshrc in scripts — causes side effects (tmux-resurrect loading early). Create aliases directly instead
- **Filesystem sync timing (BUG-009):** Always call `sync && sleep 2` via SSH after operations that write data, before VM stop or snapshot creation. Silent data loss occurs without this
- **Save hook gating (BUG-005):** All tmux save triggers (detach hook, .zlogout, auto-save) must check `~/.calf-first-run` flag. Ungated saves capture auth screens during --init
- **No explicit saves before VM stop (BUG-005):** Rely on detach hook saves only. Explicit background saves (`tmux run-shell -b`) can be killed mid-write by VM stop, corrupting save files
- **Delay before VM stop (BUG-005):** 10-second delay before `tart stop` lets detach hook saves complete. Without delay, save may be killed mid-write
- **Script architecture (BUG-008):** vm-auth.sh = authentication only; vm-first-run.sh = state management (TPM loading, flag removal). Mixing concerns caused cascading issues
