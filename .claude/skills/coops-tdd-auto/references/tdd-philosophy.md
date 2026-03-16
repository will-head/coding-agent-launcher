# TDD Philosophy and Agent Guidance

This document explains *why* the rules in this skill exist. Covers the philosophy behind behaviour-driven TDD, LLM-specific failure modes, and the reasoning behind key constraints.

---

## The Root Problem: Testing Implementation Details

The most common TDD mistake is testing implementation details instead of behaviours.

**How it happens:** A developer receives a requirement, thinks "I'll need a class with a method that does X", writes a test for that method, implements it. Result: every class has a test class, every method has a test method.

**Why this is wrong:** Kent Beck's original formulation — the trigger for a new test is a new requirement or behaviour, not a new method. Ian Cooper (NDC talks, 2013–2023) observed that most TDD pain comes from ignoring this:

> "Do not test implementation details — test behaviors."
> — Ian Cooper, summarising Kent Beck's TDD by Example

When tests are coupled to implementation details:
- Refactoring breaks tests even though behaviour hasn't changed
- The test suite becomes an obstacle to improvement rather than a safety net
- Developers begin to see tests as a burden, not a benefit

---

## The Right Unit of Testing

The "unit" in unit testing was originally a **module** — a public interface hiding its implementation. Over time "unit" got conflated with "class", which led to the class-per-test pattern and heavy mocking.

The correct unit to test is the **public API of a module** — the stable contract it offers callers. Internal details are unstable; they change as you improve the design. The public contract changes rarely.

Practical implication: tests go through the public surface of a module and verify observable outcomes. Private methods and internal helpers are covered by those tests — they don't need their own tests.

---

## Why Class-Isolation Mocks Are Harmful

Mocks used to isolate a class from its collaborators encode your implementation decisions into the test. When you refactor — merging two classes, extracting a third — the mocks break even though the behaviour hasn't changed.

The result: tests break whenever you improve internal design. You spend time fixing tests instead of fixing code. The suite stops providing confidence because it's always breaking for the wrong reasons.

The right use of test doubles is for **I/O** — things that are genuinely slow, non-deterministic, or have external shared state (databases, queues, HTTP, file systems). Don't replace collaborating objects with mocks just to isolate a class.

---

## Why This Is Especially Critical for LLMs

LLMs' training data contains a large volume of poor TDD: tests that mock heavily and test implementation details. These tests are fragile during refactoring. With coding agents this is more dangerous because:

- Tests are the safety net that prevents the agent from breaking existing behaviour.
- If the agent can modify tests to make implementation changes pass, that safety net is gone.
- Without a safety net, you can't refactor — you can only change — and the agent may silently alter behaviour.

LLMs also tend to write speculative code not supported by tests. Writing tests first is the proven way to constrain LLM-generated code to what was actually asked for.

**Reward hacking** is the specific failure mode where an agent modifies a test to make its own implementation pass. This is indistinguishable from correct behaviour in the short term and catastrophic in the long term. It must be explicitly prohibited.

---

## Human + Agent Collaboration Model (Automated)

- The task list is the pre-approved specification; no approval gate is needed.
- Tests are derived from task items, not invented by the agent.
- Reward hacking protection is *more* critical, not less — no human is watching.
- Richer prescriptive guidance compensates for the absent human supervisor.

Without test-first discipline in an automated context, there is no mechanism to validate that the agent's code meets requirements. Speculative code and silent behaviour changes become invisible.

---

## Developer Tests vs Unit Tests

Developer Tests confirm the system-under-test's behaviour. They are NOT classical unit tests.

- **Classical unit tests**: defect localisation is to the isolated module.
- **Developer tests**: defect localisation is to edits since the last green test run.
- "Unit" = isolation of the *test* (run in any order, no side effects) — NOT isolation of the *code* from collaborators.

A well-written developer test is an executable specification — it tells you what the system does, not how.

---

## Deep Modules, Narrow Interfaces

Modules should have a narrow public interface and a deep implementation. Tests target the narrow interface. Every implementation detail is reachable via a path through the public interface — that's where coverage comes from.

In ports-and-adapters architecture: test at the port, not the adapter, because behaviour might support many adapters.

---

## Behaviour-Driven Naming

Dan North observed that the word "test" leads people to think about verification of code already designed, rather than specification of behaviour about to be built. Naming tests as behaviours — "when X happens, Y should result" — naturally shifts focus to what the system does.

The naming convention `when_[condition]_should_[outcome]` reads as a specification. A failing test named this way tells you immediately whether it represents a regression or a legitimate requirement change.

---

## Scope Control

Writing tests first gives you scope control that writing them after does not. Test-first means you only implement what a test requires, which means you only implement what was asked for. Speculative code — written for requirements that don't exist yet — is a major source of unnecessary complexity.

---

## The Red Phase Matters

A test you haven't seen fail tells you nothing. If the test passes before you write the implementation, either the test is wrong or the behaviour already exists. Always verify the test fails for the right reason — the behaviour is genuinely absent, not that there's an import error or typo.

---

## Code Coverage

By testing behaviours at the public interface, high coverage typically follows because every implementation detail is reachable via the interface. However, coverage is a tool for guiding refactoring — it helps spot branches not yet exercised. It is not a target. Do not write tests to hit a coverage number.

---

## Driving in Gears

How much code per test depends on confidence:
- High confidence → larger jumps (higher gear).
- Low confidence → smaller steps (lower gear).
- Each Red-Green-Refactor cycle should take 10–20 minutes. If longer, lower the gear.

When a module's public interface is too big a jump:
1. Do some upfront design to identify a seam within the domain.
2. Temporarily make that seam a module export and write developer tests against it.
3. Once the seam and the real export are both implemented, decide:
   - **Keep the seam as an export** (preferred) if further modification would be complicated without it.
   - **Move the seam back to an implementation detail** and remove its tests if the implementation is stable.

---

## Kent Beck's Test Desiderata

Properties that make tests valuable — trade off among them:

- **Isolated** — same results regardless of run order.
- **Composable** — test dimensions of variability separately, combine results.
- **Deterministic** — no change → no result change.
- **Fast** — run quickly.
- **Behavioural** — sensitive to behaviour changes; insensitive to structural changes.
- **Structure-insensitive** — refactoring shouldn't break tests.
- **Readable** — communicates intent to a future reader.
- **Specific** — when a test fails, the cause is obvious.
- **Predictive** — all pass → suitable for production.
- **Inspiring** — a passing suite inspires confidence.

The tension between "behavioural" and "structure-insensitive" is resolved by testing at the right level — behaviour (public API) rather than implementation (internal structure).

---

## Test Pyramid

1. **Developer Tests (base)** — greatest weight. Fast, binary. Guide development. Prevent regression.
2. **Acceptance Tests (middle)** — validate API contracts. Slower.
3. **Smoke Tests** — critical end-to-end scenarios. Fail-fast, not defect localisation.
4. **UI Tests (top)** — minimal. Reserve for critical workflows only.

---

## Where TDD Doesn't Apply

- Visual UI layout — use manual/exploratory testing.
- Third-party code — don't test-drive what you didn't write.
- Spikes/prototypes — explore freely, throw the code away.

---

## Avoid BDD/Gherkin Tool Overhead

Cucumber, SpecFlow, etc. add a translation layer that increases maintenance without value — unless the product owner is actually writing the tests. Use acceptance criteria to drive developer tests directly instead.

---

## Attribution

- Kent Beck, *Test-Driven Development by Example* (2002)
- Ian Cooper, "TDD, Where Did It All Go Wrong" (NDC 2013)
- Ian Cooper, "TDD Revisited" (NDC Porto 2023)
- Kent Beck & Kelly Sutton, *Test Desiderata* video series
- Dan North, original BDD post (2006)
