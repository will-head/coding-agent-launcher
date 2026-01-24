# Refine Workflow (6-Step)

> Refine TODOs in PLAN.md to ensure they are implementation-ready with user approvals

**Use When:** Clarifying and detailing TODOs in PLAN.md before implementation begins

**Key Principles:**
- **Approval required** - user must approve changes before committing to main
- **Target main branch** - updates PLAN.md and STATUS.md directly on main
- **Comprehensive requirements** - gather all details needed for implementation
- **Track refinement** - both prefix TODO in PLAN.md and add to STATUS.md

---

## Overview

The Refine workflow ensures TODOs in PLAN.md are implementation-ready by gathering complete requirements through clarifying questions. Once refined, TODOs are prefixed with "REFINED" in PLAN.md and tracked in STATUS.md's "Refined" section.

**Target:** main branch (direct updates)
**Approvals:** Required (user reviews changes before commit)
**Steps:** 6 (thorough refinement with tracking)

---

## Session Start Procedure

At the start of each new session using this workflow:

1. **Read this workflow file** - Read `docs/WORKFLOW-REFINE.md` in full
2. **Reiterate to user** - Summarize the workflow in your own words:
   - Explain this is the Refine workflow (6-step for refining PLAN.md TODOs)
   - List the key principles (approval required, main branch, comprehensive requirements, track refinement)
   - Outline the 6 steps (Read PLAN.md → Ask Questions → Update PLAN.md → Update STATUS.md → Ask Approval → Commit)
   - Explain the REFINED prefix and STATUS.md tracking
3. **Confirm understanding** - Acknowledge understanding of the workflow before proceeding
4. **Proceed with standard session start** - Continue with git status, PLAN.md reading, etc.

This ensures both agent and user have shared understanding of the workflow being followed.

---

## When to Use

Use Refine workflow when:
- A TODO in PLAN.md lacks sufficient detail for implementation
- Requirements are unclear or ambiguous
- Multiple implementation approaches are possible
- User input is needed to define acceptance criteria
- Technical decisions require user preferences

**Do NOT use for:**
- Simple, self-explanatory TODOs
- TODOs with complete requirements already documented
- Implementation work (use Interactive or Create PR workflows instead)

---

## Step-by-Step Process

### Step 1: Read PLAN.md

Read `docs/PLAN.md` to identify the TODO needing refining.

**Identify:**
- Which TODO the user wants refined
- Current TODO description and context
- Related TODOs or dependencies
- Phase and section location

If user hasn't specified which TODO, present a list of candidates that would benefit from refining.

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

### Step 3: Update PLAN.md

Update the TODO in `docs/PLAN.md`:

1. **Prefix with "REFINED"** at the start of the TODO line
2. **Expand description** with gathered requirements
3. **Add sub-items** with implementation details if helpful
4. **Include acceptance criteria** clearly stated
5. **Note any constraints** or special considerations

**Example transformation:**

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
| Add git repo sync on init | PLAN.md Phase 0.10 | Prompt for repos during --init and clone using gh CLI | 2026-01-23 | Requires gh auth |
```

**Include:**
- Concise TODO description
- Location in PLAN.md (phase/section)
- Brief summary of refinement
- Date refined
- Any important notes or constraints

### Step 5: Ask Approval

Present changes to user for review:

1. **Show PLAN.md changes** - highlight refined TODO with full details
2. **Show STATUS.md entry** - display new tracking entry
3. **Summarize refining** - explain what was clarified
4. **List affected files** - PLAN.md and STATUS.md

**Wait for explicit user approval** before committing.

If user requests changes, return to Step 2 or Step 3 as needed.

### Step 6: Commit and Push

After user approval, commit changes to main:

```bash
git add docs/PLAN.md STATUS.md
git commit -m "$(cat <<'EOF'
Refine TODO: [brief description]

Updated PLAN.md with refined requirements for [TODO].
Added refine tracking entry to STATUS.md.

Refine details:
- [Key requirement 1]
- [Key requirement 2]
- [Key requirement 3]

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push
```

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
- [ ] TODO prefixed with "REFINED" in PLAN.md
- [ ] Entry added to STATUS.md "Refined" section
- [ ] Related TODOs considered for dependencies

---

## Important Notes

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
- Links refined items to PLAN.md location

---

## Examples

### Example 1: Vague TODO

**Original (PLAN.md):**
```markdown
- [ ] Improve error messages
```

**After Refining (PLAN.md):**
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
| Improve error messages | PLAN.md Phase 1.2 | Standardize error format with context and suggestions | 2026-01-23 | Applies to cal-bootstrap script |
```

### Example 2: Implementation Choice

**Original (PLAN.md):**
```markdown
- [ ] Add configuration file support
```

**After Refining (PLAN.md):**
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
| Add config file support | PLAN.md Phase 1.2 | YAML config at ~/.config/cal/config.yaml with validation | 2026-01-23 | Pure bash parsing, no dependencies |
```

### Example 3: Feature with Dependencies

**Original (PLAN.md):**
```markdown
- [ ] Auto-sync repos on VM start
```

**After Refining (PLAN.md):**
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
| Auto-sync repos on VM start | PLAN.md Phase 0.10 | Fetch and optionally pull repo updates on --run | 2026-01-23 | Depends on git repo sync TODO |
```

---

## Related Documentation

- [WORKFLOWS.md](WORKFLOWS.md) - Index of all workflows
- [WORKFLOW-INTERACTIVE.md](WORKFLOW-INTERACTIVE.md) - For implementing refined TODOs
- [WORKFLOW-CREATE-PR.md](WORKFLOW-CREATE-PR.md) - For implementing via PR
- [PLAN.md](PLAN.md) - Source of TODOs to refine
- [STATUS.md](../STATUS.md) - Tracks refined TODOs
