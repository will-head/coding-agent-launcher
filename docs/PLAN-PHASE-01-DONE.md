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

---

## 1.3 Tart Wrapper (PR #5, merged 2026-02-03)

**File:** `internal/isolation/tart.go`

**Implementation:**
- Implemented `TartClient` struct that wraps all Tart CLI operations
- Methods: Clone, Set, Run (headless/VNC), Stop, Delete, List, IP, Get
- JSON parsing using Go's `encoding/json` (no jq dependency)
- Auto-install Tart via Homebrew with interactive user prompt
- IP polling with progress indicator (2s interval, 60s timeout)
- VNC experimental mode (`--vnc-experimental`) by default for better UX
- Cache sharing (`--dir=tart-cache:~/.tart/cache:ro`) on all VM starts
- VM state tracking (running/stopped/not_found) with fresh queries
- Error wrapping with operation context for clear failure messages
- Comprehensive unit tests (27 tests) covering all methods and error paths

**Acceptance Criteria Met:**
- [x] All Tart operations wrapped with clear Go API
- [x] Errors include helpful context and operation details
- [x] IP polling shows progress and completes within 60s or fails clearly
- [x] Auto-install prompts user and handles missing Homebrew gracefully
- [x] Cache sharing enabled on all runs without user configuration
- [x] Unit tests cover command generation and error handling
- [x] No external dependencies (jq not required)

---

## 1.1.1 Homebrew Package Download Cache (PR #6, merged 2026-02-03)

**Cache Location:**
- **Host:** `~/.cal-cache/homebrew/` (persistent across VM operations)
- **VM:** Symlink `~/.cal-cache/homebrew/` → `/Volumes/My Shared Files/cal-cache/homebrew/`
- **Pattern:** Same as Tart cache sharing in section 1.9 (proven approach)

**Implementation Details:**

1. **Code Location:** `internal/isolation/cache.go`
   - New `CacheManager` struct with methods for setup, status
   - Integration point: Called from VM init/setup process
   - Follows existing isolation subsystem patterns

2. **Host Cache Setup:**
   - Create `~/.cal-cache/homebrew/` on host if doesn't exist
   - No host environment configuration needed (host uses default Homebrew cache)
   - Host directory structure: `~/.cal-cache/homebrew/downloads/`, `~/.cal-cache/homebrew/Cask/`

3. **VM Cache Passthrough (Symlink Approach):**
   - Create Tart shared directory: Ensure `/Volumes/My Shared Files/cal-cache/` exists
   - Copy host cache to shared volume: `rsync -a ~/.cal-cache/homebrew/ "/Volumes/My Shared Files/cal-cache/homebrew/"`
   - Create symlink in VM: `ln -sf "/Volumes/My Shared Files/cal-cache/homebrew" ~/.cal-cache/homebrew`
   - Configure in VM: `export HOMEBREW_CACHE=~/.cal-cache/homebrew` (add to `.zshrc`)
   - Verify symlink writable from VM

4. **Error Handling (Graceful Degradation):**
   - If symlink creation fails: Log warning, continue without cache
   - If shared volume unavailable: Log warning, continue without cache
   - Bootstrap still works, just slower (no hard failure)
   - Consistent with Tart cache sharing pattern in section 1.9

5. **Cache Status Command:** `cal cache status`
   - Display information:
     - Cache sizes per package manager (e.g., "Homebrew: 450 MB")
     - Cache location path (e.g., "~/.cal-cache/homebrew/")
     - Cache availability status (✓ Homebrew cache ready, ✗ npm cache not configured)
     - Last access time (from filesystem mtime)
   - Output format: Human-readable table or list
   - Implementation: `internal/isolation/cache.go` → `Status()` method

6. **Cache Invalidation Strategy:**
   - **Let package managers handle it** - no manual invalidation logic
   - Homebrew validates cache integrity and checksums automatically
   - Invalid or outdated cache entries are re-downloaded by Homebrew
   - Simplest approach: just set `HOMEBREW_CACHE` and let Homebrew manage lifetime

**Benefits:**
- **Speed:** Saves ~5-10 minutes per bootstrap (biggest single win)
- **Reliability:** Reduces network dependency, fewer timeout failures
- **Bandwidth:** Saves hundreds of MB per bootstrap iteration
- **Development:** Faster snapshot/restore testing cycles

**Constraints:**
- Requires Tart shared directories feature (graceful degradation if unavailable)
- Disk space: ~500-800 MB for Homebrew cache
- Cache persists across VM operations (intended behavior)

**Testing Strategy:**
- **Unit Tests:** Cache setup logic, symlink creation, graceful degradation paths
- **Integration Tests (with mocks):** Mock filesystem operations, verify environment configuration
- **Manual Testing:**
  - First bootstrap: Download everything, populate cache
  - Second bootstrap: Verify cache used, measure time improvement
  - Snapshot/restore: Verify cache persists and remains functional
  - Symlink failure: Verify graceful degradation (bootstrap completes without cache)

**Acceptance Criteria:**
- [x] Homebrew cache directory created on host
- [x] Symlink created in VM pointing to shared cache
- [x] `HOMEBREW_CACHE` environment variable set in VM
- [x] `cal cache status` shows Homebrew cache info (size, location, availability, last access)
- [x] Bootstrap time reduced by at least 30% on second run (Homebrew portion)
- [x] Graceful degradation works if symlink fails
- [x] Unit and integration tests pass
- [x] Documentation updated in ADR-002

**Related:**
- Section 1.9: VM lifecycle automation (Tart cache sharing pattern reference)
- BUG-006: Network timeout during bootstrap (Homebrew cache will help prevent)

---

## 1.1.2 npm Package Download Cache (PR #7, merged 2026-02-03)

**Cache Location:**
- **Host:** `~/.cal-cache/npm/` (persistent across VM operations)
- **VM:** Symlink `~/.cal-cache/npm/` → `/Volumes/My Shared Files/cal-cache/npm/`
- **Pattern:** Same as Phase 1.1.1 (proven approach)

**Implementation Details:**

1. **Code Location:** `internal/isolation/cache.go` (extend existing `CacheManager`)
   - Add npm-specific setup method
   - Integrate into VM init/setup process

2. **Host Cache Setup:**
   - Create `~/.cal-cache/npm/` on host if doesn't exist
   - No host environment configuration needed

3. **VM Cache Passthrough:**
   - Create Tart shared directory: `/Volumes/My Shared Files/cal-cache/npm/`
   - Copy host cache: `rsync -a ~/.cal-cache/npm/ "/Volumes/My Shared Files/cal-cache/npm/"`
   - Create symlink in VM: `ln -sf "/Volumes/My Shared Files/cal-cache/npm" ~/.cal-cache/npm`
   - Configure in VM: `npm config set cache ~/.cal-cache/npm` (run during vm-setup.sh)
   - Verify symlink writable

4. **Error Handling:** Graceful degradation (same as Phase 1.1.1)

5. **Cache Status:** Update `cal cache status` to include npm cache info

6. **Cache Invalidation:** Let npm handle it (validates cache metadata automatically)

**Benefits:**
- **Speed:** Saves ~2-3 minutes per bootstrap
- **Bandwidth:** Saves ~50-100 MB per bootstrap
- **Packages:** claude, agent, ccs, codex CLI tools

**Constraints:**
- Disk space: ~100-200 MB for npm cache

**Testing Strategy:**
- Unit tests for npm cache setup logic
- Integration tests with mocks
- Manual: Bootstrap twice, verify npm uses cache

**Acceptance Criteria:**
- [x] npm cache directory created on host
- [x] Symlink created in VM
- [x] `npm config get cache` returns `~/.cal-cache/npm` in VM
- [x] `cal cache status` shows npm cache info
- [x] Bootstrap time reduced by additional 15-20% with npm cache
- [x] Graceful degradation works
- [x] Tests pass

---

## 1.1.3 Go Modules Cache (PR #8, merged 2026-02-03)

**Dependencies:** Phase 1.1.2 (npm cache) must be complete first.

**Status:** Merged

**Cache Location:**
- **Host:** `~/.cal-cache/go/pkg/mod/` (persistent across VM operations)
- **VM:** Symlink `~/.cal-cache/go/` → `/Volumes/My Shared Files/cal-cache/go/`
- **Pattern:** Same as Phases 1.1.1 and 1.1.2

**Implementation Details:**

1. **Code Location:** `internal/isolation/cache.go` (extend existing `CacheManager`)
   - Add Go-specific setup method

2. **Host Cache Setup:**
   - Create `~/.cal-cache/go/pkg/mod/` on host if doesn't exist
   - Create `~/.cal-cache/go/pkg/sumdb/` for checksum database

3. **VM Cache Passthrough:**
   - Create Tart shared directory: `/Volumes/My Shared Files/cal-cache/go/`
   - Copy host cache: `rsync -a ~/.cal-cache/go/ "/Volumes/My Shared Files/cal-cache/go/"`
   - Create symlink in VM: `ln -sf "/Volumes/My Shared Files/cal-cache/go" ~/.cal-cache/go`
   - Configure in VM: `export GOMODCACHE=~/.cal-cache/go/pkg/mod` (add to `.zshrc`)
   - Verify symlink writable

4. **Error Handling:** Graceful degradation (same as previous phases)

5. **Cache Status:** Update `cal cache status` to include Go cache info

6. **Cache Invalidation:** Let Go handle it (uses `go.sum` checksums for validation)

**Benefits:**
- **Speed:** Saves ~1-2 minutes per bootstrap
- **Bandwidth:** Saves ~20-50 MB per bootstrap
- **Modules:** staticcheck, goimports, delve, mockgen, air

**Constraints:**
- Disk space: ~50-150 MB for Go module cache

**Testing Strategy:**
- Unit tests for Go cache setup logic
- Integration tests with mocks
- Manual: Bootstrap twice, verify Go uses cache

**Acceptance Criteria:**
- [x] Go cache directory created on host
- [x] Symlink created in VM
- [x] `go env GOMODCACHE` returns `~/.cal-cache/go/pkg/mod` in VM
- [x] `cal cache status` shows Go cache info
- [x] Bootstrap time reduced by additional 10-15% with Go cache
- [x] Graceful degradation works
- [x] Tests pass

## 1.1.4 **REFINED:** Git Clones Cache (PR #9, merged 2026-02-03)

**Dependencies:** Phase 1.1.3 (Go modules cache) complete.

**Status:** Merged with complete cache integration

**Cache Location:**
- **Host:** `~/.cal-cache/git/<repo-name>/` (persistent across VM operations)
- **VM:** Shared via `/Volumes/My Shared Files/cal-cache/git/<repo-name>/`
- **Pattern:** Selective caching for frequently cloned repos (TPM)

**Implementation Highlights:**

1. **Code Location:** `internal/isolation/cache.go`
   - Extended `CacheManager` with git cache methods
   - `SetupGitCache()`, `GetGitCacheInfo()`, `CacheGitRepo()`, etc.
   - Unit tests with full coverage

2. **Bootstrap Integration:**
   - `cal-bootstrap`: Cache directory creation during --init
   - `vm-setup.sh`: VM cache configuration (permanent)
   - `vm-tmux-resurrect.sh`: TPM caching from shared host cache
   - Host cache temporary (script-only), VM cache permanent

3. **Cache Population:**
   - TPM cloned from GitHub on first install
   - TPM cached to shared volume for future bootstraps
   - Cache updated with `git fetch` before use
   - Graceful fallback to GitHub if cache unavailable

4. **Additional Improvements:**
   - Homebrew/npm/Go cache integration into bootstrap
   - Cursor CLI via Homebrew Cask (now cacheable)
   - Complete package manager cache configuration
   - 100% of downloads now cached

**Testing Results:**
- ✅ All manual tests passed (git cache, TPM caching, offline bootstrap)
- ✅ Cache sharing verified working
- ✅ Offline capability confirmed
- ✅ Unit tests: 330 tests passing

**Benefits Realized:**
- **Speed:** ~30-60 seconds saved per bootstrap (TPM)
- **Offline:** Works without network after first bootstrap
- **Total Cache:** ~20-30GB (all package managers + git repos)
- **Integration:** All package managers use shared cache

**Documentation:**
- docs/PR-9-TEST-RESULTS.md - Complete test results
- docs/PR-9-INIT-REVIEW.md - Init integration review
- docs/CACHE-INTEGRATION.md - Integration design and details

**Acceptance Criteria Met:**
- [x] Git cache directory created on host
- [x] TPM cached and used during bootstrap
- [x] Cache updated with `git fetch` before use
- [x] `cal cache status` shows cached git repos
- [x] Bootstrap works offline with cached repos
- [x] Graceful degradation when cache unavailable
- [x] All tests pass (unit + manual)
- [x] Bootstrap integration complete

