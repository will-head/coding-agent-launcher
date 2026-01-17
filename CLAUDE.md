# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CAL (Coding Agent Loader) is a VM-based sandboxing system that allows AI coding agents (Claude Code, Cursor CLI, opencode) to run in complete isolation from the host filesystem while providing a familiar terminal experience. It uses Tart macOS VMs on Apple Silicon.

## Technology Stack

- **Language:** Go
- **TUI Framework:** Charm toolkit (bubbletea, lipgloss, bubbles)
- **CLI Framework:** Cobra
- **Configuration:** Viper + YAML
- **VM Runtime:** Tart (Apple Virtualization.Framework)

## Project Structure

```
cal/
├── cmd/cal/main.go              # Entry point
├── internal/
│   ├── tui/                     # bubbletea UI components
│   ├── isolation/               # VM management (tart.go, snapshot.go, ssh.go)
│   ├── agent/                   # Agent integrations (claude.go, cursor.go, opencode.go)
│   ├── env/                     # Environment plugin system
│   │   └── plugins/             # ios, android, node, python, etc.
│   ├── github/                  # GitHub CLI wrapper
│   └── config/                  # Configuration management
├── go.mod
└── go.sum
```

## Key Dependencies

```go
github.com/charmbracelet/bubbletea     // TUI framework
github.com/charmbracelet/lipgloss      // Styling
github.com/charmbracelet/bubbles       // UI components
github.com/spf13/cobra                 // CLI framework
github.com/spf13/viper                 // Configuration
golang.org/x/crypto/ssh                // SSH client
gopkg.in/yaml.v3                       // YAML parsing
```

## Architecture

CAL provides complete filesystem isolation by running agents in Tart VMs with a GitHub-based workflow:
- Source code is cloned from GitHub into the VM (not mounted from host)
- Agents have full write access within the VM
- Changes are committed and pushed via git
- Build artifacts sync to host via mounted output directory
- Code signing happens on host (credentials never enter VM)

## CLI Command Structure

```bash
cal isolation init <workspace> [--template <name>] [--env <env>...] [--agent <agent>]
cal isolation start <workspace>
cal isolation stop <workspace>
cal isolation run <workspace> [--prompt <text>]
cal isolation clone <workspace> --repo <owner/repo>
cal isolation commit <workspace> --message <msg> [--push] [--pr]
cal isolation snapshot create|restore|list|delete <workspace>
cal isolation env install|remove|list|verify <workspace> [env]
```

## Bootstrap (Manual Tart Setup)

Until CAL CLI is implemented, use Tart directly:

```bash
# Install Tart
brew install cirruslabs/cli/tart

# Clone base image and configure
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest cal-dev
tart set cal-dev --cpu 4 --memory 8192 --disk-size 80

# Create clean snapshot before agent sessions
tart clone cal-dev cal-dev-clean

# Start VM headless and SSH in
tart run cal-dev --no-graphics &
ssh admin@$(tart ip cal-dev)  # password: admin

# Rollback if agent trashes VM
tart stop cal-dev && tart delete cal-dev && tart clone cal-dev-clean cal-dev
```

## Configuration Locations

- `~/.cal/config.yaml` - Global CAL configuration
- `~/.cal/isolation/vms/{name}/vm.yaml` - Per-VM configuration
- `~/.cal/environments/plugins/` - Environment plugin definitions
- `~/cal-output/` - Build artifacts synced from VMs

## Environment Plugins

Environments (ios, android, node, python, etc.) are defined via `manifest.yaml` files specifying:
- Homebrew packages and casks to install
- Environment variables
- Post-install commands
- Verification checks
- Artifact patterns for sync
