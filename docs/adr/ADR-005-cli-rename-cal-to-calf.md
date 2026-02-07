# ADR-005: CLI Rename from CAL to CALF

**Status:** Accepted
**Date:** 2026-02-07

## Context

The CLI binary name `cal` collides with the system calendar command (`/usr/bin/cal`), requiring users to use `./cal` or modify PATH to run the tool. This impacts usability and is tracked as Critical Issue #1 in PLAN-PHASE-01-TODO.md.

## Decision

Rename the CLI from `cal` to `calf` (**C**oding **A**gent **L**oader **F**oundation).

### Rationale

1. **No system collision** — `calf` is not a standard macOS/Linux command
2. **Not in Homebrew** — No package named `calf` in Homebrew core
3. **Memorable naming** — A "calf" is a young cow, matching the project's cow mascot
4. **Acronym works** — Coding Agent Loader Foundation

### Collision Research (2026-02-07)

| Project | Type | Platform | Collision Risk |
|---------|------|----------|----------------|
| [Calf Studio Gear](https://calf-studio-gear.org/) | Linux audio plugins (LV2/JACK) | Linux (experimental macOS) | Low on macOS |
| [Calf (Compose Multiplatform)](https://github.com/MohamedRejeb/Calf) | Kotlin UI library | Android/iOS/Desktop | None (library) |
| [CALFEM](https://github.com/CALFEM/calfem-python) | Finite Element toolkit | MATLAB/Python | None (library) |

**Calf Studio Gear** is the only potential conflict:
- Available as `calf` package in Arch Linux, Fedora, Ubuntu
- NOT in standard Homebrew (requires `homebrew-audio` tap)
- macOS support is experimental with GUI issues
- Target audiences don't overlap (audio engineers vs. coding agent users)

## Mascot

The project mascot is the ASCII cow from the transparent proxy success message:

```
 ___________________________
< Transparent proxy works! >
 ---------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

This cow represents:
- **Reliability** — Displayed when proxy connectivity is confirmed working
- **Friendly UX** — A touch of personality in CLI output
- **CALF branding** — A calf is a young cow, connecting the mascot to the name

## Consequences

### Changes Required

All references to `cal` must be updated to `calf`. This includes:

#### File/Directory Renames
- `cmd/cal/` → `cmd/calf/`
- `scripts/cal-bootstrap` → `scripts/calf-bootstrap`
- `cal` (binary) → `calf`

#### VM Names
- `cal-dev` → `calf-dev`
- `cal-init` → `calf-init`
- `cal-clean` → `calf-clean`

#### Environment Variables
- `CAL_VM` → `CALF_VM`
- `CAL_LOG` → `CALF_LOG`
- `CAL_SESSION_INITIALIZED` → `CALF_SESSION_INITIALIZED`

#### Config/Cache Paths
- `~/.cal-cache/` → `~/.calf-cache/`
- `~/.cal-proxy-config` → `~/.calf-proxy-config`
- `~/.cal-proxy.log` → `~/.calf-proxy.log`
- `~/.cal-proxy.pid` → `~/.calf-proxy.pid`
- `~/.cal-vm-config` → `~/.calf-vm-config`
- `~/.cal-vm-info` → `~/.calf-vm-info`
- `~/.cal-auth-needed` → `~/.calf-auth-needed`
- `~/.cal-first-run` → `~/.calf-first-run`
- `/Volumes/My Shared Files/cal-cache/` → `/Volumes/My Shared Files/calf-cache/`

#### Mount Tags
- `cal-cache` → `calf-cache`

#### Commands
- `cal isolation` → `calf isolation`
- `cal cache` → `calf cache`
- `cal config` → `calf config`

#### Tmux Session
- `cal` session → `calf` session

#### Text References
- "CAL" → "CALF" in descriptions and documentation
- "Coding Agent Launcher" → "Coding Agent Launcher Foundation" where appropriate

### Migration Path

1. Implement changes in a single PR to avoid partial rename states
2. Update all scripts, code, and documentation atomically
3. Users with existing VMs will need to recreate them (breaking change)
4. Host cache directory can be migrated: `mv ~/.cal-cache ~/.calf-cache`

### What Stays the Same

- Repository name: `coding-agent-launcher` (unchanged)
- Go module: `github.com/will-head/coding-agent-launcher` (unchanged)
- Project description updates but core purpose unchanged
