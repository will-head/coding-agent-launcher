# Architecture

> Quick reference. See [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) for comprehensive operational details.

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOST MACHINE                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  CAL: TUI Interface │ Agent Selector │ cal-isolation      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│  ~/cal-output/  ◀────────────┴──── Build artifacts (VirtioFS)   │
│                              │                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  TART VM: GitHub CLI │ AI Agent │ Dev Environments        │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬──────────────────────────────┘
                                   ▼
                              [ GitHub ]
```

## Isolation Model

| Resource | Host | VM |
|----------|------|-----|
| Filesystem | Protected | Full access |
| Source code | Not present | Cloned via git |
| GitHub token | Not shared | Scoped PAT |
| Signing creds | Present | Never |
| Artifacts | Synced in | Generated |

## Workflow

Clone → Edit → Commit → Sync artifacts → Sign on host

## Directory Structure

**Host:** `~/.cal/{config.yaml, isolation/vms/, environments/plugins/}`, `~/cal-output/`

**VM:** `~/workspace/{repo}/`, `~/.config/gh/`, `~/output/`

## UX Design

**Status Banner** (top of terminal):
```
🔒 CAL ISOLATION ACTIVE │ VM: workspace │ Env: ios,android │ Safe Mode
```
Colors: 🟢 running, 🟡 starting, 🔴 error

**Launch Confirmation** (before agent start):
- Shows workspace, VM status, environments, agent, repo/branch
- Options: [Enter] Launch, [B] Backup First, [Q] Quit

**Hotkeys** (during session): [S]napshot, [C]ommit, [P]R, [R]ollback, [Q]uit

## Security

| Risk | Mitigation |
|------|------------|
| Agent deletes files | VM isolated; git preserves history |
| Bad code pushed | Work on branches; PR review |
| Token leak | Fine-grained PAT, limited scope |
| Malware | Snapshots enable quick recovery |
| VM accessing host | SSH keys only valid from VM network; host key verification |

## Networking

### VM Network Topology

VMs run in isolated virtual network (192.168.64.x) with NAT to host internet connection.

```
┌─────────────────────────────────────┐
│ Host Mac (192.168.64.1)            │
│  • Internet connection              │
│  • SSH server (optional)            │
└──────────────┬──────────────────────┘
               │ NAT / Bridged
┌──────────────┴──────────────────────┐
│ VM (192.168.64.x)                   │
│  • Direct internet (most networks)  │
│  • SOCKS tunnel (restrictive corps) │
└─────────────────────────────────────┘
```

### Transparent Proxy (Optional)

For corporate environments with restrictive HTTP proxies, CAL provides transparent proxying via sshuttle:

**Problem:** Corporate networks may block direct VM internet access or require complex proxy configurations that VMs can't satisfy (authentication, PAC files, etc.).

**Solution:** Use sshuttle to create a VPN-like tunnel through the host - all traffic routes automatically without app configuration.

**Architecture:**
```
┌──────────────────────────────────────────────────────────────┐
│ VM (cal-dev)                                                 │
│  All apps (no config) → sshuttle → SSH tunnel → Host → Net  │
└──────────────────────────────────────────────────────────────┘
```

**Key Benefits:**
- Truly transparent - no HTTP_PROXY env vars needed
- Works with all applications automatically
- DNS queries also route through the tunnel

**Auto-Detection:**
- Tests if VM can reach github.com directly
- Enables proxy only if connectivity test fails
- User can override with `--proxy on/off/auto`

**See [Proxy Documentation](proxy.md) for implementation details.**

## Config Schema

**Global** (`~/.cal/config.yaml`):
```yaml
isolation:
  defaults:
    vm: {cpu: 4, memory: 8192, disk_size: 80}
    github: {default_branch_prefix: "agent/"}
    output: {sync_dir: "~/cal-output"}
agents:
  claude-code: {install_command: "npm install -g @anthropic-ai/claude-code"}
```

**Per-VM** (`~/.cal/isolation/vms/{name}/vm.yaml`):
```yaml
name: "my-workspace"
resources: {cpu: 6, memory: 12288}
agent: "claude-code"
github: {repos: [{name: "my-app", branch: "agent/feature"}]}
```
