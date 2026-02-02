# Phase 0 (Bootstrap) - Outstanding TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Complete bootstrap functionality and VM operational improvements.

---

## 0.8 VM Management Improvements (Complete)

---

## 0.10 Init Improvements and Enhancements (In Progress)

### First Login Git Updates (Complete)
- [x] Created vm-first-run.sh for post-restore repo sync (completed 2026-01-26)
- [x] Separated vm-auth.sh (--init only) from vm-first-run.sh (restore only) (completed 2026-01-26)
- [x] Added logout git status check in vm-setup.sh (completed 2026-01-26)
- [x] Fixed first-run flag setting reliability (completed 2026-01-26)
- [x] Simplified vm-first-run.sh to check for remote updates only (completed 2026-01-26)
- [x] Fixed logout cancel to not re-run keychain unlock (completed 2026-01-26)


### cal-bootstrap Script Enhancements (Complete)

### Console Access & Clipboard Solutions

**Status:** ✅ **COMPLETED** - All implementation and documentation complete (2026-01-31)

---

## Known Issues

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

---

## Future Improvements

**Note:** These items are not essential for Phase 0 completion:

- [ ] **Add tmux status prompt for new shells**
  - Show message when new shell starts: "tmux status saved automatically - use [prefix] d to close"
  - Detect current tmux prefix key (in case user has changed from default Ctrl+b)
  - Display actual prefix in prompt message
  - Only show when inside tmux session
  - Add to .zshrc or tmux configuration

- [ ] Support multiple GitHub servers (github.com, enterprise) in vm-auth.sh repo cloning

- [ ] **Prevent tmux from saving state until after first login completes**
  - **Problem:** tmux auto-save captures the initial vm-auth.sh authentication screen
  - When session is restored, shows stale authentication prompts instead of fresh shell
  - **Current behavior:** Auto-save runs every 15 minutes, captures first-run output
  - **Desired behavior:** Skip auto-save during first login, start saving after vm-auth.sh completes
  - **Possible solutions:**
    - Disable tmux-continuum auto-save during first login, re-enable after completion
    - Add flag file (e.g., ~/.cal-first-login-complete) to control save behavior
    - Modify tmux-continuum configuration to check for first-run flag before saving
    - Clear saved session data after first login completes
  - **Goal:** Ensure restored sessions show clean shell, not initial setup output
