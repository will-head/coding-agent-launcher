# Phase 0 (Bootstrap) - Outstanding TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Complete bootstrap functionality and VM operational improvements.

---

## 0.8 VM Management Improvements (9/11 Complete)

- [ ] **HIGH PRIORITY (WIP):** Fix cal-bootstrap TERM environment variable handling to prevent opencode hangs while maintaining tmux compatibility
  - **Issue:** Conflicting requirements for TERM handling:
    1. Tmux requires known TERM (Ghostty sends `xterm-ghostty` which fails: "missing or unsuitable terminal")
    2. Opencode hangs when TERM is explicitly set in command environment (e.g., `TERM=xterm-256color command`)
  - **Current Status:** WIP - Simple removal of explicit TERM breaks Ghostty compatibility
  - **Original code:** `ssh ... "TERM=xterm-256color /opt/homebrew/bin/tmux ..."` (works for tmux, breaks opencode)
  - **Attempted fix:** `ssh ... "/opt/homebrew/bin/tmux ..."` (works for opencode, breaks Ghostty)
  - **Next Steps:** Implement one of three solutions:
    1. Wrapper script: Create `~/scripts/tmux-wrapper.sh` that sets TERM then launches tmux (RECOMMENDED)
    2. SSH SetEnv: Use `ssh -o SetEnv=TERM=xterm-256color` (requires sshd config check)
    3. Source .zshrc: `ssh ... "source ~/.zshrc && /opt/homebrew/bin/tmux ..."` (quick fallback)
  - **Reference:** [term-handling-investigation.md](term-handling-investigation.md) - Full investigation and test plan
  - **Test:** Must work with Ghostty, iTerm2, Terminal.app AND allow opencode run without hanging
- [ ] Reduce network check timeout from 5s to 3s for faster feedback (vm-auth.sh)
- [ ] Add explicit error handling for scp failures in setup_scripts_folder (vm-auth.sh)
- [ ] Check for specific opencode auth token file if documented (vm-auth.sh)
- [ ] Add Ctrl+C trap handlers during authentication flows (vm-auth.sh)
- [ ] Ensure gh username parsing works in non-English locales (vm-auth.sh)

---

## 0.10 Init Improvements and Enhancements (In Progress)

### Repository Management
- [ ] Support multiple GitHub servers (github.com, enterprise) in vm-auth.sh repo cloning

### First Login Git Updates
- [ ] vm-setup.sh sets flag variable for first login
- [ ] Login script checks flag and scans ~/code for git updates
- [ ] Prompt user to pull if updates found
- [ ] Unset flag variable after first login scan complete
- [ ] Set cal-init back to first-run mode (reset first-run flag)
- [ ] In vm-auth: prompt to update GitHub repos if existing repos found

### Logout Git Status Check
- [ ] On logout (exit, Ctrl-D, Ctrl-C) scan ~/code directories for git changes
- [ ] Prompt user to push before exit if uncommitted/unpushed changes found
- [ ] Allow user to abort logout or continue despite changes

### Installation Improvements
- [ ] Try to install Tart automatically during init if not present (brew install cirruslabs/cli/tart)
- [ ] Consider using GUIDs for VM/snapshot names with friendly name mapping
- [ ] Verify opencode login flow is fixed (test authentication reliability)
- [ ] Add Codex GitHub CLI Antigravity tools installation in init
- [ ] Install all packages required for full Go development in cal-dev during --init (follow best practice)
  - Research and install in vm-setup.sh: golangci-lint (linters runner), goimports, delve (debugger), mockgen (test mocking), air (hot reload)
  - Note: Core Go tools already included (go fmt, go vet, go test, go mod)
  - Reference: https://golangci-lint.run/ and Go community best practices

### cal-bootstrap Script Enhancements
- [ ] Allow `--snapshot delete` to accept multiple VM names
- [ ] Add `--snapshot delete --force` option to skip git checks and avoid booting VM (for unresponsive VMs)
- [ ] Check --help is up to date

---

## 0.11 Session State Management (Future)

- [ ] Implement constant context state persistence
- [ ] Write context to file after every operation
- [ ] Enable seamless session recovery on crash or usage limits
- [ ] Allow session continuation across Claude Code restarts

---

## Known Issues

- [ ] vm-auth.sh GitHub clone fails with network timeout (needs transparent proxy auto-start before clone attempt)
- [ ] Investigate: Environment status should be shown as last item before "What would you like to work on?" prompt (Cursor-CLI only - works correctly in Opencode and Claude Code)
- [x] Opencode VM issues (investigated 2026-01-25, resolved)
  - **Status:** ✅ Resolved - opencode works correctly in VM
  - **Finding:** `opencode run` works when TERM is inherited from environment, but hangs when TERM is explicitly set in command environment
  - **Root cause:** Opencode bug in TERM environment variable handling (not a VM issue)
  - **Workaround:** Use `opencode run` normally (TERM inherited) - works correctly
  - **Documentation:** 
    - [opencode-vm-summary.md](opencode-vm-summary.md) - Quick reference
    - [opencode-vm-investigation.md](opencode-vm-investigation.md) - Full investigation
    - [zai-glm-concurrency-error-investigation.md](zai-glm-concurrency-error-investigation.md) - Previous investigation (superseded)
  - **Test script:** [test-opencode-vm.sh](../../scripts/test-opencode-vm.sh) - Automated testing
- [ ] Z.AI GLM 4.7 API concurrency limit error in cal-dev VM (investigated 2026-01-25, superseded by opencode investigation)
  - **Note:** This issue was actually an opencode processing bug, not an API issue. The Z.AI API works correctly (verified via direct curl tests). The real issue was `opencode run` hanging, which is now understood and documented above.
  - Original investigation: [zai-glm-concurrency-error-investigation.md](zai-glm-concurrency-error-investigation.md)

---

## Phase 1 Pending TODOs

**Note:** This item doesn't fit cleanly into Phase 0 or 1, tracked here for visibility:

- [ ] Make cached macos-sequoia-base:latest available inside cal-dev to avoid duplicate downloading
