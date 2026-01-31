# BUG-001: CCS Auth Create Clipboard Keybinding Failure

| Field     | Value |
|-----------|-------|
| ID        | BUG-001 |
| Status    | Open |
| Severity  | Medium |
| Component | CCS/VM |
| Opened    | 2026-01-31 |

## Environment

- cal-dev VM (Tart macOS VM)
- CCS v7.28.1
- Claude Code v2.1.27
- SSH session via tmux

## Summary

Pressing 'c' during `ccs auth create` OAuth flow does not copy the authentication URL to the clipboard. The keybinding is non-functional when Claude Code is spawned as a subprocess by CCS.

## Steps to Reproduce

1. SSH into cal-dev VM
2. Run `ccs auth create`
3. OAuth URL is displayed with prompt to press 'c' to copy
4. Press 'c'
5. URL is not copied to clipboard

## Expected Behavior

Pressing 'c' copies the OAuth URL to the clipboard, matching the behavior when running `claude` directly.

## Actual Behavior

Pressing 'c' has no effect. The keybinding does not respond.

Running `claude` directly (not via CCS), the 'c' keybinding works as expected.

## Root Cause Analysis

CCS spawns Claude Code as a Node.js subprocess via `child_process.spawn()`. Claude Code uses the Ink terminal UI library, which requires stdin to be in "raw mode" to handle keyboard input.

When CCS spawns Claude Code as a subprocess, stdin is not properly configured for raw mode. This breaks all interactive keyboard input handled by Ink, including the 'c' keybinding for clipboard copy.

**Why behavior differs:**
- `claude` directly: stdin in raw mode -> Ink handles keyboard input -> 'c' works
- `ccs auth create`: CCS spawns Claude as subprocess -> stdin not in raw mode -> keyboard input broken

## Evidence

- [claude-code#771](https://github.com/anthropics/claude-code/issues/771) - Spawning from Node.js breaks functionality
- [claude-code#1072](https://github.com/anthropics/claude-code/issues/1072) - Ink raw mode issue

## Workarounds

1. **Run `claude` directly** - Authenticate by running `claude` instead of `ccs auth create`. CCS will use the existing auth.
2. **Use `--gui` mode** - VNC provides bidirectional clipboard support, bypassing the terminal keybinding issue.
3. **Manual URL selection** - Manually select and copy the URL from the terminal output instead of using the 'c' keybinding.

## Resolution Path

Report upstream to [kaitranntt/ccs](https://github.com/kaitranntt/ccs) GitHub. The fix likely involves CCS passing stdin with `stdio: ['inherit', 'inherit', 'inherit']` when spawning the Claude subprocess.

## Related

- [bootstrap.md troubleshooting](../bootstrap.md) - VM setup and authentication procedures
