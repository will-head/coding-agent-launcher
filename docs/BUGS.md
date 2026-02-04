# Active Bugs

Active bugs for the CAL project. Agents should only read this file when specifically asked about bugs.

When bugs are resolved, remove the entry from this file and update `bugs/README.md`.

## Severity Definitions

| Severity | Description |
|----------|-------------|
| Critical | Blocks core functionality, no workaround |
| High     | Major feature broken, workaround exists |
| Medium   | Feature degraded, acceptable workarounds |
| Low      | Minor issue, cosmetic, or edge case |

## Status Definitions

| Status      | Description |
|-------------|-------------|
| Open        | Confirmed, not yet being worked on |
| In Progress | Actively being investigated or fixed |
| Blocked     | Waiting on external dependency |

## Active Bugs

| ID | Summary | Severity | Status | Component | Phase | Opened |
|----|---------|----------|--------|-----------|-------|--------|
| BUG-009 | [gh repo clone during --init doesn't persist to snapshot](bugs/BUG-009-gh-repo-clone-lost-during-init.md) | High | Open | Bootstrap | 0 | 2026-02-04 |
