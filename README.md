# CAL - Coding Agent Loader

> **Status:** Phase 0 (Bootstrap) Mostly Complete - 4 TODOs in 0.8, 6 new TODOs in 0.10 | Phase 1 (CLI Foundation) Not Started

VM-based sandbox for running AI coding agents (Claude Code, Cursor, opencode) safely in isolated Tart macOS VMs.

## Features

- **Complete isolation** - Agents run in VMs with no host filesystem access
- **GitHub workflow** - Clone → edit → commit → PR, all changes tracked in git
- **Multi-agent** - Claude Code, opencode, Cursor CLI
- **Multi-platform** - iOS, Android, Flutter, Node, Python, Rust, Go
- **Instant rollback** - Snapshots recover from any mishap in seconds

## Requirements

- macOS 13+ on Apple Silicon
- ~60-100 GB free disk space per VM

## Quick Start

```bash
# 1. Install Tart
brew install cirruslabs/cli/tart

# 2. Run bootstrap script (creates VMs, installs tools, sets up SSH keys)
./scripts/cal-bootstrap --init

# 3. After manual login setup, start developing
./scripts/cal-bootstrap --run

# OR: Restart VM and reconnect (quick refresh)
./scripts/cal-bootstrap --restart
```

See [Bootstrap Guide](docs/bootstrap.md) for full setup instructions.

## Agent Support

This repo works with multiple AI coding agents. Context is in `AGENTS.md` with symlinks:
- `CLAUDE.md` → Claude Code
- `.cursorrules` → Cursor

## Documentation

**Status & Planning:**
- [PLAN](docs/PLAN.md) - Implementation plan & TODOs **(single source of truth for status)**
- [Roadmap](docs/roadmap.md) - Phase overview (derived from PLAN.md)
- [Phase 0 Completion](docs/phase0-completion-notes.md) - Bootstrap phase summary
- [SPEC](docs/SPEC.md) - Technical specification

**Testing:**
- [Testing Quick Start](docs/TESTING-QUICKSTART.md) - 15-minute Phase 0.8 test
- [Testing Guide](docs/TESTING.md) - Phase 0.8 testing checklist

**Reference:**
- [Architecture](docs/architecture.md) - System design, UX, config
- [CLI](docs/cli.md) - Command reference
- [Bootstrap](docs/bootstrap.md) - Manual Tart setup and VM management
- [Proxy](docs/proxy.md) - Transparent proxy for corporate environments
- [Cursor Login Fix](docs/cursor-login-fix.md) - Keychain solution for agent authentication
- [Terminal Keybindings Test](docs/terminal-keybindings-test.md) - VM terminal testing
- [SSH Alternatives Investigation](docs/ssh-alternatives-investigation.md) - Research on terminal access options
- [tmux Agent Testing](docs/tmux-agent-testing.md) - Testing guide for tmux with agents
- [Plugins](docs/plugins.md) - Environment system
- [ADR-001](docs/adr/ADR-001-cal-isolation.md) - Complete design (immutable)

## License

TBD
