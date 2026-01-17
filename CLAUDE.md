# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

CAL (Coding Agent Loader) - VM-based sandbox for running AI coding agents safely in Tart macOS VMs.

## Stack

Go + Charm (bubbletea/lipgloss/bubbles) + Cobra + Viper

## Structure

```
cmd/cal/main.go           # Entry point
internal/
  tui/                    # bubbletea UI
  isolation/              # VM management (tart, snapshots, ssh)
  agent/                  # Agent integrations (claude, cursor, opencode)
  env/                    # Environment plugins (ios, android, node, etc.)
  github/                 # gh CLI wrapper
  config/                 # Configuration
```

## Commands

```bash
# Build (once implemented)
go build -o cal ./cmd/cal

# Test
go test ./...

# Lint
golangci-lint run
```

## Docs

Source of truth: [docs/adr/ADR-001-cal-isolation.md](docs/adr/ADR-001-cal-isolation.md)

Quick reference (extracted from ADR):
- [Architecture](docs/architecture.md) - system design, UX, config
- [CLI](docs/cli.md) - command reference
- [Bootstrap](docs/bootstrap.md) - manual Tart setup
- [Plugins](docs/plugins.md) - environment system
- [Roadmap](docs/roadmap.md) - implementation phases
