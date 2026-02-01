# Phase 1 (CLI Foundation) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Replace manual Tart commands with `cal isolation` CLI.

**Deliverable:** Working `cal isolation` CLI that wraps Tart operations.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) § Phase 1 Readiness for complete operational requirements.

---

## 1.2 Configuration Management (PR #4 - validation fix applied, needs re-review)

**Design Decisions:**
- **Precedence:** Per-VM config overrides global config overrides hard-coded defaults
- **Scope:** YAML configs only (`~/.cal/config.yaml` and per-VM `vm.yaml`). Other subsystems manage their own files (proxy module handles `~/.cal-proxy-config`, lifecycle handles flags, etc.)
- **Missing config:** Use hard-coded defaults silently (no auto-create, no errors)
- **Validation:** Error out immediately with clear messages including invalid value, expected range/format, and file path
- **Validation rules:** Strict validation using Tart-documented ranges:
  - CPU: Valid range from Tart documentation
  - Memory: Valid range from Tart documentation (MB)
  - Disk size: Valid range from Tart documentation (GB)
  - Proxy mode: Must be one of `auto`, `on`, `off`
  - Base image: String validation (non-empty)
- **Config inspection:** `cal config show [--vm name]` displays effective merged configuration

**Tasks:**
1. Define config structs in `internal/config/config.go` with schema version support
2. Implement config loading from `~/.cal/config.yaml` (optional file, silent fallback to defaults)
3. Implement per-VM config from `~/.cal/isolation/vms/{name}/vm.yaml` (optional)
4. Implement config merging logic: hard-coded defaults → global config → per-VM config
5. Add config validation with strict ranges from Tart documentation
6. Add hard-coded config defaults in code
7. Implement `cal config show [--vm name]` command to display effective merged config
8. Add clear error messages (format: "Invalid {field} '{value}' in {path}: must be {expected}")

**Config schema (from ADR):**
```yaml
version: 1
isolation:
  defaults:
    vm:
      cpu: 4
      memory: 8192
      disk_size: 80
      base_image: "ghcr.io/cirruslabs/macos-sequoia-base:latest"
    github:
      default_branch_prefix: "agent/"
    output:
      sync_dir: "~/cal-output"
    proxy:
      mode: "auto"  # auto, on, off
```

**Per-VM config example (`~/.cal/isolation/vms/heavy-build/vm.yaml`):**
```yaml
# Only specify fields to override from global config
cpu: 8
memory: 16384
# Other fields inherit from global config or defaults
```

**Config loading order:**
1. Load hard-coded defaults
2. Merge global config from `~/.cal/config.yaml` (if exists)
3. Merge per-VM config from `~/.cal/isolation/vms/{name}/vm.yaml` (if exists)
4. Result: Per-VM values override global values override defaults

**Acceptance criteria:**
- Config loads from global and per-VM files with correct precedence
- Missing config files handled gracefully (silent fallback to defaults)
- Invalid config values rejected with clear error messages showing value, expected range, and file path
- `cal config show` displays effective merged configuration for default VM
- `cal config show --vm <name>` displays effective merged configuration for specific VM
- Validation uses Tart-documented ranges (research Tart docs during implementation)
- Other subsystems manage their own config files independently (config module doesn't touch them)

**Constraints:**
- YAML format only for Phase 1
- Must research Tart documentation for accurate validation ranges
- Error messages must include: field name, invalid value, expected range/format, file path where set
- Config module does NOT manage other VM files (listed below for reference only)

**Other VM files (NOT managed by config module - for reference only):**
- `~/.cal-vm-info` - VM metadata (managed by VM lifecycle subsystem)
- `~/.cal-vm-config` - VM password (managed by lifecycle subsystem, mode 600)
- `~/.cal-proxy-config` - Proxy settings (managed by proxy subsystem)
- `~/.cal-auth-needed` / `~/.cal-first-run` - Lifecycle flags (managed by lifecycle subsystem)
- `~/.tmux.conf` - tmux configuration (managed by SSH subsystem)
- `~/.zshrc` - Shell configuration (managed by lifecycle subsystem)
- `~/.zlogout` - Logout git status check (managed by git safety subsystem)

**Future enhancements (tracked as separate TODOs below):**
- Interactive config fixing on validation errors
- Environment variable overrides (e.g., `CAL_VM_CPU=8`)
- `cal config validate` command
- Config schema migration strategy for version changes
- `cal config show --defaults` to display hard-coded defaults

---

## 1.3 Tart Wrapper

**File:** `internal/isolation/tart.go`

**Tasks:**
1. Implement `TartClient` struct
2. Wrap Tart CLI commands:
   - `Clone(image, name)` - clone from registry or local VM
   - `Set(name, cpu, memory, disk)` - configure VM resources
   - `Run(name, headless, vnc, vncExperimental, dirs)` - start VM
   - `Stop(name, force)` - stop VM
   - `Delete(name)` - delete VM
   - `List()` - list VMs with JSON format for sizes
   - `IP(name)` - get VM IP (with polling/retry for boot)
   - `Get(name)` - get VM info
3. Add error handling for Tart failures
4. Add VM state tracking (running, stopped, not found)
5. Support `--dir` flag for Tart cache sharing (read-only)
6. Auto-install Tart via Homebrew if missing

**Key learnings from Phase 0 (ADR-002):**
- Use `tart list --format json` with jq for accurate size data
- VM IP polling: `tart ip` may fail while VM boots (30-60s)
- SSH readiness: test port 22 with `nc -z -w 2` after IP available
- `vm_exists()` / `vm_running()`: use BSD-compatible awk (flag variable pattern, not `-qw`)
- VNC experimental mode (`--vnc-experimental`) for bidirectional clipboard
- Cache sharing: `--dir=tart-cache:~/.tart/cache:ro` on all VM start operations

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
| `cal isolation status` | `tart list` | Show VM state and info |
| `cal isolation destroy` | N/A | Delete VMs with safety checks |
| `cal isolation snapshot list` | `cal-bootstrap -S list` | List snapshots with sizes |
| `cal isolation snapshot create <name>` | `cal-bootstrap -S create` | Create snapshot |
| `cal isolation snapshot restore <name>` | `cal-bootstrap -S restore` | Restore snapshot (git safety) |
| `cal isolation snapshot delete <names...> [--force]` | `cal-bootstrap -S delete` | Delete snapshots |
| `cal isolation rollback` | N/A | Restore to session start |

4. Global flags: `--yes` / `-y` (skip confirmations), `--proxy auto|on|off`

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
4. VM detection setup
   - Create `~/.cal-vm-info` with VM metadata
   - Add `CAL_VM=true` to `.zshrc`
   - Install helper functions (`is-cal-vm`, `cal-vm-info`)
5. Tart cache sharing setup
   - Create symlink `~/.tart/cache -> /Volumes/My Shared Files/tart-cache`
   - Idempotent (safe to run multiple times)
   - Graceful degradation if sharing not available

**Key learnings from Phase 0 (ADR-002):**
- First-run flag reliability: set in cal-dev (running, known IP) → clone to cal-init → remove from cal-dev
- Session guard (`CAL_SESSION_INITIALIZED`) persists through `exec zsh -l` (environment variable)
- vm-first-run.sh only checks for updates, doesn't auto-pull (avoids surprise merge conflicts)

---

## 1.10 Helper Script Deployment

**Tasks:**
1. Deploy helper scripts to VM `~/scripts/` directory (idempotent)
2. Scripts to deploy:
   - `vm-setup.sh` - Tool installation and configuration
   - `vm-auth.sh` - Interactive agent authentication
   - `vm-first-run.sh` - Post-restore repository update checker
   - `tmux-wrapper.sh` - TERM compatibility wrapper for tmux
3. Add `~/scripts` to PATH in `.zshrc`
4. Verify deployment after SCP (check exit codes)

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

**Notes:**
- These enhancements improve UX but are not critical for Phase 1 functionality
- Can be prioritized based on user feedback after Phase 1 completion
- Interactive fixing and env var overrides are most valuable for daily use

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
