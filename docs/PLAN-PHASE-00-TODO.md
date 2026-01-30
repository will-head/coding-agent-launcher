# Phase 0 (Bootstrap) - Outstanding TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Complete bootstrap functionality and VM operational improvements.

---

## 0.8 VM Management Improvements (11/12 Complete)
- [ ] Add explicit error handling for scp failures in setup_scripts_folder (vm-auth.sh)
- [ ] Check for specific opencode auth token file if documented (vm-auth.sh)
- [ ] Add Ctrl+C trap handlers during authentication flows (vm-auth.sh)
- [ ] Ensure gh username parsing works in non-English locales (vm-auth.sh)

---

## 0.10 Init Improvements and Enhancements (In Progress)

### First Login Git Updates (Complete)
- [x] Created vm-first-run.sh for post-restore repo sync (completed 2026-01-26)
- [x] Separated vm-auth.sh (--init only) from vm-first-run.sh (restore only) (completed 2026-01-26)
- [x] Added logout git status check in vm-setup.sh (completed 2026-01-26)
- [x] Fixed first-run flag setting reliability (completed 2026-01-26)
- [x] Simplified vm-first-run.sh to check for remote updates only (completed 2026-01-26)
- [x] Fixed logout cancel to not re-run keychain unlock (completed 2026-01-26)

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

## Future Improvements

**Note:** These items are not essential for Phase 0 completion:

- [ ] Support multiple GitHub servers (github.com, enterprise) in vm-auth.sh repo cloning

---

## Phase 1 Pending TODOs

**Note:** This item doesn't fit cleanly into Phase 0 or 1, tracked here for visibility:

- [ ] Make cached macos-sequoia-base:latest available inside cal-dev to avoid duplicate downloading
