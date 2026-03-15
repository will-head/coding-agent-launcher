# TDD Philosophy and Rationale

This document explains *why* the rules in the main skill exist. Read it when you want to understand the reasoning, not just the rules.

---

## The Root Problem: Testing Implementation Details

The most common mistake in TDD practice is testing implementation details instead of behaviors.

**How it happens:** A developer receives a requirement, then thinks: "I'll need a class with a method that does X." They write a test for that method, then implement the method. The test passes. Repeat. The result is a test suite where every class has a corresponding test class, and every method has a corresponding test method.

**Why this is wrong:** Kent Beck's original formulation was clear — the trigger for writing a test is a new requirement or behavior, not a new method. Ian Cooper (NDC talks, 2013–2023) observed that most TDD pain comes from ignoring this:

> "Do not test implementation details — test behaviors."
> — Ian Cooper, summarising Kent Beck's TDD by Example

When tests are coupled to implementation details:
- Refactoring breaks tests even though behavior hasn't changed
- Tests have to be rewritten alongside the code they're supposed to protect
- The test suite becomes an obstacle to improvement rather than a safety net
- Developers begin to see tests as a burden, not a benefit

---

## The Right Unit of Testing

The "unit" in unit testing was originally a **module** — a public interface hiding its implementation. Over time, "unit" got conflated with "class", which led to the class-per-test pattern and the heavy use of mocks to isolate classes.

The correct unit to test is the **public API of a module** — what it offers to callers. This is the stable contract. Internal implementation details are unstable; they change as you improve the design. The public contract changes rarely.

Practical implication: write tests that go through the public surface of a module and verify observable outcomes. Private methods and internal helpers are covered by those tests — they don't need their own tests.

---

## Why Class-Isolation Mocks Are Harmful

Mocks used to isolate a class from its collaborators encode your implementation decisions into the test. The test says: "this class calls that other class with these exact arguments in this order." When you refactor — perhaps merging two classes, or extracting a third — the mocks break. The behavior of the system hasn't changed, but your tests say it has.

The result is a test suite where:
- Tests break whenever you improve the internal design
- You spend time fixing tests rather than fixing code
- The tests stop providing confidence because they're always breaking for the wrong reasons

The right use of test doubles is for **I/O** — things that are genuinely slow, non-deterministic, or have shared external state (databases, message queues, HTTP APIs, file systems). Replace those with in-memory fakes. Don't replace collaborating objects with mocks just to isolate a class.

---

## Behavior-Driven Naming

Dan North observed that people often misapply TDD because the word "test" leads them to think about verification of code they've already designed, rather than specification of behavior they're about to build. Naming tests as behaviors — "when X happens, Y should result" — naturally shifts focus to what the system does rather than how it does it.

This is also why the naming convention matters: `when_[condition]_should_[outcome]` reads as a specification. It tells you what requirement the test covers, so you can quickly judge whether a failing test represents a regression or a legitimate change in requirements.

---

## Scope Control

Writing tests first gives you scope control in a way that writing them after does not. If you implement first and test after, you're confirming that the code does what you wrote — but you had no constraint on what you wrote. Test-first means you only implement what a test requires, which means you only implement what was asked for. Speculative code — code written for requirements that don't exist yet — is a major source of unnecessary complexity.

---

## The Red Phase Matters

A test that you haven't seen fail doesn't tell you anything. If the test passes before you write the implementation, either the test is wrong, or the behavior already exists. Always verify the test fails for the right reason — the behavior is genuinely absent, not that there's an import error or typo.

---

## Test Desiderata (Kent Beck)

Good tests have these properties (some support each other, some trade off):

- **Isolated** — results don't depend on test order or other tests' side effects
- **Composable** — different dimensions of variability can be tested separately and combined
- **Deterministic** — same code, same result, every time
- **Fast** — tests should run quickly so you run them often
- **Behavioral** — sensitive to changes in behavior; if behavior changes, the test should fail
- **Structure-insensitive** — not sensitive to changes in internal code structure (refactoring shouldn't break tests)
- **Readable** — the test communicates its intent to a future reader
- **Specific** — when a test fails, the cause should be obvious
- **Predictive** — if tests pass, you're reasonably confident the code is correct
- **Inspiring** — a passing test suite inspires confidence

The tension between "behavioral" and "structure-insensitive" is resolved by testing at the right level — behavior (public API) rather than implementation (internal structure).

---

## Sources

- Kent Beck, *Test-Driven Development by Example* (2002)
- Ian Cooper, "TDD, Where Did It All Go Wrong" (NDC 2013, various reprises)
- Ian Cooper, "TDD Revisited" (NDC Porto 2023)
- Kent Beck & Kelly Sutton, *Test Desiderata* video series
- Dan North, original BDD post (2006)
