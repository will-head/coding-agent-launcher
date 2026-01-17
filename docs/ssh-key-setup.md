# SSH Key Setup for Password-less VM Access

## Problem

The `reset-vm.sh` script prompts for passwords multiple times during SSH/SCP operations, which defeats automation.

## Solution

Set up SSH key authentication in the pristine VM snapshot so that all cloned VMs inherit password-less SSH access.

## One-Time Setup

### 1. Check if you have an SSH key

```bash
ls ~/.ssh/id_rsa.pub
```

If not found, generate one:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Press Enter to accept all defaults.

### 2. Copy SSH key to pristine VM

Start the pristine VM:

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

Copy your SSH key (will prompt for password ONE TIME):

```bash
ssh-copy-id admin@$VM_IP
```

When prompted, enter password: `admin`

Test password-less login (should NOT prompt for password):

```bash
ssh admin@$VM_IP "echo 'SSH key auth works!'"
```

If that worked without a password, stop the pristine VM:

```bash
tart stop cal-dev-pristine
```

```bash
kill $TART_PID 2>/dev/null || true
```

### 3. Verify it works

Now test reset-vm.sh - should have NO password prompts:

```bash
scripts/reset-vm.sh --yes cal-dev cal-dev-pristine
```

## Alternative: Use sshpass (Less Secure)

If SSH keys don't work, you can use `sshpass`:

```bash
# Install sshpass
brew install hudochenkov/sshpass/sshpass

# Modify reset-vm.sh to use sshpass
# Replace ssh/scp commands with:
sshpass -p "$VM_PASSWORD" ssh ...
sshpass -p "$VM_PASSWORD" scp ...
```

**Note:** This is less secure as the password is visible in process lists.

## Troubleshooting

### SSH Keys Not Working

Check VM permissions:

```bash
ssh admin@$VM_IP
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
exit
```

### Keys Lost After Clone

Tart should preserve SSH keys in clones. If not, the pristine VM may need its disk flushed:

```bash
# In pristine VM, ensure changes are written
sync
# Then stop cleanly
tart stop cal-dev-pristine
```
