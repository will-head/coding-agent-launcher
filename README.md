# CAL - Coding Agent Loader

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
brew install cirruslabs/cli/tart
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-dev
tart set cal-dev --cpu 4 --memory 8192 --disk-size 80
tart run cal-dev  # login: admin/admin
```

See [Bootstrap Guide](docs/bootstrap.md) for full setup instructions.

## Agent Support

This repo works with multiple AI coding agents. Context is in `AGENTS.md` with symlinks:
- `CLAUDE.md` → Claude Code
- `.cursorrules` → Cursor

## Documentation

- [Architecture](docs/architecture.md) - System design, UX, config
- [CLI](docs/cli.md) - Command reference
- [Bootstrap](docs/bootstrap.md) - Manual Tart setup
- [Plugins](docs/plugins.md) - Environment system
- [Roadmap](docs/roadmap.md) - Implementation phases
- [ADR-001](docs/adr/ADR-001-cal-isolation.md) - Complete design (source of truth)

## License

TBD
