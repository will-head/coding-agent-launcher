# CAL Implementation Plan

> 🎯 **THIS IS THE SINGLE SOURCE OF TRUTH FOR PROJECT STATUS AND TODOS**
>
> - Phase completion is determined by checkboxes below
> - All TODOs must be tracked here (code TODOs should reference this file)
> - Design decisions are in [ADR-001](adr/ADR-001-cal-isolation.md) (immutable)

## Current Status

**Phase 0 (Bootstrap):** Mostly complete (4 testing TODOs in 0.8, 9 enhancement TODOs in 0.9)
- [x] Research Tart capabilities
- [x] Document manual setup process
- [x] Create automated vm-setup script
- [x] Set up base VM with agents (automated via script)
- [x] Create clean snapshot for rollback (documented)
- [x] Investigate and test terminal keybindings (all working correctly)
- [x] **Create cal-bootstrap script** - unified VM management
  - [x] `--init`: Create cal-clean, cal-dev, cal-initialised VMs
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
  - [ ] **TODO: Fix Cursor agent login reliability** - Sometimes fails to authenticate even with keychain unlocked. Needs investigation of Cursor credential storage mechanism.
- [ ] **VM Management Improvements** (Phase 0.8 - 9 TODOs pending)
  - [ ] Add --restart/-r option to cal-bootstrap
  - [ ] Check VM keyboard layout matches host
  - [ ] Add Screen Sharing instructions for agent login failures
  - [ ] Investigate High Performance mode issues
  - [ ] Investigate SSH alternatives for shell access
  - [ ] Add git status warning on restore
  - [ ] Check for uncommitted/unpushed changes before restore
  - [ ] Simplify snapshot list output
  - [ ] Add VM detection capability for agents

**All subsequent phases:** Not started

### Known Issues
- [ ] **Cursor Agent login keychain fix** - Implemented keychain unlock solution based on [Tart FAQ](https://tart.run/faq/). The `vm-setup.sh` and `cal-bootstrap` scripts now automatically unlock the login keychain to enable agent authentication via SSH. First-time login still requires browser-based OAuth (use Screen Sharing: `open vnc://$(tart ip cal-dev)` and run `agent` in VM Terminal). After initial auth, credentials persist. See [docs/cursor-login-fix.md](cursor-login-fix.md) for details.

---

## Phase 0: Bootstrap (Immediate Priority)

**Goal:** Run AI coding agents safely in a VM TODAY using manual process.

### Tasks

#### 0.1 Base VM Setup
```bash
# On host machine
brew install cirruslabs/cli/tart
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-dev
tart set cal-dev --cpu 4 --memory 8192 --disk-size 80
tart run cal-dev
```

#### 0.2 VM Agent Installation

**Automated (Recommended):**
Transfer and run the vm-setup script from the host:
```bash
# On host machine
scp scripts/vm-setup.sh admin@<vm-ip>:~/

# In VM
chmod +x ~/vm-setup.sh
~/vm-setup.sh
source ~/.zshrc
gh auth login
```

**Manual (if needed):**
Inside VM (admin/admin):
```bash
# Core tools
brew update && brew upgrade
brew install node gh

# Claude Code
npm install -g @anthropic-ai/claude-code

# Cursor CLI
curl -fsSL https://cursor.com/install | bash

# opencode
curl -fsSL https://opencode.ai/install | bash

# Configure PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.zshrc
echo 'export TERM=xterm-256color' >> ~/.zshrc
echo 'bindkey "^[[A" up-line-or-history' >> ~/.zshrc
source ~/.zshrc

# Verify installations
claude --version
agent --version
opencode --version
gh --version

# GitHub CLI auth
gh auth login
```

#### 0.3 Safety Snapshot
```bash
# On host
tart stop cal-dev
tart clone cal-dev cal-dev-clean
tart run cal-dev
```

#### 0.4 Verification
- [x] `claude --version` works in VM
- [x] `opencode --version` works in VM
- [x] `agent --version` works in VM (Cursor CLI)
- [x] `gh auth status` shows authenticated
- [x] Rollback works: `tart delete cal-dev && tart clone cal-dev-clean cal-dev`

#### 0.5 Terminal Environment Improvements
- [x] Fix TERM setting for delete key (`xterm-256color`)
- [x] Fix up arrow history navigation
- [x] Create comprehensive keybinding test plan (docs/terminal-keybindings-test.md)
- [x] **Execute keybinding tests** ✅
  - Tested navigation keys (arrows, Home, End, Page Up/Down) - all working
  - Tested editing keys (Delete, Backspace, Ctrl+K/U/W/Y) - all working
  - Tested Emacs-style cursor movement (Ctrl+A/E/B/F/P/N) - all working
  - Tested Option/Alt word navigation (Option+Arrow, Option+Backspace) - all working
  - Documented escape sequences in test plan
  - **Conclusion:** No additional fixes needed beyond existing TERM and bindkey settings

#### 0.6 macOS Auto-Login for Screen Sharing

**Completed:**
- [x] Enable auto-login in vm-setup.sh
- [x] Configure macOS to automatically log in admin user on boot
- [x] Fix Screen Sharing showing lock screen instead of desktop
- [x] Add user notification about auto-login being enabled
- [x] Document that auto-login takes effect on next VM reboot

**Deliverable:** ✅ Auto-login configured - Screen Sharing now shows desktop instead of lock screen after VM reboot.

#### 0.7 Keychain Access for Cursor Agent

**Completed:**
- [x] Research keychain issue from Tart FAQ
- [x] Implement keychain unlock in vm-setup.sh
- [x] Implement keychain unlock in cal-bootstrap (--run mode)
- [x] Create test script (test-cursor-login.sh)
- [x] Document solution in cursor-login-fix.md

**Testing Required:**
- [ ] **USER TODO: Complete Phase 0.7 testing** - Follow TESTING.md checklist to verify keychain solution
  - [ ] Test agent login via Screen Sharing after keychain unlock
  - [ ] Verify credentials persist after successful login
  - [ ] Test credential persistence across VM reboots
  - [ ] Verify keychain auto-unlock on cal-bootstrap --run

**Deliverable:** Keychain automatically unlocked when connecting to VM, enabling Cursor agent authentication via SSH sessions.

#### 0.8 VM Management Improvements

**Pending TODOs:**
- [ ] Add `--restart` / `-r` option to cal-bootstrap for quick VM restart
- [ ] Check VM keyboard layout matches host keyboard layout
- [ ] Add instructions to use Screen Sharing (standard mode, not High Performance) if login fails for Claude Agent, Cursor Agent, or opencode
- [ ] Investigate why High Performance Screen Sharing mode doesn't work properly
- [ ] Investigate if there's a better option than SSH for true shell access
- [ ] Add warning on snapshot restore to check that git is updated in VM (uncommitted changes will be lost)
- [ ] Investigate if uncommitted or unpushed git changes can be automatically checked if they exist in VM before restore
- [ ] Remove distinction between clones and snapshots in `--snapshot list` (they're functionally the same for our purposes)
- [ ] Create method for coding agent to detect if it's running in a VM and add this capability to coding agent's config

**Deliverable:** Enhanced VM management with better safety checks, clearer UX, and agent VM detection.

---

## Phase 1: CLI Foundation

**Goal:** Replace manual Tart commands with `cal isolation` CLI.

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
