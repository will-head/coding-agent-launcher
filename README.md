# CAL - Coding Agent Loader

> **Status:** Phase 0 (Bootstrap) Complete | Phase 1 (CLI Foundation) In Progress

VM-based sandbox for running AI coding agents (Claude Code, Cursor, opencode) safely in isolated Tart macOS VMs.

## Features

- **Complete isolation** - Agents run in VMs with no host filesystem access
- **GitHub workflow** - Clone → edit → commit → PR, all changes tracked in git
- **Multi-agent** - Claude Code, Cursor, opencode (with automatic keychain unlock for OAuth)
- **Instant rollback** - Snapshots recover from any mishap in seconds
- **Transparent proxy** - Works in corporate environments with network restrictions

## Requirements

- macOS 13+ on Apple Silicon
- ~60-100 GB free disk space per VM

## Quick Start

```bash
# 1. Install Tart (optional - cal-bootstrap will auto-install if not present)
brew install cirruslabs/cli/tart

# 2. Run bootstrap script (creates VMs, installs tools, sets up SSH keys)
./scripts/cal-bootstrap --init

# 3. After manual login setup, start developing
./scripts/cal-bootstrap --run
```

**Note:** cal-bootstrap will automatically install Tart via Homebrew if it's not already installed.

See [Bootstrap Guide](docs/bootstrap.md) for setup instructions.

## Agent Support

Context for AI coding agents is in `AGENTS.md` with symlinks:
- `CLAUDE.md` → Claude Code
- `.cursorrules` → Cursor

## Documentation

**Quick Start:**
- [Bootstrap Guide](docs/bootstrap.md) - VM setup and daily workflow
- [ADR-002](docs/adr/ADR-002-tart-vm-operational-guide.md) - Comprehensive operational guide

**Planning:**
- [PLAN.md](PLAN.md) - TODOs and status **(source of truth)**
- [Roadmap](docs/roadmap.md) - Phase overview

**Reference:**
- [Architecture](docs/architecture.md) - System design overview
- [CLI](docs/cli.md) - Command reference
- [Proxy](docs/proxy.md) - Corporate network setup
- [VM Detection](docs/vm-detection.md) - Agent environment detection
- [SPEC](docs/SPEC.md) - Technical specification

**Historical:**
- [ADR-001](docs/adr/ADR-001-cal-isolation.md) - Original design decisions (immutable)

## License

TBD
