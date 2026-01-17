# Architecture

> Extracted from [ADR-001](adr/ADR-001-cal-isolation.md) for quick reference.

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
