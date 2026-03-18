# TDD Remediation 4 — Arrange/Act/Assert Consistency and Table-Driven Test Elimination

> **Source:** coops-tdd audit 2026-03-18
>
> **Scope:** Fix all FAIL and WARN violations from the Remediation 4 audit. Items ordered smallest-to-largest: documentation close first (no code change), then pure structural additions (Arrange/Act/Assert), then structural rewrites (table-driven → individual blocks), then test isolation improvements.
>
> **Reference assessment:** coops-tdd audit report, session history 2026-03-18
>
> **Workflow:** Always follow the `coops-tdd` skill throughout this remediation. Every item — even pure test restructuring — must go through the coops-tdd process before changes are made.
>
> **Style reference:** Use `cmd/calf/config_test.go` and the `TestCloneWhenTart*` tests in `internal/isolation/tart_test.go` as style guides. Each scenario is an individual `t.Run("when...should...", ...)` block with explicit `// Arrange`, `// Act`, `// Assert` sections — not table-driven loops.

---

## Summary of Violations

| # | File | Severity | Violation |
|---|------|----------|-----------|
| 1 | `docs/TDD-REMEDIATION-3-TODO.md` | FAIL | Items 8, 9, 10 implemented (commits `4b0ebe9`, `2c17cf4`) but not moved to DONE file |
| 2 | `internal/config/config_test.go` | WARN | All 21 subtests across 6 test functions missing `// Arrange`, `// Act`, `// Assert` sections |
| 3 | `internal/isolation/tart_test.go` | WARN | 22 subtests in `TestClone`, `TestSet`, `TestStop`, `TestDelete`, `TestList`, `TestIP`, `TestGet`, `TestRun`, `TestRunWithCacheDirs` missing `// Arrange`, `// Act`, `// Assert` sections |
| 4 | `internal/isolation/tart_test.go` | FAIL | `TestIsRunning`, `TestExists`, `TestGetState` use table-driven `for _, tt := range tests` loops; convention requires individual `t.Run("when...should...", ...)` blocks |
| 5 | `internal/isolation/cache_test.go` | WARN | `TestHomebrewCacheSetup`, `TestGetHomebrewCacheInfo`, `TestCacheStatus`, and equivalent tests for npm/go/git use `os.MkdirTemp` + `defer os.RemoveAll` instead of `t.TempDir()` |
| 6 | `internal/isolation/cache_test.go` | WARN | ~40 subtests across older test groups missing `// Arrange`, `// Act`, `// Assert` sections |
| 7 | `internal/isolation/cache_test.go` | WARN | Several test functions (`TestHomebrewCacheSetup`, `TestGetHomebrewCacheInfo`, `TestCacheStatus`, and equivalents) create a shared `cm` at function scope; subtests share mutable state and cannot be independently reproduced |

Items 5, 6, and 7 share the same root cause (older tests predating the current style guide) and are addressed together in Item 7 below.

---

## Item 1 — Close TDD-R3 Items 8, 9, 10 in DONE File (FAIL — doc drift, no code change)

**File:** `docs/TDD-REMEDIATION-3-TODO.md`, `docs/TDD-REMEDIATION-3-DONE.md`

**Problem:** Items 8, 9, and 10 are unchecked in the TODO file's Execution Order and Completion Criteria sections, but their work is fully implemented:

- Item 8 (`TestCloneWhenTart*` rewritten using options) — commit `4b0ebe9`
- Item 9 (`makeInstallingRunCommand` deleted) — commit `4b0ebe9`
- Item 10 (`newRootCmd()` / `newConfigCmd()` factories) — commit `2c17cf4`

**Action:** Move Items 8, 9, and 10 from `TDD-REMEDIATION-3-TODO.md` to `TDD-REMEDIATION-3-DONE.md` with completion date 2026-03-18. Mark all their completion criteria as `[x]` in the DONE file. Update the Execution Order in the TODO file to show all items struck through. Verify `go test ./...` and `staticcheck ./...` pass — they should, as no code changes are made.

---

## Item 2 — Add Arrange/Act/Assert to `config_test.go` (WARN)

**File:** `internal/config/config_test.go`

**Problem:** All 21 subtests across `TestLoadConfig`, `TestLoadVMConfig`, `TestValidateConfig`, `TestGetDefaultConfigPath`, `TestGetVMConfigPath`, and `TestConfigPathValidation` lack `// Arrange`, `// Act`, `// Assert` section markers. The logic is correct; only structural markers are missing.

**Action:** Add `// Arrange`, `// Act`, `// Assert` comments to every subtest. The test logic does not change — only markers are inserted.

Pattern to apply:

```go
t.Run("when config file is missing should use default values", func(t *testing.T) {
    // Arrange
    tmpDir := t.TempDir()
    configPath := filepath.Join(tmpDir, "config.yaml")

    // Act
    cfg, err := LoadConfig(configPath, "")

    // Assert
    if err != nil {
        t.Fatalf("LoadConfig returned unexpected error: %v", err)
    }
    if cfg.Isolation.Defaults.VM.CPU != 4 {
        t.Errorf("Expected CPU default 4, got %d", cfg.Isolation.Defaults.VM.CPU)
    }
    // ... remaining assertions
})
```

Notes on placement:
- **Arrange:** variable declarations, file setup, config struct construction
- **Act:** the single call under test (`LoadConfig`, `cfg.Validate`, `GetDefaultConfigPath`, etc.)
- **Assert:** all `if err` / `if !` / `if !=` checks follow Act

Where a test has multiple assertions under Assert, group them all after the single Act line — do not insert additional Act lines.

Run `go test ./internal/config/...` — all tests pass. Test count unchanged.

---

## Item 3 — Add Arrange/Act/Assert to `tart_test.go` Non-Clone Tests (WARN)

**File:** `internal/isolation/tart_test.go` (lines 103–351 and 473–635)

**Problem:** 22 subtests across 9 test functions have no `// Arrange`, `// Act`, `// Assert` markers. Affected functions: `TestClone`, `TestSet`, `TestStop`, `TestDelete`, `TestList`, `TestIP`, `TestGet`, `TestRun`, `TestRunWithCacheDirs`.

**Action:** Add section markers to each subtest. No logic changes — only markers inserted.

The Arrange section for most tests is the mock setup and `createTestClient` call. The Act section is the single method call under test. The Assert section is all `if` checks.

Example pattern for a typical subtest:

```go
t.Run("when clone succeeds should execute tart clone command with correct args", func(t *testing.T) {
    // Arrange
    mock := newMockCommandRunner()
    mock.addOutput("clone test-image test-vm", "")
    client := createTestClient(mock)

    // Act
    err := client.Clone("test-image", "test-vm")

    // Assert
    if err != nil {
        t.Errorf("Clone() unexpected error = %v", err)
    }
    if len(mock.commands) != 1 {
        t.Errorf("Expected 1 command, got %d", len(mock.commands))
    }
    expected := []string{"tart", "clone", "test-image", "test-vm"}
    if !slices.Equal(mock.commands[0], expected) {
        t.Errorf("Clone() command = %v, want %v", mock.commands[0], expected)
    }
})
```

Run `go test ./internal/isolation/... -run TestClone|TestSet|TestStop|TestDelete|TestList|TestIP|TestGet|TestRun|TestRunWithCacheDirs` — all pass. Test count unchanged.

---

## Item 4 — Rewrite Table-Driven `TestIsRunning`, `TestExists`, `TestGetState` as Individual Blocks (FAIL)

**File:** `internal/isolation/tart_test.go` (lines 353–471)

**Problem:** Three test functions use `for _, tt := range tests { t.Run(tt.name, ...) }` loops. AGENTS.md style guide explicitly requires individual `t.Run("when...should...", ...)` blocks with `// Arrange`, `// Act`, `// Assert` sections — not table-driven loops.

**Action:** Replace each table + loop with individual `t.Run` blocks. The subtest names already exist in the `name` fields — carry them directly.

### `TestIsRunning` — replace with three individual blocks:

```go
func TestIsRunning(t *testing.T) {
    t.Run("when vm is running should return true", func(t *testing.T) {
        // Arrange
        mock := newMockCommandRunner()
        mock.addOutput("list --format json", `[{"name":"test-vm","state":"running"}]`)
        client := createTestClient(mock)

        // Act
        got := client.IsRunning("test-vm")

        // Assert
        if !got {
            t.Errorf("IsRunning() = false, want true")
        }
    })

    t.Run("when vm is stopped should return false", func(t *testing.T) {
        // Arrange
        mock := newMockCommandRunner()
        mock.addOutput("list --format json", `[{"name":"test-vm","state":"stopped"}]`)
        client := createTestClient(mock)

        // Act
        got := client.IsRunning("test-vm")

        // Assert
        if got {
            t.Errorf("IsRunning() = true, want false")
        }
    })

    t.Run("when vm does not exist should return false", func(t *testing.T) {
        // Arrange
        mock := newMockCommandRunner()
        mock.addOutput("list --format json", `[]`)
        client := createTestClient(mock)

        // Act
        got := client.IsRunning("test-vm")

        // Assert
        if got {
            t.Errorf("IsRunning() = true, want false")
        }
    })
}
```

### `TestExists` — replace with two individual blocks:

```go
func TestExists(t *testing.T) {
    t.Run("when vm exists in list should return true", func(t *testing.T) {
        // Arrange
        mock := newMockCommandRunner()
        mock.addOutput("list --format json", `[{"name":"test-vm","state":"running"}]`)
        client := createTestClient(mock)

        // Act
        got := client.Exists("test-vm")

        // Assert
        if !got {
            t.Errorf("Exists() = false, want true")
        }
    })

    t.Run("when vm does not exist in list should return false", func(t *testing.T) {
        // Arrange
        mock := newMockCommandRunner()
        mock.addOutput("list --format json", `[]`)
        client := createTestClient(mock)

        // Act
        got := client.Exists("test-vm")

        // Assert
        if got {
            t.Errorf("Exists() = true, want false")
        }
    })
}
```

### `TestGetState` — replace with three individual blocks:

```go
func TestGetState(t *testing.T) {
    t.Run("when vm is running should return running state", func(t *testing.T) {
        // Arrange
        mock := newMockCommandRunner()
        mock.addOutput("list --format json", `[{"name":"test-vm","state":"running"}]`)
        client := createTestClient(mock)

        // Act
        got := client.GetState("test-vm")

        // Assert
        if got != StateRunning {
            t.Errorf("GetState() = %v, want StateRunning", got)
        }
    })

    t.Run("when vm is stopped should return stopped state", func(t *testing.T) {
        // Arrange
        mock := newMockCommandRunner()
        mock.addOutput("list --format json", `[{"name":"test-vm","state":"stopped"}]`)
        client := createTestClient(mock)

        // Act
        got := client.GetState("test-vm")

        // Assert
        if got != StateStopped {
            t.Errorf("GetState() = %v, want StateStopped", got)
        }
    })

    t.Run("when vm does not exist should return not found state", func(t *testing.T) {
        // Arrange
        mock := newMockCommandRunner()
        mock.addOutput("list --format json", `[]`)
        client := createTestClient(mock)

        // Act
        got := client.GetState("test-vm")

        // Assert
        if got != StateNotFound {
            t.Errorf("GetState() = %v, want StateNotFound", got)
        }
    })
}
```

Run `go test ./internal/isolation/... -run TestIsRunning|TestExists|TestGetState` — all 8 subtests pass. Test count unchanged.

---

## Item 5 — Refactor `cache_test.go` Older Tests: `t.TempDir()`, Arrange/Act/Assert, Per-Subtest Isolation (WARN)

**File:** `internal/isolation/cache_test.go`

**Problem:** Three related issues in older test groups (all predating the current style guide):

### 5a — Replace `os.MkdirTemp` + `defer os.RemoveAll` with `t.TempDir()`

Test functions `TestHomebrewCacheSetup`, `TestGetHomebrewCacheInfo`, `TestCacheStatus`, and the npm/go/git equivalents use:

```go
tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
if err != nil {
    t.Fatalf("failed to create temp dir: %v", err)
}
defer os.RemoveAll(tmpDir)
```

Replace with `t.TempDir()` which is the idiomatic Go test helper — it registers cleanup automatically and avoids the explicit `defer`:

```go
tmpDir := t.TempDir()
```

### 5b — Add Arrange/Act/Assert section markers

All subtests in the affected test groups (and any other subtests in the file that lack markers) need `// Arrange`, `// Act`, `// Assert` sections added. No logic changes.

### 5c — Refactor shared `cm` at function scope to per-subtest isolation

Several test functions create a shared `NewCacheManagerWithDirs` instance at function scope, then run multiple subtests against it. This means subtest state is shared and test order matters. Refactor so each subtest creates its own `t.TempDir()` and `NewCacheManagerWithDirs` instance.

**Example — current pattern (shared `cm`):**

```go
func TestHomebrewCacheSetup(t *testing.T) {
    tmpDir := t.TempDir()
    cm := NewCacheManagerWithDirs(tmpDir, filepath.Join(tmpDir, "cache"))

    t.Run("when home dir is available should create homebrew cache directory", func(t *testing.T) {
        // uses shared cm
    })

    t.Run("when called twice should succeed both times", func(t *testing.T) {
        // uses shared cm — depends on previous subtest having run
    })
}
```

**Replace with per-subtest isolation:**

```go
func TestHomebrewCacheSetup(t *testing.T) {
    t.Run("when home dir is available should create homebrew cache directory", func(t *testing.T) {
        // Arrange
        tmpDir := t.TempDir()
        cm := NewCacheManagerWithDirs(tmpDir, filepath.Join(tmpDir, "cache"))

        // Act
        err := cm.SetupHomebrewCache()

        // Assert
        if err != nil {
            t.Fatalf("SetupHomebrewCache failed: %v", err)
        }
        // ... directory existence checks
    })

    t.Run("when called twice should succeed both times", func(t *testing.T) {
        // Arrange
        tmpDir := t.TempDir()
        cm := NewCacheManagerWithDirs(tmpDir, filepath.Join(tmpDir, "cache"))

        // Act — first call
        if err := cm.SetupHomebrewCache(); err != nil {
            t.Fatalf("first SetupHomebrewCache failed: %v", err)
        }
        // Act — second call (idempotency check)
        err := cm.SetupHomebrewCache()

        // Assert
        if err != nil {
            t.Fatalf("second SetupHomebrewCache failed: %v", err)
        }
    })
}
```

Apply this pattern to all affected test functions in the file: `TestHomebrewCacheSetup`, `TestGetHomebrewCacheInfo`, `TestCacheStatus`, and npm/go/git equivalents.

**Note on `TestGetHomebrewCacheInfo` "cache contains files" subtest:** This subtest calls `SetupHomebrewCache` in its own Arrange section — the shared `cm` pre-state is not needed. With per-subtest isolation the subtest becomes self-contained.

Run `go test ./internal/isolation/...` — all tests pass. Test count unchanged.
Run `go test -count=2 ./internal/isolation/...` — proves no shared state leakage.

---

## Execution Order

Work through items strictly in this order to keep the test suite green throughout:

1. **Item 1** — Close TDD-R3 Items 8, 9, 10 in DONE file. Run `go test ./...`.
2. **Item 2** — Add Arrange/Act/Assert to `config_test.go`. Run `go test ./internal/config/...`.
3. **Item 3** — Add Arrange/Act/Assert to `tart_test.go` non-Clone tests. Run `go test ./internal/isolation/...`.
4. **Item 4** — Rewrite table-driven `TestIsRunning`, `TestExists`, `TestGetState`. Run `go test ./internal/isolation/...`.
5. **Item 5** — Refactor `cache_test.go`: `t.TempDir()` + Arrange/Act/Assert + per-subtest `cm`. Run `go test -count=2 ./internal/isolation/...`.

Final check: `go test ./...` and `staticcheck ./...` must both pass clean.

---

## Completion Criteria

- [ ] TDD-R3 Items 8, 9, 10 moved to `TDD-REMEDIATION-3-DONE.md` with completion date 2026-03-18
- [ ] All subtests in `internal/config/config_test.go` have `// Arrange`, `// Act`, `// Assert` sections
- [ ] All subtests in `internal/isolation/tart_test.go` have `// Arrange`, `// Act`, `// Assert` sections
- [ ] `TestIsRunning`, `TestExists`, `TestGetState` in `tart_test.go` rewritten as individual `t.Run` blocks (no table-driven loops)
- [ ] `os.MkdirTemp` + `defer os.RemoveAll` replaced with `t.TempDir()` throughout `cache_test.go`
- [ ] All subtests in `internal/isolation/cache_test.go` have `// Arrange`, `// Act`, `// Assert` sections
- [ ] Shared `cm` at function scope in `cache_test.go` replaced with per-subtest `NewCacheManagerWithDirs` + `t.TempDir()`
- [ ] `go test ./...` passes (test count ≥ 208)
- [ ] `go test -count=2 ./internal/isolation/...` passes (proves no shared state leakage)
- [ ] `staticcheck ./...` passes with no warnings
