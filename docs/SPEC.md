# CAL Technical Specification

> Quick reference derived from [ADR-001](adr/ADR-001-cal-isolation.md) (design) and [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) (operations).

## Overview

CAL (Coding Agent Loader) is a CLI tool that runs AI coding agents (Claude Code, opencode, Cursor CLI, CCS, Codex) in isolated Tart macOS VMs, protecting the host filesystem while providing a seamless developer experience.

## Core Components

### 1. cal-isolation Module

**Purpose:** VM-based sandboxing for AI coding agents

**Responsibilities:**
- Tart VM lifecycle management (create, start, stop, delete)
- Snapshot management for instant rollback
- SSH/tmux session management
- Git safety checks before destructive operations

### 2. Agent Integration

**Supported Agents:**
| Agent | Install Command | Config Dir | Status |
|-------|-----------------|------------|--------|
| Claude Code | `npm install -g @anthropic-ai/claude-code` | `~/.claude` | Working |
| opencode | `brew install anomalyco/tap/opencode` | `~/.opencode` | Working* |
| Cursor CLI | `curl -fsSL https://cursor.com/install \| bash` | `~/.cursor` | Working** |
| CCS | `npm install -g @kaitranntt/ccs` | N/A | Working |
| Codex CLI | `npm install -g @openai/codex` | N/A | Working |

*opencode hangs when TERM is explicitly set in command environment. Use tmux-wrapper.sh (see [ADR-002 § TERM Environment Variable Handling](adr/ADR-002-tart-vm-operational-guide.md#term-environment-variable-handling)).
**Cursor CLI requires automatic keychain unlock for OAuth. Implemented via .zshrc (see [ADR-002 § Keychain Auto-Unlock](adr/ADR-002-tart-vm-operational-guide.md#keychain-auto-unlock)).

### 3. Environment Plugin System

**Purpose:** Pluggable development environments installed on-demand

**Core Plugins:** ios, android, java, dotnet, flutter, react-native, node, python, rust, go, cpp

### 4. GitHub Integration

**Purpose:** Git-based workflow for code isolation

**Capabilities:**
- Repository cloning into VM workspace
- Branch creation with configurable prefix (default: `agent/`)
- Commit/push operations
- Pull request creation via `gh` CLI

---

## Technical Requirements

### Host Requirements

| Requirement | Specification |
|-------------|---------------|
| OS | macOS 13.0 (Ventura) or later |
| Hardware | Apple Silicon (M1/M2/M3/M4) |
| Disk Space | ~60-100 GB per VM |
| Dependencies | Homebrew, Tart CLI |

### VM Configuration Defaults

| Resource | Default | Minimum |
|----------|---------|---------|
| CPU | 4 cores | 2 cores |
| Memory | 8192 MB | 4096 MB |
| Disk | 80 GB | 50 GB |
| Base Image | `ghcr.io/cirruslabs/macos-sequoia-base:latest` | - |

### Network

- SSH access to VM (default credentials: admin/admin)
- VNC experimental mode for GUI with bidirectional clipboard (`--gui`)
- Screen Sharing (legacy, one-way clipboard only)
- Transparent proxy via sshuttle for corporate networks (auto/on/off)
- Bootstrap SOCKS proxy (SSH -D) during init before sshuttle installed
- GitHub HTTPS/SSH for repository operations

---

## Directory Structure

### Host (`~/.cal/`)

```
~/.cal/
├── config.yaml                    # Global configuration
├── agents/                        # Agent-specific configs
├── environments/
│   ├── registry.yaml              # Available environments
│   ├── plugins/
│   │   ├── core/                  # Built-in (ios, android, etc.)
│   │   └── community/             # User-installed
│   └── cache/                     # Downloaded SDKs
└── isolation/
    ├── vms/{name}/                # Per-VM metadata
    │   ├── vm.yaml
    │   └── environments.yaml
    ├── templates/                 # Reusable VM configs
    └── logs/
```

### Host (`~/cal-output/`)

```
~/cal-output/{workspace}/
├── builds/                        # .app, .ipa, .apk, etc.
├── test-results/                  # .xcresult, etc.
└── logs/
```

### VM (`/Users/admin/`)

```
~/code/github.com/{owner}/{repo}/  # Cloned repositories
~/scripts/                         # Helper scripts (vm-auth.sh, vm-setup.sh, etc.)
~/.config/gh/                      # GitHub CLI auth
~/.cal-vm-info                     # VM detection metadata
~/.cal-vm-config                   # VM password (mode 600)
~/.cal-proxy-config                # Proxy settings
~/.cal-env/                        # Environment markers
~/output/                          # Artifact staging (synced to host)
```

---

## CLI Interface

### Command Structure

```
cal isolation <command> [options]
cal iso <command> [options]        # Shorthand alias
```

### Core Commands

| Category | Commands |
|----------|----------|
| Workspace | `init`, `start`, `stop`, `destroy`, `status`, `ssh` |
| Git/GitHub | `clone`, `commit`, `pr`, `auth` |
| Agent | `run`, `agent list/install/use/update` |
| Snapshots | `snapshot create/restore/list/delete/cleanup`, `rollback` |
| Environments | `env list/install/remove/verify/info/update` |
| Artifacts | `sync`, `watch`, `logs`, `sign`, `cleanup` |

---

## Security Model

### Isolation Boundaries

| Resource | Host | VM | Notes |
|----------|------|-----|-------|
| Filesystem | Protected | Full access | No mounts to host dirs |
| Source code | Not present | Cloned via git | Changes tracked |
| GitHub token | Not shared | VM-only PAT | Fine-grained, limited scope |
| Signing creds | Present | Never | Sign on host post-build |
| Build artifacts | Synced in | Generated | One-way sync |

### Agent Permissions

Agents are configured with allow/deny lists for:
- Bash commands (e.g., allow `git:*`, deny `sudo:*`)
- File operations (e.g., allow `Edit(~/workspace/**)`, deny `Edit(/etc/**)`)

---

## UX Requirements

### Status Banner

Always visible at top of terminal during agent sessions:
```
🔒 CAL ISOLATION ACTIVE │ VM: <name> │ Env: <envs> │ Safe Mode
```

**Colors:**
- Green: VM running, isolation active
- Yellow: VM starting/stopping
- Amber: Warning state
- Red: Error state

### Launch Confirmation

Before starting agent, display:
- Workspace name
- VM status
- Isolation confirmation
- Installed environments
- Active agent
- Repository and branch
- Last backup timestamp

**Options:** [Enter] Launch, [B] Backup First, [Q] Quit

### Session Hotkeys

During session: [S]napshot, [C]ommit, [P]R, [R]ollback, [Q]uit, ?:Help

---

## Success Criteria

1. **Isolation verified** - Destructive operations in VM cannot affect host
2. **Agent parity** - Agent experience identical to running locally
3. **Git workflow** - Clone, edit, commit, push, PR all work from VM
4. **Recovery** - Rollback to known state in <2 minutes via snapshots
5. **Performance** - Build times within 1.5x of native
6. **Audit trail** - All changes visible in git history

---

## Open Questions (from ADR)

1. **Xcode version management** - Multiple versions per VM vs. one per VM?
2. **Image updates** - Strategy for updating base images without losing customizations?
3. **GitHub token storage** - Encrypted in host config vs. re-auth each session?

---

## References

- [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) - Operational guide (comprehensive reference)
- [ADR-001](adr/ADR-001-cal-isolation.md) - Original design decisions (immutable)
- [Architecture](architecture.md) - System design summary
- [CLI Reference](cli.md) - Command documentation
- [Bootstrap Guide](bootstrap.md) - VM setup and management
