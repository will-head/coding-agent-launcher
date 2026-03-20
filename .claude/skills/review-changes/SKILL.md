---
name: review-changes
description: Review current code changes for quality, reuse, and efficiency against coding standards, then record any new patterns found to CODING-STANDARDS-[LANG]-PATTERNS.md. Invoke at code review checkpoints before committing.
context: fork
---

# Review Changes

Review current code changes for quality, reuse, and efficiency. Always load relevant coding standards before reviewing. Document findings with file and line references, severity ratings (critical / major / minor), and specific recommendations.

## Change Scope

Identify current changes — `git diff` shows unstaged, `git diff --cached` shows staged:

```bash
git diff && git diff --cached
```

## Step 1: Load Standards

Invoke the `coding-standards` skill to load the relevant standards for the language(s) being reviewed. This loads `CODING-STANDARDS/CODING-STANDARDS.md` (shared) and any language-specific file (e.g. `CODING-STANDARDS-GO.md`). This re-loads standards to ensure freshness even if already loaded at session start.

## Step 2: Run simplify

Invoke the `simplify` skill.

If `simplify` is unavailable, skip to Step 3 and apply the checklist manually.

## Step 3: Apply Checklist

Using the loaded standards, verify every item in the Code Review Checklist against the current changes. Also check:

- **Code quality** — Readability, maintainability, modularity
- **Test coverage** — All scenarios tested (valid inputs, invalid inputs, errors, edge cases)
- **Security** — Input validation, no injection risks, proper error handling
- **Performance** — Efficient algorithms, no unnecessary operations
- **Language conventions** — Apply the loaded standards for the project's language(s)

## Step 4: Record Patterns

Invoke the `coding-standards` skill to record patterns from the findings above. It owns all pattern tracking and promotion.

## Step 5: Present Findings

Present a structured report:

```
## Code Review Findings

### Issues
- [file:line] [critical/major/minor] — [description] — [recommendation]

_If no issues: "No issues found."_

### Patterns Recorded
- [LANG] [pattern-slug] — count now N[, PROMOTED if count reached 3]

_If none: "No new patterns recorded."_

### Summary
[Overall assessment and readiness for next step]
```

## Step 6: Fix Issues

If critical or major issues were found, invoke the appropriate `coops-tdd` variant to fix them:

| Context | Skill |
|---------|-------|
| Human in the loop | `coops-tdd` |
| Autonomous agent | `coops-tdd-auto` |

If no critical or major issues were found, the review is complete — proceed to the next workflow step.
