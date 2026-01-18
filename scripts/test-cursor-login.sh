#!/bin/zsh

# Test Cursor Agent Login with Keychain Fix
# This script verifies the keychain unlock solution for Cursor agent authentication

VM_IP="${1:-192.168.64.4}"
VM_USER="${2:-admin}"
VM_PASSWORD="${VM_PASSWORD:-admin}"

echo "Testing Cursor Agent Login Fix"
echo "==============================="
echo ""

# Step 1: Check keychain status
echo "1. Checking keychain status..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${VM_USER}@${VM_IP}" \
    "security list-keychains && security default-keychain"
echo ""

# Step 2: Unlock keychain
echo "2. Unlocking keychain..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${VM_USER}@${VM_IP}" \
    "security unlock-keychain -p '${VM_PASSWORD}' login.keychain && echo '✓ Keychain unlocked'" || echo "⚠ Unlock failed"
echo ""

# Step 3: Set keychain timeout (will fail in SSH - requires GUI)
echo "3. Setting keychain timeout to 24 hours..."
echo "   (Note: This typically fails in SSH sessions - GUI access required)"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${VM_USER}@${VM_IP}" \
    "security set-keychain-settings -t 86400 -l login.keychain 2>&1" || echo "   ⚠ Expected failure - requires GUI interaction"
echo ""

# Step 4: Check agent version
echo "4. Verifying agent installation..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${VM_USER}@${VM_IP}" \
    "source ~/.zshrc && agent --version"
echo ""

# Step 5: Check agent auth status
echo "5. Checking agent authentication status..."
echo "   (This will timeout if not logged in, which is expected)"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${VM_USER}@${VM_IP}" \
    "source ~/.zshrc && (agent whoami &); sleep 3; pkill -f '^cursor-agent$' 2>/dev/null || true; wait 2>/dev/null || true" 2>&1 | head -15 || true
echo ""

echo "==============================="
echo "Next Steps:"
echo ""
echo "To complete Cursor agent login:"
echo "1. Open Screen Sharing: open vnc://${VM_IP}"
echo "2. Open Terminal in the VM GUI"
echo "3. Run: agent"
echo "4. Complete the OAuth flow in the browser"
echo ""
echo "With the keychain unlocked, credentials will be stored successfully."
echo ""
echo "Alternative: Use SSH with X forwarding (if browser can be forwarded)"
echo "  ssh -Y ${VM_USER}@${VM_IP}"
echo "  agent login"
