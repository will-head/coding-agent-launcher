---
name: coding-standards
description: Manages language-specific coding standards in CODING-STANDARDS/ and tracks recurring review-changes findings. Invoke this skill whenever writing or modifying code (Go, Shell, or any tracked language) to load relevant best practices as mandatory constraints. Also invoked by review-changes to load standards context and record observed issues to PATTERNS files. Run explicitly to promote recurring patterns (3+ occurrences) to permanent standards, audit file sizes and token load, or migrate an existing CODING_STANDARDS.md into the new structure. Use this skill any time code is being written, reviewed, or standards are being discussed — even if the user doesn't mention "standards" explicitly.
---

# Coding Standards

Manages a `CODING-STANDARDS/` directory in the project root containing per-language best practices, derived from repeated review-changes findings.

## Directory Structure

```
CODING-STANDARDS/
├── CODING-STANDARDS.md                  # Shared standards + index of language files
├── CODING-STANDARDS-GO.md               # Go-specific standards (created on demand)
├── CODING-STANDARDS-SH.md               # Shell-specific standards (created on demand)
├── CODING-STANDARDS-GO-PATTERNS.md      # Pattern tracking for Go (created on demand)
└── CODING-STANDARDS-SH-PATTERNS.md      # Pattern tracking for Shell (created on demand)
```

**Naming rules:** UPPERCASE, hyphens only. Language codes: `GO`, `SH`, `TS`, `PY` — add as needed.

---

## Modes

### 1. Load Mode — when writing or modifying code

Before writing or modifying code, load the relevant standards so they inform every decision:

1. Identify the language(s) being worked on
2. Read `CODING-STANDARDS/CODING-STANDARDS.md` (shared rules + index)
3. Read `CODING-STANDARDS/CODING-STANDARDS-[LANG].md` if it exists
4. Treat loaded rules as mandatory constraints throughout the work — not suggestions

If no language-specific file exists yet, rely on shared standards and note the gap.

### 2. Code-Review Mode — when reviewing code

1. Load standards as above (shared + language-specific)
2. Use loaded standards as the review baseline — flag anything that violates them
3. After completing the review, for each issue found:
   - Read `CODING-STANDARDS-[LANG]-PATTERNS.md` (create it if it doesn't exist)
   - Check whether a semantically similar pattern already exists — "avoid eval" and "don't use eval in scripts" are the same pattern; "avoid eval" and "sanitise before eval" are not
   - If match found: increment its count and add a new example
   - If no match: add a new entry (count starts at 1)
4. After updating patterns, check if any entry has count ≥ 3 — if so, flag for promotion

#### Identifying Good Patterns

Extract the underlying pattern from the specific finding — not the instance:

- **Too specific:** "Line 182 in vm-auth.sh doesn't check for jq"
- **Good pattern:** "Scripts use external tools without checking if they're installed"

Ask:
- Could this happen elsewhere in the codebase?
- Is this a symptom of a larger anti-pattern?
- Does this apply to one language or all code types?

### 3. Promote Mode — explicit review of patterns

Run when explicitly invoked to review patterns, or when review-changes flags a promotion candidate:

1. Read all `CODING-STANDARDS-[LANG]-PATTERNS.md` files
2. For each pattern with count ≥ 3 not yet in `CODING-STANDARDS-[LANG].md`:
   - Draft a standards entry and add it to the language file (create the file if needed)
   - Update the pattern's status to `[PROMOTED]` — keep it for historical reference
3. Deduplicate any semantically similar entries across the standards files
4. Run a file audit (see below)
5. Update the index table in `CODING-STANDARDS.md`

### 4. Migrate Mode — first-time setup

If `CODING-STANDARDS/` does not exist but `CODING_STANDARDS.md` (or `CODING-STANDARDS.md`) exists in the project root:

1. Create `CODING-STANDARDS/` directory
2. Read the existing file and identify shared vs language-specific content
3. Write `CODING-STANDARDS/CODING-STANDARDS.md` with shared content + index table
4. Write language-specific files for any language-specific content found
5. Delete the original file once migration is confirmed complete

---

## File Formats

### PATTERNS file entry

```markdown
## [pattern-slug]

**Count:** N
**Status:** active | promoted
**Description:** One-sentence description of the issue.
**Why it matters:** Brief explanation of risk or consequence.

**Examples:**
- YYYY-MM-DD: `file:line` — what happened

**Related:** [other-slug]
```

### Standards file entry (promoted rule)

```markdown
## [Rule name]

**Rule:** One-sentence imperative statement.
**Why:** Brief rationale — what goes wrong without it.

**Wrong:**
```lang
# bad example
```

**Correct:**
```lang
# good example
```
```

### CODING-STANDARDS.md index table

```markdown
## Language Index

| Language | Standards | Patterns |
|----------|-----------|----------|
| Go | [CODING-STANDARDS-GO.md](CODING-STANDARDS-GO.md) | [CODING-STANDARDS-GO-PATTERNS.md](CODING-STANDARDS-GO-PATTERNS.md) |
| Shell | standards pending | [CODING-STANDARDS-SH-PATTERNS.md](CODING-STANDARDS-SH-PATTERNS.md) |
```

When a language has patterns tracked but no promoted rules yet, mark Standards as "standards pending".

---

## File Audit

Run after Promote Mode, or when any file is approaching 300 lines. Target: shared file + one language file + its patterns file should stay under ~600 lines combined for efficient context loading.

1. Check line counts of all files in `CODING-STANDARDS/`
2. For files > 300 lines: identify sections to summarise or split; propose to user before acting
3. For PATTERNS files: if a `[PROMOTED]` entry is older than 30 days and its rule is confirmed in the standards file, it can be archived or removed to keep the file lean
4. Report total estimated token load for a typical review session (shared + one language file + patterns)

---

## Creating New Language Files

When a pattern is first observed for a new language:
- Create `CODING-STANDARDS-[LANG]-PATTERNS.md` with the first entry
- Do NOT create `CODING-STANDARDS-[LANG].md` yet — wait until the promotion threshold is reached
- Add a "standards pending" row to the index in `CODING-STANDARDS.md`
