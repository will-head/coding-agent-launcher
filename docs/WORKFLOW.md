# Git Workflow Reference

> Detailed procedures for commits, code review, and documentation updates.
> Read this when performing git operations.

## Session Startup

On new session:
1. Read AGENTS.md (core rules)
2. Ask user approval, then run `git status` and `git fetch`
3. Read `docs/PLAN.md` for current TODOs and phase status
4. Report status and suggest next steps from PLAN.md

---

## Git Commit Workflow

### Documentation-Only Changes

For changes **only** to `.md` files or code comments:
1. Make changes
2. Ask user approval to commit
3. Commit and push

Skip tests, build, and code review for docs-only changes.

### Code/Script Changes (Full 8-Step Workflow)

**Each step is a blocking checkpoint.**

#### Step 1: Implement
- Use TDD: write failing test, implement, verify pass
- Follow Go conventions and shell script best practices
- Make minimum changes needed

#### Step 2: Test
- Ask user approval before running
- Execute: `go test ./...`
- Stop if tests fail

#### Step 3: Build
- Ask user approval before running
- Execute: `go build -o cal ./cmd/cal`
- Stop if build fails

#### Step 4: Code Review
Review for:
- Code quality, test coverage, security, performance
- Go conventions, shell script best practices
- New TODOs (must add to PLAN.md)

#### Step 5: Present Review
- Always present review findings
- **STOP and wait for explicit user approval**
- "approved", "looks good", "proceed" = approved

#### Step 6: Update Documentation
Update if affected:
- `README.md`, `AGENTS.md`, `docs/SPEC.md`, `docs/PLAN.md`
- `docs/architecture.md`, `docs/cli.md`, `docs/bootstrap.md`
- `docs/plugins.md`, `docs/roadmap.md`
- Inline comments in changed files

**Never modify `docs/adr/*`** - ADRs are immutable.

Sync TODOs:
- Code TODOs must have PLAN.md entries
- Phase status must reflect actual completion

#### Step 7: Commit and Push
- Ask user approval
- Use imperative mood, add Co-Authored-By line
- Execute only after all steps complete

---

## TODO Tracking

**PLAN.md is the single source of truth for all TODOs.**

Rules:
- All phase-affecting TODOs must be in PLAN.md
- Phase complete only when ALL checkboxes are `[x]`
- Code TODOs are notes only, must also be in PLAN.md
- roadmap.md derives from PLAN.md (keep in sync)

Before commit:
```bash
grep -r "TODO" scripts/ --include="*.sh"
```
Verify each TODO has a PLAN.md entry.

---

## Code Review Checklist

**Review areas:**
- Code quality and maintainability
- Test coverage
- Security (especially shell scripts)
- Performance implications
- Go conventions
- Shell script best practices (quoting, error handling)
- Error handling
- Concurrency safety

**Format:**
- Structured findings with file:line references
- Severity ratings
- Recommendations

---

## Commit Message Format

```
Brief summary (imperative mood)

Detailed description of what changed and why.

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

---

## Pre-Commit Checklist

Before every commit:
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Code review presented and approved (for code changes)
- [ ] Documentation updated
- [ ] TODOs synced to PLAN.md
- [ ] User approved commit
