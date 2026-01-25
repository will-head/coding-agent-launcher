# Phase 4 (Environment Plugin System) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Pluggable development environments.

**Deliverable:** Multi-platform development with pluggable environments.

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
     post_install: []string
   verify: []VerifyCommand
   artifacts: ArtifactConfig
   ```
2. Parse and validate manifests
3. Store in `~/.cal/environments/plugins/`

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
- `node` - Node.js LTS (~200MB)
- `python` - Python 3.12 (~500MB)
- `go` - Go toolchain (~500MB)
- `rust` - Rust/Cargo (~1GB)

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
