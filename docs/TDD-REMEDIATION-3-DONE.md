# TDD Remediation 3 — Completed Items

> **Source:** coops-tdd audit 2026-03-17

---

## Item 1 — Rename `TestVMStateString` Subtests (2026-03-17)

**File:** `internal/isolation/tart_test.go`

Replaced table-driven `TestVMStateString` with individual `t.Run("when...should...", ...)` blocks, each with explicit `// Arrange / // Act / // Assert` sections. Added separate `want` field; removed the dual-purpose `name` field that doubled as expected string.

Also applied as part of code review: replaced hand-rolled `equalStringSlices` and `sliceContains` helpers with stdlib `slices.Equal` and `slices.Contains` (Go 1.21+); removed both helpers.

**Completion criteria met:**
- [x] `TestVMStateString` subtests renamed to `when...should...` with separate `want` field
- [x] `go test ./...` passes (203 tests)
- [x] `staticcheck ./...` clean
