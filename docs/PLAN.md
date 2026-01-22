# CAL Implementation Plan

> 🎯 **THIS IS THE SINGLE SOURCE OF TRUTH FOR PROJECT STATUS AND TODOS**
>
> - Phase completion is determined by checkboxes below
> - All TODOs must be tracked here (code TODOs should reference this file)
> - Operational guide: [ADR-002](adr/ADR-002-tart-vm-operational-guide.md)
> - Original design: [ADR-001](adr/ADR-001-cal-isolation.md) (immutable)

## Current Status

**Phase 0 (Bootstrap): Mostly Complete** - Core functionality documented in [ADR-002](adr/ADR-002-tart-vm-operational-guide.md). Outstanding TODOs in 0.8, 0.10, 0.11 below.
- [x] Research Tart capabilities
- [x] Document manual setup process
- [x] Create automated vm-setup script
- [x] Set up base VM with agents (automated via script)
- [x] Create clean snapshot for rollback (documented)
- [x] Investigate and test terminal keybindings (all working correctly)
- [x] **Create cal-bootstrap script** - unified VM management
  - [x] `--init`: Create cal-clean, cal-dev, cal-init VMs
  - [x] `--run`: Start VM and SSH in automatically
  - [x] `--stop`: Stop cal-dev
  - [x] `--snapshot`: List, create, restore, delete snapshots
  - [x] Auto-detect mode based on VM state
  - [x] SSH key setup automation
  - [x] Cleanup traps for background processes
- [x] **macOS Auto-Login for Screen Sharing** (Phase 0.7)
  - [x] Enable auto-login in vm-setup.sh
  - [x] Configure macOS to auto-login admin user
  - [x] Fix Screen Sharing lock screen issue
- [x] **Keychain Access for Cursor Agent** (Phase 0.8 - Complete with known issues)
  - [x] Research keychain issue from Tart FAQ
  - [x] Implement keychain unlock in vm-setup.sh
  - [x] Implement keychain unlock in cal-bootstrap
  - [x] Create test script and documentation
  - [x] Test agent login via Screen Sharing
  - [x] Verify credential persistence (works after SSH reconnect)
  - [x] Test across VM reboots (credentials persist with keychain unlock + .zshrc)
  - [x] Verify auto-unlock on connection
  - [x] **NOT FIXABLE: Cursor agent authentication in VMs** - OAuth polling fails to detect browser completion in VM environments. API key authentication requires OAuth config to exist first (dependency cycle). Cursor CLI is not currently compatible with VM/SSH-only environments. Testing confirmed (Jan 2026) that both OAuth and API key methods fail in Tart VMs.
- [x] **SSH Alternatives Investigation** (Phase 0.8 - Complete)
  - [x] Research alternatives (Mosh, Eternal Terminal, console access, tmux)
  - [x] Performance testing and comparison
  - [x] **Conclusion:** SSH is optimal for local VM (excellent performance)
  - [x] **Enhancement:** Added tmux support for session persistence
 - [x] **VM Management Improvements** (Phase 0.8 - 7/10 complete)
   - [x] Fix opencode installation in `--init` script (added Go install fallback, improved PATH setup)
   - [x] Simplify `--init` auth flow (removed verification prompt since opencode now works reliably)
   - [x] Add `--restart` option to cal-bootstrap for quick VM restart
   - [ ] Check VM keyboard layout matches host keyboard layout
   - [x] Add Screen Sharing instructions for agent login failures (displayed on --run)
   - [ ] Investigate High Performance mode issues
   - [x] Add warning on snapshot restore to check that git is updated in VM (uncommitted/unpushed changes checked)
   - [x] Investigate if uncommitted or unpushed git changes can be automatically checked if they exist in VM before restore (implemented)
   - [x] Remove distinction between clones and snapshots in `--snapshot list` (they're functionally same for our purposes)
   - [x] Create method for coding agent to detect if running in VM (env var + info file + helper functions, see docs/vm-detection.md)
- [x] **Transparent Proxy for Network Reliability** (Phase 0.9 - Complete, migrated to sshuttle)
   - [x] Implement transparent proxy via sshuttle (VM→Host)
   - [x] Add bootstrap SOCKS proxy (SSH -D) for --init phase before sshuttle installed
   - [x] Add `--proxy on/off/auto` flag to cal-bootstrap
   - [x] Implement auto mode (tests github.com connectivity, enables proxy if needed)
   - [x] Setup VM→Host SSH keys with host key verification
   - [x] Add VM commands: proxy-start, proxy-stop, proxy-restart, proxy-status, proxy-log
   - [x] Auto-start proxy on VM boot/shell login (configurable via PROXY_MODE)
   - [x] Auto-start in vm-auth.sh if network fails
   - [x] Check host SSH server and Python availability
   - [x] Comprehensive documentation (docs/proxy.md, updated bootstrap.md and architecture.md)
   - [ ] **Init Improvements and Enhancements** (Phase 0.10 - In Progress)
       - [ ] Add option to sync git repos on init (clone specified repos into VM automatically) - PR#1 awaiting fixes
         - Testing found: zsh syntax error (read -ra), wrong clone method, unclear prompt format
     - [ ] Try to install Tart automatically during init if not present (brew install cirruslabs/cli/tart)
     - [x] **NOT FIXABLE: Cursor API key auth support** - API keys require OAuth-downloaded user configuration to function. Since OAuth polling fails in VMs (see Phase 0.8), API keys cannot work either. Cursor CLI authentication not possible in VM environments.
     - [ ] Consider using GUIDs for VM/snapshot names with friendly name mapping
     - [ ] Verify opencode login flow is fixed (test authentication reliability)
     - [ ] Add Codex GitHub CLI Antigravity tools installation in init
      - [ ] **Check and fix authentication flows**
        - [ ] GH CLI: Fix PAT login flow (currently fails, token may be issue)
        - [ ] opencode: Works but reports not authenticated in check (investigate status check)
        - Note: Cursor CLI issues tracked separately (see Phase 0.8 line 39)
        - Note: Claude Code authentication working correctly - do not modify
      - [ ] **Clone GitHub repos in vm-auth** - after gh authentication
        - [ ] Prompt user to select repos to clone (present list of user's repos)
        - [ ] Clone selected repos to ~/code/[github server]/[username]/[repo]
        - [ ] Support multiple GitHub servers (github.com, enterprise)
      - [ ] **First login git updates in cal-init**
        - [ ] vm-setup.sh sets flag variable for first login
        - [ ] Login script checks flag and scans ~/code for git updates
        - [ ] Prompt user to pull if updates found
        - [ ] Unset flag variable after first login scan complete
      - [ ] **Logout git status check**
        - [ ] On logout (exit, Ctrl-D, Ctrl-C) scan ~/code directories for git changes
        - [ ] Prompt user to push before exit if uncommitted/unpushed changes found
        - [ ] Allow user to abort logout or continue despite changes
     - [x] Renamed cal-initialised to cal-init (shorter, clearer naming)
     - [x] Make `--init` safer: delete existing cal-dev and cal-init as first step
       - [x] Warn user before deletion
       - [x] Check for uncommitted/unpushed git changes
       - [x] Provide abort option with no changes made
       - [x] Only proceed after user confirmation
       - [x] Check both cal-dev and cal-init upfront (not at Step 9)
       - [x] Single confirmation for entire init operation
     - [x] Create code directory in user home during --init
     - [x] Add git change checks to all destructive operations (delete VM, restore snapshot, etc)
       - [x] Implemented for --snapshot restore (refactored to use reusable function)
       - [x] Implemented for --snapshot delete (checks all VMs except cal-clean)
       - [x] Implemented for --init (checks cal-dev before deleting both VMs)
       - [x] Created reusable check_vm_git_changes() function to reduce duplication
       - Note: Checks skip cal-clean (base image with no expected work)
     - [ ] Install all packages required for full Go development in cal-dev during --init (follow best practice)
       - Research and install in vm-setup.sh: golangci-lint (linters runner), goimports, delve (debugger), mockgen (test mocking), air (hot reload)
       - Note: Core Go tools already included (go fmt, go vet, go test, go mod)
       - Reference: https://golangci-lint.run/ and Go community best practices
     - [x] Create auth script to easily re-run agent authentication
       - [x] Create vm-auth.sh script that runs: gh auth login, claude auth login, agent (Cursor auth), opencode auth login
       - [x] Provide convenient way to re-authenticate all agents without manual steps
       - [x] Make script idempotent (skip if already authenticated, smart defaults)
       - [x] Install in cal-dev during --init
       - [x] Detect network connectivity and auto-start transparent proxy when needed
     - [x] Add vm-setup.sh and vm-auth.sh to ~/scripts folder in cal-dev during --init
       - [x] Create ~/scripts directory in cal-dev if it doesn't exist
       - [x] Copy vm-setup.sh and vm-auth.sh from host to VM during --init
       - [x] Add ~/scripts to PATH in .zshrc for easy access
       - [x] Run vm-setup.sh from ~/scripts (no duplication in ~)
     - [x] Update README.md Quick Start to match bootstrap.md (correct Quick Start instructions)
     - [ ] **vm-auth.sh Improvements** (Future enhancements - low priority)
       - [ ] Reduce network check timeout from 5s to 3s for faster feedback
       - [ ] Use `gh api user -q .login` for more robust username extraction
       - [ ] Add explicit error handling for scp failures in setup_scripts_folder
       - [ ] Check for specific opencode auth token file if documented
       - [ ] Add Ctrl+C trap handlers during authentication flows
       - [ ] Ensure gh username parsing works in non-English locales
     - [ ] **cal-bootstrap Script Enhancements**
       - [x] Show VM/snapshot sizes in `--snapshot list` output (uses JSON API, displays actual size with GB units, includes total)
       - [x] Remove cal-dev prefix from snapshot names (snapshots now use exact names specified by user)
       - [ ] Allow `--snapshot delete` to accept multiple VM names
       - [ ] Add `--snapshot delete --force` option to skip git checks and avoid booting VM (for unresponsive VMs)
       - [ ] When cal-init exists and user runs `--init`, offer to replace cal-init with current cal-dev before proceeding with init
     - [ ] **Session State Management** (Phase 0.11 - Future)
       - [ ] Implement constant context state persistence
       - [ ] Write context to file after every operation
       - [ ] Enable seamless session recovery on crash or usage limits
       - [ ] Allow session continuation across Claude Code restarts
     - [x] **Documentation Cleanup**
       - [x] Clean up AGENTS.md (CLAUDE.md symlinks to it)
         - [x] Change internal refs from CLAUDE.md to AGENTS.md
         - [x] Merge duplicate Command Execution Policy sections
         - [x] Review for inconsistencies (fixed Step numbering in documentation-only exception)
         - [x] Add TDD (Test-Driven Development) to 8-step workflow Step 1
       - [x] Restructure docs for progressive disclosure and token optimization
         - [x] Create docs/WORKFLOW.md for detailed git workflow procedures
         - [x] Slim AGENTS.md to core rules only (445→76 lines, 86% reduction)
         - [x] Move detailed procedures to WORKFLOW.md (read on-demand when committing)
       - [x] Comprehensive documentation update based on ADR-002
         - [x] Update all docs to reference ADR-002 as operational guide
         - [x] Simplify existing docs for progressive disclosure
         - [x] Note Cursor CLI VM incompatibility throughout
         - [x] Update README, SPEC, architecture, bootstrap, cli, proxy, roadmap, vm-detection, AGENTS, PLAN
      - [x] Add Merge PR workflow (8-step with approvals)
        - [x] Add to workflow mode table in CLAUDE.md
        - [x] Document 8-step merge procedure in CLAUDE.md
        - [x] Add to WORKFLOW.md with detailed procedures
        - [x] Update session start workflow lists
      - [x] Add Test PR workflow (7-step manual testing gate)
        - [x] Add to workflow mode table in CLAUDE.md and AGENTS.md
        - [x] Document 7-step test procedure in CLAUDE.md and AGENTS.md
        - [x] Add to WORKFLOW.md with detailed procedures
        - [x] Update session start workflow lists
        - [x] Add "Tested" section to PRS.md between "Reviewed" and "Merged"
        - [x] Update Merge PR workflow to read from "Tested" instead of "Reviewed"
        - [x] Create comprehensive PR workflow diagram (PR-WORKFLOW-DIAGRAM.md)
        - [x] Verify all workflows update PLAN.md and return to main branch
      - [x] **Workflow Documentation Improvements**
        - [x] Rename "Standard" workflow to "Interactive" throughout all documentation
        - [x] Rename PRS.md section headings: "Awaiting Review" → "Needs Review", "Awaiting Changes" → "Needs Changes", "Reviewed" → "Needs Testing", "Tested" → "Needs Merging"
        - [x] Split workflow documentation into separate files for each workflow
          - [x] Create docs/WORKFLOW-CREATE-PR.md for Create PR workflow details
          - [x] Create docs/WORKFLOW-REVIEW-PR.md for Review PR workflow details
          - [x] Create docs/WORKFLOW-UPDATE-PR.md for Update PR workflow details
          - [x] Create docs/WORKFLOW-TEST-PR.md for Test PR workflow details
          - [x] Create docs/WORKFLOW-MERGE-PR.md for Merge PR workflow details
          - [x] Create docs/WORKFLOW-INTERACTIVE.md for Interactive workflow details
          - [x] Create docs/WORKFLOW-DOCUMENTATION.md for Documentation workflow details
          - [x] Create docs/WORKFLOWS.md as index listing all workflows with references to detail files
          - [x] Update CLAUDE.md to reference new workflow detail files
        - [x] Emphasize in all workflow docs: PLAN.md and PRS.md changes must be done on main branch, not PR branch
        - [x] Emphasize in all workflow docs: PR comments must use heredoc format to preserve formatting (gh pr comment/review --body "$(cat <<'EOF' ... EOF)")
        - [ ] Consolidate useful content from old WORKFLOW.md into WORKFLOWS.md, consider deprecating or removing WORKFLOW.md

**Deliverable:** Core Phase 0 implementation documented in [ADR-002](adr/ADR-002-tart-vm-operational-guide.md). Three-tier VM architecture, automated setup, transparent proxy, git safety checks, and VM detection. Outstanding items in 0.8/0.10/0.11 tracked above.

**Testing Issues Found & Fixed:**
- [x] vm_exists() initially used grep -qw which didn't work reliably - fixed with awk column match
- [x] vm_exists() and vm_running() awk syntax incompatible with BSD awk - fixed with flag variable pattern
- [x] vm_running() used grep which could match partial names - fixed with awk column-specific matching
- [x] Double confirmation prompt on restore - fixed by consolidating to single prompt after git check
- [x] Triple duplicate git check blocks in restore - consolidated to single check
- [x] Git check only ran if VM already running - now always boots VM to check before restore
- [x] Git search limited to ~/workspace - expanded to ~/workspace, ~/projects, ~/repos, ~/code, + ~ maxdepth 2
- [x] $vm_to_run undefined variable in do_restart - fixed to use $VM_DEV
- [x] Missing Screen Sharing hint in do_restart - added for parity with do_run
- [x] Delete only warned for cal-dev - added warnings for cal-clean and cal-init
- [x] Argument parsing `shift || true` showed error in zsh - fixed with `[[ $# -gt 0 ]] && shift`
- [x] Unpushed commits detection requires proper git upstream tracking to be set - working as designed (has prerequisites)

---

## Phase 1: CLI Foundation

**Goal:** Replace manual Tart commands with `cal isolation` CLI.

**Pending TODOs:**
- [ ] Make cached macos-sequoia-base:latest available inside cal-dev to avoid duplicate downloading

### 1.1 Project Scaffolding

**Tasks:**
1. Initialize Go module
   ```bash
   go mod init github.com/[org]/cal
   ```

2. Create directory structure:
   ```
   cmd/cal/main.go
   internal/
     config/config.go
     isolation/
       tart.go
       snapshot.go
       ssh.go
     tui/
       app.go
       styles.go
   ```

3. Add dependencies:
   ```go
   require (
       github.com/charmbracelet/bubbletea
       github.com/charmbracelet/lipgloss
       github.com/charmbracelet/bubbles
       github.com/spf13/cobra
       github.com/spf13/viper
       golang.org/x/crypto/ssh
       gopkg.in/yaml.v3
   )
   ```

**Estimated files:** 8-10 new Go files

### 1.2 Configuration Management

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
```

### 1.3 Tart Wrapper

**File:** `internal/isolation/tart.go`

**Tasks:**
1. Implement `TartClient` struct
2. Wrap Tart CLI commands:
   - `Clone(image, name)` - clone from registry
   - `Set(name, cpu, memory, disk)` - configure VM
   - `Run(name, headless, vnc, dirs)` - start VM
   - `Stop(name, force)` - stop VM
   - `Delete(name)` - delete VM
   - `List()` - list VMs
   - `IP(name)` - get VM IP
   - `Get(name)` - get VM info
3. Add error handling for Tart failures
4. Add VM state tracking

### 1.4 Snapshot Management

**File:** `internal/isolation/snapshot.go`

**Tasks:**
1. Implement `SnapshotManager` struct
2. Methods:
   - `Create(workspace, name)` - create snapshot via `tart clone`
   - `Restore(workspace, name)` - restore from snapshot
   - `List(workspace)` - list snapshots
   - `Delete(workspace, name)` - delete snapshot
   - `Cleanup(workspace, olderThan, autoOnly)` - cleanup old snapshots
3. Auto-snapshot on session start (configurable)
4. Snapshot naming convention: `{workspace}-{type}-{timestamp}`

### 1.5 SSH Management

**File:** `internal/isolation/ssh.go`

**Tasks:**
1. Implement `SSHClient` struct using `golang.org/x/crypto/ssh`
2. Methods:
   - `Connect(host, user, password)` - establish connection
   - `Run(command)` - execute command
   - `Shell()` - interactive shell
   - `Close()` - close connection
3. Password authentication (default: admin/admin)
4. Connection retry logic (VM may be booting)

### 1.6 CLI Commands (Cobra)

**File:** `cmd/cal/main.go` + `cmd/cal/isolation.go`

**Tasks:**
1. Root command `cal`
2. Subcommand group `cal isolation` (alias: `cal iso`)
3. Implement commands:
   - `init <name> [--template] [--env] [--agent] [--cpu] [--memory] [--disk]`
   - `start <name> [--headless] [--vnc]`
   - `stop <name> [--force]`
   - `destroy <name>`
   - `status <name>`
   - `ssh <name> [command]`
   - `snapshot create/restore/list/delete <name>`
   - `rollback <name>`

**Deliverable:** Working `cal isolation` CLI that wraps Tart operations.

---

## Phase 2: Agent Integration & UX

**Goal:** Seamless agent launching with safety UI.

### 2.1 TUI Framework Setup

**Files:** `internal/tui/app.go`, `internal/tui/styles.go`

**Tasks:**
1. Create bubbletea application scaffold
2. Define lipgloss styles for:
   - Status banner (green/yellow/red backgrounds)
   - Confirmation screen
   - Hotkey bar
3. Implement view switching

### 2.2 Status Banner

**File:** `internal/tui/banner.go`

**Tasks:**
1. Render status banner:
   ```
   🔒 CAL ISOLATION ACTIVE │ VM: <name> │ Env: <envs> │ Safe Mode
   ```
2. Dynamic color based on VM state
3. Update banner in real-time during session

### 2.3 Launch Confirmation Screen

**File:** `internal/tui/confirm.go`

**Tasks:**
1. Display workspace info before launch
2. Show isolation status
3. Handle user input: Enter (launch), B (backup), Q (quit)
4. Optional: `--yes` flag to skip confirmation

### 2.4 Agent Management

**File:** `internal/agent/agent.go`

**Tasks:**
1. Define `Agent` interface:
   ```go
   type Agent interface {
       Name() string
       InstallCommand() string
       ConfigDir() string
       LaunchCommand(prompt string) string
       IsInstalled(ssh *SSHClient) bool
   }
   ```
2. Implement for Claude Code, opencode, Cursor CLI
3. Agent installation in VM
4. Agent configuration management

### 2.5 SSH Tunnel with Banner Overlay

**Tasks:**
1. Establish SSH tunnel to VM
2. Overlay status banner at top of terminal
3. Pass through agent terminal output
4. Capture hotkey inputs (S, C, P, R, Q)
5. Clean exit handling

**Deliverable:** `cal isolation run <workspace>` launches agent with full UX.

---

## Phase 3: GitHub Workflow

**Goal:** Complete git workflow from VM.

### 3.1 GitHub Authentication

**File:** `internal/github/gh.go`

**Tasks:**
1. Wrap `gh auth login` for VM
2. Support token-based auth
3. Auth status checking
4. Secure token storage (encrypted in host config or re-auth each session)

### 3.2 Repository Cloning

**Tasks:**
1. `cal isolation clone <workspace> --repo owner/repo`
2. Support `--branch` for existing branch
3. Support `--new-branch` with prefix (default: `agent/`)
4. Clone into `~/workspace/{repo}` in VM

### 3.3 Commit and Push

**Tasks:**
1. `cal isolation commit <workspace> --message "msg"`
2. Optional `--push` flag
3. Show git diff before commit
4. Handle uncommitted changes on exit

### 3.4 Pull Request Creation

**Tasks:**
1. `cal isolation pr <workspace> --title "title"`
2. Support `--body` and `--base` flags
3. Use `gh pr create` in VM
4. Return PR URL

### 3.5 Status Display

**Tasks:**
1. Enhanced `cal isolation status <workspace>`
2. Show git status of cloned repos
3. Show uncommitted changes
4. Show current branch

**Deliverable:** Clone → Edit → Commit → PR workflow working.

---

## Phase 4: Environment Plugin System

**Goal:** Pluggable development environments.

### 4.1 Plugin Manifest Schema

**File:** `internal/env/plugin.go`

**Tasks:**
1. Define manifest YAML schema:
   ```yaml
   name: string
   display_name: string
   requires: []string
   provides: []string
   size_estimate: string
   install:
     env: map[string]string
     brew: []string
     cask: []string
     post_install: []string
   verify: []VerifyCommand
   artifacts: ArtifactConfig
   ```
2. Parse and validate manifests
3. Store in `~/.cal/environments/plugins/`

### 4.2 Plugin Registry

**File:** `internal/env/registry.go`

**Tasks:**
1. Discover plugins from core/ and community/
2. Track installed environments per workspace
3. Dependency resolution (e.g., android requires java)
4. Cache downloaded SDKs

### 4.3 Core Plugins

Create manifests for:
- `ios` - Xcode, Swift, simulators (~30GB)
- `android` - SDK, Gradle, Kotlin (~12GB)
- `java` - OpenJDK 17 (~500MB)
- `node` - Node.js LTS (~200MB)
- `python` - Python 3.12 (~500MB)
- `go` - Go toolchain (~500MB)
- `rust` - Rust/Cargo (~1GB)

### 4.4 Environment CLI Commands

**Tasks:**
1. `cal isolation env list <workspace>`
2. `cal isolation env install <workspace> <env>`
3. `cal isolation env remove <workspace> <env>`
4. `cal isolation env verify <workspace>`
5. `cal isolation env info <env>`

### 4.5 VM Templates

**Tasks:**
1. Define template schema
2. Create templates: minimal, ios, android, mobile, backend
3. `cal isolation init --template <name>`
4. Auto-install environments on first start

**Deliverable:** Multi-platform development with pluggable environments.

---

## Phase 5: TUI & Polish

**Goal:** Full terminal UI experience.

### 5.1 Workspace Selector

**Tasks:**
1. Interactive list of workspaces
2. Show status (running/stopped)
3. Quick actions (start, stop, ssh, run)

### 5.2 Real-time Status

**Tasks:**
1. VM resource usage
2. Active processes
3. Git status
4. Environment status

### 5.3 Log Streaming

**Tasks:**
1. `cal isolation logs <workspace> --follow`
2. Build log capture
3. Agent output capture

### 5.4 Multiple VMs

**Tasks:**
1. Support running multiple VMs simultaneously
2. Apple limits: max 2 concurrent VMs
3. VM switching in TUI

**Deliverable:** Complete TUI for CAL.

---

## Recommended Order of Implementation

### Immediate (Phase 0)
1. Complete manual VM setup following bootstrap guide
2. Verify all agents work
3. Create safety snapshot
4. Begin using for development

### Short-term (Phase 1)
1. Project scaffolding (1.1)
2. Configuration management (1.2)
3. Tart wrapper (1.3)
4. CLI commands (1.6)
5. Snapshot management (1.4)
6. SSH management (1.5)

### Medium-term (Phases 2-3)
1. Status banner (2.2)
2. Launch confirmation (2.3)
3. Agent management (2.4)
4. GitHub auth (3.1)
5. Clone/commit/PR (3.2-3.4)
6. TUI framework (2.1)
7. SSH tunnel with overlay (2.5)

### Long-term (Phases 4-5)
1. Plugin system (4.1-4.4)
2. Core plugins (4.3)
3. Templates (4.5)
4. Full TUI (5.1-5.4)

---

## Testing Strategy

### Unit Tests
- Configuration parsing
- Git command generation
- SSH command building

### Integration Tests
- VM lifecycle
- Snapshot operations
- SSH connectivity

### End-to-End Tests
- Full workflow: init → start → clone → run → commit → pr
- Agent installation verification
- Rollback verification

### Manual Testing
- Destructive operation containment
- Network interruption recovery
- VM crash recovery

---

## Dependencies to Install (for development)

```bash
# On host (for building CAL)
brew install go
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Verify
go version
golangci-lint --version
```

---

## Next Action

**Complete Phase 0 first:**
1. Set up base VM with all agents
2. Create safety snapshot
3. Verify rollback works
4. Use for actual development

Then proceed to Phase 1 CLI implementation.
