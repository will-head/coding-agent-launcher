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
