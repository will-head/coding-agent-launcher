# Phase 1 (CLI Foundation) - Completed Items

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Replace manual Tart commands with `cal isolation` CLI.

**Deliverable:** Working `cal isolation` CLI that wraps Tart operations.

---

## 1.1 **REFINED:** Project Scaffolding (PR #3, merged 2026-02-01)

**Tasks:**
1. Initialize Go module
   ```bash
   go mod init github.com/will-head/coding-agent-launcher
   ```
   - Use full repository path as module name
   - Enables internal imports like `import "github.com/will-head/coding-agent-launcher/internal/config"`

2. Create directory structure (directories only, add .go files when implementing features):
   ```
   cmd/cal/
   internal/
     config/
     isolation/
     agent/
     tui/
   ```
   - Test files will be added alongside code as features are implemented (e.g., `config_test.go` next to `config.go`)

3. Create `cmd/cal/main.go` with minimal Cobra root command:
   - Basic cobra setup with root command
   - Add version flag (`--version`)
   - Ready to add subcommands in later TODOs
   - Should be executable and respond to `cal --version`

4. Add initial dependencies (cobra/viper for CLI foundation):
   ```bash
   go get github.com/spf13/cobra
   go get github.com/spf13/viper
   ```
   - Add remaining dependencies (bubbletea, lipgloss, bubbles, ssh, yaml) incrementally as features are implemented
   - TUI libraries added when implementing TUI features (Phase 2)
   - SSH library added when implementing SSH management (1.5)

5. Create `.gitignore` (comprehensive):
   - Standard Go ignores: `cal` binary, `*.out`, `coverage.txt`, `vendor/`, build artifacts
   - IDE/editor files: `.vscode/`, `.idea/`, `*.swp`, `.DS_Store`
   - Local config/test files: `*.local`, `tmp/`, `test-output/`

6. Create `Makefile` with build automation:
   - `build`: Compile binary to `./cal` using `go build -o cal ./cmd/cal`
   - `test`: Run all tests with `go test ./...` (may be empty initially)
   - `lint`: Run `staticcheck ./...` for code quality checks
   - `install`: Install binary to `$(GOPATH)/bin` or `/usr/local/bin`
   - `clean`: Remove binary and test artifacts

**Acceptance Criteria:**
- [x] Project builds successfully: `go build ./cmd/cal` completes without errors
- [x] `make build` and `make test` execute successfully
- [x] `cal --version` runs and displays version information
- [x] All standard Go project files present: `go.mod`, `.gitignore`, `Makefile`, directory structure created
- [x] No placeholder .go files in internal/ (just directories)

**Constraints:**
- Use staticcheck for linting, not golangci-lint
- Keep scaffolding minimal - add files and dependencies incrementally
- Directory structure only - actual implementation files added in subsequent TODOs

**Estimated files:** 4 new files (`go.mod`, `.gitignore`, `Makefile`, `cmd/cal/main.go`) + directory structure

---

## 1.2 **REFINED:** Configuration Management (PR #4, merged 2026-02-01)

**Design Decisions:**
- **Precedence:** Per-VM config overrides global config overrides hard-coded defaults
- **Scope:** YAML configs only (`~/.cal/config.yaml` and per-VM `vm.yaml`). Other subsystems manage their own files (proxy module handles `~/.cal-proxy-config`, lifecycle handles flags, etc.)
- **Missing config:** Use hard-coded defaults silently (no auto-create, no errors)
- **Validation:** Error out immediately with clear messages including invalid value, expected range/format, and file path
- **Validation rules:** Strict validation using Tart-documented ranges:
  - CPU: Valid range from Tart documentation
  - Memory: Valid range from Tart documentation (MB)
  - Disk size: Valid range from Tart documentation (GB)
  - Proxy mode: Must be one of `auto`, `on`, `off`
  - Base image: String validation (non-empty)
- **Config inspection:** `cal config show [--vm name]` displays effective merged configuration

**Tasks:**
1. Define config structs in `internal/config/config.go` with schema version support
2. Implement config loading from `~/.cal/config.yaml` (optional file, silent fallback to defaults)
3. Implement per-VM config from `~/.cal/isolation/vms/{name}/vm.yaml` (optional)
4. Implement config merging logic: hard-coded defaults → global config → per-VM config
5. Add config validation with strict ranges from Tart documentation
6. Add hard-coded config defaults in code
7. Implement `cal config show [--vm name]` command to display effective merged config
8. Add clear error messages (format: "Invalid {field} '{value}' in {path}: must be {expected}")

**Config schema (from ADR):**
```yaml
version: 1
isolation:
  defaults:
    vm:
      cpu: 4
      memory: 8192
      disk_size: 80
      base_image: "ghcr.io/cirruslabs/macos-sequoia-base:latest"
    github:
      default_branch_prefix: "agent/"
    output:
      sync_dir: "~/cal-output"
    proxy:
      mode: "auto"  # auto, on, off
```

**Per-VM config example (`~/.cal/isolation/vms/heavy-build/vm.yaml`):**
```yaml
# Only specify fields to override from global config
cpu: 8
memory: 16384
# Other fields inherit from global config or defaults
```

**Config loading order:**
1. Load hard-coded defaults
2. Merge global config from `~/.cal/config.yaml` (if exists)
3. Merge per-VM config from `~/.cal/isolation/vms/{name}/vm.yaml` (if exists)
4. Result: Per-VM values override global values override defaults

**Acceptance criteria:**
- [x] Config loads from global and per-VM files with correct precedence
- [x] Missing config files handled gracefully (silent fallback to defaults)
- [x] Invalid config values rejected with clear error messages showing value, expected range, and file path
- [x] `cal config show` displays effective merged configuration for default VM
- [x] `cal config show --vm <name>` displays effective merged configuration for specific VM
- [x] Validation uses Tart-documented ranges (research Tart docs during implementation)
- [x] Other subsystems manage their own config files independently (config module doesn't touch them)

**Constraints:**
- YAML format only for Phase 1
- Must research Tart documentation for accurate validation ranges
- Error messages must include: field name, invalid value, expected range/format, file path where set
- Config module does NOT manage other VM files (listed below for reference only)

**Other VM files (NOT managed by config module - for reference only):**
- `~/.cal-vm-info` - VM metadata (managed by VM lifecycle subsystem)
- `~/.cal-vm-config` - VM password (managed by lifecycle subsystem, mode 600)
- `~/.cal-proxy-config` - Proxy settings (managed by proxy subsystem)
- `~/.cal-auth-needed` / `~/.cal-first-run` - Lifecycle flags (managed by lifecycle subsystem)
- `~/.tmux.conf` - tmux configuration (managed by SSH subsystem)
- `~/.zshrc` - Shell configuration (managed by lifecycle subsystem)
- `~/.zlogout` - Logout git status check (managed by git safety subsystem)

**Future enhancements (tracked as separate TODOs below):**
- Interactive config fixing on validation errors
- Environment variable overrides (e.g., `CAL_VM_CPU=8`)
- `cal config validate` command
- Config schema migration strategy for version changes
- `cal config show --defaults` to display hard-coded defaults
