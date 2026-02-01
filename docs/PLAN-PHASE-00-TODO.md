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

## 0.11 Tmux Session Persistence

**Goal:** Automatically save and restore tmux sessions across VM restarts and snapshots.

**Implementation:** Separate script `scripts/vm-tmux-resurrect.sh`

**Tasks:**
- [ ] Create `vm-tmux-resurrect.sh` script
- [ ] Install tmux-resurrect plugin (https://github.com/tmux-plugins/tmux-resurrect)
- [ ] Install tmux-continuum plugin for automatic saves
- [ ] Configure tmux.conf settings:
  - Enable pane contents restoration: `set -g @resurrect-capture-pane-contents 'on'`
  - Set history limit: `set -g history-limit 5000`
  - Enable tmux-continuum: `set -g @continuum-restore 'on'`
  - Set continuum save interval: `set -g @continuum-save-interval '15'` (minutes)
- [ ] Hook into `.zshrc` to restore sessions on login
- [ ] Hook into `.zlogout` to save sessions on logout
- [ ] Call from `vm-setup.sh` during `cal-bootstrap --init`
- [ ] Test session persistence across logout/login
- [ ] Test session persistence across VM restart
- [ ] Test session persistence across snapshot/restore (should restore to snapshot state)

**Configuration:**
- Pane contents (scrollback): Enabled (5000 line limit)
- Vim/neovim sessions: Default tmux-resurrect behavior
- Shell history per pane: Not implemented (too complex)
- Auto-save: Every 15 minutes via tmux-continuum
- Manual save: On logout via `.zlogout` hook

**Persistence Strategy:**
- Resurrect data lives in VM (`~/.tmux/resurrect/`)
- Snapshots capture current resurrect state
- Restoring snapshot brings back sessions from that point in time
- No cross-VM sync or host storage

**Phase 1 Integration:**
- Add `vm-tmux-resurrect.sh` to section 1.10 (Helper Script Deployment)
- Deploy to `~/scripts/` during VM initialization
- Include in list of scripts to verify after SCP

---

## Future Improvements

**Note:** These items are not essential for Phase 0 completion:

- [ ] Support multiple GitHub servers (github.com, enterprise) in vm-auth.sh repo cloning
