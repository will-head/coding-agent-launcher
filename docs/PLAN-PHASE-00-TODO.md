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

- [ ] Update CCS installation in vm-setup.sh
  - Change from current install command to: `npm install -g @kaitranntt/ccs --force`
  - Run `ccs sync` after installation
  - TODO: Add automated tests for CCS installation and sync verification

- [ ] Add `--status` option to cal-bootstrap
  - Show cal-dev VM IP address if running
  - Display other useful VM information (state, resources, etc.)

- [ ] Verify TPM (Tmux Plugin Manager) setup
  - Ensure TPM loads properly on tmux start
  - Verify tmux-resurrect plugin is installed and running automatically
  - Verify tmux-continuum plugin is installed and running automatically

- [ ] Deploy Claude statusline integration
  - Install `scripts/statusline-command.sh` to VM `/Users/admin/scripts/` and make executable
  - Create helper script to add statusLine configuration to `~/.claude/settings.json`
  - StatusLine format: `"statusLine": {"type": "command", "command": "~/.claude/statusline-command.sh orange"}`
  - Script should be executable but not run automatically (requires manual execution after Claude authentication)
  - Script should merge with existing settings.json content (preserve all existing fields)

- [ ] Support multiple GitHub servers (github.com, enterprise) in vm-auth.sh repo cloning
