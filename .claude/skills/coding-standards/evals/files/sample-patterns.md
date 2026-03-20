# CODING-STANDARDS-GO-PATTERNS

Pattern tracking for Go code. Written by code-review; promoted by coding-standards skill at count ≥ 3.

---

## error-messages-without-context

**Count:** 3
**Status:** active
**Description:** Error returns use bare `err` or generic strings without context about where/why the error occurred.
**Why it matters:** Bare errors propagate up the call stack without context, making debugging painful — you see "file not found" but not which file or what operation failed.

**Examples:**
- 2026-02-10: `internal/isolation/tart.go:88` — `return "", err` after exec.Command failure, no context
- 2026-02-18: `internal/github/client.go:45` — `return nil, err` after HTTP call, no URL or status in message
- 2026-03-05: `internal/env/loader.go:22` — `return err` after os.ReadFile, no path in message

**Related:** proactive-validation

---

## fmt-println-in-library-code

**Count:** 1
**Status:** active
**Description:** Library packages use fmt.Println/Printf for output instead of returning errors or using a logger.
**Why it matters:** Library code that prints directly to stdout is untestable and breaks callers that need to control output.

**Examples:**
- 2026-03-12: `internal/isolation/cache.go:34` — `fmt.Println("cache cleared")` in non-main package

**Related:** error-messages-without-context
