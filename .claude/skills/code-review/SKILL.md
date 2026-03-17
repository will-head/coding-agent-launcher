---
name: code-review
description: Review current code changes for quality, reuse, and efficiency against CODING_STANDARDS.md, then update CODING_STANDARDS.md with any new patterns found. Use at code review checkpoints in the Interactive workflow (steps 4 and 7) and Bug Cleanup workflow (steps 5 and 8). Invoke whenever a workflow step requires a structured code review before committing.
context: fork
---

# Code Review

Review current code changes for quality, reuse, and efficiency. Always verify against `CODING_STANDARDS.md`. Document findings with file and line references, severity ratings (critical / major / minor), and specific recommendations.

## Change Scope

Identify current changes — `git diff` shows unstaged, `git diff --cached` shows staged:

```bash
git diff && git diff --cached
```

## Step 1: Run simplify

Invoke the `simplify` skill.

If `simplify` is unavailable, skip to Step 2 and apply the CODING_STANDARDS.md checklist manually.

## Step 2: Apply CODING_STANDARDS.md Checklist

Read `CODING_STANDARDS.md` and verify every item in the Code Review Checklist section against the current changes. Also check:

- **Code quality** — Readability, maintainability, modularity
- **Test coverage** — All scenarios tested (valid inputs, invalid inputs, errors, edge cases)
- **Security** — Input validation, no injection risks, proper error handling
- **Performance** — Efficient algorithms, no unnecessary operations
- **Go conventions** — Idiomatic Go, stdlib over custom implementations, GoDoc on all exported identifiers; run `staticcheck ./...` and `go test ./...`
- **Shell script best practices** — Proper quoting, dependency checks, no `eval`, errors never suppressed

## Step 3: Check for New Patterns

After completing the review, consider whether any issues found represent a recurring pattern not yet captured in `CODING_STANDARDS.md`. If so:

1. Add a new section to `CODING_STANDARDS.md` following the existing format:
   - Problem description
   - Standards (bulleted Must/Never/Should rules)
   - Code examples (Bad / Good / Better where applicable)
2. Add the pattern to the Code Review Checklist in `CODING_STANDARDS.md`
3. Note any additions in the review findings presented to the user

## Step 4: Present Findings

Present a structured report:

```
## Code Review Findings

### Issues
- [file:line] [critical/major/minor] — [description] — [recommendation]

_If no issues: "No issues found."_

### CODING_STANDARDS.md Updates
- [Added/None] — [pattern name if added]

### Summary
[Overall assessment and readiness for next step]
```
