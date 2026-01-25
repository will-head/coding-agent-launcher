# Opencode VM Issues - Quick Reference

> **Status:** ✅ Resolved - opencode works correctly in VM  
> **Date:** 2026-01-25  
> **Full Investigation:** [opencode-vm-investigation.md](opencode-vm-investigation.md)

## TL;DR

**`opencode run` works perfectly in CAL VM** when TERM is naturally inherited from the environment. It only hangs when TERM is explicitly set in the command environment.

## Key Finding

✅ **opencode works in VM** - No setup changes needed

❌ **Bug identified** - `opencode run` hangs when TERM is explicitly set

## Working vs Failing

### ✅ Works (Default Usage)
```bash
# TERM naturally inherited from tmux/shell
opencode run "test message"
# ✅ Completes successfully (~11 seconds)
```

### ❌ Hangs (Explicit TERM)
```bash
# TERM explicitly set in command
TERM=xterm-256color opencode run "test message"
# ❌ Hangs indefinitely
```

## What This Means

1. **No VM changes needed** - opencode works correctly with current setup
2. **Avoid explicit TERM** - Don't set TERM in scripts/wrappers that call opencode
3. **Bug to report** - This is an opencode bug, not a VM issue

## Test Results

| Test | Result | Notes |
|------|--------|-------|
| `opencode run` (default) | ✅ PASS | Works in 11s |
| `opencode serve` | ✅ PASS | Works correctly |
| Network connectivity | ✅ PASS | DNS and API working |
| Storage/locks | ✅ PASS | No issues |
| `opencode run` (TERM set) | ❌ FAIL | Hangs |

## Recommendations

1. **Use opencode normally** - It works fine in VM
2. **Don't set TERM explicitly** - Let it inherit from environment
3. **Report bug upstream** - Open GitHub issue with opencode maintainers

## Related Documentation

- [Full Investigation](opencode-vm-investigation.md) - Detailed analysis
- [Test Script](../../scripts/test-opencode-vm.sh) - Automated testing
- [Z.AI Investigation](zai-glm-concurrency-error-investigation.md) - Previous API issues

---

**Last Updated:** 2026-01-25  
**Status:** ✅ Resolved - opencode works in VM
