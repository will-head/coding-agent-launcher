# Agent Context

Project context for AI coding agents (Claude Code, Cursor, opencode).

---

## Session Startup Procedure

🚨 **MANDATORY - EVERY NEW SESSION** 🚨

At the start of EVERY new session, the agent MUST:

1. **Read and Understand Workflow**
   - Read this entire CLAUDE.md file
   - Understand the mandatory Git workflow
   - Internalize all absolute prohibitions

2. **Present Workflow Summary**
   - Present the 8-step workflow to user
   - Highlight documentation-only exception
   - Confirm understanding of checkpoints

3. **Check Project Status**
   - Run `git status` and `git fetch` to verify repo state
   - **Check PLAN.md for unchecked TODOs** (authoritative source)
   - Review `docs/roadmap.md` for current phase (should match PLAN.md)

4. **Read SPEC and PLAN for Next Steps**
   - Read `docs/SPEC.md` for technical requirements
   - Read `docs/PLAN.md` for implementation details
   - Identify current phase and pending tasks
   - Use PLAN.md as the guide for what to implement next

5. **Report Status to User**
   - Git status (branch, uncommitted changes, sync status)
   - TODO/task status
   - Current roadmap phase and completion
   - Next recommended tasks from PLAN.md

6. **Suggest Next Stages**
   - Based on PLAN.md, suggest logical next steps
   - Offer specific options for what to work on
   - Wait for user direction

**This procedure ensures:**
- Agent understands project workflow
- User has visibility into project state
- Session starts with clear context and direction
- No workflow violations from lack of awareness

---

## Project

CAL (Coding Agent Loader) - VM-based sandbox for running AI coding agents safely in Tart macOS VMs.

## Stack

Go + Charm (bubbletea/lipgloss/bubbles) + Cobra + Viper

## Structure

```
cmd/cal/main.go           # Entry point
internal/
  tui/                    # bubbletea UI
  isolation/              # VM management (tart, snapshots, ssh)
  agent/                  # Agent integrations (claude, cursor, opencode)
  env/                    # Environment plugins (ios, android, node, etc.)
  github/                 # gh CLI wrapper
  config/                 # Configuration
```

## Commands

```bash
# Build (once implemented)
go build -o cal ./cmd/cal

# Test
go test ./...

# Lint
golangci-lint run
```

## Docs

**Source of truth (NEVER MODIFY):**
- [ADR-001](docs/adr/ADR-001-cal-isolation.md) - Complete design decisions

**Planning documents (read these for next steps):**
- [SPEC](docs/SPEC.md) - Technical specification
- [PLAN](docs/PLAN.md) - Implementation plan with tasks **(SINGLE SOURCE OF TRUTH FOR TODOS)**

**Quick reference (extracted from ADR):**
- [Architecture](docs/architecture.md) - system design, UX, config
- [CLI](docs/cli.md) - command reference
- [Bootstrap](docs/bootstrap.md) - manual Tart setup
- [Plugins](docs/plugins.md) - environment system
- [Roadmap](docs/roadmap.md) - implementation phases (derived from PLAN.md)

---

# TODO Tracking Policy

🚨 **CRITICAL: PLAN.md IS THE SINGLE SOURCE OF TRUTH FOR ALL TODOS** 🚨

This policy prevents confusion about project status and ensures no work items are lost.

## Rules

### 1. PLAN.md is Authoritative
- **ALL TODOs affecting phase completion MUST be in `docs/PLAN.md`**
- Phase status is determined ONLY by checking PLAN.md checkboxes
- A phase is NOT complete until ALL checkboxes in that phase are checked `[x]`
- If a checkbox is unchecked `[ ]`, the phase is NOT complete

### 2. TODOs in Code Comments
TODOs in code (e.g., `# TODO: ...` in scripts) are allowed but:
- They are **implementation notes only**
- They **DO NOT** replace PLAN.md entries
- When adding a TODO to code, you **MUST ALSO** add it to PLAN.md
- Format in code: `# TODO: Brief description (see PLAN.md section X.X)`

### 3. Code Review TODOs
When code review identifies improvements or issues deferred for later:
- **MUST** add them to PLAN.md under the appropriate phase/section
- **MUST** mark them as unchecked `[ ]`
- **MUST** update the phase status if this changes completion
- **MUST NOT** mark a phase complete if new TODOs were added

### 4. Roadmap.md is Derived
- `docs/roadmap.md` is a **summary view** of PLAN.md
- It should reflect PLAN.md status, not have independent checkboxes
- When updating PLAN.md, also update roadmap.md to match
- If they disagree, PLAN.md is correct

### 5. No Orphan Status Documents
- Do not create "completion summary" documents that duplicate PLAN.md
- Phase status lives in PLAN.md "Current Status" section
- Remove or clearly mark as "snapshot" any status summary documents

## Verification Before Commit

Before marking any phase complete or committing:
1. **Grep for TODOs:** `grep -r "TODO" scripts/ --include="*.sh"`
2. **Check PLAN.md:** Every TODO in code has a corresponding unchecked item
3. **Verify status:** Phase marked complete only if ALL items are `[x]`

## Example

**Wrong:**
```bash
# In script header
# TODO: Add --yes flag
# TODO: Run shellcheck
```
```markdown
# In PLAN.md
**Phase 0:** Complete ✅   # WRONG - TODOs exist!
```

**Correct:**
```bash
# In script header  
# TODO: Add --yes flag (see PLAN.md section 0.6)
# TODO: Run shellcheck (see PLAN.md section 0.6)
```
```markdown
# In PLAN.md
**Phase 0:** Mostly complete (2 TODOs remaining)
- [x] Create script
- [ ] Add --yes flag
- [ ] Run shellcheck
```

---

# Git Workflow

🚨 **MANDATORY WORKFLOW - NO EXCEPTIONS** 🚨

⚠️ **CRITICAL:** This workflow MUST be followed for EVERY commit. Violations waste time and create technical debt.

## Exception: Documentation-Only Changes

If changes are **ONLY** to documentation files (.md files, code comments), you may use the simplified workflow:

**Documentation-Only Workflow:**
1. Update documentation files
2. **ASK USER FOR APPROVAL** - Present changes and ask if they want to commit
3. Commit with descriptive message (only after user approval)
4. Push to remote

**Skip these steps for documentation-only changes:**
- ❌ Step 2: Run All Tests
- ❌ Step 3: Build the Project
- ❌ Step 4: Conduct Code Review
- ❌ Step 6: Present Code Review (unless user requests it)

**Still REQUIRED for documentation-only changes:**
- ✅ Step 5: Ask for User Approval - **ALWAYS REQUIRED**
- ✅ Step 7: Update ALL Documentation
- ✅ Step 8: Commit and Push (only after approval)

**Qualifying documentation files:**
- `*.md` files (README.md, AGENTS.md/CLAUDE.md, docs/*)
- Inline code comments and doc comments

**Important:** If ANY code or script logic changes (even one line in Go code or shell scripts), use the full 8-step workflow.

---

## The Mandatory 8-Step Workflow

Each step is a **BLOCKING CHECKPOINT**. You MUST complete each step fully before proceeding to the next.

### Step 1: Implement Changes
- Write code following best practices
- Make minimum changes to achieve the goal
- Follow Go conventions and project structure
- Follow shell script best practices for `scripts/`

### Step 2: Run All Tests
- **Execute:** `go test ./...`
- **VERIFY:** All tests pass
- **IF TESTS FAIL:** Fix issues, do NOT proceed
- **FOR SCRIPTS:** Provide manual test instructions with clean, copy-pasteable commands (no line numbers)
- 🛑 **STOP HERE if tests fail**

### Step 3: Build the Project
- **Execute:** `go build -o cal ./cmd/cal`
- **VERIFY:** Build succeeds with no errors
- **IF BUILD FAILS:** Fix issues, do NOT proceed
- 🛑 **STOP HERE if build fails**

### Step 4: Conduct Code Review
- **Review:** code quality, test coverage, security, performance, conventions
- **Analyze:** ALL changed files (Go code, shell scripts, configs)
- **Prepare:** findings in structured format
- **Identify:** potential issues or improvements
- **Check TODOs:** Verify any new TODOs in code are also in PLAN.md
- **Verify status:** If TODOs added, phase cannot be marked complete

### Step 5: Present Code Review (ALWAYS)
- **ALWAYS present the code review** - no exceptions, do not ask first
- **Present:** findings clearly and completely
- **Include:** all issues, improvements, and assessment
- 🛑 **STOP HERE** 🛑
- **WAIT** for explicit user approval
- **DO NOT PROCEED** without clear approval (e.g., "approved", "looks good", "proceed")

### Step 7: Update ALL Documentation
**MANDATORY - BEFORE COMMITTING**

Update these files if affected by changes:
- ☐ `README.md` - Project overview
- ☐ `AGENTS.md` - Agent context and guidelines (CLAUDE.md symlinks here)
- ☐ `docs/SPEC.md` - Technical specification
- ☐ `docs/PLAN.md` - Implementation plan **(MUST include any new TODOs)**
- ☐ `docs/architecture.md` - System design
- ☐ `docs/cli.md` - Command reference
- ☐ `docs/bootstrap.md` - Setup instructions
- ☐ `docs/plugins.md` - Environment system
- ☐ `docs/roadmap.md` - Implementation phases **(MUST match PLAN.md status)**
- ☐ Inline code comments and doc comments
- ☐ Script comments in `scripts/`

**⚠️ NEVER update `docs/adr/*` - ADRs are immutable (see ADR Protection Rules)**

**TODO Synchronization Checklist:**
- ☐ Grep for TODOs in changed files: `grep -r "TODO" <files>`
- ☐ Every code TODO has corresponding PLAN.md entry
- ☐ PLAN.md phase status reflects actual completion (no unchecked items = complete)
- ☐ roadmap.md status matches PLAN.md

**VERIFY:** All documentation accurately reflects the changes

### Step 8: Commit and Push
**Create meaningful commit message following format:**
```
Brief summary (imperative mood)

Detailed description of what changed and why.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Execute:** `git add <files> && git commit -m "message" && git push`

**ONLY AFTER:** All above steps are complete

---

## Absolute Prohibitions

**NEVER, UNDER ANY CIRCUMSTANCES:**

- ❌ **Install software on the host machine without explicit user approval** - Check first, then ask permission
- ❌ **Provide test instructions with line numbers or decoration** - Always use clean, copy-pasteable commands
- ❌ **Commit without asking user first** - NO EXCEPTIONS, not even for documentation
- ❌ Commit without user approval of code review (for code/script changes)
- ❌ Commit without updating documentation
- ❌ Commit with failing tests
- ❌ Commit with build failures
- ❌ Skip presenting the code review (always show it)
- ❌ Assume user approval without explicit confirmation
- ❌ Skip any step "to save time"
- ❌ Proceed past a STOP checkpoint without user input
- ❌ Commit before documentation is updated
- ❌ Push before commit message is reviewed

---

## ADR Protection Rules

🚨 **ADRs ARE IMMUTABLE - NEVER MODIFY** 🚨

**Architecture Decision Records (ADRs) in `docs/adr/` are the source of truth for this project.**

**ABSOLUTE RULES:**

- ❌ **NEVER edit, modify, or delete any ADR file** - even if asked to "refactor documentation"
- ❌ **NEVER change content in ADRs** - not even typos, formatting, or "improvements"
- ❌ **NEVER move or rename ADR files**
- ❌ **NEVER add new content to existing ADRs**

**When refactoring documentation:**
- Update SPEC.md, PLAN.md, and other docs freely
- Extract information FROM ADRs into other docs
- Reference ADRs, don't modify them
- ADRs capture decisions at a point in time - they are historical records

**If ADR content seems wrong or outdated:**
- Create a NEW ADR (e.g., ADR-002) that supersedes the old one
- The new ADR should reference the old one and explain what changed
- NEVER modify the original ADR

**Why this matters:**
- ADRs document WHY decisions were made
- They provide historical context for future developers
- Modifying them destroys the decision history
- Other documents (SPEC, PLAN) can evolve; ADRs are frozen records

---

## Why This Workflow Exists

Each step prevents real problems:

- **Tests** - Catch regressions and bugs
- **Build** - Ensure compilation succeeds
- **Code review** - Catch issues before they enter codebase
- **User approval** - Respect user's oversight and control
- **Documentation** - Prevent confusion and technical debt
- **Proper commits** - Maintain clean git history

**Violations create:**
- Wasted time fixing and recommitting
- Technical debt from outdated documentation
- Bugs that slip past inadequate testing
- Loss of user trust and control

---

## Workflow Checklist

Before every git commit, verify:

- ☐ All tests pass (`go test ./...`)
- ☐ Build succeeds with no errors (`go build -o cal ./cmd/cal`)
- ☐ Code review conducted and presented to user (always show it)
- ☐ User explicitly approved proceeding
- ☐ ALL documentation updated
- ☐ **TODOs synchronized:** Code TODOs are in PLAN.md, phase status is accurate
- ☐ Commit message is clear and complete

**If ANY checkbox is unchecked: DO NOT COMMIT**

---

## Code Review Requirements

**Mandatory review areas:**
- Code quality and maintainability
- Test coverage
- Security vulnerabilities (especially in shell scripts)
- Performance implications
- Adherence to Go conventions
- Shell script best practices (quoting, error handling, etc.)
- Project structure compliance
- Error handling
- Concurrency safety (if applicable)

**Review format:**
- Clear, structured presentation
- Specific findings with file/line references
- Severity ratings for issues
- Recommendations for improvements

**Review approval:**
- Must receive explicit user approval
- "Looks good", "approved", "proceed" = approved
- No response, ambiguous response = NOT approved
- WAIT for clear approval before proceeding
