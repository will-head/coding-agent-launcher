# Coding Standards

Mandatory standards for CALF development, derived from code review findings.

---

## Code Duplication

**Never** leave copy-paste artifacts. Extract repeated logic into functions. Use `git diff` before committing to catch unintended duplications.

---

## Dependency Management

**Must** verify external tools exist before use and give clear error messages when missing.

**Shell:**
```bash
for tool in jq gh curl; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Error: Required tool '$tool' is not installed"
        exit 1
    fi
done
```

**Go:**
```go
if _, err := exec.LookPath("tart"); err != nil {
    return fmt.Errorf("required command 'tart' not found in PATH")
}
```

---

## Documentation Accuracy

- **Must** verify code implements what docs describe; update docs immediately when behaviour changes
- **Must** include `TODO:` status for planned features not yet implemented
- **Must** review PR descriptions against actual code changes
- **Allowed** to document default dev credentials — label as "default" and note how to change

---

## Error Handling

**Never** redirect errors to `/dev/null`. Log errors even when not shown to users. Provide actionable messages.

```bash
# Bad
git clone "$repo" &>/dev/null

# Good
if ! git clone "$repo" 2>&1; then
    echo "Error: Failed to clone $repo. Check network and SSH keys."
    return 1
fi
```

---

## Proactive Validation

Validate preconditions before attempting operations: auth before network, permissions before filesystem, connectivity before remote.

```bash
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "Error: GitHub SSH authentication failed"
    echo "Run: ssh-keygen && gh auth login"
    return 1
fi
```

---

## Shell `trap` Handlers

Each new `trap ... EXIT` call **replaces** the previous one — it does not chain. When a script creates multiple temporary directories (or other resources) at different points, every subsequent `trap` must include all earlier resources.

**Never** register a second `trap EXIT` that omits resources registered by the first.

```bash
# Bad — TMP leaks if the script exits after TMP2 is created
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
# ... later ...
TMP2=$(mktemp -d)
trap 'rm -rf "$TMP2"' EXIT   # silently drops TMP cleanup

# Good — update the handler to cover all live resources
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
# ... later ...
TMP2=$(mktemp -d)
trap 'rm -rf "$TMP" "$TMP2"' EXIT
```

---

## Security Practices

**Never** use `eval`. Quote all variables in shell scripts. Sanitize external input before use in commands.

```bash
# Bad
eval echo "$some_path"

# Good
target_dir="${HOME}/code"
```

---

## Testing Requirements

### Invoke `coops-tdd` skill before any code change

The `coops-tdd` skill is mandatory before writing any code. It covers: `when...should...` naming, Arrange/Act/Assert structure, public-interface-only rule, mock rules, and Red/Green/Refactor cycle. Code written without invoking it must not be committed.

### Mandatory scenarios — Go

Every change must cover: success path · all error return paths · edge/boundary conditions · component interactions (where applicable).

### Mandatory scenarios — shell scripts

Valid inputs · invalid inputs · missing dependencies · auth failures · existing state · network failures.

---

## Go Test Style

Naming, Arrange/Act/Assert, and public-interface-only rules come from the `coops-tdd` skill. These rules cover Go-specific patterns the skill does not address.

### No table-driven loops

**Never** use `for _, tt := range tests { t.Run(tt.name, ...) }`. Each scenario must be its own `t.Run` block with its own Arrange/Act/Assert.

```go
// Good
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

// Bad
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) { ... })
}
```

### Fresh instance per test — no shared state

Each subtest creates its own instance. Never share a constructed instance across subtests.

**Commands (cobra):** wrap a factory function in a setup helper:

```go
func setupRootCmd(t *testing.T, args ...string) (*cobra.Command, *bytes.Buffer, *bytes.Buffer) {
    t.Helper()
    out, errOut := &bytes.Buffer{}, &bytes.Buffer{}
    cmd := newRootCmd("test")
    cmd.SetOut(out); cmd.SetErr(errOut); cmd.SetArgs(args)
    return cmd, out, errOut
}
```

**Structs with injectable deps:** use functional options — never write unexported fields directly:

```go
// Good
client := NewTartClient(
    WithLookPath(func(file string) (string, error) { ... }),
    WithRunCommand(func(args ...string) (string, error) { return mock.runCommand("tart", args...) }),
)

// Bad
client.lookPath = func(...) { ... }  // unexported field
```

### `t.TempDir()` over `os.MkdirTemp`

```go
homeDir := t.TempDir()                                            // Good — auto-cleanup
tmpDir, _ := os.MkdirTemp("", "x"); defer os.RemoveAll(tmpDir)   // Bad
```

### `t.Helper()` in test helpers

Call `t.Helper()` first in any function that calls `t.Fatal`/`t.Error` — failure output points to the calling test, not the helper.

### Canonical reference files

| File | Demonstrates |
|------|-------------|
| `cmd/calf/config_test.go` | Factory via `newRootCmd()`, `t.Setenv` for env isolation |
| `cmd/calf/main_test.go` | Shared setup helper, fresh cmd per test |
| `cmd/calf/cache_test.go` | File-system assertions, confirm/decline flows |
| `internal/isolation/tart_test.go` (Clone tests) | Functional options, multi-option client construction |
| `internal/isolation/cache_test.go` (`TestClearCache`) | Per-subtest `t.TempDir()` + factory |

---

## Go Language Standards

### Stdlib over custom implementations

Use `strings`, `filepath`, `slices` etc. before writing custom helpers.

```go
// Bad
func contains(s, substr string) bool {
    for i := 0; i <= len(s)-len(substr); i++ {
        if s[i:i+len(substr)] == substr { return true }
    }
    return false
}

// Good
strings.Contains(s, substr)
```

### GoDoc on all exported identifiers

All exported types, functions, constants, and variables must have GoDoc comments starting with the identifier name.

```go
// Config represents the top-level CAL configuration structure.
type Config struct { ... }

// LoadConfig loads configuration from global and per-VM paths.
// Returns error if files exist but cannot be read or parsed.
func LoadConfig(globalPath, vmPath string) (*Config, error) { ... }
```

---

## Code Review Checklist

Before submitting code for review, **must** verify:

- [ ] `coops-tdd` skill invoked before writing any code
- [ ] No duplicate code blocks or copy-paste errors
- [ ] All external dependencies checked before use
- [ ] Documentation matches implementation; planned features marked `TODO:`
- [ ] Errors never silently suppressed
- [ ] Preconditions validated before operations
- [ ] No `eval`; all shell variables quoted
- [ ] Each `trap EXIT` update covers all previously registered resources — no silent drops
- [ ] All test scenarios executed; `go test ./...` and `staticcheck ./...` pass
- [ ] `go build ./...` succeeds
- [ ] Stdlib used over custom implementations
- [ ] All exported Go identifiers have GoDoc comments
- [ ] No table-driven `for _, tt := range tests` loops — each scenario is its own `t.Run` block
- [ ] Each subtest creates its own fresh instance — no shared state between subtests
- [ ] Temporary directories use `t.TempDir()` not `os.MkdirTemp` + `defer os.RemoveAll`
- [ ] Test helpers call `t.Helper()` as their first statement
- [ ] Injectable deps use functional options or exported constructors — no unexported field writes
