# CAL - Coding Agent Loader

A VM-based sandboxing system that allows AI coding agents (Claude Code, Cursor CLI, opencode) to run in complete isolation from the host filesystem while providing a familiar terminal experience.

## Why CAL?

AI coding agents running with elevated permissions can perform destructive operations. CAL provides:

- **Complete isolation** - Agents run in Tart macOS VMs with no access to host filesystem
- **GitHub-based workflow** - Clone → edit → commit → PR, all changes tracked in git
- **Multi-agent support** - Claude Code, opencode, Cursor CLI
- **Multi-platform development** - iOS, Android, Flutter, Node, Python, Rust, Go, and more
- **Instant rollback** - Snapshots let you recover from any agent mishap in seconds

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon Mac (M1/M2/M3/M4)
- ~60-100 GB free disk space per VM
- Homebrew

## Quick Start (Manual Bootstrap)

Until the CAL CLI is implemented, use Tart directly:

```bash
# Install Tart
brew install cirruslabs/cli/tart

# Clone base macOS image (~25GB)
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-dev
tart set cal-dev --cpu 4 --memory 8192 --disk-size 80

# Start VM
tart run cal-dev

# Inside VM (login: admin/admin), install agents:
brew install node gh
npm install -g @anthropic-ai/claude-code
gh auth login

# Create safety snapshot (on host)
tart stop cal-dev
tart clone cal-dev cal-dev-clean
tart run cal-dev
```

### Daily Workflow

```bash
# Start headless and SSH in
tart run cal-dev --no-graphics &
ssh admin@$(tart ip cal-dev)

# Work with agents inside VM
cd ~/workspace/your-repo
claude  # or: opencode

# If something goes wrong, rollback (on host)
tart stop cal-dev && tart delete cal-dev && tart clone cal-dev-clean cal-dev
```

## Planned CLI

```bash
cal isolation init my-workspace --template ios --agent claude-code
cal isolation clone my-workspace --repo owner/my-app
cal isolation run my-workspace --prompt "Add unit tests"
cal isolation commit my-workspace --message "Add tests" --pr
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         HOST MACHINE                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  CAL CLI / TUI                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ~/cal-output  ◀─────  Build artifacts synced from VM      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  TART VM (Isolated)                                         │ │
│  │  ├── GitHub CLI (clone/commit/push/PR)                      │ │
│  │  ├── AI Agent (Claude Code / opencode / Cursor)             │ │
│  │  └── Dev Environments (Xcode, Android SDK, Node, etc.)      │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Documentation

- [ADR-001: cal-isolation Architecture](docs/ADR-001-cal-isolation.md) - Full design document

## License

TBD
