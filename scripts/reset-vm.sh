#!/bin/bash

set -e

# Script to reset a VM from a pristine snapshot
# Usage: ./reset-vm.sh <vm-name> <pristine-name>
# Optional: Set TART_PATH environment variable to specify tart location
#
# TODO: Add cleanup trap for background VM process
# TODO: Automate SSH/SCP password authentication (use ssh-copy-id or sshpass)
# TODO: Make VM credentials configurable via environment variable
# TODO: Add --yes flag to skip confirmation prompt for automation
# TODO: Run shellcheck and address warnings

if [ $# -ne 2 ]; then
    echo "Usage: $0 <vm-name> <pristine-name>"
    echo "Example: $0 cal-dev cal-dev-pristine"
    exit 1
fi

VM_NAME="$1"
PRISTINE_NAME="$2"

# Determine tart command location
if [ -n "$TART_PATH" ] && [ -x "$TART_PATH" ]; then
    TART="$TART_PATH"
elif [ -x "./temp/tart.app/Contents/MacOS/tart" ]; then
    TART="./temp/tart.app/Contents/MacOS/tart"
elif [ -x "./tart.app/Contents/MacOS/tart" ]; then
    TART="./tart.app/Contents/MacOS/tart"
elif command -v tart &>/dev/null; then
    TART="tart"
else
    echo "❌ Error: tart not found"
    echo ""
    echo "   Please install tart or set TART_PATH environment variable:"
    echo ""
    echo "   Option 1 - Install via Homebrew (recommended):"
    echo "     brew install cirruslabs/cli/tart"
    echo ""
    echo "   Option 2 - Use TART_PATH environment variable:"
    echo "     export TART_PATH=/path/to/tart.app/Contents/MacOS/tart"
    echo "     $0 $*"
    echo ""
    echo "   Option 3 - Run from directory containing tart.app:"
    echo "     cd /directory/with/tart.app"
    echo "     /path/to/reset-vm.sh $*"
    echo ""
    exit 1
fi

echo "🔄 CAL VM Reset Script"
echo "======================"
echo ""
echo "VM Name: $VM_NAME"
echo "Pristine: $PRISTINE_NAME"
echo ""

# Step 1: Delete the modified VM
echo "1️⃣  Deleting modified VM..."
if "$TART" list | grep -qw "${VM_NAME}"; then
    echo ""
    echo "  ⚠️  This will permanently delete VM: $VM_NAME"
    echo "      All changes in the VM will be lost!"
    echo ""
    read -p "  Continue? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  ✗ Aborted by user"
        exit 1
    fi

    # Stop VM if running
    if "$TART" list | grep -w "${VM_NAME}" | grep -q "running"; then
        echo "  → Stopping running VM..."
        "$TART" stop "$VM_NAME"
        sleep 2
    fi

    echo "  → Deleting $VM_NAME..."
    "$TART" delete "$VM_NAME"
    echo "  ✓ VM deleted"
else
    echo "  ✓ VM doesn't exist, skipping delete"
fi

# Step 2: Clone from pristine
echo ""
echo "2️⃣  Cloning from pristine snapshot..."
if ! "$TART" list | grep -qw "${PRISTINE_NAME}"; then
    echo "  ❌ Error: Pristine VM '$PRISTINE_NAME' not found"
    echo "     Available VMs:"
    "$TART" list | sed 's/^/       /'
    exit 1
fi

"$TART" clone "$PRISTINE_NAME" "$VM_NAME"
echo "  ✓ VM cloned from $PRISTINE_NAME"

# Step 3: Start VM in background
echo ""
echo "3️⃣  Starting VM in background..."
"$TART" run --no-graphics "$VM_NAME" &
TART_PID=$!
echo "  ✓ VM started (PID: $TART_PID)"

# Step 4: Wait for VM to boot and get IP
echo ""
echo "4️⃣  Waiting for VM to boot and obtain IP..."
MAX_WAIT=60
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 2))

    VM_IP=$("$TART" ip "$VM_NAME" 2>/dev/null || echo "")

    if [ -n "$VM_IP" ]; then
        echo "  ✓ VM IP: $VM_IP"
        break
    fi

    printf "  ⏳ Waiting... (%ds/%ds)\r" "$WAIT_COUNT" "$MAX_WAIT"
done

if [ -z "$VM_IP" ]; then
    echo ""
    echo "  ⚠️  Could not obtain IP after ${MAX_WAIT}s"
    echo "     VM may still be booting. Check manually with: $TART ip $VM_NAME"
    exit 1
fi

# Step 5: Wait for SSH to be available
echo ""
echo "5️⃣  Waiting for SSH to be available..."
MAX_WAIT=60
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           admin@"$VM_IP" "echo ok" &>/dev/null; then
        echo "  ✓ SSH is ready"
        break
    fi

    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 2))
    printf "  ⏳ Waiting for SSH... (%ds/%ds)\r" "$WAIT_COUNT" "$MAX_WAIT"
done

if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    echo ""
    echo "  ⚠️  SSH not available after ${MAX_WAIT}s"
    echo "     Try connecting manually with: ssh admin@$VM_IP"
    exit 1
fi

# Step 6: Copy vm-setup script to VM
echo ""
echo "6️⃣  Copying vm-setup script to VM..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$SCRIPT_DIR/vm-setup.sh" ]; then
    if scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           "$SCRIPT_DIR/vm-setup.sh" admin@"$VM_IP":~/ &>/dev/null; then
        echo "  ✓ vm-setup.sh copied to VM"
    else
        echo "  ⚠️  Failed to copy vm-setup.sh"
    fi
else
    echo "  ⚠️  vm-setup.sh not found at $SCRIPT_DIR/vm-setup.sh"
fi

# Summary
echo ""
echo "✅ VM Reset Complete!"
echo ""
echo "📋 Next steps:"
echo "  1. Connect to VM:"
echo "     ssh admin@$VM_IP"
echo ""
echo "  2. Run setup script in VM:"
echo "     chmod +x ~/vm-setup.sh"
echo "     ~/vm-setup.sh"
echo "     source ~/.zshrc"
echo "     gh auth login"
echo ""
echo "  💡 TODO: Automate these steps in script (requires password-less SSH)"
echo ""
echo "  3. Stop VM when done:"
echo "     $TART stop $VM_NAME"
echo ""
echo "💡 VM is running in background (PID: $TART_PID)"
echo "   To attach to console: $TART run $VM_NAME"
echo ""
