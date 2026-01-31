# Refine Workflow (6-Step)

> Refine TODOs in the active phase TODO file to ensure they are implementation-ready with user approvals

**Use When:** Clarifying and detailing TODOs in the current phase before implementation begins

**Key Principles:**
- **Defaults to active phase** - refine TODOs in current active phase unless user specifies different phase
- **Approval required** - user must approve changes before committing to main
- **Target main branch** - updates phase TODO file and STATUS.md directly on main
- **Comprehensive requirements** - gather all details needed for implementation
- **Track refinement** - both prefix TODO in phase file and add to STATUS.md

---

## Overview

The Refine workflow ensures TODOs in phase TODO files are implementation-ready by gathering complete requirements through clarifying questions. Once refined, TODOs are prefixed with "REFINED" in the phase TODO file and tracked in STATUS.md's "Refined" section.

**Default Behavior:** Refines TODOs in the **current active phase** unless user specifies a different phase.

**Target:** main branch (direct updates)
**Approvals:** Required (user reviews changes before commit)
**Steps:** 6 (thorough refinement with tracking)

---

## Session Start Procedure

Follow [Session Start Procedure](WORKFLOWS.md#session-start-procedure) from Shared Conventions, highlighting:
- This is the Refine workflow (6-step for refining phase TODO files)
- Key principles: defaults to active phase, approval required, main branch, comprehensive requirements, track refinement
- 6 steps: Read PLAN.md & Phase TODO → Ask Questions → Update Phase TODO → Update STATUS.md → Ask Approval → Commit
- Explain the REFINED prefix and STATUS.md tracking
- Defaults to active phase unless user specifies different phase

---

## When to Use

Use Refine workflow when:
- A TODO in a phase TODO file lacks sufficient detail for implementation
- Requirements are unclear or ambiguous
- Multiple implementation approaches are possible
- User input is needed to define acceptance criteria
- Technical decisions require user preferences

**Defaults to active phase** but user can specify any phase to refine.

**Do NOT use for:**
- Simple, self-explanatory TODOs
- TODOs with complete requirements already documented
- Implementation work (use Interactive or Create PR workflows instead)

---

## Step-by-Step Process

### Step 1: Read PLAN.md and Determine Target Phase TODO File

**First, read `PLAN.md`** to determine the current active phase:
- Check "Current Status" section to identify active phase (e.g., "Phase 0 (Bootstrap): Mostly Complete")
- Note the active phase TODO file (e.g., `docs/PLAN-PHASE-00-TODO.md`)
- Verify the phase status

**Determine target phase:**
- **Default:** Use the active phase unless user specifies otherwise
- **User-specified:** If user mentions a specific phase (e.g., "refine Phase 1 TODO"), use that phase instead
- Read the appropriate phase TODO file based on target phase

**Then, read the target phase TODO file** to identify the TODO needing refining:

**Identify:**
- Which TODO the user wants refined
- Current TODO description and context
- Related TODOs or dependencies within the same phase
- Section location within the phase file

If user hasn't specified which TODO, present candidates using [Numbered Choice Presentation](WORKFLOWS.md#numbered-choice-presentation) so the user can reply with just a number.

### Step 2: Ask Clarifying Questions

Ask comprehensive questions to gather all requirements. Use the `AskUserQuestion` tool to collect:

**Requirements:**
- What is the desired outcome?
- What are the acceptance criteria?
- Are there constraints or limitations?
- What edge cases need handling?

**Implementation Details:**
- What approach should be used?
- Are there preferred tools or libraries?
- Should existing patterns be followed?
- What testing is required?

**User Preferences:**
- UI/UX decisions
- Configuration options
- Error handling behavior
- Performance vs. simplicity trade-offs

**Continue asking until:**
- All ambiguity is resolved
- Implementation path is clear
- Acceptance criteria are defined
- User confirms completeness

### Step 3: Update Active Phase TODO File

Update the TODO in the active phase TODO file (e.g., `docs/PLAN-PHASE-00-TODO.md`):

1. **Prefix with "REFINED"** at the start of the TODO line
2. **Expand description** with gathered requirements
3. **Add sub-items** with implementation details if helpful
4. **Include acceptance criteria** clearly stated
5. **Note any constraints** or special considerations

**Example transformation (in `docs/PLAN-PHASE-00-TODO.md`):**

Before:
```markdown
- [ ] Add option to sync git repos on init
```

After:
```markdown
- [ ] **REFINED:** Add option to sync git repos on init
  - Prompt user during --init to enter repo names (format: owner/repo)
  - Clone using `gh repo clone` to ~/code/github.com/owner/repo
  - Support multiple repos (comma-separated input)
  - Skip if gh auth not configured (show warning)
  - Acceptance criteria: User can specify repos during init and they are cloned successfully
  - Constraints: Must handle gh auth failures gracefully
```

### Step 4: Update STATUS.md

Add entry to `STATUS.md` under the "Refined" section:

**Entry format:**
```markdown
| TODO | Location | Description | Refined Date | Notes |
|------|----------|-------------|--------------|-------|
| Add git repo sync on init | PLAN-PHASE-00-TODO.md § 0.10 | Prompt for repos during --init and clone using gh CLI | 2026-01-23 | Requires gh auth |
```

**Include:**
- Concise TODO description
- Location in phase TODO file (e.g., `PLAN-PHASE-00-TODO.md § 0.10` for section 0.10)
- Brief summary of refinement
- Date refined (use YYYY-MM-DD format)
- Any important notes or constraints

### Step 5: Ask Approval

Present changes to user for review:

1. **Show phase TODO file changes** - highlight refined TODO with full details (e.g., in `docs/PLAN-PHASE-00-TODO.md`)
2. **Show STATUS.md entry** - display new tracking entry
3. **Summarize refining** - explain what was clarified
4. **List affected files** - phase TODO file and STATUS.md

**Wait for explicit user approval** before committing.

If user requests changes, return to Step 2 or Step 3 as needed.

### Step 6: Commit and Push

After user approval, stage `docs/PLAN-PHASE-XX-TODO.md` and `STATUS.md`, then commit using [Commit Message Format](WORKFLOWS.md#commit-message-format). Include "Refine TODO:" prefix and list key requirements in the body. Push after commit.

**Done!** TODO is now implementation-ready.

---

## Refine Quality Checklist

Before presenting for approval:
- [ ] All ambiguity removed from TODO
- [ ] Implementation approach is clear
- [ ] Acceptance criteria are defined
- [ ] Edge cases are considered
- [ ] Constraints and limitations documented
- [ ] User preferences captured
- [ ] Correct phase TODO file updated (active phase or user-specified)
- [ ] TODO prefixed with "REFINED" in phase TODO file
- [ ] Entry added to STATUS.md "Refined" section with correct location format
- [ ] Related TODOs considered for dependencies (within same phase)

---

## Important Notes

### Phase Selection

**Default behavior:**
- Refine TODOs in the current active phase
- Most TODOs should be refined in the active phase

**User can specify different phase:**
- User may want to refine future phase TODOs for planning purposes
- If user specifies a phase (e.g., "refine the config file TODO in Phase 1"), use that phase
- Useful for planning ahead or clarifying dependencies

### What Makes a TODO "Refined"

A refined TODO should:
- Be actionable without further clarification
- Have clear acceptance criteria
- Include implementation guidance
- Note any constraints or gotchas
- Specify testing requirements
- Be ready for immediate implementation

### When to Stop Asking Questions

Stop asking questions when:
- User confirms "that's everything"
- Implementation path is unambiguous
- All decision points have answers
- Further details would be over-specification

### Multiple TODOs

If multiple related TODOs need refining:
- Refine one at a time
- Note dependencies between them
- Ensure consistency across refined TODOs
- Can run workflow multiple times

### STATUS.md Tracking

The "Refined" section in STATUS.md:
- Provides quick overview of refined TODOs
- Helps avoid duplicate refine work
- Tracks when refining occurred
- Links refined items to phase TODO file location (e.g., `PLAN-PHASE-00-TODO.md § 0.10`)

---

## Examples

### Example 1: Vague TODO

**Original (in `docs/PLAN-PHASE-01-TODO.md`):**
```markdown
- [ ] Improve error messages
```

**After Refining (in `docs/PLAN-PHASE-01-TODO.md`):**
```markdown
- [ ] **REFINED:** Improve error messages in cal-bootstrap script
  - Add context to all error messages (what failed, why, what to do)
  - Use consistent format: "ERROR: [what failed]. [why]. [action]"
  - Replace generic "Command failed" with specific operation names
  - Add suggestions for common failures (Tart not installed, VM not found, etc.)
  - Acceptance criteria: All error messages follow format and provide actionable guidance
  - Testing: Trigger each error condition and verify message quality
```

**STATUS.md entry:**
```markdown
| Improve error messages | PLAN-PHASE-01-TODO.md § 1.2 | Standardize error format with context and suggestions | 2026-01-23 | Applies to cal-bootstrap script |
```

### Example 2: Implementation Choice

**Original (in `docs/PLAN-PHASE-01-TODO.md`):**
```markdown
- [ ] Add configuration file support
```

**After Refining (in `docs/PLAN-PHASE-01-TODO.md`):**
```markdown
- [ ] **REFINED:** Add configuration file support for cal-bootstrap
  - File location: ~/.config/cal/config.yaml (XDG standard)
  - Format: YAML with sections for vm_defaults, proxy, snapshots
  - Supported options: default_cpu, default_memory, default_disk, proxy_mode, auto_snapshot
  - Fallback to built-in defaults if file missing (no error)
  - Validation: Check types and ranges, show warnings for invalid values
  - Acceptance criteria: Config file overrides defaults, validation works, errors are clear
  - Implementation: Use yq or pure bash parsing (decided: pure bash for zero dependencies)
```

**STATUS.md entry:**
```markdown
| Add config file support | PLAN-PHASE-01-TODO.md § 1.2 | YAML config at ~/.config/cal/config.yaml with validation | 2026-01-23 | Pure bash parsing, no dependencies |
```

### Example 3: Feature with Dependencies

**Original (in `docs/PLAN-PHASE-00-TODO.md`):**
```markdown
- [ ] Auto-sync repos on VM start
```

**After Refining (in `docs/PLAN-PHASE-00-TODO.md`):**
```markdown
- [ ] **REFINED:** Auto-sync repos on VM start in cal-bootstrap
  - Prerequisites: Requires "Add git repo sync on init" TODO to be completed first
  - Behavior: On `--run`, check ~/code for git repos, fetch updates, show status if behind
  - User prompt: If repos are behind, ask "Pull updates? [Y/n]"
  - Default action: Pull all repos if user confirms
  - Configurable: Add AUTO_SYNC=true/false to config file (default: true)
  - Skip conditions: No network, no repos found, AUTO_SYNC=false
  - Acceptance criteria: Updates are detected and user can choose to pull automatically
  - Dependencies: Blocks on git repo sync TODO (must have repos to sync)
```

**STATUS.md entry:**
```markdown
| Auto-sync repos on VM start | PLAN-PHASE-00-TODO.md § 0.10 | Fetch and optionally pull repo updates on --run | 2026-01-23 | Depends on git repo sync TODO |
```

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-INTERACTIVE.md](WORKFLOW-INTERACTIVE.md) - For implementing refined TODOs
- [WORKFLOW-CREATE-PR.md](WORKFLOW-CREATE-PR.md) - For implementing via PR
- [PLAN.md](../PLAN.md) - Phase overview and current status
- [PLAN-PHASE-XX-TODO.md](PLAN-PHASE-00-TODO.md) - Phase-specific TODO files (source of TODOs to refine)
- [STATUS.md](../STATUS.md) - Tracks refined TODOs
