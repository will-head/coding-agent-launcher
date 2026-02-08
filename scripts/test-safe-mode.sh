#!/bin/bash
# Smoke test for --safe-mode (and --no-network) implementation
# VERSION: 3.0 (SAFE - never deletes VMs)
#
# Tests:
#   1. VM exists (prerequisite)
#   2. Host marker files exist
#   3. Status shows safe mode
#   4. VM boots and SSH works
#   5. Internet connectivity (DNS, HTTPS)
#   6. Local network blocked
#   7. No host mounts present
#   8. VM config file correct
#   9. Persistence across restart
#
# Usage:
#   ./test-safe-mode.sh           # Run all tests
#
# NOTE: Does NOT create or delete VMs - run calf-bootstrap --init first

# No set -e: test scripts handle errors explicitly
# No set -u: avoids issues with unset variables in conditionals

# Trap CTRL-C per-test (does not kill the whole script)
trap 'echo ""; echo "  Test interrupted - continuing..."; echo ""' INT

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CALF_BOOTSTRAP="${SCRIPT_DIR}/calf-bootstrap"
VM_DEV="calf-dev"
VM_USER="admin"
TART="${TART:-tart}"
VM_IP=""

# SSH options used everywhere
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters (global - no local keyword)
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

pass() { echo -e "  ${GREEN}✓ PASS${NC}: $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC}: $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
skip() { echo -e "  ${YELLOW}⊘ SKIP${NC}: $1"; TESTS_SKIPPED=$((TESTS_SKIPPED + 1)); }
info() { echo -e "  ${BLUE}ℹ${NC} $1"; }

# Run an SSH command on the VM with output captured
# Usage: result=$(vm_run "command")
vm_run() {
    ssh $SSH_OPTS "$VM_USER@$VM_IP" "$1" 2>/dev/null
}

# Run an SSH command on the VM with a hard timeout (kills from host side)
# Returns 0 if command succeeded within timeout, 1 otherwise
# Usage: vm_run_timeout 5 "ping -c 1 192.168.1.1"
vm_run_timeout() {
    local secs="$1"
    local cmd="$2"

    # Run SSH in background
    ssh $SSH_OPTS "$VM_USER@$VM_IP" "$cmd" &>/dev/null &
    local ssh_pid=$!

    # Start a kill timer in background
    ( sleep "$secs" && kill "$ssh_pid" 2>/dev/null ) &
    local timer_pid=$!

    # Wait for SSH to finish (either command completed or timer killed it)
    wait "$ssh_pid" 2>/dev/null
    local exit_code=$?

    # Clean up timer (if SSH finished before timeout)
    kill "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null

    return $exit_code
}

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  CALF Safe Mode Smoke Test v3.0"
echo "  (SAFE - never deletes VMs)"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ─── Prerequisites ────────────────────────────────────────────

echo "Checking prerequisites..."

if [ ! -f "$CALF_BOOTSTRAP" ]; then
    echo "  calf-bootstrap not found at: $CALF_BOOTSTRAP"
    exit 1
fi
info "Found: $CALF_BOOTSTRAP"

if ! command -v "$TART" &>/dev/null; then
    echo "  tart not found"
    exit 1
fi
info "Found: $(which "$TART")"

if ! command -v softnet &>/dev/null; then
    echo "  softnet not found (required for --no-network)"
    echo "  Install with: brew install cirruslabs/cli/softnet"
    exit 1
fi
info "Found: $(which softnet)"

softnet_path=$(which softnet)
if [ ! -u "$softnet_path" ]; then
    echo "  softnet SUID bit not set"
    echo "  Run: sudo chown root:wheel $softnet_path && sudo chmod u+s $softnet_path"
    exit 1
fi
info "Softnet SUID: OK"

echo ""

# ═══════════════════════════════════════════════════════════════
# Test 1: VM exists
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 1: VM Prerequisites"
echo "═══════════════════════════════════════════════════════════"
echo ""

if ! "$TART" list 2>/dev/null | awk 'NR>1 {print $2}' | grep -q "^calf-dev$"; then
    echo "  calf-dev does not exist"
    echo ""
    echo "  Run this first:"
    echo "    ./calf-bootstrap --init --safe-mode --yes"
    echo ""
    exit 1
fi

info "calf-dev exists"
pass "VM prerequisites met"
echo ""

# ═══════════════════════════════════════════════════════════════
# Test 2: Host marker files
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 2: Host marker files"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ -f ~/.calf-vm-no-mount ]; then
    pass "~/.calf-vm-no-mount exists"
else
    fail "~/.calf-vm-no-mount missing"
fi

if [ -f ~/.calf-vm-no-network ]; then
    pass "~/.calf-vm-no-network exists"
else
    fail "~/.calf-vm-no-network missing"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Test 3: Status display
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 3: Status display"
echo "═══════════════════════════════════════════════════════════"
echo ""

status_output=$("$CALF_BOOTSTRAP" --status 2>&1 || true)
echo "$status_output" | grep -A 5 "calf-dev" || true

if echo "$status_output" | grep -qi "safe mode\|no mounts.*network isolated"; then
    pass "Status shows safe mode"
else
    fail "Status does not show safe mode"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Test 4: VM boot and SSH
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 4: VM boot and SSH connectivity"
echo "═══════════════════════════════════════════════════════════"
echo ""

if "$TART" list 2>/dev/null | awk -v vm="$VM_DEV" 'NR>1 { if ($2 == vm && $NF == "running") { found=1; exit } } END { exit !found }'; then
    info "VM already running"
else
    info "Starting VM in background..."
    "$TART" run --no-graphics "$VM_DEV" &>/dev/null &
    sleep 5
fi

info "Waiting for VM IP..."
VM_IP=""
for i in $(seq 1 30); do
    VM_IP=$("$TART" ip "$VM_DEV" 2>/dev/null || echo "")
    if [ -n "$VM_IP" ]; then
        break
    fi
    sleep 2
done

if [ -z "$VM_IP" ]; then
    fail "VM did not get an IP address"
    echo "  Cannot continue without VM IP"
    exit 1
fi

info "VM IP: $VM_IP"

info "Testing SSH..."
if vm_run "echo ok" >/dev/null 2>&1; then
    pass "SSH works"
else
    fail "SSH failed"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Test 5: Internet connectivity
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 5: Internet connectivity (should work)"
echo "═══════════════════════════════════════════════════════════"
echo ""

info "Testing DNS resolution..."
dns_result=$(vm_run "nslookup github.com 2>/dev/null | grep 'Address:' | tail -1" || echo "")
if [ -n "$dns_result" ]; then
    pass "DNS works: $dns_result"
else
    fail "DNS failed"
fi

info "Testing HTTPS to github.com..."
http_code=$(vm_run "curl -s --connect-timeout 5 -o /dev/null -w '%{http_code}' https://github.com" || echo "000")
if [ "$http_code" != "000" ]; then
    pass "HTTPS works (HTTP $http_code)"
else
    fail "HTTPS failed"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Test 6: Local network blocked
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 6: Local network isolation (should be blocked)"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Get host's real network gateway (not the VM bridge)
HOST_GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}' || echo "")

if [ -n "$HOST_GATEWAY" ]; then
    info "Testing ping to host gateway: $HOST_GATEWAY (5s timeout)..."
    if vm_run_timeout 5 "ping -c 1 -W 3000 $HOST_GATEWAY"; then
        fail "Local network NOT blocked (can ping $HOST_GATEWAY)"
    else
        pass "Local network blocked (cannot reach $HOST_GATEWAY)"
    fi
else
    skip "Cannot determine host gateway IP"
fi

info "Testing ping to 192.168.1.1 (5s timeout)..."
if vm_run_timeout 5 "ping -c 1 -W 3000 192.168.1.1"; then
    info "192.168.1.1: reachable (may not exist on this network)"
else
    pass "192.168.1.1 blocked or unreachable"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Test 7: No host mounts
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 7: Host mounts (should be absent)"
echo "═══════════════════════════════════════════════════════════"
echo ""

tart_cache_check=$(vm_run "ls -d '/Volumes/My Shared Files/tart-cache' 2>/dev/null || echo 'NOT_FOUND'" || echo "SSH_FAILED")

if [ "$tart_cache_check" = "NOT_FOUND" ]; then
    pass "No tart-cache mount"
elif [ "$tart_cache_check" = "SSH_FAILED" ]; then
    skip "Cannot check mounts (SSH failed)"
else
    fail "tart-cache mount present: $tart_cache_check"
fi

calf_cache_check=$(vm_run "mount | grep calf-cache || echo 'NOT_FOUND'" || echo "SSH_FAILED")

if echo "$calf_cache_check" | grep -q "NOT_FOUND"; then
    pass "No calf-cache mount"
elif [ "$calf_cache_check" = "SSH_FAILED" ]; then
    skip "Cannot check calf-cache (SSH failed)"
else
    fail "calf-cache mount present"
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Test 8: VM config file
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 8: VM config file (~/.calf-vm-config)"
echo "═══════════════════════════════════════════════════════════"
echo ""

vm_config=$(vm_run "cat ~/.calf-vm-config 2>/dev/null || echo 'NOT_FOUND'" || echo "SSH_FAILED")

if [ "$vm_config" = "SSH_FAILED" ]; then
    skip "Cannot read VM config (SSH failed)"
elif [ "$vm_config" = "NOT_FOUND" ]; then
    fail "VM config file missing"
else
    info "VM config contents:"
    echo "$vm_config" | sed 's/^/      /'

    if echo "$vm_config" | grep -q "NO_MOUNT=true"; then
        pass "NO_MOUNT=true in config"
    else
        fail "NO_MOUNT=true not found in config"
    fi

    if echo "$vm_config" | grep -q "NO_NETWORK=true"; then
        pass "NO_NETWORK=true in config"
    else
        fail "NO_NETWORK=true not found in config"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Test 9: Persistence across restart
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test 9: Persistence across VM restart"
echo "═══════════════════════════════════════════════════════════"
echo ""

info "Stopping VM..."
"$TART" stop "$VM_DEV" 2>/dev/null || true
sleep 2

info "Starting VM again..."
"$TART" run --no-graphics "$VM_DEV" &>/dev/null &
sleep 5

info "Waiting for VM IP..."
VM_IP=""
for i in $(seq 1 30); do
    VM_IP=$("$TART" ip "$VM_DEV" 2>/dev/null || echo "")
    if [ -n "$VM_IP" ]; then
        break
    fi
    sleep 2
done

if [ -z "$VM_IP" ]; then
    fail "VM did not restart properly"
else
    info "VM IP: $VM_IP"

    # Wait for SSH to come up after restart
    info "Waiting for SSH..."
    ssh_ok=false
    for i in $(seq 1 15); do
        if vm_run "echo ok" >/dev/null 2>&1; then
            ssh_ok=true
            break
        fi
        sleep 2
    done

    if [ "$ssh_ok" = true ]; then
        dns_result=$(vm_run "nslookup github.com 2>/dev/null | grep 'Address:' | tail -1" || echo "")
        if [ -n "$dns_result" ]; then
            pass "Persistence: DNS works after restart"
        else
            fail "Persistence: DNS failed after restart"
        fi
    else
        fail "Persistence: SSH failed after restart"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo "  Test Summary"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "  ${GREEN}All tests passed!${NC}"
else
    echo -e "  ${RED}Some tests failed${NC}"
fi
echo ""
