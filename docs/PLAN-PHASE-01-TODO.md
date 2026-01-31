# Phase 1 (CLI Foundation) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Replace manual Tart commands with `cal isolation` CLI.

**Deliverable:** Working `cal isolation` CLI that wraps Tart operations.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) § Phase 1 Readiness for complete operational requirements.

---

## 1.1 **REFINED:** Project Scaffolding (PR #3 - needs changes: empty dirs, AGENTS.md linter ref)

**Tasks:**
1. Initialize Go module
   ```bash
   go mod init github.com/will-head/coding-agent-launcher
   ```
   - Use full repository path as module name
   - Enables internal imports like `import "github.com/will-head/coding-agent-launcher/internal/config"`

2. Create directory structure (directories only, add .go files when implementing features):
   ```
   cmd/cal/
   internal/
     config/
     isolation/
     agent/
     tui/
   ```
   - Test files will be added alongside code as features are implemented (e.g., `config_test.go` next to `config.go`)

3. Create `cmd/cal/main.go` with minimal Cobra root command:
   - Basic cobra setup with root command
   - Add version flag (`--version`)
   - Ready to add subcommands in later TODOs
   - Should be executable and respond to `cal --version`

4. Add initial dependencies (cobra/viper for CLI foundation):
   ```bash
   go get github.com/spf13/cobra
   go get github.com/spf13/viper
   ```
   - Add remaining dependencies (bubbletea, lipgloss, bubbles, ssh, yaml) incrementally as features are implemented
   - TUI libraries added when implementing TUI features (Phase 2)
   - SSH library added when implementing SSH management (1.5)

5. Create `.gitignore` (comprehensive):
   - Standard Go ignores: `cal` binary, `*.out`, `coverage.txt`, `vendor/`, build artifacts
   - IDE/editor files: `.vscode/`, `.idea/`, `*.swp`, `.DS_Store`
   - Local config/test files: `*.local`, `tmp/`, `test-output/`

6. Create `Makefile` with build automation:
   - `build`: Compile binary to `./cal` using `go build -o cal ./cmd/cal`
   - `test`: Run all tests with `go test ./...` (may be empty initially)
   - `lint`: Run `staticcheck ./...` for code quality checks
   - `install`: Install binary to `$(GOPATH)/bin` or `/usr/local/bin`
   - `clean`: Remove binary and test artifacts

**Acceptance Criteria:**
- [ ] Project builds successfully: `go build ./cmd/cal` completes without errors
- [ ] `make build` and `make test` execute successfully
- [ ] `cal --version` runs and displays version information
- [ ] All standard Go project files present: `go.mod`, `.gitignore`, `Makefile`, directory structure created
- [ ] No placeholder .go files in internal/ (just directories)

**Constraints:**
- Use staticcheck for linting, not golangci-lint
- Keep scaffolding minimal - add files and dependencies incrementally
- Directory structure only - actual implementation files added in subsequent TODOs

**Estimated files:** 4 new files (`go.mod`, `.gitignore`, `Makefile`, `cmd/cal/main.go`) + directory structure

---

## 1.2 Configuration Management

**Tasks:**
1. Define config structs in `internal/config/config.go`
2. Implement config loading from `~/.cal/config.yaml`
3. Implement per-VM config from `~/.cal/isolation/vms/{name}/vm.yaml`
4. Add config validation
5. Add config defaults

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

**VM configuration files the CLI must manage (from ADR-002):**
- `~/.cal-vm-info` - VM metadata (name, version, created date)
- `~/.cal-vm-config` - VM password for keychain unlock (mode 600)
- `~/.cal-proxy-config` - Proxy settings (HOST_GATEWAY, HOST_USER, PROXY_MODE)
- `~/.cal-auth-needed` / `~/.cal-first-run` - Lifecycle flags
- `~/.tmux.conf` - tmux configuration
- `~/.zshrc` - Shell configuration blocks (keychain, VM detection, proxy functions, logout check)
- `~/.zlogout` - Logout git status check

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
