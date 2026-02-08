#!/bin/zsh

# Test script for SMB firewall blocking
# Run this to verify pf rules are blocking SMB access

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo "${BLUE}║  SMB Firewall Blocking Test                   ║${NC}"
echo "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Check if pf is enabled
echo "${BLUE}━━━ Test 1: pf Firewall Status ━━━${NC}"
if sudo pfctl -s info 2>/dev/null | grep -q "Status: Enabled"; then
    echo "${GREEN}✓ pf firewall is enabled${NC}"
else
    echo "${RED}✗ pf firewall is NOT enabled${NC}"
fi
echo ""

# Test 2: Check if CALF anchor exists
echo "${BLUE}━━━ Test 2: CALF Anchor Status ━━━${NC}"
if sudo pfctl -s Anchors 2>/dev/null | grep -q "calf.smb.block"; then
    echo "${GREEN}✓ calf.smb.block anchor exists${NC}"
else
    echo "${RED}✗ calf.smb.block anchor NOT found${NC}"
fi
echo ""

# Test 3: Show anchor rules
echo "${BLUE}━━━ Test 3: Active Blocking Rules ━━━${NC}"
echo "Rules in calf.smb.block anchor:"
sudo pfctl -a calf.smb.block -sr 2>/dev/null || echo "${YELLOW}No rules loaded${NC}"
echo ""

# Test 4: Check anchor file
echo "${BLUE}━━━ Test 4: Anchor File ━━━${NC}"
if [ -f /etc/pf.anchors/calf.smb.block ]; then
    echo "${GREEN}✓ Anchor file exists: /etc/pf.anchors/calf.smb.block${NC}"
    echo ""
    echo "Contents:"
    cat /etc/pf.anchors/calf.smb.block | grep -v '^#' | grep -v '^$'
else
    echo "${RED}✗ Anchor file NOT found${NC}"
fi
echo ""

# Test 5: Check VM bridge interface
echo "${BLUE}━━━ Test 5: VM Bridge Interface ━━━${NC}"
vm_ip=$(tart ip calf-dev 2>/dev/null || echo "")
if [ -z "$vm_ip" ]; then
    echo "${YELLOW}VM not running, cannot detect bridge${NC}"
else
    echo "VM IP: $vm_ip"
    subnet=$(echo "$vm_ip" | sed 's/\.[0-9]*$//')

    for iface in $(ifconfig | grep '^bridge' | cut -d: -f1); do
        bridge_ip=$(ifconfig "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}')
        if [ -n "$bridge_ip" ] && echo "$bridge_ip" | grep -q "^${subnet}\."; then
            echo "${GREEN}✓ Bridge interface: $iface ($bridge_ip)${NC}"
        fi
    done
fi
echo ""

# Test 6: Test SMB connectivity from VM (if running)
echo "${BLUE}━━━ Test 6: SMB Connectivity Test ━━━${NC}"
if [ -n "$vm_ip" ]; then
    echo "Testing SMB port 445 to gateway (192.168.64.1) from VM..."
    echo "This should TIMEOUT (connection blocked by firewall):"
    echo ""

    # Try to connect - should timeout
    if timeout 5 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        admin@$vm_ip "nc -zv 192.168.64.1 445" 2>&1 | tee /tmp/smb-test.log; then
        echo "${RED}✗ FAIL: Connection succeeded (firewall NOT blocking!)${NC}"
    else
        if grep -q "timed out\|refused" /tmp/smb-test.log 2>/dev/null; then
            echo "${GREEN}✓ PASS: Connection blocked (timeout/refused)${NC}"
        else
            echo "${YELLOW}? Result unclear, check manually${NC}"
        fi
    fi
else
    echo "${YELLOW}VM not running, skipping connectivity test${NC}"
fi
echo ""

# Summary
echo "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo "${BLUE}║  Test Complete                                 ║${NC}"
echo "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo "${YELLOW}Expected behavior:${NC}"
echo "  - pf firewall: Enabled"
echo "  - calf.smb.block anchor: Loaded with rules"
echo "  - SMB ports 139/445: Blocked on bridge interface"
echo "  - mDNS port 5353: Blocked on bridge interface"
echo "  - VM connection to SMB: Timeout/refused"
echo ""
