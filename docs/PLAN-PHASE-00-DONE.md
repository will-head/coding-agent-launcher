# Phase 0 (Bootstrap) - Completed Items

> [← Back to PLAN.md](../PLAN.md)

**Status:** Mostly Complete

**Goal:** Manual VM setup and bootstrap automation documented and implemented.

**Deliverable:** Core Phase 0 implementation documented in [ADR-002](adr/ADR-002-tart-vm-operational-guide.md). Three-tier VM architecture, automated setup, transparent proxy, git safety checks, and VM detection.

---

## Completed Tasks

### Core Bootstrap (Complete)
- [x] Research Tart capabilities
- [x] Document manual setup process
- [x] Create automated vm-setup script
- [x] Set up base VM with agents (automated via script)
- [x] Create clean snapshot for rollback (documented)
- [x] Investigate and test terminal keybindings (all working correctly)

### cal-bootstrap Script (Complete)
- [x] **Create cal-bootstrap script** - unified VM management
  - [x] `--init`: Create cal-clean, cal-dev, cal-init VMs
  - [x] `--run`: Start VM and SSH in automatically
  - [x] `--stop`: Stop cal-dev
  - [x] `--snapshot`: List, create, restore, delete snapshots
  - [x] Auto-detect mode based on VM state
  - [x] SSH key setup automation
  - [x] Cleanup traps for background processes

### macOS Auto-Login (Phase 0.7 - Complete)
- [x] Enable auto-login in vm-setup.sh
- [x] Configure macOS to auto-login admin user
- [x] Fix Screen Sharing lock screen issue

### Keychain Access for Cursor Agent (Phase 0.8 - Complete)
- [x] Research keychain issue from Tart FAQ
- [x] Implement keychain unlock in vm-setup.sh
- [x] Implement keychain unlock in cal-bootstrap
- [x] Create test script and documentation
- [x] Test agent login via Screen Sharing
- [x] Verify credential persistence (works after SSH reconnect)
- [x] Test across VM reboots (credentials persist with keychain unlock + .zshrc)
- [x] Verify auto-unlock on connection
- [x] **FIXED: Cursor agent authentication now works** - Automatic keychain unlock on every SSH login (via .zshrc) enables Cursor OAuth flows to access browser credentials. The keychain must be unlocked for OAuth browser authentication to succeed in VM environments.

### Keychain Auto-Unlock and First-Run Automation (Phase 0.8.5 - Complete)
- [x] Save VM password to ~/.cal-vm-config (mode 600) for automated keychain unlock
- [x] Add keychain auto-unlock to .zshrc (runs on every SSH login)
- [x] Implement first-run flag (~/.cal-first-run) to trigger vm-auth.sh automatically
- [x] Add VM reboot step in --init to apply .zshrc configuration
- [x] Fix filesystem sync timing (sync + sleep to ensure flag survives VM reboot)
- [x] Fix tmux to start login shell ('zsh -l') so .zshrc first-run code executes
- [x] Re-enable Cursor Agent authentication in vm-auth.sh
- [x] Improve auth detection (use command output vs file existence checks)
- [x] Add CAL_FIRST_RUN environment variable for vm-auth.sh continuation prompt
- [x] Security trade-off documented: plaintext password stored with mode 600 permissions

### SSH Alternatives Investigation (Phase 0.8 - Complete)
- [x] Research alternatives (Mosh, Eternal Terminal, console access, tmux)
- [x] Performance testing and comparison
- [x] **Conclusion:** SSH is optimal for local VM (excellent performance)
- [x] **Enhancement:** Added tmux support for session persistence

### VM Management Improvements (Phase 0.8 - 13/13 Complete)
- [x] Network check timeout optimization - already implemented at 2s (faster than requested 3s) (completed 2026-01-30)
- [x] Check for specific opencode auth token file if documented (vm-auth.sh) - already using opencode auth list command-based approach (completed 2026-01-30)
- [x] **PR #2:** Implement clipboard sharing via tart-guest-agent (merged 2026-01-25)
  - **Solution:** Installed tart-guest-agent which enables VM→Host clipboard sharing (one-way only)
  - **Findings:**
    - High Performance mode: Incompatible with Tart VMs (Virtualization.framework limitation) - shows black screen and locked VM
    - Standard mode clipboard: VM→Host only via tart-guest-agent (SPICE vdagent protocol)
    - Host→VM paste: Causes Screen Sharing disconnect (not necessarily crash) - known limitation, documented with warning
    - Historical copy/paste disconnect issue: Fixed in Tart PR #154 (not affecting CAL setup)
  - **Implementation:**
    - Added tart-guest-agent installation to vm-setup.sh (Homebrew)
    - Configured launchd service for auto-start (/Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist)
    - Added verification step in setup script
    - Updated documentation with clipboard support instructions and warnings
  - **Documentation:** docs/bootstrap.md (Screen Sharing section), scripts/vm-setup.sh
- [x] Fix opencode installation in `--init` script (added Go install fallback, improved PATH setup)
- [x] Simplify `--init` auth flow (removed verification prompt since opencode now works reliably)
- [x] Add `--restart` option to cal-bootstrap for quick VM restart
- [x] Check VM keyboard layout matches host keyboard layout
- [x] Auto-configure VM keyboard layout to match host keyboard layout during setup
- [x] Make sure keyboard layout is set on login in case it has changed since last run (not needed - VM auto-syncs from host)
- [x] Add Screen Sharing instructions for agent login failures (displayed on --run)
- [x] Add warning on snapshot restore to check that git is updated in VM (uncommitted/unpushed changes checked)
- [x] Investigate if uncommitted or unpushed git changes can be automatically checked if they exist in VM before restore (implemented)
- [x] Remove distinction between clones and snapshots in `--snapshot list` (they're functionally same for our purposes)
- [x] Create method for coding agent to detect if running in VM (env var + info file + helper functions, see docs/vm-detection.md)
- [x] **Fix cal-bootstrap TERM environment variable handling** (completed 2026-01-25)
  - **Issue:** Conflicting requirements for TERM handling:
    1. Tmux requires known TERM (Ghostty sends `xterm-ghostty` which fails: "missing or unsuitable terminal")
    2. Opencode hangs when TERM is explicitly set in command environment (e.g., `TERM=xterm-256color command`)
  - **Solution:** Implemented wrapper script approach (Option 3 from investigation)
    - Created `scripts/tmux-wrapper.sh` that sets `TERM=xterm-256color` in script environment
    - Updated `setup_scripts_folder()` to deploy wrapper script to VM's `~/scripts/`
    - Updated all SSH tmux calls in `do_run()` and `do_restart()` to use `~/scripts/tmux-wrapper.sh`
    - Ensured scripts folder is set up before connecting (idempotent operation)
  - **Why this works:**
    - TERM set in script environment (inherited naturally by opencode) - avoids opencode hang
    - Tmux receives known TERM value (`xterm-256color`) that exists in VM terminfo database
    - Works with Ghostty, Terminal.app, iTerm2, and all terminals
  - **Test Results:** ✅ Verified working with Ghostty, Terminal.app, and opencode (no hang)
  - **Reference:** [term-handling-investigation.md](term-handling-investigation.md) - Full investigation and solution

### Transparent Proxy for Network Reliability (Phase 0.9 - Complete)
- [x] Implement transparent proxy via sshuttle (VM→Host)
- [x] Add bootstrap SOCKS proxy (SSH -D) for --init phase before sshuttle installed
- [x] Add `--proxy on/off/auto` flag to cal-bootstrap
- [x] Implement auto mode (tests github.com connectivity, enables proxy if needed)
- [x] Setup VM→Host SSH keys with host key verification
- [x] Add VM commands: proxy-start, proxy-stop, proxy-restart, proxy-status, proxy-log
- [x] Auto-start proxy on VM boot/shell login (configurable via PROXY_MODE)
- [x] Auto-start in vm-auth.sh if network fails
- [x] Check host SSH server and Python availability
- [x] Comprehensive documentation (docs/proxy.md, updated bootstrap.md and architecture.md)

### Installation Improvements (Phase 0.10 - Partial)
- [x] Add CCS (Claude Code Switch) installation during --init (completed 2026-01-26)
- [x] Fix Claude Code authentication detection (check settings.json content, not just existence) (completed 2026-01-26)
- [x] Try to install Tart automatically during init if not present (completed 2026-01-30)
  - Auto-installs via Homebrew if not found in PATH
  - Checks for brew availability and provides clear error messages
  - Implementation in cal-bootstrap script
- [x] Install all packages required for full Go development in cal-dev during --init (completed 2026-01-30)
  - Installed tools: golangci-lint, staticcheck, goimports, delve (dlv), mockgen, air
  - Added GOPATH and Go bin directory to PATH in .zshrc
  - Core Go tools (go fmt, go vet, go test, go mod) already included
  - Implementation in vm-setup.sh

### Init Improvements and Enhancements (Phase 0.10 - Partial)
- [x] Add option to sync git repos on init (clone specified repos into VM automatically)
- [x] **Cursor OAuth authentication working** - OAuth now works with automatic keychain unlock (see Phase 0.8). First-run automation triggers vm-auth.sh on first login to authenticate all agents including Cursor.
- [x] **Check and fix authentication flows**
  - [x] GH CLI: Fix PAT login flow (currently fails, token may be issue)
  - [x] opencode: Works but reports not authenticated in check (investigate status check)
  - Note: Cursor CLI issues tracked separately (see Phase 0.8 line 39)
  - Note: Claude Code authentication working correctly - do not modify
- [x] **Clone GitHub repos in vm-auth** - after gh authentication
  - [x] Prompt user to select repos to clone (present list of user's repos)
  - [x] Clone selected repos to ~/code/[github server]/[username]/[repo]
- [x] Renamed cal-initialised to cal-init (shorter, clearer naming)
- [x] Make `--init` safer: delete existing cal-dev and cal-init as first step
  - [x] Warn user before deletion
  - [x] Check for uncommitted/unpushed git changes
  - [x] Provide abort option with no changes made
  - [x] Only proceed after user confirmation
  - [x] Check both cal-dev and cal-init upfront (not at Step 9)
  - [x] Single confirmation for entire init operation
- [x] Create code directory in user home during --init
- [x] Add git change checks to all destructive operations (delete VM, restore snapshot, etc)
  - [x] Implemented for --snapshot restore (refactored to use reusable function)
  - [x] Implemented for --snapshot delete (checks all VMs except cal-clean)
  - [x] Implemented for --init (checks cal-dev before deleting both VMs)
  - [x] Created reusable check_vm_git_changes() function to reduce duplication
  - Note: Checks skip cal-clean (base image with no expected work)
- [x] Create auth script to easily re-run agent authentication
  - [x] Create vm-auth.sh script that runs: gh auth login, claude auth login, agent (Cursor auth), opencode auth login
  - [x] Provide convenient way to re-authenticate all agents without manual steps
  - [x] Make script idempotent (skip if already authenticated, smart defaults)
  - [x] Install in cal-dev during --init
  - [x] Detect network connectivity and auto-start transparent proxy when needed
- [x] Add vm-setup.sh and vm-auth.sh to ~/scripts folder in cal-dev during --init
  - [x] Create ~/scripts directory in cal-dev if it doesn't exist
  - [x] Copy vm-setup.sh and vm-auth.sh from host to VM during --init
  - [x] Add ~/scripts to PATH in .zshrc for easy access
  - [x] Run vm-setup.sh from ~/scripts (no duplication in ~)
- [x] Update README.md Quick Start to match bootstrap.md (correct Quick Start instructions)

### vm-auth.sh Improvements (Completed)
- [x] Refactor auth flow: check auth status first, prompt for update (Y/N), then run standard auth flow
- [x] Add GitHub repo sync after authentication: prompt user to enter repos by name for cloning
- [x] Use `gh api user -q .login` for more robust username extraction

### cal-bootstrap Script Enhancements (Completed)
- [x] Show VM/snapshot sizes in `--snapshot list` output (uses JSON API, displays actual size with GB units, includes total)
- [x] Remove cal-dev prefix from snapshot names (snapshots now use exact names specified by user)
- [x] When cal-init exists and user runs `--init` ask: Do you want to replace cal-init with current cal-dev y/N

### First Login and Logout Improvements (Completed 2026-01-26)
- [x] **Fixed first-run flag setting reliability**
  - Problem: Booting cal-init briefly to set flag didn't get IP consistently (network timing issue)
  - Solution: Set flag in cal-dev (while running with known IP) → Clone to cal-init (flag copies) → Remove flag from cal-dev after restart
  - Implementation: Modified cal-bootstrap --init flow and replace-init flow
  - Result: 100% reliable flag setting without ever booting cal-init separately
- [x] **Fixed logout cancel keychain unlock spam**
  - Problem: Cancelling logout with exec zsh -l re-ran keychain unlock and first-run checks
  - Solution: Added CAL_SESSION_INITIALIZED flag to prevent repeat execution in same session chain
  - Implementation: Wrapped keychain unlock in session flag check, flag persists through exec
  - Result: Clean shell after logout cancel, git check still runs on next exit
- [x] **Simplified vm-first-run.sh**
  - Removed: Authentication checking, re-auth prompts, repository sync/pull, clone prompts
  - Kept: Network connectivity with proxy auto-start, remote update checking
  - Added: Better fetch error diagnostics (timeout, auth, network categories)
  - Result: Fast, focused script that shows which repos have available updates
- [x] **Fixed macOS compatibility issues**
  - Removed timeout command dependency (not available on macOS by default)
  - Git has built-in timeouts, external timeout not needed
  - Fixed status messages to distinguish "up to date" vs "fetch failed"
- [x] **Logout git status check**
  - On logout (exit, Ctrl-D, Ctrl-C): Scans ~/code for uncommitted or unpushed changes
  - Prompts user to push before exit if changes found
  - Allows user to abort logout (exec zsh -l) or continue despite changes
  - Implemented in ~/.zlogout via vm-setup.sh

### Documentation Cleanup (Complete)
- [x] Clean up AGENTS.md (CLAUDE.md symlinks to it)
  - [x] Change internal refs from CLAUDE.md to AGENTS.md
  - [x] Merge duplicate Command Execution Policy sections
  - [x] Review for inconsistencies (fixed Step numbering in documentation-only exception)
  - [x] Add TDD (Test-Driven Development) to 8-step workflow Step 1
- [x] Restructure docs for progressive disclosure and token optimization
  - [x] Create docs/WORKFLOW.md for detailed git workflow procedures
  - [x] Slim AGENTS.md to core rules only (445→76 lines, 86% reduction)
  - [x] Move detailed procedures to WORKFLOW.md (read on-demand when committing)
- [x] Comprehensive documentation update based on ADR-002
  - [x] Update all docs to reference ADR-002 as operational guide
  - [x] Simplify existing docs for progressive disclosure
  - [x] Note Cursor CLI VM incompatibility throughout
  - [x] Update README, SPEC, architecture, bootstrap, cli, proxy, roadmap, vm-detection, AGENTS, PLAN
- [x] Add Merge PR workflow (8-step with approvals)
  - [x] Add to workflow mode table in CLAUDE.md
  - [x] Document 8-step merge procedure in CLAUDE.md
  - [x] Add to WORKFLOW.md with detailed procedures
  - [x] Update session start workflow lists
- [x] Add Test PR workflow (7-step manual testing gate)
  - [x] Add to workflow mode table in CLAUDE.md and AGENTS.md
  - [x] Document 7-step test procedure in CLAUDE.md and AGENTS.md
  - [x] Add to WORKFLOW.md with detailed procedures
  - [x] Update session start workflow lists
  - [x] Add "Tested" section to STATUS.md between "Reviewed" and "Merged"
  - [x] Update Merge PR workflow to read from "Tested" instead of "Reviewed"
  - [x] Create comprehensive PR workflow diagram (PR-WORKFLOW-DIAGRAM.md)
  - [x] Verify all workflows update PLAN.md and return to main branch
- [x] **Workflow Documentation Improvements**
  - [x] Rename "Standard" workflow to "Interactive" throughout all documentation
  - [x] Rename STATUS.md section headings: "Awaiting Review" → "Needs Review", "Awaiting Changes" → "Needs Changes", "Reviewed" → "Needs Testing", "Tested" → "Needs Merging"
  - [x] Split workflow documentation into separate files for each workflow
    - [x] Create docs/WORKFLOW-CREATE-PR.md for Create PR workflow details
    - [x] Create docs/WORKFLOW-REVIEW-PR.md for Review PR workflow details
    - [x] Create docs/WORKFLOW-UPDATE-PR.md for Update PR workflow details
    - [x] Create docs/WORKFLOW-TEST-PR.md for Test PR workflow details
    - [x] Create docs/WORKFLOW-MERGE-PR.md for Merge PR workflow details
    - [x] Create docs/WORKFLOW-INTERACTIVE.md for Interactive workflow details
    - [x] Create docs/WORKFLOW-DOCUMENTATION.md for Documentation workflow details
    - [x] Create docs/WORKFLOWS.md as index listing all workflows with references to detail files
    - [x] Update CLAUDE.md to reference new workflow detail files
  - [x] Emphasize in all workflow docs: PLAN.md and STATUS.md changes must be done on main branch, not PR branch
  - [x] Emphasize in all workflow docs: PR comments must use heredoc format to preserve formatting (gh pr comment/review --body "$(cat <<'EOF' ... EOF)")
  - [x] Consolidate useful content from old WORKFLOW.md into WORKFLOWS.md, then remove WORKFLOW.md
    - [x] Read WORKFLOW.md and identify useful content not yet in WORKFLOWS.md
    - [x] Incorporate useful items into WORKFLOWS.md
    - [x] If conflicts exist, WORKFLOWS.md is the source of truth
    - [x] Remove WORKFLOW.md after consolidation is complete
- [x] **Add Refine Workflow** (New workflow type - refine PLAN.md TODOs for implementation)
  - [x] Create docs/WORKFLOW-REFINE.md documenting the Refine workflow
    - Purpose: Refine TODOs in PLAN.md to ensure implementation-ready
    - Process: Read TODO, ask clarifying questions, gather all requirements
    - Outcome: Prefix TODO with "REFINED" once user confirms completeness
    - Target: TODOs in PLAN.md that need detailed requirements before coding
  - [x] Add Refine workflow to WORKFLOWS.md index and quick reference table
  - [x] Add Refine workflow to CLAUDE.md workflow mode table and session start checklist
  - [x] Rename PRS.md to STATUS.md (Refine workflow uses STATUS.md to track refined items)
  - [x] Update all references from PRS.md to STATUS.md throughout documentation
  - [x] Update STATUS.md structure to support tracking refined TODOs (add "Refined" section)

---

## Testing Issues Found & Fixed

- [x] vm_exists() initially used grep -qw which didn't work reliably - fixed with awk column match
- [x] vm_exists() and vm_running() awk syntax incompatible with BSD awk - fixed with flag variable pattern
- [x] vm_running() used grep which could match partial names - fixed with awk column-specific matching
- [x] Double confirmation prompt on restore - fixed by consolidating to single prompt after git check
- [x] Triple duplicate git check blocks in restore - consolidated to single check
- [x] Git check only ran if VM already running - now always boots VM to check before restore
- [x] Git search limited to ~/workspace - expanded to ~/workspace, ~/projects, ~/repos, ~/code, + ~ maxdepth 2
- [x] $vm_to_run undefined variable in do_restart - fixed to use $VM_DEV
- [x] Missing Screen Sharing hint in do_restart - added for parity with do_run
- [x] Delete only warned for cal-dev - added warnings for cal-clean and cal-init
- [x] Argument parsing `shift || true` showed error in zsh - fixed with `[[ $# -gt 0 ]] && shift`
- [x] Unpushed commits detection requires proper git upstream tracking to be set - working as designed (has prerequisites)
- [x] cal-bootstrap snapshot delete unnecessarily stops cal-dev if already running before checking git changes (should skip stop if VM already running) - **FIXED**: Removed premature stop, git check now intelligently handles VM state
