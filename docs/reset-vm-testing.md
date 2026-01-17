# Testing Guide for reset-vm.sh

## Prerequisites: SSH Key Setup (One-Time)

Run each command separately:

```bash
tart run --no-graphics cal-dev-pristine &
```

```bash
TART_PID=$!
```

```bash
sleep 10
```

```bash
VM_IP=$(tart ip cal-dev-pristine)
```

```bash
echo "VM IP: $VM_IP"
```

```bash
ssh-copy-id admin@$VM_IP
```

When prompted, enter: `admin`

Test it worked (should NOT ask for password):

```bash
ssh admin@$VM_IP "echo 'SSH key auth works!'"
```

Clean up:

```bash
tart stop cal-dev-pristine
```

```bash
kill $TART_PID 2>/dev/null || true
```

---

## Test 1: Basic Functionality

```bash
scripts/reset-vm.sh cal-dev cal-dev-pristine
```

**Expected results:**
- Prompts for confirmation (y/n)
- NO password prompts
- VM stays running at end
- Can SSH in afterward

Verify VM is accessible:

```bash
ssh admin@$(tart ip cal-dev)
```

Type `exit` to disconnect.

Stop VM:

```bash
tart stop cal-dev
```

---

## Test 2: Non-Interactive Mode

```bash
scripts/reset-vm.sh --yes cal-dev cal-dev-pristine
```

**Expected results:**
- NO confirmation prompt
- NO password prompts
- Completes automatically

Stop VM:

```bash
tart stop cal-dev
```

---

## Test 3: Skip Automated Setup

```bash
SKIP_POST_SETUP=true scripts/reset-vm.sh --yes cal-dev cal-dev-pristine
```

**Expected results:**
- Faster (skips vm-setup.sh execution)
- Copies vm-setup.sh but doesn't run it

Stop VM:

```bash
tart stop cal-dev
```

---

## Test 4: Cleanup Trap (Ctrl+C)

```bash
scripts/reset-vm.sh cal-dev cal-dev-pristine
```

When you see "Waiting for VM to boot", press `Ctrl+C`

**Expected results:**
- Shows "🧹 Cleaning up background VM process"
- VM stops

Verify no orphaned processes:

```bash
ps aux | grep tart
```

Should only show the grep command itself.

---

## Test Results

Mark which tests passed:

- [ ] Test 1: Basic functionality
- [ ] Test 2: Non-interactive mode
- [ ] Test 3: Skip automated setup
- [ ] Test 4: Cleanup trap

**If all pass:** Report success!

**If any fail:** Copy the error output and report it.
