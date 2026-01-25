# Phase 0 (Bootstrap) - Outstanding TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** In Progress

**Goal:** Complete bootstrap functionality and VM operational improvements.

---

## 0.8 VM Management Improvements (9/11 Complete)

- [ ] **PR #2:** Fix Screen Sharing issues (High Performance black screen, Standard copy/paste disconnect)
  - **Problem 1 (High Performance):** When accessing Tart VM via macOS Screen Sharing, High Performance mode shows locked/black screen and cannot be used
  - **Problem 2 (Standard):** Standard mode works but copy/paste to/from host causes VM to disconnect
  - **Investigation scope:**
    - **Web research (comprehensive):**
      - Search Tart GitHub issues for Screen Sharing problems (High Performance mode, copy/paste issues)
      - Research macOS Virtualization.framework Screen Sharing limitations and known issues
      - Check Tart documentation for Screen Sharing configuration options or recommendations
      - Search for community discussions about Tart VM Screen Sharing (Reddit, Stack Overflow, forums)
      - Research Apple's Virtualization.framework VNC/Screen Sharing capabilities and constraints
      - Look for workarounds or fixes others have found for similar issues
    - **Technical investigation:**
      - Determine root cause of High Performance mode black screen issue
      - Check if Apple Silicon requirements are met (both host and guest must be Apple Silicon with macOS Sonoma 14+)
      - Verify network requirements (UDP ports 5900, 5901, 5902 accessibility, bandwidth)
      - Research whether High Performance is Tart VM limitation, macOS virtualization constraint, or configuration issue
      - **Primary focus:** Find solution to Standard mode copy/paste disconnect issue
      - Check Tart configuration options, macOS Screen Sharing settings, or VM setup that could resolve disconnect
      - Test different Tart VNC/display configurations if available
  - **Implementation tasks:**
    - Fix Standard mode copy/paste disconnect if solution found
    - Fix High Performance mode black screen if solution found
    - Update vm-setup.sh or cal-bootstrap with any configuration changes needed
    - Add workarounds or fallback options if complete fix not possible
  - **Documentation to produce:**
    - Document findings in bootstrap.md (NOT ADR - ADRs are immutable)
    - List what works, what doesn't, and why
    - Document any fixes implemented
    - Provide user guidance on Screen Sharing setup
    - Include links to relevant Tart issues or documentation
  - **References:**
    - Apple Screen Sharing modes: https://support.apple.com/en-gb/guide/remote-desktop/apdf8e09f5a9/mac
    - Tart documentation and GitHub issues
  - **Acceptance criteria:** Screen Sharing works reliably (copy/paste fixed if possible), comprehensive research documented, user guidance provided
  - **Implementation approach:** Investigate and implement fixes during Create PR workflow
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
