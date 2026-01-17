# ADR-001: cal-isolation Architecture and Implementation

## Component of Coding Agent Loader (CAL)

**ADR:** 001  
**Status:** Proposed  
**Module:** `cal-isolation`  
**Parent Project:** Coding Agent Loader (CAL)  
**Created:** 2026-01-17  
**Purpose:** Isolated macOS VM environment for running AI coding agents safely

---

## Decision

We will create `cal-isolation`, a VM-based sandboxing system that allows AI coding agents (Claude Code, Cursor CLI, opencode) to run in complete isolation from the host filesystem while providing a familiar, interactive terminal experience.

---

## Language Selection: Go

### Decision

**Go** with the Charm toolkit (`bubbletea`, `lipgloss`, `bubbles`) for TUI development.

### Rationale

| Criterion | Go | Rust | Swift | TypeScript |
|-----------|-----|------|-------|------------|
| TUI Framework | ⭐ bubbletea (best) | ratatui (excellent) | Basic/DIY | ink (good) |
| CLI Framework | cobra (mature) | clap (excellent) | ArgumentParser | commander |
| Compile Speed | Fast | Slow | Medium | N/A (interpreted) |
| Binary Distribution | Single binary | Single binary | Single binary | Requires runtime |
| macOS GUI Path | Wails/IPC | Tauri/bindings | SwiftUI (native) | Electron/Tauri |
| Learning Curve | Low | High | Medium | Low |
| Domain Fit | Excellent | Excellent | Good | Fair |

### Why Go Wins

1. **TUI is critical path** - `bubbletea` is the gold standard for terminal UIs. Used by GitHub CLI, `gum`, `glow`, and most modern CLI tools.

2. **Perfect domain fit** - Go excels at:
   - Process management (starting/stopping VMs)
   - SSH connections (`golang.org/x/crypto/ssh`)
   - Concurrent operations (goroutines for file watching, log streaming)
   - Shelling out to Tart CLI

3. **Fast iteration** - Quick compile times, simple testing, easy deployment.

4. **Single binary** - `go build` produces one distributable file.

5. **Community alignment** - Modern DevOps/CLI tools are predominantly Go.

### macOS GUI Path (Future)

When ready for native GUI:
- **Option A:** Wails (Go + web frontend) - good enough for most cases
- **Option B:** Go backend + Swift GUI over IPC/gRPC - native feel
- **Option C:** Keep TUI primary, add menu bar app with `systray`

### Project Structure

```
cal/
├── cmd/
│   └── cal/
│       └── main.go                 # Entry point
├── internal/
│   ├── tui/                        # bubbletea UI
│   │   ├── app.go                  # Main TUI application
│   │   ├── banner.go               # Safety status banner
│   │   ├── confirm.go              # Launch confirmation screen
│   │   └── styles.go               # lipgloss styling
│   ├── isolation/                  # VM management
│   │   ├── tart.go                 # Tart CLI wrapper
│   │   ├── snapshot.go             # Snapshot management
│   │   └── ssh.go                  # SSH tunnel handling
│   ├── agent/                      # Agent integrations
│   │   ├── agent.go                # Common interface
│   │   ├── claude.go               # Claude Code
│   │   ├── cursor.go               # Cursor CLI
│   │   └── opencode.go             # opencode
│   ├── env/                        # Environment plugins
│   │   ├── plugin.go               # Plugin interface
│   │   ├── registry.go             # Plugin registry
│   │   └── plugins/                # Built-in plugins
│   │       ├── ios.go
│   │       ├── android.go
│   │       └── node.go
│   ├── github/                     # GitHub integration
│   │   └── gh.go                   # gh CLI wrapper
│   └── config/                     # Configuration
│       └── config.go
├── go.mod
└── go.sum
```

### Key Dependencies

```go
require (
    github.com/charmbracelet/bubbletea     // TUI framework
    github.com/charmbracelet/lipgloss      // Styling
    github.com/charmbracelet/bubbles       // UI components
    github.com/spf13/cobra                 // CLI framework
    github.com/spf13/viper                 // Configuration
    golang.org/x/crypto/ssh                // SSH client
    gopkg.in/yaml.v3                       // YAML parsing
)
```

### Alternatives Considered

**Rust with ratatui:**
- Pros: Excellent performance, strong typing, great TUI
- Cons: Steeper learning curve, slower iteration
- Verdict: Good choice if performance critical or learning Rust is a goal

**Swift:**
- Pros: Native macOS, direct SwiftUI path for GUI
- Cons: Weak TUI ecosystem, would need to build more infrastructure
- Verdict: Consider if native GUI is near-term priority

**TypeScript:**
- Pros: Fast development, familiar, good `ink` framework
- Cons: Requires Node runtime, slower startup
- Verdict: Good for prototyping, less ideal for distribution

---

## Context

AI coding agents running with elevated permissions can perform destructive operations. This ADR defines the architecture for running these agents safely in isolated VMs while maintaining a seamless developer experience.

### CAL Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   CODING AGENT LOADER (CAL)                     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      CAL Core                            │   │
│  │  - TUI Interface (Phase 1)                               │   │
│  │  - macOS GUI (Future)                                    │   │
│  │  - Agent orchestration                                   │   │
│  │  - Configuration management                              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│         ┌────────────────────┼────────────────────┐            │
│         ▼                    ▼                    ▼            │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │cal-isolation│     │ cal-agents  │     │  cal-git    │       │
│  │             │     │             │     │             │       │
│  │ Tart VM     │     │ Claude Code │     │ GitHub      │       │
│  │ management  │     │ opencode    │     │ integration │       │
│  │             │     │ Cursor CLI  │     │             │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

### Development Environments (Pluggable)

cal-isolation supports multiple development environments through a plugin system. Environments can be installed, removed, and combined as needed within a single VM.

```
┌─────────────────────────────────────────────────────────────────┐
│                    VM ENVIRONMENT STACK                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   AI Coding Agents                       │   │
│  │     Claude Code  │  opencode  │  Cursor CLI             │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Development Environments                    │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │   │
│  │  │  iOS/   │ │ Android │ │  .NET/  │ │  Rust/  │  ...   │   │
│  │  │ macOS   │ │         │ │   C#    │ │  Go/C++ │        │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Base macOS VM                         │   │
│  │              (Tart + Homebrew + Git + gh)                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Supported Environment Categories:**

| Category | Environments | Key Tools |
|----------|--------------|-----------|
| **Apple** | iOS, macOS, watchOS, tvOS, visionOS | Xcode, Swift, SwiftUI, UIKit |
| **Android** | Android apps, Wear OS | Android Studio, Gradle, Kotlin, Java |
| **Cross-Platform Mobile** | Flutter, React Native, .NET MAUI | Flutter SDK, Node.js, .NET SDK |
| **Backend** | Node.js, Python, Go, Rust, Java | Runtime + package managers |
| **Desktop** | Electron, Tauri, .NET WPF/macOS | Node.js, Rust, .NET SDK |
| **Systems** | C/C++, Rust, Go | Clang, GCC, Cargo, Go toolchain |
| **Web** | Frontend, Full-stack | Node.js, Bun, Deno |
| **Data/ML** | Python ML, Jupyter | Python, conda, PyTorch, TensorFlow |

**Example: Cross-Platform Mobile Development Session**

```bash
# Create workspace with both iOS and Android support
cal isolation init mobile-app \
  --env ios \
  --env android \
  --agent claude-code

# Clone cross-platform project
cal isolation clone mobile-app --repo owner/my-flutter-app

# Run agent to build both platforms
cal isolation run mobile-app --prompt "Build and test for both iOS and Android"

# Artifacts for both platforms synced to host
ls ~/cal-output/mobile-app/builds/
# MyApp.ipa
# MyApp.apk
```

### Problem Statement

AI coding agents (Claude Code, opencode, Cursor CLI) running with elevated permissions can perform destructive operations including deleting the user's home directory. CAL provides a unified interface for managing these agents safely, with `cal-isolation` handling the VM-based sandboxing.

### Solution

`cal-isolation` provisions and manages Tart macOS VMs that provide:
- Complete filesystem isolation from host
- GitHub-based workflow (clone → edit → commit → PR)
- Support for multiple AI coding agents
- Multi-platform development capability (iOS, Android, .NET, etc.)
- Headless operation for unattended tasks

---

## User Experience

### Core UX Principle

**The agent experience inside the VM should be identical to running locally** - same terminal interaction, same commands, same workflow. The only differences are:
1. A status banner showing isolation is active
2. A confirmation prompt before launching

### Terminal Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 🔒 CAL ISOLATION ACTIVE │ VM: my-workspace │ Env: ios,android │ Safe Mode  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ╭─────────────────────────────────────────────────────────────────────╮   │
│  │                                                                     │   │
│  │  $ claude                                                           │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ Claude Code                                                  │   │   │
│  │  │                                                              │   │   │
│  │  │ > Help me refactor the authentication module                │   │   │
│  │  │                                                              │   │   │
│  │  │ I'll help you refactor the auth module. Let me first       │   │   │
│  │  │ examine the current structure...                            │   │   │
│  │  │                                                              │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  ╰─────────────────────────────────────────────────────────────────────╯   │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ [S]napshot │ [C]ommit │ [P]R │ [R]ollback │ [Q]uit                   │ ?:Help │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Status Banner

The banner at the top shows:
- 🔒 **Lock icon** - Visual confirmation of isolation
- **VM name** - Which workspace is active
- **Environments** - Installed dev environments (ios, android, node, etc.)
- **Safe Mode** - Confirmation that destructive operations are contained

**Banner colors:**
- 🟢 Green background = VM running, isolation active
- 🟡 Yellow background = VM starting/stopping
- 🔴 Red background = Error state

### Launch Confirmation

Before starting the agent, CAL shows a confirmation:

```
┌─────────────────────────────────────────────────────────────────┐
│                    🔒 CAL Isolation Check                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Workspace:     my-workspace                                    │
│  VM Status:     ● Running                                       │
│  Isolation:     ✓ Active - Host filesystem protected            │
│  Environments:  ios, android                                    │
│  Agent:         Claude Code                                     │
│  Repository:    owner/my-app (branch: agent/feature)            │
│                                                                 │
│  ⚠️  The agent will have full access within the VM.             │
│      Your host system and other files are protected.            │
│                                                                 │
│  Last backup: 2 minutes ago (auto-snapshot)                     │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│            [Enter] Launch Agent    [B] Backup First    [Q] Quit │
└─────────────────────────────────────────────────────────────────┘
```

### Interaction Flow

1. User runs `cal isolation run my-workspace`
2. CAL verifies VM is running and isolation is active
3. Confirmation screen shown (can be skipped with `--yes`)
4. Auto-snapshot taken if enabled
5. SSH tunnel established to VM
6. Agent launched with status banner visible
7. User interacts with agent normally (exactly like local)
8. On exit, prompt to commit/push changes

### Agent Interaction

Once launched, the agent (Claude Code, Cursor CLI, etc.) works **exactly as it would locally**:
- Same keyboard shortcuts
- Same command interface
- Same file editing capabilities
- Same terminal output

The only difference is the status banner reminding user they're protected.

---

## Research Summary

### Tart Overview

Tart is an open-source virtualization toolset by Cirrus Labs, designed specifically for Apple Silicon Macs. Key characteristics:

- **Performance:** Uses Apple's native Virtualization.Framework for near-native performance (~97% native in benchmarks)
- **Architecture:** CLI-first, designed for automation and CI/CD pipelines
- **Distribution:** VM images distributed via OCI-compatible container registries (like Docker images)
- **Licensing:** Fair Source License - royalty-free for personal workstations
- **Requirements:** Apple Silicon Mac, macOS 13.0 (Ventura) or later

### Available Pre-built Images

Cirrus Labs maintains official images. We use the **base** image as our starting point:

| Image Type | Description | Size | Use |
|------------|-------------|------|-----|
| `macos-{version}-vanilla` | Clean macOS with auto-login only | ~20 GB | Custom builds |
| **`macos-{version}-base`** | **Homebrew + common dev tools, no Xcode** | **~25 GB** | **Our default** |
| `macos-{version}-xcode:N` | Base + Xcode N pre-installed | ~54 GB | Not used directly |

**Why `macos-base`?**
- Homebrew pre-installed (essential for our plugin system)
- SSH enabled and configured
- Auto-login configured for headless operation
- No Xcode = smaller image, faster clone
- Xcode installed via environment plugin only when needed

**Supported macOS versions:** Tahoe (26), Sequoia (15), Sonoma (14)

**Registry location:** `ghcr.io/cirruslabs/macos-{version}-base:latest`

### Directory Mounting Capabilities

Tart supports mounting host directories into the VM using VirtioFS:

```bash
# Basic mount
tart run --dir=project:~/src/project my-vm

# Read-only mount (critical for protection)
tart run --dir=project:~/src/project:ro my-vm

# Multiple directories
tart run --dir=src:~/projects/app --dir=output:~/output my-vm
```

**Mount behavior:**
- Directories appear at `/Volumes/My Shared Files/{name}` inside the VM
- Can be remounted to custom locations inside VM
- Read-only mode prevents any writes back to host
- Requires macOS 13.0+ on both host and guest

### Headless Operation

Tart supports running VMs without a GUI window:

```bash
# Run headless with VNC available for debugging
tart run my-vm --no-graphics --vnc

# Access via SSH
ssh admin@$(tart ip my-vm)
```

**Default credentials:** `admin`/`admin`

### VM Management Commands

```bash
# Clone image from registry
tart clone ghcr.io/cirruslabs/macos-sequoia-xcode:latest my-dev-vm

# Configure resources
tart set my-dev-vm --cpu 4 --memory 8192 --disk-size 100

# List VMs
tart list

# Get VM info
tart get my-dev-vm

# Get VM IP
tart ip my-dev-vm

# Delete VM
tart delete my-dev-vm
```

### iOS Simulator Support

- iOS Simulator works inside Tart macOS VMs
- Xcode images come with simulator runtimes pre-installed
- Can run xcodebuild tests against simulators
- Requires "Aqua session" for UI framework operations (auto-login helps)

### Known Limitations & Considerations

1. **Nested virtualization:** Limited or not supported depending on chip/OS version
2. **Network permissions:** Some newer macOS versions require GUI approval for local network access on first run
3. **Keychain in headless mode:** May require manual unlocking for certain operations
4. **Disk space:** VM images are large (25-54+ GB); plan for storage
5. **Apple licensing:** Permits running macOS VMs only on Apple hardware, limited to 2 concurrent VMs

---

## Functional Requirements

### Core Features

#### FR-1: VM Provisioning
- [ ] Clone pre-built base images from Cirrus Labs registry
- [ ] Configure VM resources (CPU, memory, disk size)
- [ ] Set up SSH access with custom credentials
- [ ] Generate random MAC address and serial for each VM instance
- [ ] Install GitHub CLI (`gh`) in VM
- [ ] Support VM templates with pre-configured environments

#### FR-2: Environment Plugin System
- [ ] Define environments via manifest.yaml plugins
- [ ] Install/remove environments on demand
- [ ] Handle environment dependencies automatically
- [ ] Verify environment installations
- [ ] Support custom/community environment plugins
- [ ] Manage environment variables and PATH
- [ ] Cache downloaded SDKs/tools for faster reinstall

#### FR-3: Multi-Agent Support
- [ ] Install and configure Claude Code
- [ ] Install and configure opencode
- [ ] Install and configure Cursor CLI
- [ ] Agent-specific permission/configuration management
- [ ] Switch between agents within same VM
- [ ] Agent-agnostic prompt passing

#### FR-4: GitHub Integration
- [ ] Authenticate with GitHub via `gh auth login`
- [ ] Clone repositories into VM workspace
- [ ] Support branch creation for agent work
- [ ] Commit changes with meaningful messages
- [ ] Push to remote branches
- [ ] Create pull requests from VM

#### FR-5: Headless Operation
- [ ] Run VMs without GUI by default
- [ ] Provide VNC access for debugging when needed
- [ ] Automated SSH connection management
- [ ] Health checks to verify VM is responsive

#### FR-6: Multi-Platform Development
- [ ] iOS/macOS builds with Xcode and simulators
- [ ] Android builds with Android SDK and emulators
- [ ] .NET/C# builds with dotnet CLI
- [ ] Cross-platform builds (Flutter, React Native, MAUI)
- [ ] Backend development (Node, Python, Go, Rust)
- [ ] Sync appropriate artifacts for each platform

#### FR-7: Lifecycle Management
- [ ] Start/stop VM commands
- [ ] Snapshot/restore for quick reset to known state
- [ ] Cleanup of old VMs and cache
- [ ] Status reporting including git status and installed environments

#### FR-8: CAL Integration
- [ ] Expose API for CAL core to manage VMs
- [ ] Event emission for TUI updates
- [ ] Configuration inheritance from CAL global config
- [ ] Shared authentication/credentials with CAL

---

## Technical Architecture

### cal-isolation Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOST MACHINE                             │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     CAL (Main Process)                    │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────┐  │  │
│  │  │    TUI     │  │  Agent     │  │   cal-isolation    │  │  │
│  │  │ Interface  │  │  Selector  │  │   (this module)    │  │  │
│  │  └────────────┘  └────────────┘  └────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    OUTPUT DIRECTORY                       │  │
│  │  ~/cal-output  ◀─────  Build artifacts synced from VM    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│         ┌───────────────────────────────────────────────────┐  │
│         │              TART VM (Managed by cal-isolation)   │  │
│         │                                                   │  │
│         │  ┌─────────────────────────────────────────────┐  │  │
│         │  │              GitHub CLI (gh)                │  │  │
│         │  │  - Clone repos directly into VM             │  │  │
│         │  │  - Commit and push changes                  │  │  │
│         │  └─────────────────────────────────────────────┘  │  │
│         │                                                   │  │
│         │  ┌─────────────────────────────────────────────┐  │  │
│         │  │           AI Coding Agent                   │  │  │
│         │  │  ┌───────────┬───────────┬──────────────┐   │  │  │
│         │  │  │  Claude   │ opencode  │  Cursor CLI  │   │  │  │
│         │  │  │   Code    │           │              │   │  │  │
│         │  │  └───────────┴───────────┴──────────────┘   │  │  │
│         │  └─────────────────────────────────────────────┘  │  │
│         │                                                   │  │
│         │  ┌─────────────────────────────────────────────┐  │  │
│         │  │         Xcode + iOS Simulator              │  │  │
│         │  └─────────────────────────────────────────────┘  │  │
│         └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

                              │
                              │ HTTPS/SSH
                              ▼
                    ┌───────────────────┐
                    │      GitHub       │
                    └───────────────────┘
```

### Key Benefits of GitHub-Based Workflow

1. **Complete isolation:** No filesystem connection between host and VM
2. **Full editing capability:** Agents can freely modify, create, delete files
3. **Version control built-in:** All changes tracked via git
4. **Safe experimentation:** Work on branches, discard if needed
5. **PR workflow:** Changes can be reviewed before merging
6. **Audit trail:** Full git history of all changes made
7. **Agent-agnostic:** Same isolation works for any coding agent

### Directory Structure (Host)

```
~/.cal/                              # CAL main configuration
├── config.yaml                      # Global CAL configuration
├── agents/                          # Agent-specific configs
│   ├── claude-code.yaml
│   ├── opencode.yaml
│   └── cursor-cli.yaml
├── environments/                    # Environment plugin system
│   ├── registry.yaml                # Available environments index
│   ├── plugins/                     # Plugin definitions
│   │   ├── core/                    # Built-in environments
│   │   │   ├── ios/
│   │   │   ├── android/
│   │   │   ├── dotnet/
│   │   │   ├── flutter/
│   │   │   ├── node/
│   │   │   ├── python/
│   │   │   ├── rust/
│   │   │   └── go/
│   │   └── community/               # User-installed plugins
│   └── cache/                       # Downloaded SDKs/tools
└── isolation/                       # cal-isolation specific
    ├── vms/                         # VM metadata
    │   └── {vm-name}/
    │       ├── vm.yaml              # VM-specific config
    │       ├── environments.yaml    # Installed environments
    │       └── github-token         # Encrypted GH token (optional)
    ├── templates/                   # Reusable VM templates
    │   ├── minimal/
    │   ├── ios/
    │   ├── android/
    │   ├── mobile-full/
    │   └── backend/
    └── logs/                        # Operation logs

~/cal-output/                        # Build artifacts synced from VM
└── {vm-name}/
    ├── builds/                      # .app, .ipa, .apk, .exe, etc.
    ├── test-results/                # Test output bundles
    └── logs/                        # Build logs
```

### Directory Structure (VM)

```
/Users/admin/
├── workspace/                       # Working directory
│   └── {repo-name}/                 # Cloned from GitHub
│       ├── .git/                    # Full git history
│       └── ...                      # Project files
├── .config/
│   ├── gh/                          # GitHub CLI authentication
│   └── {agent}/                     # Agent-specific config
│       └── settings.json            # Permissions
├── .cal-env/                        # Environment marker files
│   ├── ios.installed
│   ├── android.installed
│   └── ...
├── Library/
│   └── Android/sdk/                 # Android SDK (if installed)
└── output/                          # Build artifacts (synced to host)
```

---

## Session Backup and Rollback

### Overview

Every session can be protected by automatic snapshots, allowing instant rollback if the VM gets trashed by an agent. This balances disk space usage against recovery speed.

### Backup Strategies

| Strategy | Disk Usage | Recovery Time | Use Case |
|----------|------------|---------------|----------|
| **None** | 0 | N/A (recreate VM) | Ephemeral workspaces |
| **Session Start** | ~2-5 GB | ~30 seconds | Default - restore to session start |
| **Periodic** | ~5-15 GB | ~30 seconds | Long sessions, checkpoint every N minutes |
| **Full Clone** | ~50-100 GB | ~2 minutes | Critical work, full VM copy |

### Default Behavior: Session Start Snapshot

```bash
cal isolation run my-workspace
# 1. Auto-creates snapshot "session-2026-01-17-1430"
# 2. Launches agent
# 3. On exit, prompts: Keep changes? Rollback? Create named snapshot?
```

### Snapshot Implementation

Tart supports copy-on-write snapshots via `tart clone`:

```bash
# Create snapshot (fast, ~2-5 GB for changes)
tart clone my-workspace my-workspace-backup-20260117

# Restore from snapshot (fast, ~30 seconds)
tart delete my-workspace
tart clone my-workspace-backup-20260117 my-workspace

# List snapshots
tart list | grep my-workspace
```

### Snapshot Management

```yaml
# ~/.cal/config.yaml
isolation:
  snapshots:
    auto_snapshot_on_session_start: true
    max_auto_snapshots: 3              # Keep last 3 session snapshots
    auto_cleanup_after_days: 7         # Delete old snapshots
    snapshot_prefix: "session"
```

### CLI Commands

```bash
# Manual snapshot
cal isolation snapshot create my-workspace --name "before-refactor"

# List snapshots
cal isolation snapshot list my-workspace
# NAME                         CREATED              SIZE
# session-2026-01-17-1430      10 minutes ago       2.1 GB
# session-2026-01-17-0900      5 hours ago          3.4 GB
# before-refactor              2 days ago           1.8 GB

# Rollback to snapshot
cal isolation snapshot restore my-workspace --name "session-2026-01-17-1430"

# Rollback to session start (shortcut)
cal isolation rollback my-workspace

# Delete snapshot
cal isolation snapshot delete my-workspace --name "before-refactor"
```

### Recovery Scenarios

**Scenario 1: Agent trashed the workspace**
```bash
# Quick rollback to session start
cal isolation rollback my-workspace
# Restored to snapshot: session-2026-01-17-1430 (30 seconds)
```

**Scenario 2: Want to undo last hour of changes**
```bash
cal isolation snapshot list my-workspace
cal isolation snapshot restore my-workspace --name "session-2026-01-17-1330"
```

**Scenario 3: VM completely broken, need fresh start**
```bash
# Delete and recreate from template
cal isolation destroy my-workspace
cal isolation init my-workspace --template mobile
```

### Disk Space Considerations

**Snapshot sizing:**
- Base VM: ~25 GB (macos-base image)
- Each snapshot: ~2-5 GB (copy-on-write, only stores changes)
- With 3 auto-snapshots: ~35-40 GB total

**Cleanup commands:**
```bash
# Remove all auto-snapshots
cal isolation snapshot cleanup my-workspace --auto-only

# Remove snapshots older than 7 days
cal isolation snapshot cleanup my-workspace --older-than 7d

# Show disk usage
cal isolation disk-usage my-workspace
# VM:        24.2 GB
# Snapshots: 8.4 GB (3 snapshots)
# Total:     32.6 GB
```

---

### Overview

Each development environment is defined as a plugin with a standard interface. Environments can be installed, removed, and combined within a single VM, enabling multi-platform development sessions.

### Plugin Manifest Schema

Each environment plugin defines a `manifest.yaml`:

```yaml
# ~/.cal/environments/plugins/core/android/manifest.yaml
name: android
display_name: "Android Development"
version: "1.0.0"
description: "Android app development with Kotlin/Java"

# Dependencies on other environments
requires:
  - java  # Will auto-install if not present

# Optional enhancements
recommends:
  - node  # For React Native projects

# What this environment provides
provides:
  - android-sdk
  - android-ndk
  - gradle
  - kotlin
  - adb
  - emulator

# Disk space estimate
size_estimate: "12GB"

# Installation configuration
install:
  # Environment variables to set
  env:
    ANDROID_HOME: "$HOME/Library/Android/sdk"
    ANDROID_SDK_ROOT: "$HOME/Library/Android/sdk"
  
  # Homebrew packages
  brew:
    - openjdk@17
    - gradle
    - kotlin
  
  # Homebrew casks
  cask:
    - android-commandlinetools
  
  # Post-install commands
  post_install:
    - sdkmanager --install "platform-tools"
    - sdkmanager --install "platforms;android-34"
    - sdkmanager --install "build-tools;34.0.0"

# Verification commands
verify:
  - command: "adb --version"
    expect_contains: "Android Debug Bridge"
  - command: "gradle --version"
    expect_contains: "Gradle"

# Build artifact patterns for sync
artifacts:
  patterns:
    - "*.apk"
    - "*.aab"
    - "build/outputs/**"
```

### Core Environment Plugins

| Environment | Provides | Size | Dependencies |
|-------------|----------|------|--------------|
| `ios` | Xcode, Swift, SwiftUI, simulators, xctest | ~30GB | - |
| `android` | Android SDK, Gradle, Kotlin, ADB, emulator | ~12GB | java |
| `java` | OpenJDK 17, Maven, Gradle | ~500MB | - |
| `dotnet` | .NET SDK 8, C#, F#, MAUI | ~3GB | - |
| `flutter` | Flutter SDK, Dart | ~2GB | ios?, android? |
| `react-native` | React Native CLI, Metro | ~500MB | node, (ios?, android?) |
| `node` | Node.js 20 LTS, npm, yarn, pnpm | ~200MB | - |
| `python` | Python 3.12, pip, poetry, venv | ~500MB | - |
| `python-ml` | Python + PyTorch, TensorFlow, Jupyter | ~8GB | python |
| `rust` | Rust, Cargo, clippy, rustfmt | ~1GB | - |
| `go` | Go 1.22, golangci-lint | ~500MB | - |
| `cpp` | Clang, CMake, ninja, vcpkg | ~2GB | - |

*Note: `?` indicates optional dependency - Flutter/RN can target one or both platforms*

### iOS Environment Plugin (Full Example)

The iOS environment installs Xcode via `xcodes` CLI, allowing version management:

```yaml
# ~/.cal/environments/plugins/core/ios/manifest.yaml
name: ios
display_name: "iOS/macOS Development"
version: "1.0.0"
description: "Full Apple development with Xcode, Swift, and simulators"

provides:
  - xcode
  - swift
  - swiftui
  - uikit
  - appkit
  - xctest
  - instruments
  - ios-simulator
  - xcodebuild
  - actool
  - ibtool

size_estimate: "30GB"  # Xcode + one simulator runtime

# No dependencies - works on base macOS image

install:
  brew:
    - xcodes           # Xcode version manager
    - swiftlint
    - swiftformat
    - fastlane
    - xcbeautify       # Better xcodebuild output
  
  post_install:
    # Install latest stable Xcode
    - xcodes install --latest --experimental-unxip
    # Accept license
    - sudo xcodebuild -license accept
    # Install iOS simulator runtime
    - xcodes runtimes install "iOS 18.0"
    # Set as active Xcode
    - sudo xcode-select -s /Applications/Xcode.app
  
  env:
    DEVELOPER_DIR: "/Applications/Xcode.app/Contents/Developer"

# Allow installing specific Xcode version
options:
  xcode_version:
    description: "Specific Xcode version to install"
    default: "latest"
    example: "16.0"

verify:
  - command: "xcodebuild -version"
    expect_contains: "Xcode"
  - command: "swift --version"
    expect_contains: "Swift"
  - command: "xcrun simctl list devices"
    expect_contains: "iPhone"

uninstall:
  - rm -rf /Applications/Xcode.app
  - rm -rf ~/Library/Developer/Xcode
  - rm -rf ~/Library/Caches/com.apple.dt.Xcode
  - xcodes runtimes delete "iOS 18.0" || true

artifacts:
  patterns:
    - "*.ipa"
    - "*.xcarchive"
    - "*.app"
    - "*.xcresult"
    - "*.dSYM"
  exclude:
    - "DerivedData/**"
    - "*.xcuserdata"
```

### Android Environment Plugin

```yaml
# ~/.cal/environments/plugins/core/android/manifest.yaml
name: android
display_name: "Android Development"
version: "1.0.0"
description: "Android app development with Kotlin and Java"

requires:
  - java

provides:
  - android-sdk
  - android-ndk
  - gradle
  - kotlin
  - adb
  - android-emulator
  - sdkmanager

size_estimate: "12GB"

install:
  env:
    ANDROID_HOME: "$HOME/Library/Android/sdk"
    ANDROID_SDK_ROOT: "$HOME/Library/Android/sdk"
    PATH: "$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
  
  brew:
    - kotlin
  
  cask:
    - android-commandlinetools
  
  post_install:
    - yes | sdkmanager --licenses || true
    - sdkmanager "platform-tools"
    - sdkmanager "platforms;android-35"
    - sdkmanager "build-tools;35.0.0"
    - sdkmanager "emulator"
    - sdkmanager "system-images;android-35;google_apis;arm64-v8a"
    # Create default emulator
    - avdmanager create avd -n "Pixel_8_API_35" -k "system-images;android-35;google_apis;arm64-v8a" -d "pixel_8" || true

options:
  api_level:
    description: "Android API level to install"
    default: "35"

verify:
  - command: "adb --version"
    expect_contains: "Android Debug Bridge"
  - command: "gradle --version"
    expect_contains: "Gradle"
  - command: "kotlin -version"
    expect_contains: "Kotlin"

artifacts:
  patterns:
    - "*.apk"
    - "*.aab"
    - "build/outputs/**"
  exclude:
    - "build/intermediates/**"
    - ".gradle/**"
```

### Java Environment Plugin (Dependency)

```yaml
name: java
display_name: "Java Development Kit"
version: "1.0.0"

provides:
  - java
  - javac
  - jar

size_estimate: "500MB"

install:
  brew:
    - openjdk@17
  
  post_install:
    - sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
  
  env:
    JAVA_HOME: "$(brew --prefix)/opt/openjdk@17"
    PATH: "$JAVA_HOME/bin:$PATH"

verify:
  - command: "java --version"
    expect_contains: "openjdk 17"
```

### Environment CLI Commands

#### `cal isolation env list`
```bash
cal isolation env list [workspace]
# ENVIRONMENT     STATUS      SIZE      DESCRIPTION
# ios             installed   25.1 GB   iOS/macOS Development
# android         available   ~12 GB    Android Development
# flutter         available   ~2 GB     Flutter (requires: ios, android)
# node            installed   489 MB    Node.js Development
```

#### `cal isolation env install`
```bash
# Install environment into workspace
cal isolation env install my-workspace android

# Install multiple (flutter auto-installs ios + android if missing)
cal isolation env install my-workspace flutter

# Install with options
cal isolation env install my-workspace python --variant ml
```

#### `cal isolation env remove`
```bash
cal isolation env remove my-workspace android
```

#### `cal isolation env verify`
```bash
cal isolation env verify my-workspace
# ✓ ios: Xcode 16.0, Swift 5.10
# ✓ android: SDK 34, Gradle 8.5, Kotlin 1.9.22
# ✓ node: v20.11.0, npm 10.2.0
```

### VM Templates

Pre-configured environment combinations for quick setup. All start from `macos-base`:

| Template | Environments Installed | Total Size | Use Case |
|----------|------------------------|------------|----------|
| `minimal` | (none) | ~25GB | Base macOS, add envs manually |
| `ios` | ios | ~55GB | iOS/macOS development |
| `android` | java, android | ~38GB | Android development |
| `mobile` | ios, java, android | ~67GB | Both mobile platforms |
| `mobile-full` | ios, java, android, flutter, node | ~72GB | All mobile options |
| `cross-platform` | java, android, dotnet, flutter, node | ~45GB | Cross-platform (no iOS) |
| `backend` | node, python, go, rust | ~28GB | Backend/CLI development |
| `fullstack` | ios, node, python | ~58GB | Full-stack + iOS |

```bash
# Use template - environments auto-installed on first start
cal isolation init my-app --template mobile

# Or start minimal and add as needed
cal isolation init my-app --template minimal
cal isolation start my-app
cal isolation env install my-app ios      # Takes ~10-15 min first time
cal isolation env install my-app android  # Takes ~5-10 min
```

**Template Definition Example:**

```yaml
# ~/.cal/isolation/templates/mobile.yaml
name: mobile
description: "iOS + Android native development"
base_image: "ghcr.io/cirruslabs/macos-sequoia-base:latest"

# Environments to install (in order, respecting dependencies)
environments:
  - ios
  - java      # android dependency
  - android

resources:
  cpu: 6
  memory: 12288    # 12 GB - need more for simulators/emulators
  disk_size: 100   # GB - Xcode + Android SDK need space

# Post-setup commands
post_init:
  - echo "Mobile development environment ready!"
```

---

## Configuration Schema

### Global Configuration (`~/.cal/config.yaml`)

```yaml
# CAL Global Configuration
version: 1

isolation:
  defaults:
    vm:
      cpu: 4
      memory: 8192                # MB
      disk_size: 80               # GB - enough for base + a few environments
      base_image: "ghcr.io/cirruslabs/macos-sequoia-base:latest"
    
    github:
      default_branch_prefix: "agent/"
      auto_push: false
      create_pr: false
    
    output:
      sync_dir: "~/cal-output"
      watch_patterns:
        - "*.xcarchive"
        - "*.ipa"
        - "*.apk"
        - "*.aab"
        - "*.app"
        - "*.exe"
        - "*.dll"
        - "*.xcresult"

agents:
  claude-code:
    install_command: "npm install -g @anthropic-ai/claude-code"
    config_dir: "~/.claude"
    default_mode: "acceptEdits"
  
  opencode:
    install_command: "go install github.com/opencode-ai/opencode@latest"
    config_dir: "~/.opencode"
    default_mode: "default"
  
  cursor-cli:
    install_command: "npm install -g @cursor/cli"
    config_dir: "~/.cursor"
    default_mode: "default"

ui:
  theme: "auto"
  show_logs: true
```

### VM Configuration (`~/.cal/isolation/vms/{name}/vm.yaml`)

```yaml
name: "my-ios-workspace"
base_image: "ghcr.io/cirruslabs/macos-sequoia-xcode:16"
created_at: "2026-01-17T10:00:00Z"

resources:
  cpu: 6
  memory: 12288
  disk_size: 150

github:
  authenticated: true
  repos:
    - name: "my-ios-app"
      url: "github.com/owner/my-ios-app"
      branch: "agent/refactor-auth"
      cloned_at: "2026-01-17T10:30:00Z"

# Active agent for this workspace
agent: "claude-code"

# Agent-specific permissions
agent_config:
  claude-code:
    mode: "acceptEdits"
    allowed_tools:
      - "Bash(xcodebuild:*)"
      - "Bash(swift:*)"
      - "Bash(git:*)"
      - "Bash(gh:*)"
      - "Edit(*)"
      - "Read(*)"
    denied_tools:
      - "Bash(rm -rf /)"
      - "Bash(sudo:*)"
  
  opencode:
    auto_approve: ["read", "write"]
    deny: ["shell:sudo*"]

snapshots:
  - name: "clean-install"
    created_at: "2026-01-17T10:30:00Z"
```

---

## CLI Interface Design

### Command Structure

CAL uses a unified CLI with subcommands for each module:

```bash
cal <module> <command> [options]
```

For `cal-isolation`:

```bash
cal isolation <command> [options]

# Shorthand alias
cal iso <command> [options]
```

### cal-isolation Commands

#### `cal isolation init`
Initialize a new isolated VM workspace.

```bash
# Basic init with default (minimal) template
cal isolation init my-workspace

# Init with specific template
cal isolation init my-workspace --template mobile-full

# Init with specific environments
cal isolation init my-workspace --env ios --env android

# Init with agent pre-selected
cal isolation init my-workspace --template ios --agent claude-code

# Full options
cal isolation init my-workspace \
  --template minimal \
  --env ios \
  --env node \
  --agent claude-code \
  --cpu 6 \
  --memory 16384 \
  --disk 150
```

#### `cal isolation start`
Start a VM and prepare for agent session.

```bash
cal isolation start my-workspace [--headless] [--vnc]
```

#### `cal isolation stop`
Stop a running VM.

```bash
cal isolation stop my-workspace [--force]
```

#### `cal isolation ssh`
SSH into a running VM.

```bash
cal isolation ssh my-workspace [command]
```

#### `cal isolation clone`
Clone a GitHub repository into the VM workspace.

```bash
# Clone a repo
cal isolation clone my-workspace --repo owner/repo-name

# Clone to specific branch
cal isolation clone my-workspace --repo owner/repo-name --branch feature/new-feature

# Clone and create new branch for agent work
cal isolation clone my-workspace --repo owner/repo-name --new-branch agent/refactor-auth
```

#### `cal isolation run`
Run the configured agent inside the VM.

```bash
# Interactive mode with default agent
cal isolation run my-workspace

# With prompt
cal isolation run my-workspace --prompt "Build and test the iOS app"

# Specify agent explicitly
cal isolation run my-workspace --agent opencode --prompt "Refactor the networking layer"

# Autonomous mode (safe because isolated in VM)
cal isolation run my-workspace --autonomous --prompt "Fix all linting errors"
```

#### `cal isolation commit`
Commit and optionally push changes made by agent.

```bash
# Commit with message
cal isolation commit my-workspace --message "Refactored auth module"

# Commit and push
cal isolation commit my-workspace --message "Refactored auth module" --push

# Create PR
cal isolation commit my-workspace --message "Refactored auth module" --pr --pr-title "Auth refactor"
```

#### `cal isolation pr`
Create a pull request from changes in the VM.

```bash
cal isolation pr my-workspace \
  --title "Refactor authentication module" \
  --body "Agent refactored the auth module for better testability" \
  --base main
```

#### `cal isolation status`
Show status of VM and any uncommitted changes.

```bash
cal isolation status my-workspace
# Output:
# VM: my-workspace (running)
# Agent: claude-code
# Repos:
#   my-ios-app (branch: agent/refactor-auth)
#     - 3 files modified
#     - 1 file added
#     - Last commit: 2h ago
```

#### `cal isolation snapshot`
Manage VM snapshots.

```bash
cal isolation snapshot create my-workspace --name "before-refactor"
cal isolation snapshot restore my-workspace --name "before-refactor"
cal isolation snapshot list my-workspace
cal isolation snapshot delete my-workspace --name "before-refactor"
```

#### `cal isolation sync`
Sync build artifacts from VM to host.

```bash
# One-time sync
cal isolation sync my-workspace

# Watch mode - sync as files change
cal isolation sync my-workspace --watch
```

#### `cal isolation auth`
Manage GitHub authentication in the VM.

```bash
# Interactive login (opens browser)
cal isolation auth login my-workspace

# Login with token
cal isolation auth login my-workspace --token ghp_xxxx

# Check auth status
cal isolation auth status my-workspace

# Logout
cal isolation auth logout my-workspace
```

#### `cal isolation agent`
Manage agents in the VM.

```bash
# List installed agents
cal isolation agent list my-workspace

# Install an agent
cal isolation agent install my-workspace claude-code

# Switch active agent
cal isolation agent use my-workspace opencode

# Update agent
cal isolation agent update my-workspace claude-code
```

#### `cal isolation env`
Manage development environments in the VM.

```bash
# List available and installed environments
cal isolation env list my-workspace
# ENVIRONMENT     STATUS      SIZE      PROVIDES
# ios             installed   25.1 GB   xcode, swift, swiftui
# android         installed   11.8 GB   android-sdk, gradle, kotlin
# flutter         available   ~2 GB     flutter-sdk, dart
# node            installed   489 MB    node, npm, yarn

# Install an environment
cal isolation env install my-workspace android

# Install multiple / with dependencies
cal isolation env install my-workspace flutter  # auto-installs ios, android

# Install with variant
cal isolation env install my-workspace python --variant ml

# Remove an environment
cal isolation env remove my-workspace android

# Verify installations
cal isolation env verify my-workspace
# ✓ ios: Xcode 16.0, Swift 5.10
# ✓ android: SDK 34, Gradle 8.5, Kotlin 1.9.22
# ✓ node: v20.11.0, npm 10.2.0

# Show environment details
cal isolation env info android
# Android Development
# Provides: android-sdk, gradle, kotlin, adb
# Requires: java
# Size: ~12 GB

# Update environment
cal isolation env update my-workspace android
```

#### `cal isolation cleanup`
Clean up resources.

```bash
cal isolation cleanup [--all] [--cache] [--stopped]
```

#### `cal isolation sign`
Sign a build artifact on the host (credentials never enter VM).

```bash
cal isolation sign my-workspace \
  --archive ~/cal-output/my-workspace/MyApp.xcarchive \
  --identity "Apple Development: you@example.com" \
  --profile ~/path/to/profile.mobileprovision \
  --output ~/cal-output/my-workspace/MyApp.ipa
```

#### `cal isolation watch`
Watch output directory for changes with real-time streaming.

```bash
# Basic watch with log streaming
cal isolation watch my-workspace

# Watch with post-build hook
cal isolation watch my-workspace --on-archive "./scripts/sign-and-deploy.sh {}"
```

#### `cal isolation logs`
Stream or view build logs.

```bash
# Follow logs in real-time
cal isolation logs my-workspace --follow

# View last N lines
cal isolation logs my-workspace --tail 100
```

### CAL Main Commands (Future)

These commands will be part of CAL core, using cal-isolation under the hood:

```bash
# Launch CAL TUI
cal

# Quick start: init + start + clone + run in one command
cal quick my-workspace \
  --repo owner/my-app \
  --agent claude-code \
  --prompt "Add unit tests for the auth module"

# List all workspaces across modules  
cal list

# Global status
cal status
```

---

## Bootstrap Instructions

### Priority: Get Coding Agents Running Safely ASAP

Before CAL is fully built, we need to run coding agents safely to continue development. These instructions set up a minimal safe environment using Tart directly.

### Phase 0: Manual Safe Setup (Use Now)

#### Prerequisites (On Host)

```bash
# Install Tart
brew install cirruslabs/cli/tart

# Verify installation
tart --version
```

#### Step 1: Create Base VM

```bash
# Clone the base macOS image (~25GB download, no Xcode)
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-dev

# Configure resources (adjust based on your Mac's specs)
# Minimum: 4 CPU, 8GB RAM
# Recommended: 6 CPU, 12GB RAM for running agents + builds
tart set cal-dev --cpu 4 --memory 8192 --disk-size 80

# Start the VM (GUI window will appear)
tart run cal-dev
```

#### Step 2: Initial VM Setup (Inside VM)

Once the VM GUI appears, log in with `admin`/`admin` and open Terminal:

```bash
# Update Homebrew (pre-installed in base image)
brew update && brew upgrade

# ============================================
# CORE TOOLS
# ============================================

# Install Node.js (required for Claude Code and some agents)
brew install node

# Install Go (required for opencode)
brew install go

# Install GitHub CLI
brew install gh

# ============================================
# CLAUDE CODE
# ============================================

# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Verify
claude --version

# ============================================
# OPENCODE
# ============================================

# Install opencode
go install github.com/opencode-ai/opencode@latest

# Add Go bin to PATH (add to ~/.zshrc for persistence)
echo 'export PATH="$HOME/go/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify
opencode --version

# ============================================
# CURSOR CLI (if available)
# ============================================

# Option A: If Cursor has an official CLI package
# npm install -g @cursor/cli  # Verify actual package name

# Option B: Install Cursor app (includes CLI)
# brew install --cask cursor
# The CLI may be at: /Applications/Cursor.app/Contents/Resources/app/bin/cursor

# Option C: Use Cursor's integrated terminal instead of CLI
# Download from: https://cursor.sh

# ============================================
# GITHUB AUTHENTICATION
# ============================================

# Authenticate with GitHub (required for clone/push)
gh auth login
# Choose: GitHub.com → HTTPS → Login with browser

# Verify authentication
gh auth status
```

#### Step 3: Create Clean Snapshot (Critical!)

This is your safety net. **Do this before any agent session.**

```bash
# On HOST machine (not inside VM)

# Stop the VM gracefully
tart stop cal-dev

# Create a clean snapshot to restore to
tart clone cal-dev cal-dev-clean

# Verify snapshot exists
tart list
# Should show both: cal-dev and cal-dev-clean

# Restart the VM
tart run cal-dev
```

#### Step 4: Clone Your Project (Inside VM)

```bash
# Create workspace directory
mkdir -p ~/workspace && cd ~/workspace

# Clone your project (replace with your repo)
gh repo clone your-username/your-repo

# Or clone CAL itself to continue development
gh repo clone your-username/coding-agent-loader

# Navigate to project
cd your-repo
```

#### Step 5: Run Coding Agents Safely

**Claude Code:**
```bash
# Inside VM, in your project directory
cd ~/workspace/your-repo

# Interactive mode
claude

# With initial prompt
claude "Help me implement feature X"

# With specific file context
claude "Review and improve this file" --file src/main.go
```

**opencode:**
```bash
# Inside VM, in your project directory
cd ~/workspace/your-repo

# Start opencode
opencode

# Or with prompt
opencode "Refactor the authentication module"
```

**Cursor:**
```bash
# If using Cursor app, open project in Cursor
# The AI features work within the editor

# If CLI is available:
cursor ~/workspace/your-repo
```

#### Rollback If Something Goes Wrong

If an agent trashes the VM, recovery takes ~30 seconds:

```bash
# On HOST machine

# Stop the damaged VM
tart stop cal-dev

# Delete the damaged VM
tart delete cal-dev

# Restore from clean snapshot
tart clone cal-dev-clean cal-dev

# Restart
tart run cal-dev

# You're back to a clean state!
```

### Quick Reference: Daily Workflow

```bash
# ============================================
# ON HOST - Start session
# ============================================

# 1. Start VM (headless for cleaner workflow)
tart run cal-dev --no-graphics &

# 2. Wait for boot (~30 seconds)
sleep 30

# 3. Get VM IP address
VM_IP=$(tart ip cal-dev)
echo "VM IP: $VM_IP"

# 4. Create session snapshot (safety backup)
tart stop cal-dev
tart clone cal-dev cal-dev-session-$(date +%Y%m%d-%H%M)
tart run cal-dev --no-graphics &
sleep 30

# 5. SSH into VM
ssh admin@$(tart ip cal-dev)

# ============================================
# INSIDE VM - Work session
# ============================================

# 6. Navigate to project
cd ~/workspace/your-repo

# 7. Pull latest changes
git pull

# 8. Run your preferred agent
claude  # or: opencode

# ... do your work ...

# 9. When done, commit and push
git add -A
git commit -m "Changes from coding session"
git push

# 10. Exit SSH
exit

# ============================================
# ON HOST - End session
# ============================================

# 11. Stop VM
tart stop cal-dev

# 12. (Optional) Clean up old session snapshots
tart list | grep "cal-dev-session"
# tart delete cal-dev-session-YYYYMMDD-HHMM  # delete old ones
```

### Headless Operation (Recommended)

Running without the VM window is cleaner and uses less resources:

```bash
# Start headless with VNC available for debugging
tart run cal-dev --no-graphics --vnc &

# Wait for boot
sleep 30

# Connect via SSH (primary interface)
ssh admin@$(tart ip cal-dev)

# If you need GUI access (e.g., for Xcode), connect via Screen Sharing:
# Open Finder → Go → Connect to Server → vnc://$(tart ip cal-dev)
# Password: admin
```

### Shell Aliases (Add to ~/.zshrc on Host)

```bash
# Add these to your ~/.zshrc on the HOST machine for convenience

# VM Management
alias cal-start='tart run cal-dev --no-graphics --vnc & sleep 30 && ssh admin@$(tart ip cal-dev)'
alias cal-stop='tart stop cal-dev'
alias cal-ssh='ssh admin@$(tart ip cal-dev)'
alias cal-ip='tart ip cal-dev'

# Snapshots
alias cal-snap='tart stop cal-dev && tart clone cal-dev cal-dev-$(date +%Y%m%d-%H%M) && tart run cal-dev --no-graphics &'
alias cal-rollback='tart stop cal-dev && tart delete cal-dev && tart clone cal-dev-clean cal-dev && echo "Restored to clean state"'
alias cal-snaps='tart list | grep cal-dev'

# Quick access
alias cal-vnc='open vnc://$(tart ip cal-dev)'
```

After adding, run `source ~/.zshrc`, then:
```bash
cal-start      # Start VM and SSH in
cal-snap       # Create snapshot
cal-rollback   # Restore to clean state
cal-stop       # Stop VM
```

### Mounting Output Directory (Optional)

To sync build artifacts from VM to host:

```bash
# On HOST, create output directory
mkdir -p ~/cal-output

# Start VM with mounted output directory
tart run cal-dev --no-graphics --dir=output:~/cal-output &

# Inside VM, files written to /Volumes/My\ Shared\ Files/output/
# will appear in ~/cal-output on host immediately
```

### Troubleshooting

**VM won't start:**
```bash
# Check if already running
tart list
# Force stop if stuck
tart stop cal-dev --force
```

**SSH connection refused:**
```bash
# VM may still be booting, wait longer
sleep 60 && ssh admin@$(tart ip cal-dev)

# Or check if SSH is enabled in VM
# In VM GUI: System Preferences → Sharing → Remote Login
```

**Agent not found in VM:**
```bash
# Verify PATH includes Go binaries
echo $PATH
# Should include: /Users/admin/go/bin

# Reinstall if needed
npm install -g @anthropic-ai/claude-code
go install github.com/opencode-ai/opencode@latest
```

**Out of disk space in VM:**
```bash
# Inside VM, check usage
df -h

# Clean up
rm -rf ~/Library/Caches/*
rm -rf ~/.npm/_cacache
go clean -cache
```

---

## Implementation Phases

### Phase 0: Bootstrap (CURRENT PRIORITY) ✅
**Goal:** Get Claude Code running safely in VM immediately

- [x] Research Tart capabilities
- [x] Document manual setup process (see Bootstrap Instructions)
- [ ] Set up base VM with `macos-sequoia-base`
- [ ] Install Claude Code in VM
- [ ] Create clean snapshot for rollback
- [ ] Begin using for CAL development

**Deliverable:** Can run Claude Code safely TODAY using manual process

### Phase 1: CLI Foundation
**Goal:** Basic CLI wrapper around manual process

- [ ] CAL project structure setup (monorepo)
- [ ] CLI scaffold: `cal isolation init`, `start`, `stop`, `ssh`
- [ ] Configuration file management (`~/.cal/`)
- [ ] Tart wrapper for VM operations
- [ ] Snapshot management: `cal isolation snapshot`, `rollback`
- [ ] Auto-snapshot on session start

**Deliverable:** Replace manual Tart commands with `cal isolation` CLI

### Phase 2: Agent Integration & UX
**Goal:** Seamless agent launching with safety UI

- [ ] Launch confirmation screen
- [ ] Status banner implementation (green = safe)
- [ ] SSH tunnel with banner overlay
- [ ] Claude Code integration
- [ ] Cursor CLI integration  
- [ ] opencode integration
- [ ] GitHub authentication in VM

**Deliverable:** `cal isolation run` with full safety UX

### Phase 3: GitHub Workflow
**Goal:** Complete git workflow from VM

- [ ] `cal isolation clone` with branch creation
- [ ] `cal isolation commit` and `push`
- [ ] `cal isolation pr` for PR creation
- [ ] Status display of uncommitted changes
- [ ] Exit prompts for uncommitted work

**Deliverable:** Clone → Edit → PR workflow

### Phase 4: Environment Plugin System
**Goal:** Pluggable development environments

- [ ] Environment plugin manifest schema
- [ ] Core plugins: ios, android, node, python, go, rust, dotnet
- [ ] `cal isolation env` commands
- [ ] Dependency resolution
- [ ] VM templates

**Deliverable:** Multi-platform development

### Phase 5: TUI & Polish
**Goal:** Full TUI experience

- [ ] Interactive workspace selection
- [ ] Real-time VM status
- [ ] Environment management UI
- [ ] Log streaming
- [ ] Multiple simultaneous VMs

**Deliverable:** Complete TUI for CAL

### Future: macOS GUI
- Native SwiftUI application
- Menu bar integration
- Notifications

---

## Security Model

### Isolation Architecture

| Resource | Host | VM | Notes |
|----------|------|-----|-------|
| Filesystem | Isolated | Full access | No mounts to host directories |
| Source code | Not present | Cloned from GitHub | Changes committed via git |
| GitHub token | Not shared | VM-only token | Fine-grained PAT with limited scope |
| Signing creds | Present | Never | Signing happens on host post-build |
| Build artifacts | Synced | Generated | One-way sync from VM to host |

### GitHub Authentication Security

**Recommended: Fine-grained Personal Access Token (PAT)**

Create a token with minimal permissions for the VM:
- Repository access: Only specific repos agents will work on
- Permissions:
  - Contents: Read and write
  - Pull requests: Read and write
  - Metadata: Read-only

```bash
# Create token at: https://github.com/settings/tokens?type=beta
# Then in VM:
gh auth login --with-token < token.txt
```

**Token isolation:** The GitHub token in the VM cannot access repos outside its scope, limiting blast radius if compromised.

### Agent Permissions (Inside VM)

Each agent has its own permission model. cal-isolation configures appropriate restrictions for each:

**Claude Code (`~/.claude/settings.json`):**
```json
{
  "permissions": {
    "allow": [
      "Bash(xcodebuild:*)",
      "Bash(swift:*)",
      "Bash(git:*)",
      "Bash(gh pr:*)",
      "Bash(gh issue:*)",
      "Bash(npm:*)",
      "Bash(pod:*)",
      "Edit(~/workspace/**)",
      "Read(**)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(rm -rf ~)",
      "Bash(sudo:*)",
      "Bash(gh auth:*)",
      "Edit(/etc/**)",
      "Edit(~/.config/gh/**)"
    ]
  }
}
```

**opencode:** Uses its own config format (TBD based on opencode docs)

**Cursor CLI:** Uses its own config format (TBD based on Cursor docs)

### Workflow Security Benefits

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY BOUNDARIES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  HOST MACHINE                                                   │
│  ├── Home directory: PROTECTED (not accessible from VM)         │
│  ├── Signing credentials: PROTECTED (never enter VM)            │
│  ├── SSH keys: PROTECTED (not shared)                          │
│  └── Other projects: PROTECTED (VM can't see them)              │
│                                                                 │
│  GITHUB                                                         │
│  ├── Other repos: PROTECTED (token scoped to specific repos)   │
│  ├── Main branch: PROTECTED (work on feature branches)          │
│  └── Audit trail: All changes visible in git history           │
│                                                                 │
│  VM (Sandboxed)                                                 │
│  ├── Can modify: Cloned repo files only                        │
│  ├── Can push: To allowed repos/branches only                  │
│  ├── Can build: Full Xcode access                              │
│  └── Cannot access: Host filesystem, other repos, main creds   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Agent deletes files | Isolated to VM; git history preserves everything |
| Pushes bad code to main | Work on branches, require PR review |
| Exfiltrates GitHub token | Use fine-grained PAT with minimal scope |
| Excessive resource usage | CPU/memory limits on VM |
| Installs malware | Snapshots allow quick recovery; VM is disposable |
| Accesses other repos | Token scoped to specific repositories only |
| Agent-specific exploits | Each agent sandboxed with own permission config |

---

## Dependencies

### Required
- macOS 13.0 (Ventura) or later
- Apple Silicon Mac (M1/M2/M3/M4)
- Homebrew
- Tart CLI (`brew install cirruslabs/cli/tart`)
- ~60-100 GB free disk space per VM

### Recommended
- sshpass (for automated SSH: `brew install cirruslabs/cli/sshpass`)
- Node.js (for Claude Code CLI installation in VM)

---

## Testing Strategy

### Unit Tests
- Configuration parsing and validation
- Git command generation
- SSH command building

### Integration Tests
- VM lifecycle (create, start, stop, delete)
- GitHub authentication flow
- Repository cloning
- Commit and push operations
- PR creation
- SSH connectivity
- Claude Code installation and execution

### End-to-End Tests
- Full workflow: init → start → auth → clone → claude → commit → pr
- iOS build inside VM
- Simulator test execution
- Build artifact sync verification

### Manual Testing Scenarios
1. Claude Code attempts `rm -rf ~` → verify only VM affected, git history preserved
2. Long-running build task → verify stability
3. Network interruption → verify graceful handling
4. VM crash → verify recovery via snapshot
5. Push to wrong branch → verify branch protection works
6. Token with wrong scope → verify clear error message

---

## Success Criteria

1. **Isolation verified:** Destructive operations in VM cannot affect host filesystem
2. **iOS builds work:** Can successfully build and test iOS apps inside VM
3. **Git workflow works:** Can clone, commit, push, and create PRs from VM
4. **Unattended operation:** Can run Claude Code tasks without manual intervention
5. **Recovery possible:** Can restore to known state within 2 minutes via snapshots
6. **Performance acceptable:** Build times within 1.5x of native (accounting for VM overhead)
7. **Audit trail:** All changes made by Claude Code visible in git history

---

## Design Decisions

### 1. Code Signing Strategy

**Decision:** Simulator-first development with optional host-side signing for device deployment.

Code signing for iOS requires sensitive credentials:
- **Development/Distribution Certificates** (stored in Keychain)
- **Provisioning Profiles** (link app ID, certs, and devices)
- **Apple Developer account access**

**The Problem:** Exposing these to agents in the VM creates security risk. If an agent (or a compromised dependency) exfiltrates credentials, your signing identity is compromised.

**Implemented Approach - Tiered Signing:**

| Tier | Use Case | Signing Location | Credentials in VM |
|------|----------|------------------|-------------------|
| **Development** | Simulator testing, debugging | None needed | ❌ None |
| **Ad-hoc/Device** | Testing on physical devices | Host (post-build) | ❌ None |
| **Distribution** | App Store / Enterprise | Host (post-build) | ❌ None |

**Workflow for Device Builds:**

```
┌─────────────────────────────────────────────────────────────────┐
│                         VM (Isolated)                           │
│  1. Agent builds unsigned .app                                  │
│  2. xcodebuild archive -configuration Release                   │
│  3. Output: MyApp.xcarchive → /Volumes/.../output/              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       HOST (Trusted)                            │
│  4. cal isolation sign my-workspace --identity "Apple Dev"      │
│  5. xcodebuild -exportArchive with signing credentials          │
│  6. Output: MyApp.ipa (signed, ready for device)                │
└─────────────────────────────────────────────────────────────────┘
```

**CLI Support:**

```bash
# Build unsigned archive in VM
cal isolation run my-workspace --prompt "Build release archive for iOS"

# Sign on host (credentials never enter VM)
cal isolation sign my-workspace \
  --archive ~/cal-output/my-workspace/MyApp.xcarchive \
  --identity "Apple Development: will@example.com" \
  --profile ~/Library/MobileDevice/Provisioning\ Profiles/dev.mobileprovision
```

**Future Enhancement:** For teams needing frequent device builds, could integrate with a dedicated signing service (like Fastlane Match with a separate, audited CI credential set).

---

### 2. GitHub-Based Workflow

**Decision:** Clone repositories from GitHub into VM instead of mounting host directories.

**Rationale:**
- **Complete isolation:** No filesystem connection between host and VM whatsoever
- **Full write access:** Agents can freely create, modify, delete files
- **Built-in versioning:** All changes tracked in git automatically
- **Safe experimentation:** Work on branches, discard if needed
- **Audit trail:** Full history of what agents changed
- **Agent-agnostic:** Same isolation works for any coding agent

**Workflow:**

```bash
# 1. Initialize workspace
cal isolation init my-workspace --agent claude-code

# 2. Start VM
cal isolation start my-workspace

# 3. Authenticate with GitHub (one-time)
cal isolation auth login my-workspace

# 4. Clone repo and create working branch
cal isolation clone my-workspace --repo owner/my-ios-app --new-branch agent/feature-work

# 5. Run agent
cal isolation run my-workspace --prompt "Implement the new login screen"

# 6. Review and commit
cal isolation status my-workspace
cal isolation commit my-workspace --message "Add login screen" --push

# 7. Create PR for review
cal isolation pr my-workspace --title "New login screen" --base main
```

**Branch Strategy:**
- Auto-create branches with prefix (default: `agent/`)
- Never push directly to `main` or `develop`
- All changes go through PR review
- Easy to discard failed experiments (just delete branch)

---

### 3. Build Artifact Sync

**Decision:** Real-time sync of build artifacts using mounted output directory.

**Rationale:**
- Immediate feedback on build results
- Can monitor compilation progress
- Build logs available as they're written
- IPA/xcarchive files available for host-side signing

**Implementation:**

While source code lives entirely in the VM (cloned from GitHub), build artifacts need to come back to the host for signing and distribution. We use a single mounted directory for this:

```bash
tart run my-workspace --dir=output:~/cal-output/my-workspace
```

**Sync Architecture:**

```
┌────────────────────────────────────────────────────────────────┐
│                              VM                                │
│  ~/output/  ◄──── Agent writes build artifacts here      │
│         │                                                      │
│         ▼ (VirtioFS mount - real-time)                         │
│  /Volumes/My Shared Files/output/                              │
└────────────────────────────────────────────────────────────────┘
                              │
            VirtioFS (real-time, bidirectional)
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│                             HOST                               │
│  ~/cal-output/my-workspace/  ◄──── Files appear immediately     │
│         │                                                      │
│         ▼ (optional watcher)                                   │
│  cal isolation watch my-workspace                                    │
│  - Triggers on new .ipa, .xcarchive, .app files                │
│  - Runs post-build hooks (signing, notification)               │
│  - Streams build logs to terminal                              │
└────────────────────────────────────────────────────────────────┘
```

**What Gets Synced:**
- Build artifacts (`.app`, `.ipa`, `.xcarchive`)
- Test results (`.xcresult`)
- Build logs
- Code coverage reports

**What Stays in VM:**
- Source code (managed via git)
- Dependencies (`Pods/`, `node_modules/`)
- Derived data

**CLI Commands:**

```bash
# Start VM with artifact sync
cal isolation start my-workspace  # Output dir mounted by default

# Watch with post-build hook
cal isolation watch my-workspace --on-archive "cal isolation sign my-workspace --archive {}"

# Tail build logs
cal isolation logs my-workspace --follow
```

---

## Remaining Open Questions

1. **Xcode version management:** Support multiple Xcode versions in one VM (using `xcodes` tool) or one Xcode per VM?
2. **Image updates:** Strategy for keeping VM base images current without losing customisations?
3. **GitHub token storage:** Store encrypted in host config, or require re-auth each session?

---

## Dependencies

### Required (Host)
- macOS 13.0 (Ventura) or later
- Apple Silicon Mac (M1/M2/M3/M4)
- Homebrew
- Tart CLI (`brew install cirruslabs/cli/tart`)
- GitHub account with access to target repositories
- ~60-100 GB free disk space per VM

### Installed in VM (automated by cal isolation)
- GitHub CLI (`gh`)
- Claude Code CLI (via npm)
- Node.js (for Claude Code)

---

## References

- [Tart Documentation](https://tart.run/)
- [Tart GitHub Repository](https://github.com/cirruslabs/tart)
- [Cirrus Labs macOS Image Templates](https://github.com/cirruslabs/macos-image-templates)
- [Claude Code Documentation](https://code.claude.com/docs)
- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Apple Virtualization Framework](https://developer.apple.com/documentation/virtualization)
- [HashiCorp Packer Tart Builder](https://developer.hashicorp.com/packer/integrations/cirruslabs/tart)
