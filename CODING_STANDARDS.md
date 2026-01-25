# Coding Standards

This document establishes mandatory coding standards for CAL development. These standards are derived from common errors found in code reviews and must be followed to maintain code quality and prevent repeated mistakes.

---

## Code Duplication

### Never duplicate code blocks
**Common Error:** Copy-pasting code sections and forgetting to remove duplicates, leaving identical blocks in the same file.

**Standards:**
- **Must** review all files for duplicate code before committing
- **Must** extract repeated logic into functions rather than duplicating
- **Never** leave copy-paste artifacts in code
- **Must** use version control diff tools to catch unintended duplications

---

## Dependency Management

### Always verify external tool availability
**Common Error:** Using external tools (like `jq`, `gh`, `curl`) without checking if they're installed, leading to cryptic runtime failures.

**Standards:**
- **Must** check for all required external dependencies before use
- **Must** provide clear error messages when dependencies are missing
- **Must** document all external dependencies in scripts and code comments
- **Must** use consistent dependency checking patterns across the codebase

**Shell Script Pattern:**
```bash
# Check for required tools
for tool in jq gh curl; do
    if ! command -v "$tool" &>/dev/null; then
        echo "Error: Required tool '$tool' is not installed"
        exit 1
    fi
done
```

**Go Pattern:**
```go
// Check external command availability in init() or early validation
if _, err := exec.LookPath("tart"); err != nil {
    return fmt.Errorf("required command 'tart' not found in PATH")
}
```

---

## Documentation Accuracy

### Ensure code matches documentation claims
**Common Error:** Documentation claiming functionality that isn't actually implemented in the code.

**Standards:**
- **Must** verify that code implements what documentation describes
- **Never** document intended behavior that isn't implemented
- **Must** update documentation immediately when behavior changes
- **Must** include implementation status for planned features (e.g., "TODO: Add sorting")
- **Must** review PR descriptions against actual code changes

### Documenting default credentials is acceptable
**Accepted Practice:** Including default passwords or credentials in documentation for development/testing environments is explicitly allowed and not considered a documentation error.

**Standards:**
- **Allowed** to document default credentials for local development or testing VMs
- **Should** label clearly as "default" or "initial" credentials when possible
- **Should** include guidance on changing credentials for production use
- **Never** flag this as a documentation issue requiring fixes

**Example:**
```bash
# This is acceptable in documentation:
open vnc://$(tart ip cal-dev)   # password: admin

# Better (with production guidance):
open vnc://$(tart ip cal-dev)   # password: admin (default, change for production)
```

---

## Error Handling

### Never suppress errors silently
**Common Error:** Using `&>/dev/null` or similar constructs to hide all error output, making debugging impossible.

**Standards:**
- **Never** redirect errors to `/dev/null` unless explicitly justified
- **Must** log errors even if not displayed to users
- **Must** provide actionable error messages that guide users to solutions
- **Must** distinguish between expected failures and unexpected errors
- **Must** preserve error context through function call chains

**Shell Script Pattern:**
```bash
# Bad
git clone "$repo" &>/dev/null

# Good - show errors
git clone "$repo" 2>&1

# Better - conditional error handling
if ! git clone "$repo" 2>&1; then
    echo "Error: Failed to clone $repo. Check network and SSH keys."
    return 1
fi
```

---

## Proactive Validation

### Validate preconditions before attempting operations
**Common Error:** Attempting operations (like git clone) without checking prerequisites (like SSH key configuration), leading to confusing failures.

**Standards:**
- **Must** validate all preconditions before attempting operations
- **Must** check authentication before network operations
- **Must** verify filesystem permissions before file operations
- **Must** test connectivity before remote operations
- **Must** provide clear guidance when preconditions fail

**Shell Script Pattern:**
```bash
# Check SSH access before attempting clone
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "Error: GitHub SSH authentication failed"
    echo "Run: ssh-keygen && gh auth login"
    return 1
fi
```

---

## Security Practices

### Avoid dangerous language features
**Common Error:** Using `eval` for simple operations like path expansion, creating code injection vulnerabilities.

**Standards:**
- **Never** use `eval` unless absolutely necessary
- **Must** use language-native features for common operations
- **Must** sanitize all external input before use in commands
- **Must** quote all variables in shell scripts to prevent injection
- **Must** avoid dynamic code execution patterns

**Shell Script Pattern:**
```bash
# Bad - uses eval
eval echo "$some_path"

# Good - use parameter expansion
echo "${some_path/#\~/$HOME}"

# Better - use built-in variable
target_dir="${HOME}/code"
```

---

## Testing Requirements

### Test all code paths and failure scenarios
**Common Error:** Only testing the "happy path" without verifying error handling, edge cases, or failure modes.

**Standards:**
- **Must** test both success and failure scenarios
- **Must** test with missing dependencies
- **Must** test with invalid inputs
- **Must** test with existing state (e.g., files already present)
- **Must** test authentication failures
- **Must** document test scenarios in PR descriptions

### Mandatory Test Scenarios for Shell Scripts
Every shell script change **must** be tested with:
1. **Valid inputs** - expected success path
2. **Invalid inputs** - malformed or incorrect data
3. **Missing dependencies** - tools not installed
4. **Authentication failures** - invalid credentials or keys
5. **Existing state** - resources already present
6. **Network failures** - offline or unreachable services

### Mandatory Test Scenarios for Go Code
Every Go code change **must** include:
1. **Unit tests** - test functions in isolation
2. **Error cases** - test all error return paths
3. **Edge cases** - boundary conditions and limits
4. **Integration tests** - test component interactions (where applicable)

---

## Code Review Checklist

Before submitting code for review, **must** verify:

- [ ] No duplicate code blocks or copy-paste errors
- [ ] All external dependencies are checked before use
- [ ] Documentation accurately describes implementation
- [ ] Errors are never silently suppressed
- [ ] Preconditions are validated before operations
- [ ] No `eval` or other dangerous constructs
- [ ] All test scenarios have been executed
- [ ] All tests pass (`go test ./...` for Go code)
- [ ] Code builds successfully (`go build` for Go code)

---

## Enforcement

These standards are **mandatory**. Code reviews will reject changes that violate these standards. When in doubt, refer to this document and ask questions before implementing.

## References

- See `docs/WORKFLOWS.md` for workflow procedures
- See `CLAUDE.md` for agent-specific instructions
- See `docs/SPEC.md` for technical specifications
