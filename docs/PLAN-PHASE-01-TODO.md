# Phase 1 (CLI Foundation) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Replace manual Tart commands with `cal isolation` CLI.

**Deliverable:** Working `cal isolation` CLI that wraps Tart operations.

---

## Pending TODOs

- [ ] Make cached macos-sequoia-base:latest available inside cal-dev to avoid duplicate downloading

---

## 1.1 Project Scaffolding

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
```

---

## 1.3 Tart Wrapper

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

---

## 1.4 Snapshot Management

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

---

## 1.5 SSH Management

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

---

## 1.6 CLI Commands (Cobra)

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
