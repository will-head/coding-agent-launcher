# Phase 5 (TUI & Polish) - TODOs

> [← Back to PLAN.md](../PLAN.md)

**Status:** Not Started

**Goal:** Full terminal UI experience.

**Deliverable:** Complete TUI for CAL.

---

## 5.1 Workspace Selector

**Tasks:**
1. Interactive list of workspaces
2. Show status (running/stopped)
3. Quick actions (start, stop, ssh, run)

---

## 5.2 Real-time Status

**Tasks:**
1. VM resource usage
2. Active processes
3. Git status
4. Environment status

---

## 5.3 Log Streaming

**Tasks:**
1. `cal isolation logs <workspace> --follow`
2. Build log capture
3. Agent output capture

---

## 5.4 Multiple VMs

**Tasks:**
1. Support running multiple VMs simultaneously
2. Apple limits: max 2 concurrent VMs
3. VM switching in TUI

---

## 5.5 Session State Management

**Goal:** Enable seamless session recovery and continuation across interruptions.

**Tasks:**
1. Implement constant context state persistence
2. Write context to file after every operation
3. Enable seamless session recovery on crash or usage limits
4. Allow session continuation across Claude Code restarts

**Note:** Moved from Phase 0 (originally section 0.11) to Phase 5 as this is a polish/UX enhancement rather than bootstrap requirement.
