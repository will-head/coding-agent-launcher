# tmux Agent Compatibility Testing

> Test plan for verifying AI coding agents work correctly in tmux sessions
>
> **Status:** Testing Required  
> **Date:** January 18, 2026

## Purpose

Verify that Claude Code, Cursor agent, and opencode all function correctly when run inside tmux sessions, with no degradation of terminal features or interactive capabilities.

## Test Environment

```bash
# Start VM with tmux
./scripts/calf-bootstrap --run

# Inside VM, verify tmux is active
echo $TMUX  # Should output socket path
tmux -V     # Should show tmux version
```

## Test Cases

### Test 1: Claude Code in tmux

**Objective:** Verify Claude Code TUI works correctly

**Steps:**
1. Inside tmux session: `claude`
2. Verify TUI renders correctly
3. Test interactive features:
   - Arrow key navigation works
   - Text input works
   - Ctrl+C interrupts properly
   - Colors render correctly
   - Window resizing works (resize terminal, check if TUI adapts)
4. Run a simple task: "Create a hello.txt file with 'Hello World'"
5. Exit cleanly (Ctrl+D or exit command)

**Expected Result:**
- ✅ TUI renders without artifacts
- ✅ All keybindings work
- ✅ Colors display correctly
- ✅ Agent completes task successfully
- ✅ Clean exit

**Known Considerations:**
- Claude Code likely uses blessed/node TUI
- Should work with TERM=screen-256color (set by tmux config)

---

### Test 2: Cursor agent in tmux

**Objective:** Verify Cursor agent works correctly

**Steps:**
1. Inside tmux session: `agent`
2. Verify authentication works (keychain should be unlocked)
3. Test basic interaction:
   - Login status shown correctly
   - Can run commands
   - TUI (if any) renders properly
4. Test with a simple task
5. Exit cleanly

**Expected Result:**
- ✅ Authentication succeeds
- ✅ Commands work normally
- ✅ No terminal corruption
- ✅ Clean exit

**Known Considerations:**
- Cursor agent may use simpler TUI or plain output
- Keychain unlock from calf-bootstrap should still work in tmux

---

### Test 3: opencode in tmux

**Objective:** Verify opencode works correctly

**Steps:**
1. Inside tmux session: `opencode`
2. Verify TUI renders correctly
3. Test interactive features:
   - Navigation works
   - Input works
   - Commands execute
4. Run a simple task
5. Exit cleanly

**Expected Result:**
- ✅ TUI renders without issues
- ✅ All features work
- ✅ Clean exit

**Known Considerations:**
- opencode TUI framework unknown
- Should work with standard terminal settings

---

### Test 4: Session Persistence

**Objective:** Verify sessions survive disconnects

**Steps:**
1. Start agent inside tmux (e.g., `claude`)
2. Start a long-running task
3. Detach from tmux (Ctrl+b d)
4. Exit SSH session
5. Reconnect: `./scripts/calf-bootstrap --run`
6. Verify agent still running and task in progress

**Expected Result:**
- ✅ Agent process survives SSH disconnect
- ✅ Task continues running
- ✅ Can reattach and see current state
- ✅ No data loss

---

### Test 5: Multiple Panes

**Objective:** Verify multiple panes work for simultaneous activities

**Steps:**
1. Inside tmux, split vertically (Ctrl+b |)
2. In left pane: Run an agent task
3. In right pane: Monitor with `top` or `watch`
4. Navigate between panes (Ctrl+b arrow)
5. Verify both panes work independently

**Expected Result:**
- ✅ Panes split correctly
- ✅ Each pane has independent shell
- ✅ Agent works in one pane while other is active
- ✅ Navigation works smoothly

---

### Test 6: Terminal Resizing

**Objective:** Verify TUIs handle terminal resize correctly

**Steps:**
1. Start agent with TUI inside tmux
2. Resize terminal window (drag corners)
3. Verify TUI adapts to new size
4. Make terminal very small, then large
5. Check for rendering artifacts

**Expected Result:**
- ✅ TUI adapts to resize events
- ✅ No rendering corruption
- ✅ Content reflows correctly

---

### Test 7: Copy/Paste Mode

**Objective:** Verify tmux copy mode works

**Steps:**
1. Generate some output (e.g., `ls -la`)
2. Enter copy mode (Ctrl+b [)
3. Navigate with arrows
4. Select text (Space, move, Enter)
5. Paste (Ctrl+b ])

**Expected Result:**
- ✅ Can scroll through history
- ✅ Text selection works
- ✅ Paste works correctly

---

### Test 8: Mouse Support

**Objective:** Verify mouse interactions work

**Steps:**
1. Inside tmux, create multiple panes
2. Click on different panes (should switch focus)
3. Scroll with mouse wheel (should scroll content)
4. Drag pane borders (should resize)
5. Test mouse in agent TUI (if supported)

**Expected Result:**
- ✅ Click switches panes
- ✅ Scroll works
- ✅ Resize works
- ✅ Mouse in TUI works (if agent supports it)

---

### Test 9: Ctrl+C / Ctrl+Z Behavior

**Objective:** Verify signal handling works correctly

**Steps:**
1. Start agent in tmux
2. Send Ctrl+C (interrupt)
3. Verify agent handles it correctly
4. Start agent again
5. Send Ctrl+Z (suspend)
6. Run `jobs` to see suspended job
7. Run `fg` to resume

**Expected Result:**
- ✅ Ctrl+C interrupts agent cleanly
- ✅ Ctrl+Z suspends process
- ✅ Can resume with fg
- ✅ No tmux interference

---

### Test 10: Large Output Handling

**Objective:** Verify large output doesn't cause issues

**Steps:**
1. Inside tmux, generate large output (e.g., `find / 2>/dev/null`)
2. Verify output scrolls correctly
3. Test scrollback (Ctrl+b [)
4. Check memory usage doesn't spike

**Expected Result:**
- ✅ Large output handled smoothly
- ✅ Scrollback accessible
- ✅ No performance degradation

---

## Known Issues and Workarounds

### Issue: Nested tmux Sessions

**Problem:** Accidentally starting tmux inside tmux

**Detection:**
```bash
echo $TMUX  # If set, already in tmux
```

**Workaround:**
- Don't run `tmux` command manually inside tmux
- Use `tmux new-window` (Ctrl+b c) for new windows instead

---

### Issue: Prefix Key Conflict

**Problem:** Ctrl+b is tmux prefix, some agents may use it

**Workaround:**
- Change tmux prefix in ~/.tmux.conf if needed:
  ```bash
  set -g prefix C-a
  unbind C-b
  ```
- Or use double press to send to application: Ctrl+b Ctrl+b

---

### Issue: Terminal Size Mismatch

**Problem:** Agent TUI shows wrong size

**Solution:**
```bash
# Force terminal size update
tmux refresh-client
# Or restart tmux session
```

---

## Test Results Template

```markdown
## Test Results

**Date:** YYYY-MM-DD  
**Tester:** [Name]  
**tmux Version:** [version]  
**VM:** cal-dev

### Claude Code
- [ ] TUI renders correctly
- [ ] Keybindings work
- [ ] Colors correct
- [ ] Task completion works
- [ ] Clean exit
- **Notes:**

### Cursor agent
- [ ] Authentication works
- [ ] Commands work
- [ ] No terminal corruption
- [ ] Clean exit
- **Notes:**

### opencode
- [ ] TUI renders correctly
- [ ] Features work
- [ ] Clean exit
- **Notes:**

### Session Persistence
- [ ] Survives disconnect
- [ ] Task continues
- [ ] Reattach works
- **Notes:**

### Multiple Panes
- [ ] Splits work
- [ ] Independent operation
- [ ] Navigation works
- **Notes:**

### Overall Assessment
- **Status:** [Pass/Fail/Needs Investigation]
- **Recommendation:** [Use tmux by default / Keep optional / More testing needed]
- **Issues Found:** [List any issues]
```

---

## Automated Testing (Future)

For automated CI/CD testing:

```bash
#!/bin/bash
# test-tmux-agents.sh

set -e

echo "Starting tmux agent tests..."

# Test 1: Start tmux session
ssh admin@$(tart ip cal-dev) "tmux new-session -d -s test-session"

# Test 2: Run agent in session
ssh admin@$(tart ip cal-dev) "tmux send-keys -t test-session 'claude --version' C-m"
sleep 2

# Test 3: Capture output
OUTPUT=$(ssh admin@$(tart ip cal-dev) "tmux capture-pane -t test-session -p")
echo "Output: $OUTPUT"

# Test 4: Kill session
ssh admin@$(tart ip cal-dev) "tmux kill-session -t test-session"

echo "Tests complete"
```

---

## Success Criteria

For tmux support to be considered production-ready:

1. ✅ All three agents (claude, agent, opencode) work without issues
2. ✅ Session persistence verified (survives disconnects)
3. ✅ No terminal corruption or rendering artifacts
4. ✅ Keybindings work correctly (no conflicts)
5. ✅ Multiple panes work reliably
6. ✅ No degradation in agent performance
7. ✅ Documentation is clear and complete
8. ✅ No blocking issues found

If any agent has issues:
- Document the specific problem
- Investigate workaround or config change
- Consider making tmux optional (not default) if issues are significant

---

## Rollback Plan

If tmux causes issues:

1. tmux is now default (no flag required)
2. Users can continue using plain SSH: `./scripts/calf-bootstrap --run`
3. Can disable tmux installation in vm-setup.sh if needed
4. Document known issues and workarounds

---

## References

- [tmux documentation](https://github.com/tmux/tmux/wiki)
- [tmux cheat sheet](https://tmuxcheatsheet.com)
- [Terminal keybindings test results](terminal-keybindings-test.md)
- [SSH alternatives investigation](ssh-alternatives-investigation.md)
