# How to Update CODING_STANDARDS.md

This document provides instructions for successfully updating the project's coding standards based on code review findings and common errors.

---

## When to Update

Update `CODING_STANDARDS.md` when:
- **Recurring errors** appear in multiple code reviews
- **New categories of mistakes** are identified
- **Security vulnerabilities** are discovered in code patterns
- **Best practices** emerge from successful implementations
- **Tool or technology changes** require new patterns

**Do NOT update for:**
- One-off mistakes that are unlikely to repeat
- Trivial style preferences without impact
- Project-specific implementation details (those go in docs/)
- Temporary workarounds or hacks

---

## Update Process

### 1. Identify the Pattern

**Extract the underlying pattern** from specific code review findings:

❌ **Bad:** "Line 182 in vm-auth.sh doesn't check for jq"
✅ **Good:** "Scripts use external tools without checking if they're installed"

**Questions to ask:**
- What category of error is this? (duplication, validation, error handling, security, etc.)
- Could this happen in other parts of the codebase?
- Is this a symptom of a larger anti-pattern?
- Does this apply to one language or all code types?

### 2. Generalize the Description

**Remove specific references** that won't be meaningful in the future:

❌ **Bad:** "Copy-pasting code sections and forgetting to remove duplicates (e.g., lines 1-92 and 97-177 in test scripts)"
✅ **Good:** "Copy-pasting code sections and forgetting to remove duplicates, leaving identical blocks in the same file"

❌ **Bad:** "Documentation claiming 'sorted by last push' when no sorting is implemented"
✅ **Good:** "Documentation claiming functionality that isn't actually implemented in the code"

**Principles:**
- Use "like" or "such as" for examples, not specific file/line references
- Describe the pattern, not the specific instance
- Focus on the mistake type, not the context where it occurred
- Make it recognizable to someone who didn't see the original code

### 3. Determine Scope and Structure

**Before writing, clarify:**

| Question | Consideration |
|----------|--------------|
| **Scope** | Does this apply to shell scripts only, Go only, or all code? |
| **Severity** | Is this critical (security/data loss), moderate (bugs/maintenance), or minor (style)? |
| **Category** | Does this fit in an existing section or need a new one? |
| **Applicability** | Is this a CAL-specific pattern or general software engineering? |

**Existing categories:**
- Code Duplication
- Dependency Management
- Documentation Accuracy
- Error Handling
- Proactive Validation
- Security Practices
- Testing Requirements

**Add new sections** only if the pattern doesn't fit existing categories.

### 4. Write Prescriptive Standards

**Use mandatory language:**
- **Must** - Required, non-negotiable
- **Never** - Prohibited completely
- **Always** - Every single time
- **Should** - Strong recommendation (use sparingly)

❌ **Bad:** "It's a good idea to check dependencies"
✅ **Good:** "**Must** check for all required external dependencies before use"

❌ **Bad:** "Consider avoiding eval"
✅ **Good:** "**Never** use `eval` unless absolutely necessary"

### 5. Provide Code Examples

**Include concrete patterns** showing bad vs. good:

```markdown
**Shell Script Pattern:**
```bash
# Bad
git clone "$repo" &>/dev/null

# Good - show errors
git clone "$repo" 2>&1

# Better - conditional error handling
if ! git clone "$repo" 2>&1; then
    echo "Error: Failed to clone $repo. Check network and SSH keys."
    return 1
fi
```
```

**Guidelines:**
- Show what NOT to do (with "Bad" label)
- Show acceptable approach (with "Good" label)
- Show best practice when applicable (with "Better" label)
- Include both shell script and Go patterns when relevant
- Keep examples short and focused on the specific issue

### 6. Update CLAUDE.md Summary

After updating CODING_STANDARDS.md, **must update** the summary in CLAUDE.md:

**Location:** `CLAUDE.md` under "Core Rules" → "Coding Standards" section

**Include:**
- Brief bullet list of error categories (max 6-7 bullets)
- Testing requirements reminder
- Link to full CODING_STANDARDS.md

**Keep it concise** - agents read this on every session start.

---

## Writing Guidelines

### Tone and Language

✅ **Do:**
- Use imperative voice ("Check dependencies before use")
- Be direct and unambiguous
- Focus on the "why" behind the rule
- Make consequences clear ("leading to cryptic runtime failures")
- Use consistent formatting and structure

❌ **Don't:**
- Use passive voice ("Dependencies should be checked")
- Be vague or wishy-washy
- Include personal opinions without justification
- Use jargon without explanation
- Mix severity levels within a section

### Structure Template

```markdown
## [Category Name]

### [Rule Title]
**Common Error:** [General description of the mistake pattern]

**Standards:**
- **Must** [required action]
- **Never** [prohibited action]
- **Must** [another required action]

**[Language] Pattern:**
```[language]
# Bad
[anti-pattern code]

# Good
[acceptable code]

# Better - [explanation]
[best practice code]
```
```

### Testing Standards

For new error categories related to testing:
- Add to both "Mandatory Test Scenarios for Shell Scripts" and "Mandatory Test Scenarios for Go Code" sections
- Keep numbered lists consistent
- Be specific about what to test, not how to test it

### Code Review Checklist

When adding new standards:
- Add corresponding checkbox to "Code Review Checklist"
- Keep checklist concise (aim for 10 items max)
- Focus on verifiable items, not subjective judgments

---

## Review Process

### Before Committing

**Verify:**
- [ ] Error description is generalized, not specific to one instance
- [ ] Standards use prescriptive language (Must/Never/Always)
- [ ] Code examples show bad vs. good patterns
- [ ] Examples apply to relevant languages (shell, Go, both)
- [ ] CLAUDE.md summary is updated with any new categories
- [ ] Document follows existing structure and formatting
- [ ] Spelling and grammar are correct
- [ ] Links to other docs are valid

### Testing the Update

**Ask yourself:**
- Would this prevent the original error from recurring?
- Would a developer encountering this pattern recognize it?
- Are the examples clear without additional context?
- Could an agent or human follow these standards?
- Does this add value or just create noise?

### Getting Feedback

**Consider review if:**
- Adding a new major category (not just expanding existing)
- Changing prescriptive language from Must to Never or vice versa
- Adding security-related standards
- Removing or relaxing existing standards

---

## Maintenance

### Regular Review

**Quarterly review:**
- Are standards still relevant?
- Are they being followed?
- Do they need examples updated for new tools/versions?
- Can any be removed or consolidated?

### Version Control

- CODING_STANDARDS.md is version controlled in git
- Changes should be in dedicated commits
- Commit message should reference the PR or issue that prompted the update

**Example commit message:**
```
Update coding standards: Add proactive validation rules

Based on PR #1 code review findings. Adds requirements for
validating preconditions before operations to prevent confusing
failures.

Related: #1
```

---

## Examples from Project History

### Example 1: Adding Dependency Management Standards

**Trigger:** PR review found `jq` used without availability check

**Process:**
1. Identified pattern: "Using external tools without checking installation"
2. Generalized: Applies to all shell scripts and Go code calling external commands
3. Created new section: "Dependency Management"
4. Added patterns for both shell (`command -v`) and Go (`exec.LookPath`)
5. Updated CLAUDE.md summary

**Result:** Clear standard for all future external tool usage

### Example 2: Generalizing Error Descriptions

**Original:** "Line 182 in vm-auth.sh doesn't check for jq"
**Generalized:** "Using external tools (like `jq`, `gh`, `curl`) without checking if they're installed, leading to cryptic runtime failures"

**Why:** The specific line reference is meaningless to future developers, but the pattern description is immediately recognizable.

---

## Quick Reference

**Update Checklist:**
- [ ] Pattern identified from code review or recurring issue
- [ ] Description generalized (no specific file/line references)
- [ ] Fits into existing category or justifies new category
- [ ] Standards use prescriptive language (Must/Never/Always)
- [ ] Code examples show bad/good/better patterns
- [ ] Applies to relevant languages (shell, Go, or both)
- [ ] CLAUDE.md summary updated
- [ ] Code review checklist updated if needed
- [ ] Document reviewed for clarity and correctness
- [ ] Committed with clear message referencing source

---

## References

- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - The standards document
- [CLAUDE.md](../CLAUDE.md) - Agent instructions with standards summary
- [WORKFLOW.md](WORKFLOW.md) - Code review and workflow procedures
