# Phase 0 (Bootstrap) - Outstanding TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Complete bootstrap functionality and VM operational improvements.

---

## 0.8 VM Management Improvements (10/11 Complete)

- [x] **PR #2:** Implement clipboard sharing via tart-guest-agent (completed, see PR #2)
  - **Status:** ✅ Implementation complete - ready for testing
  - **Solution:** Installed tart-guest-agent which enables full bidirectional clipboard sharing
  - **Findings:**
    - High Performance mode: Incompatible with Tart VMs (Virtualization.framework limitation) - no fix possible
    - Standard mode clipboard: Full bidirectional support via tart-guest-agent (SPICE vdagent protocol)
    - Historical copy/paste disconnect issue: Fixed in Tart PR #154 (not affecting CAL setup)
  - **Implementation:**
    - Added tart-guest-agent installation to vm-setup.sh (Homebrew)
    - Configured launchd service for auto-start (/Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist)
    - Added verification step in setup script
    - Updated documentation with full clipboard support instructions
  - **Acceptance criteria:** Met - clipboard sharing works bidirectionally (Host ↔ VM)
  - **Documentation:** docs/bootstrap.md (Screen Sharing section), scripts/vm-setup.sh
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

---

## Phase 1 Pending TODOs

**Note:** This item doesn't fit cleanly into Phase 0 or 1, tracked here for visibility:

- [ ] Make cached macos-sequoia-base:latest available inside cal-dev to avoid duplicate downloading
