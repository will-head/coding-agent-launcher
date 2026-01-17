# Agent Context

Project context for AI coding agents (Claude Code, Cursor, opencode).

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

Source of truth: [docs/adr/ADR-001-cal-isolation.md](docs/adr/ADR-001-cal-isolation.md)

Quick reference (extracted from ADR):
- [Architecture](docs/architecture.md) - system design, UX, config
- [CLI](docs/cli.md) - command reference
- [Bootstrap](docs/bootstrap.md) - manual Tart setup
- [Plugins](docs/plugins.md) - environment system
- [Roadmap](docs/roadmap.md) - implementation phases

---

# Git Workflow

🚨 **MANDATORY WORKFLOW - NO EXCEPTIONS** 🚨

⚠️ **CRITICAL:** This workflow MUST be followed for EVERY commit. Violations waste time and create technical debt.

## Exception: Documentation-Only Changes

If changes are **ONLY** to documentation files (.md files, code comments), you may use the simplified workflow:

**Documentation-Only Workflow:**
1. Update documentation files
2. Commit with descriptive message
3. Push to remote

**Skip these steps for documentation-only changes:**
- ❌ Step 2: Run All Tests
- ❌ Step 3: Build the Project  
- ❌ Step 4: Code Review
- ❌ Step 5: Ask for User Approval
- ❌ Step 6: Present Code Review

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

### Step 5: Ask for User Approval
- **MANDATORY:** Ask user: *"Would you like to see the code review before committing?"*
- 🛑 **STOP HERE** 🛑
- **DO NOT ASSUME** user wants to proceed
- **WAIT** for user response

### Step 6: Present Code Review
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
- ☐ `docs/adr/ADR-001-cal-isolation.md` - Source of truth
- ☐ `docs/architecture.md` - System design
- ☐ `docs/cli.md` - Command reference
- ☐ `docs/bootstrap.md` - Setup instructions
- ☐ `docs/plugins.md` - Environment system
- ☐ `docs/roadmap.md` - Implementation phases
- ☐ Inline code comments and doc comments
- ☐ Script comments in `scripts/`

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

- ❌ Commit without user approval of code review
- ❌ Commit without updating documentation
- ❌ Commit with failing tests
- ❌ Commit with build failures
- ❌ Skip asking user if they want to see the review
- ❌ Assume user approval without explicit confirmation
- ❌ Skip any step "to save time"
- ❌ Proceed past a STOP checkpoint without user input
- ❌ Commit before documentation is updated
- ❌ Push before commit message is reviewed

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
- ☐ Code review conducted
- ☐ Asked user: "Would you like to see the code review?"
- ☐ User explicitly approved proceeding
- ☐ ALL documentation updated
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
