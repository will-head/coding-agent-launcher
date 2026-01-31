# Phase 4 (Environment Plugin System) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Pluggable development environments.

**Deliverable:** Multi-platform development with pluggable environments.

**Reference:** [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) for tool installation patterns and PATH configuration.

---

## 4.1 Plugin Manifest Schema

**File:** `internal/env/plugin.go`

**Tasks:**
1. Define manifest YAML schema:
   ```yaml
   name: string
   display_name: string
   requires: []string
   provides: []string
   size_estimate: string
   install:
     env: map[string]string
     brew: []string
     cask: []string
     npm: []string
     go_install: []string
     post_install: []string
   verify: []VerifyCommand
   artifacts: ArtifactConfig
   ```
2. Parse and validate manifests
3. Store in `~/.cal/environments/plugins/`

**Key learnings from Phase 0 (ADR-002):**
- Tools install via multiple methods: brew, brew cask, npm, go install, curl scripts
- PATH configuration varies by tool: ~/.local/bin, ~/go/bin, ~/scripts, ~/.opencode/bin
- Shell reload (`exec zsh` or `source ~/.zshrc`) needed after PATH changes
- Some tools need Homebrew environment initialized: `eval "$(/opt/homebrew/bin/brew shellenv)"`

---

## 4.2 Plugin Registry

**File:** `internal/env/registry.go`

**Tasks:**
1. Discover plugins from core/ and community/
2. Track installed environments per workspace
3. Dependency resolution (e.g., android requires java)
4. Cache downloaded SDKs

---

## 4.3 Core Plugins

Create manifests for:
- `ios` - Xcode, Swift, simulators (~30GB)
- `android` - SDK, Gradle, Kotlin (~12GB)
- `java` - OpenJDK 17 (~500MB)
- `node` - Node.js LTS (~200MB) - already installed by vm-setup.sh
- `python` - Python 3.12 (~500MB)
- `go` - Go toolchain + dev tools (~500MB) - already installed by vm-setup.sh
- `rust` - Rust/Cargo (~1GB)

**Note:** Node and Go (with dev tools) are already installed as part of Phase 0 bootstrap. Core plugins for these should detect existing installations and only add missing components.

**Go dev tools already installed (from ADR-002):**
- golangci-lint (meta-linter), staticcheck, goimports, delve (dlv), mockgen, air

---

## 4.4 Environment CLI Commands

**Tasks:**
1. `cal isolation env list <workspace>`
2. `cal isolation env install <workspace> <env>`
3. `cal isolation env remove <workspace> <env>`
4. `cal isolation env verify <workspace>`
5. `cal isolation env info <env>`

---

## 4.5 VM Templates

**Tasks:**
1. Define template schema
2. Create templates: minimal, ios, android, mobile, backend
3. `cal isolation init --template <name>`
4. Auto-install environments on first start
