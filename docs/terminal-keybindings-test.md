# Terminal Keybindings Test Plan

> Investigation of terminal keybindings in Tart VM SSH environment
>
> **Status:** In Progress  
> **Date:** January 17, 2026

## Purpose

Test and document which terminal keybindings work correctly when SSHing into the Tart VM, and identify any that need fixing in `vm-setup.sh`.

## Current Known Fixes

Already implemented in `vm-setup.sh`:
- ✅ **TERM setting:** `export TERM=xterm-256color` (fixes delete key)
- ✅ **Up arrow:** `bindkey "^[[A" up-line-or-history` (fixes history navigation)

## Test Environment

**Test Command:**
```bash
ssh admin@$(tart ip cal-dev)
```

**Alternative (with terminal allocation):**
```bash
ssh -t admin@$(tart ip cal-dev)
```

## Test Categories

### 1. Basic Navigation Keys

| Key | Expected Behavior | Status | Notes |
|-----|------------------|--------|-------|
| Up Arrow | Previous history entry | ✅ FIXED | Fixed via bindkey |
| Down Arrow | Next history entry | ✅ WORKS | Standard terminal |
| Left Arrow | Move cursor left | ✅ WORKS | Standard terminal |
| Right Arrow | Move cursor right | ✅ WORKS | Standard terminal |
| Home | Move to line start | ✅ WORKS | Sends Ctrl+A (Emacs) |
| End | Move to line end | ✅ WORKS | Sends Ctrl+E (Emacs) |
| Page Up | Scroll up | ✅ WORKS | Terminal scrollback |
| Page Down | Scroll down | ✅ WORKS | Terminal scrollback |

### 2. Editing Keys

| Key | Expected Behavior | Status | Notes |
|-----|------------------|--------|-------|
| Delete | Delete character under cursor | ✅ FIXED | Fixed via TERM |
| Backspace | Delete character before cursor | ✅ WORKS | Standard terminal |
| Ctrl+K | Kill (delete) to end of line | ✅ WORKS | Standard Emacs |
| Ctrl+U | Kill to beginning of line | ✅ WORKS | Standard Emacs |
| Ctrl+W | Delete previous word | ✅ WORKS | Standard Emacs |
| Ctrl+Y | Yank (paste) killed text | ✅ WORKS | Standard Emacs |

### 3. Cursor Movement (Emacs-style)

| Key | Expected Behavior | Status | Notes |
|-----|------------------|--------|-------|
| Ctrl+A | Move to line start | ✅ WORKS | Confirmed working |
| Ctrl+E | Move to line end | ✅ WORKS | Confirmed working |
| Ctrl+B | Move backward one character | ✅ WORKS | Standard Emacs |
| Ctrl+F | Move forward one character | ✅ WORKS | Standard Emacs |
| Ctrl+P | Previous history entry | ✅ WORKS | Standard Emacs |
| Ctrl+N | Next history entry | ✅ WORKS | Standard Emacs |

### 4. Word Navigation

| Key | Expected Behavior | Status | Notes |
|-----|------------------|--------|-------|
| Alt+Left / Opt+Left | Move back one word | ✅ WORKS | Sends ESC+b (detected) |
| Alt+Right / Opt+Right | Move forward one word | ✅ WORKS | Sends ESC+f (detected) |
| Alt+Backspace / Opt+Backspace | Delete previous word | ✅ WORKS | Sends ESC+DEL (detected) |
| Alt+D / Opt+D | Delete next word | ⏳ TEST | Need to test |
| Ctrl+Left | Move back one word | ⏳ TEST | Alternative |
| Ctrl+Right | Move forward one word | ⏳ TEST | Alternative |

### 5. Special Functions

| Key | Expected Behavior | Status | Notes |
|-----|------------------|--------|-------|
| Ctrl+C | Interrupt/Cancel | ✅ WORKS | Standard signal |
| Ctrl+D | EOF / Exit shell | ✅ WORKS | Standard signal |
| Ctrl+Z | Suspend process | ✅ WORKS | Standard signal |
| Ctrl+L | Clear screen | ✅ WORKS | Standard terminal |
| Ctrl+R | Reverse history search | ✅ WORKS | ZSH feature |
| Tab | Command/filename completion | ✅ WORKS | ZSH feature |

### 6. Advanced ZSH Features

| Key | Expected Behavior | Status | Notes |
|-----|------------------|--------|-------|
| Ctrl+X Ctrl+E | Edit command in $EDITOR | ⏳ TEST | |
| Alt+. / Opt+. | Insert last argument | ⏳ TEST | Useful shortcut |
| Alt+# / Opt+# | Comment line, add to history | ⏳ TEST | |

## Test Procedure

### Step 1: Set Up Test Environment

```bash
# On host
tart run cal-dev --no-graphics &
sleep 30

# SSH into VM
ssh admin@$(tart ip cal-dev)
```

### Step 2: Test Each Category

For each test:
1. Try the keybinding
2. Note if it works as expected
3. If broken, capture the actual behavior
4. Document the escape sequence (if visible)

### Step 3: Capture Escape Sequences

For broken keys, use `cat` to see raw escape sequences:

```bash
# In VM
cat -v
# Press the key, observe output
# Example: Up arrow shows ^[[A
# Ctrl+C to exit
```

Or use this test script:

```bash
# Save as test-keys.sh in VM
#!/bin/bash
echo "Press any key (Ctrl+C to exit):"
while true; do
    read -rsn1 key
    printf "Key pressed: %q\n" "$key"
done
```

### Step 4: Test in Different Contexts

Test keybindings in:
- [ ] Raw zsh prompt
- [ ] Inside a text editor (vim, nano)
- [ ] Inside an agent session (claude, agent, opencode)
- [ ] Inside a running process (like `less`, `man`)

## Expected Issues

Based on common SSH terminal problems:

**Likely to be broken:**
- Alt/Option key combinations (macOS sends different sequences)
- Function keys (F1-F12)
- Ctrl+Arrow combinations
- Home/End keys (vary by terminal emulator)

**Usually work fine:**
- Basic Ctrl+key combinations
- Letter keys, numbers, symbols
- Basic arrow keys
- Tab completion

## Fixes to Implement

Document any required fixes in this format:

```bash
# Fix for <key>: <description>
bindkey "<escape-sequence>" <widget>
```

Example:
```bash
# Fix for down arrow: next history entry
bindkey "^[[B" down-line-or-history
```

## Testing Tools

Useful commands for investigation:

```bash
# Show current key bindings
bindkey

# Show specific binding
bindkey "^[[A"

# Show all zsh widgets
zle -la

# Test terminal capabilities
infocmp

# Show current TERM value
echo $TERM
```

## Results Summary

**Test Date:** January 17, 2026  
**Test Environment:** Tart VM via SSH (macOS host)

### Working Keys

**Navigation:**
- ✅ Up Arrow - Previous history (FIXED via bindkey)
- ✅ Down Arrow - Standard terminal behavior
- ✅ Left/Right Arrow - Standard cursor movement
- ✅ Home - Sends Ctrl+A (Emacs binding, moves to line start)
- ✅ End - Sends Ctrl+E (Emacs binding, moves to line end)
- ✅ Page Up/Down - Terminal scrollback

**Editing:**
- ✅ Delete - (FIXED via TERM=xterm-256color)
- ✅ Backspace - Standard terminal
- ✅ Ctrl+K/U/W/Y - Standard Emacs editing

**Cursor Movement (Emacs-style):**
- ✅ Ctrl+A/E - Line start/end (confirmed)
- ✅ Ctrl+B/F/P/N - Standard Emacs navigation

**Word Navigation (Option/Alt keys):**
- ✅ Option+Left - Backward word (sends ESC+b)
- ✅ Option+Right - Forward word (sends ESC+f)
- ✅ Option+Backspace - Delete word backward (sends ESC+DEL)

**Special Functions:**
- ✅ Ctrl+C/D/Z/L - Signal handling
- ✅ Ctrl+R - Reverse search
- ✅ Tab - Completion

### Broken Keys

None identified. All tested keys are working correctly.

### Keys Not Yet Tested

- ⏳ Option+D (delete word forward)
- ⏳ Ctrl+Arrow combinations
- ⏳ Ctrl+X Ctrl+E (edit in $EDITOR)
- ⏳ Option+. (insert last argument)

### Required Fixes

**None currently identified.**

The current fixes in `vm-setup.sh` are sufficient:
- `export TERM=xterm-256color` - Fixes delete key
- `bindkey "^[[A" up-line-or-history` - Fixes up arrow history

**Note:** ZSH already has default bindings for ESC+b, ESC+f, and ESC+DEL (the sequences sent by Option+Arrow and Option+Backspace), so these work out of the box.

### Raw Escape Sequences Captured

```
Option+Left:      ESC + b (0x1b 0x62)
Option+Right:     ESC + f (0x1b 0x66)
Option+Backspace: ESC + DEL (0x1b 0x7f)
```

These match standard Emacs/readline conventions and are already bound in ZSH by default.

### Testing Notes

1. **Home/End behavior:** Correctly send Ctrl+A and Ctrl+E (Emacs-style). No fix needed.

2. **Terminal-level keys:** All basic keys work at the terminal level.

3. **Option/Alt keys:** Successfully transmit as ESC+key sequences, which ZSH recognizes natively.

4. **Conclusion:** The VM terminal environment is fully functional for development work. No additional keybinding fixes are needed beyond the two already in `vm-setup.sh`.

## References

- [ZSH Line Editor (ZLE) Documentation](http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html)
- [ZSH Key Bindings](http://zsh.sourceforge.net/Guide/zshguide04.html)
- [Terminal Escape Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
