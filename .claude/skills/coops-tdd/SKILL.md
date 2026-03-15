---
name: coops-tdd
description: "REQUIRED: Invoke before writing any code. This skill MUST run first whenever the user wants to create, build, implement, fix, or add functionality — regardless of scale. Covers: new functions, bug fixes, new methods, new classes, API integrations, features, utilities, or any behavioral change to the codebase. Skip only for: explaining concepts, reading/summarizing existing code, documentation edits, config changes, or setup questions. The skill structures implementation via test-first development: write a failing test, write minimal code to pass it, then refactor."
---

# TDD Workflow

Always follow this workflow before writing any implementation code. TDD is how we write software here — it is not optional.

## The Core Rule

**Write a failing test before writing any implementation code.**

The trigger for a new test is a **new behavior or requirement** — never a new method or class. Tests describe what the system should do, not how it does it.

## Red → Green → Refactor

### 🔴 RED — Write a Failing Test

1. Identify the **behavior** being implemented (from the requirement, story, or description)
2. Write a test that specifies that behavior
3. Verify the test fails for the right reason — the behavior genuinely doesn't exist yet (not a syntax error or import problem)

**Test naming** — name the test to describe the behavior under test:
- Format: `when_[condition]_should_[expected_outcome]`
- Examples:
  - `when_balance_is_zero_should_reject_withdrawal`
  - `when_email_is_invalid_should_raise_error`
  - `when_password_is_too_short_should_fail_validation`
- Adapt to language conventions (snake_case for Python, PascalCase for C#, etc.) while keeping the descriptive format

**Test file naming** — one test per file where practical, named for the behavior being tested.

**Test structure — Arrange / Act / Assert:**

Make these three sections explicit — use comments or blank lines to separate them clearly:

```python
def test_when_balance_is_zero_should_reject_withdrawal():
    # Arrange
    account = Account(balance=0)

    # Act / Assert
    with pytest.raises(InsufficientFundsError):
        account.withdraw(10)
```

**Evident Data** — only include the data that matters to the test outcome. Use builders or helpers to hide irrelevant setup noise, so the important values stand out immediately.

### 🟢 GREEN — Make the Test Pass

Write the **minimum code** necessary to make the test pass. Nothing more. Do not write code for requirements not yet expressed in a test. Move fast — cleanup is for the refactor step.

### 🔵 REFACTOR — Improve the Design

With tests green, improve the code's design. Rules:
- Make only structural changes (rename, extract, reorganise) — do not change behavior
- Run all tests after each change to confirm nothing broke
- Refactoring should never break tests — if it does, the tests were coupled to implementation details, not behavior

Repeat the cycle for the next behavior.

---

## What to Test

**Test the public API of a module** — the stable contract it offers to callers. In practice:
- Public functions and methods
- Exported classes and their public interface
- Observable outcomes (return values, raised exceptions, state changes visible to callers)

**Do not test:**
- Private/internal implementation details
- How the code achieves the result internally
- Things not visible to consumers of the module

This distinction matters: implementation details change as code is improved; public behavior changes far less often. Tests coupled to behavior survive refactoring. Tests coupled to implementation details break constantly and become a maintenance burden.

> If a test would break when you improve the internal design of the code — without changing what it does — the test is testing the wrong thing.

Do not expose internals just to make them testable. If something is private, it is covered by the tests that exercise the behavior that caused it to be created.

---

## Test Doubles

Use test doubles only for **I/O** — not to isolate classes from each other:

- Replace slow or brittle I/O (databases, queues, HTTP, file system) with in-memory fakes
- Prefer writing real in-memory implementations over mocks where possible — they tend to be more honest about the behavior
- **Do not** use mocks or stubs to isolate one class from another — tests should implicate the most recent edit, not classes in isolation

The reason to avoid class-isolation mocks: they encode your implementation decisions into the test itself. When you refactor, the mocks break even though the behavior hasn't changed. The result is a test suite that fights against improvement rather than supporting it.

---

## Scope Control

Writing the test first enforces scope: you only write the code the test requires. Each test should be the most obvious, smallest step toward the requirement. If you find yourself writing a lot of code to make one test pass, the test is probably too large — break it into a smaller first step.

Only add code needed to satisfy a behavioral requirement expressed in a test. Do not write speculative code for requirements not yet covered by a test.

---

## What Not to Do

- Do not write implementation code before writing a failing test
- Do not write tests after implementation (except for pure I/O adapters where test-first is genuinely impractical)
- Do not test private or internal implementation details
- Do not expose internals just to test them
- Do not use mocks to isolate classes from each other
- Do not write speculative code not required by any test

---

## Further Reading

If you want to understand the reasoning behind these rules — why behavior-based tests are cheaper to own, why class-isolation mocks are harmful, and the historical context for how TDD went wrong in common practice — read `references/tdd-philosophy.md`.
