#!/bin/bash
# Test script: Verify --net-softnet-block approach for SMB/mDNS isolation
#
# Findings so far:
#   - Blocking gateway (192.168.64.1/32) breaks SSH (host IS the gateway)
#   - Blocking mDNS multicast (224.0.0.251/32) blocks Bonjour discovery
#   - SMB port 445 open on gateway but smbutil browsing fails
#
# This version tests:
#   1. Broader multicast block (224.0.0.0/4) — all multicast, not just mDNS
#   2. Deep SMB investigation — can shares actually be mounted?
#   3. Multiple block rules — combine multicast + link-local
#
# Usage:
#   ./test-softnet-block.sh info              # System info
#   ./test-softnet-block.sh start [scenario]  # Start VM (scenario: mdns|multicast|multi)
#   ./test-softnet-block.sh test <vm_ip>      # Run tests via SSH
#   ./test-softnet-block.sh all [scenario]    # All phases (default: multicast)

set -euo pipefail

# Configuration
TART="${TART:-tart}"
VM_DEV="${VM_DEV:-calf-dev}"
VM_USER="${VM_USER:-admin}"
VM_PASSWORD="${VM_PASSWORD:-admin}"
GATEWAY="192.168.64.1"

# Block scenarios
SCENARIO="${SCENARIO:-multicast}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓ PASS${NC}: $1"; }
fail() { echo -e "  ${RED}✗ FAIL${NC}: $1"; }
warn() { echo -e "  ${YELLOW}⚠ WARN${NC}: $1"; }
info() { echo -e "  ${BLUE}ℹ${NC} $1"; }

# Check if VM is running (matches calf-bootstrap vm_running)
vm_running() {
    "$TART" list 2>/dev/null | awk -v vm="$1" 'NR>1 { if ($2 == vm && $NF == "running") { found=1; exit } } END { if (found) exit 0; else exit 1 }'
}

# Get block flags for a scenario
get_block_flags() {
    local scenario="$1"
    case "$scenario" in
        mdns)
            # Just mDNS multicast (previous test — known working)
            echo "--net-softnet-block=224.0.0.251/32"
            ;;
        multicast)
            # All multicast (224.0.0.0/4) — broader coverage
            echo "--net-softnet-block=224.0.0.0/4"
            ;;
        multi)
            # Multiple rules: all multicast + link-local (169.254.0.0/16)
            echo "--net-softnet-block=224.0.0.0/4 --net-softnet-block=169.254.0.0/16"
            ;;
        *)
            echo "Unknown scenario: $scenario" >&2
            return 1
            ;;
    esac
}

describe_scenario() {
    local scenario="$1"
    case "$scenario" in
        mdns)
            echo "mDNS only (224.0.0.251/32)"
            ;;
        multicast)
            echo "All multicast (224.0.0.0/4)"
            ;;
        multi)
            echo "All multicast (224.0.0.0/4) + link-local (169.254.0.0/16)"
            ;;
    esac
}

# ── Phase 1: Gather info ──────────────────────────────────────────────

do_info() {
    echo ""
    echo "=== Phase 1: System Information ==="
    echo ""

    # Tart version
    echo "Tart version:"
    if command -v "$TART" &>/dev/null; then
        local version
        version=$("$TART" --version 2>/dev/null || echo "unknown")
        info "$version"

        if "$TART" run --help 2>&1 | grep -qi "softnet.*block\|softnet-block"; then
            pass "--net-softnet-block flag found in help"
        else
            warn "--net-softnet-block not found in help text (may still work — Tart 2.30.0+ required)"
        fi
    else
        fail "tart not found"
        return 1
    fi

    # Softnet
    echo ""
    echo "Softnet:"
    local softnet_path
    softnet_path=$(which softnet 2>/dev/null || echo "")
    if [ -n "$softnet_path" ]; then
        info "Path: $softnet_path"
        if [ -u "$softnet_path" ]; then
            pass "SUID bit set"
        else
            warn "SUID bit not set (needed for --net-softnet)"
        fi
    else
        fail "softnet not found"
    fi

    # VM status
    echo ""
    echo "VM status:"
    if "$TART" list 2>/dev/null | grep -q "$VM_DEV"; then
        info "$VM_DEV exists"
        if vm_running "$VM_DEV"; then
            local vm_ip
            vm_ip=$("$TART" ip "$VM_DEV" 2>/dev/null || echo "")
            pass "$VM_DEV is running (IP: ${vm_ip:-unknown})"
        else
            info "$VM_DEV exists but not running"
        fi
    else
        warn "$VM_DEV not found"
    fi

    # Bridge interface
    echo ""
    echo "Bridge interfaces:"
    local bridges
    bridges=$(ifconfig 2>/dev/null | grep '^bridge' | cut -d: -f1 || true)
    for iface in $bridges; do
        local bridge_ip
        bridge_ip=$(ifconfig "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' || true)
        if [ -n "$bridge_ip" ]; then
            info "$iface: $bridge_ip"
        fi
    done
    if [ -z "$bridges" ]; then
        info "None found (VM not running)"
    fi

    # Scenarios
    echo ""
    echo "Available scenarios:"
    info "mdns      — Block mDNS only (224.0.0.251/32)"
    info "multicast — Block all multicast (224.0.0.0/4)"
    info "multi     — Block all multicast + link-local (224.0.0.0/4 + 169.254.0.0/16)"
    echo ""
    echo "Current scenario: $SCENARIO ($(describe_scenario "$SCENARIO"))"
    echo ""
}

# ── Phase 2: Start VM with block rules ───────────────────────────────

do_start() {
    local scenario="${1:-$SCENARIO}"
    local block_flags
    block_flags=$(get_block_flags "$scenario")

    echo ""
    echo "=== Phase 2: Start VM — Scenario: $scenario ==="
    echo ""
    echo "Block rules: $block_flags"
    echo ""

    # Check if VM is already running
    if vm_running "$VM_DEV"; then
        local vm_ip
        vm_ip=$("$TART" ip "$VM_DEV" 2>/dev/null || echo "")
        echo "VM is already running (IP: ${vm_ip:-unknown})"
        echo "Stop it first with: tart stop $VM_DEV"
        return 1
    fi

    echo "Starting $VM_DEV with --net-softnet $block_flags ..."
    echo ""

    # Start VM in background (word-split block_flags intentionally)
    # shellcheck disable=SC2086
    "$TART" run --no-graphics --net-softnet $block_flags "$VM_DEV" &
    local tart_pid=$!
    echo "VM started (PID: $tart_pid)"

    # Wait for IP
    echo "Waiting for IP..."
    local max_wait=60
    local count=0
    local vm_ip=""

    while [ $count -lt $max_wait ]; do
        sleep 2
        count=$((count + 2))
        vm_ip=$("$TART" ip "$VM_DEV" 2>/dev/null || echo "")
        if [ -n "$vm_ip" ]; then
            echo "VM IP: $vm_ip"
            break
        fi
        printf "  Waiting... (%ds/%ds)\r" "$count" "$max_wait"
    done

    if [ -z "$vm_ip" ]; then
        echo "Could not obtain IP after ${max_wait}s"
        return 1
    fi

    # Wait for SSH
    echo "Waiting for SSH..."
    count=0
    while [ $count -lt $max_wait ]; do
        if ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null "$VM_USER@$vm_ip" "echo ok" &>/dev/null; then
            echo "SSH is ready"
            echo ""
            echo "VM running with scenario: $scenario"
            echo "Run tests: ./test-softnet-block.sh test $vm_ip"
            return 0
        fi
        sleep 2
        count=$((count + 2))
        printf "  Waiting... (%ds/%ds)\r" "$count" "$max_wait"
    done

    echo "SSH not available after ${max_wait}s"
    return 1
}

# ── Phase 3: Run tests (via SSH) ─────────────────────────────────────

do_test() {
    local vm_ip="${1:-}"
    local run_via_ssh=false

    if [ -n "$vm_ip" ]; then
        run_via_ssh=true
        echo ""
        echo "=== Phase 3: Network Tests via SSH ($vm_ip) ==="
    else
        echo ""
        echo "=== Phase 3: Network Tests (local) ==="
    fi
    echo ""
    echo "Scenario: $SCENARIO ($(describe_scenario "$SCENARIO"))"
    echo ""

    local test_pass=0
    local test_fail=0
    local test_info=0

    run_cmd() {
        local cmd="$1"
        if [ "$run_via_ssh" = true ]; then
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                -o ConnectTimeout=5 "$VM_USER@$vm_ip" "$cmd" 2>/dev/null
        else
            eval "$cmd"
        fi
    }

    # macOS-compatible timeout: run command with a time limit
    # Usage: run_cmd_timeout <seconds> <command>
    run_cmd_timeout() {
        local secs="$1"
        local cmd="$2"
        local wrapper="$cmd & CMD_PID=\$!; (sleep $secs; kill \$CMD_PID 2>/dev/null) & TIMER_PID=\$!; wait \$CMD_PID 2>/dev/null; RESULT=\$?; kill \$TIMER_PID 2>/dev/null; wait \$TIMER_PID 2>/dev/null; exit \$RESULT"
        run_cmd "$wrapper"
    }

    # ── Core connectivity (must work) ─────────────────────────────

    echo "── Core Connectivity ──"
    echo ""

    # Test 1: SSH
    if [ "$run_via_ssh" = true ]; then
        echo "Test 1: SSH from host to VM"
        pass "SSH works"
        test_pass=$((test_pass + 1))
    fi

    # Test 2: DNS
    echo ""
    echo "Test 2: DNS resolution"
    local dns_output
    dns_output=$(run_cmd "nslookup github.com 2>/dev/null" 2>/dev/null || echo "FAILED")
    if echo "$dns_output" | grep -q "Address.*[0-9]" 2>/dev/null; then
        pass "DNS works"
        echo "    $(echo "$dns_output" | grep 'Server:' || true)"
        test_pass=$((test_pass + 1))
    else
        fail "DNS failed"
        test_fail=$((test_fail + 1))
    fi

    # Test 3: HTTPS
    echo ""
    echo "Test 3: Internet connectivity (HTTPS)"
    local http_code
    http_code=$(run_cmd "curl -s --connect-timeout 5 -o /dev/null -w '%{http_code}' https://github.com" 2>/dev/null || echo "000")
    if [ "$http_code" != "000" ]; then
        pass "HTTPS works (HTTP $http_code)"
        test_pass=$((test_pass + 1))
    else
        fail "HTTPS failed"
        test_fail=$((test_fail + 1))
    fi

    # Test 4: Ping
    echo ""
    echo "Test 4: Ping (8.8.8.8)"
    if run_cmd "ping -c 1 -W 3 8.8.8.8" &>/dev/null; then
        pass "Ping works"
        test_pass=$((test_pass + 1))
    else
        warn "Ping failed (softnet may block ICMP — not counted)"
    fi

    # ── mDNS / Bonjour (should be blocked) ────────────────────────

    echo ""
    echo "── mDNS / Bonjour Discovery ──"
    echo ""

    # Test 5: mDNS SMB service discovery
    echo "Test 5: mDNS discovery — SMB services (_smb._tcp)"
    local mdns_smb
    mdns_smb=$(run_cmd_timeout 5 "dns-sd -B _smb._tcp local. 2>/dev/null" 2>/dev/null || echo "")
    if echo "$mdns_smb" | grep -q "Add"; then
        fail "mDNS found SMB services (should be blocked)"
        echo "    $mdns_smb"
        test_fail=$((test_fail + 1))
    else
        pass "No SMB services discovered via mDNS"
        test_pass=$((test_pass + 1))
    fi

    # Test 6: mDNS any service discovery
    echo ""
    echo "Test 6: mDNS discovery — all services (_services._dns-sd._udp)"
    local mdns_all
    mdns_all=$(run_cmd_timeout 5 "dns-sd -B _services._dns-sd._udp local. 2>/dev/null" 2>/dev/null || echo "")
    if echo "$mdns_all" | grep -q "Add"; then
        fail "mDNS found services (should be blocked)"
        echo "    $(echo "$mdns_all" | head -5)"
        test_fail=$((test_fail + 1))
    else
        pass "No services discovered via mDNS"
        test_pass=$((test_pass + 1))
    fi

    # ── SMB Deep Investigation (informational) ────────────────────

    echo ""
    echo "── SMB Deep Investigation (gateway $GATEWAY) ──"
    echo ""

    # Test 7: Port 445 open?
    echo "Test 7: SMB port 445 connectivity"
    local smb445_open=false
    if run_cmd "nc -zv -G 3 $GATEWAY 445" &>/dev/null 2>&1; then
        warn "Port 445 OPEN"
        smb445_open=true
        test_info=$((test_info + 1))
    else
        info "Port 445 closed/unreachable"
        test_info=$((test_info + 1))
    fi

    # Test 8: Port 139 open?
    echo ""
    echo "Test 8: SMB port 139 connectivity"
    if run_cmd "nc -zv -G 3 $GATEWAY 139" &>/dev/null 2>&1; then
        warn "Port 139 OPEN"
        test_info=$((test_info + 1))
    else
        info "Port 139 closed/unreachable"
        test_info=$((test_info + 1))
    fi

    # Test 9: smbutil view — list shares as guest
    echo ""
    echo "Test 9: SMB share listing (smbutil view — guest)"
    local smb_view
    smb_view=$(run_cmd "smbutil view -N //guest@$GATEWAY 2>&1 || echo 'SMB_FAILED'" 2>/dev/null || echo "SMB_FAILED")
    if echo "$smb_view" | grep -qi "SMB_FAILED\|No route\|timed out\|refused\|error\|Authentication"; then
        info "Share listing failed: $(echo "$smb_view" | head -1)"
        test_info=$((test_info + 1))
    else
        warn "Share listing succeeded:"
        echo "    $(echo "$smb_view" | head -5)"
        test_info=$((test_info + 1))
    fi

    # Test 10: smbutil view — list shares as admin
    echo ""
    echo "Test 10: SMB share listing (smbutil view — admin:admin)"
    local smb_view_admin
    smb_view_admin=$(run_cmd "smbutil view //admin:admin@$GATEWAY 2>&1 || echo 'SMB_FAILED'" 2>/dev/null || echo "SMB_FAILED")
    if echo "$smb_view_admin" | grep -qi "SMB_FAILED\|No route\|timed out\|refused\|error\|Authentication"; then
        info "Share listing failed: $(echo "$smb_view_admin" | head -1)"
        test_info=$((test_info + 1))
    else
        warn "Share listing succeeded:"
        echo "    $(echo "$smb_view_admin" | head -5)"
        test_info=$((test_info + 1))
    fi

    # Test 11: Try to mount a share (read-only, temporary)
    echo ""
    echo "Test 11: SMB mount attempt (mount_smbfs — guest)"
    local mount_result
    mount_result=$(run_cmd "mkdir -p /tmp/calf-smb-test && mount_smbfs -N //guest@$GATEWAY/Users /tmp/calf-smb-test 2>&1; echo \"EXIT:\$?\"; umount /tmp/calf-smb-test 2>/dev/null; rmdir /tmp/calf-smb-test 2>/dev/null" 2>/dev/null || echo "MOUNT_FAILED")
    if echo "$mount_result" | grep -q "EXIT:0"; then
        fail "SMB MOUNT SUCCEEDED as guest — shares are accessible!"
        echo "    $mount_result"
        test_fail=$((test_fail + 1))
    else
        info "Mount failed: $(echo "$mount_result" | grep -v EXIT | head -1)"
        test_info=$((test_info + 1))
    fi

    # Test 12: Try to mount with admin creds
    echo ""
    echo "Test 12: SMB mount attempt (mount_smbfs — admin:admin)"
    local mount_admin
    mount_admin=$(run_cmd "mkdir -p /tmp/calf-smb-test && mount_smbfs //admin:admin@$GATEWAY/Users /tmp/calf-smb-test 2>&1; echo \"EXIT:\$?\"; umount /tmp/calf-smb-test 2>/dev/null; rmdir /tmp/calf-smb-test 2>/dev/null" 2>/dev/null || echo "MOUNT_FAILED")
    if echo "$mount_admin" | grep -q "EXIT:0"; then
        fail "SMB MOUNT SUCCEEDED as admin — shares are accessible!"
        echo "    $mount_admin"
        test_fail=$((test_fail + 1))
    else
        info "Mount failed: $(echo "$mount_admin" | grep -v EXIT | head -1)"
        test_info=$((test_info + 1))
    fi

    # ── Broadcast / Link-local ────────────────────────────────────

    echo ""
    echo "── Other Discovery Vectors ──"
    echo ""

    # Test 13: NetBIOS name resolution
    echo "Test 13: NetBIOS name resolution (nmblookup)"
    local netbios
    netbios=$(run_cmd "command -v nmblookup >/dev/null 2>&1 && nmblookup '*' 2>/dev/null || echo 'NOT_AVAILABLE'" 2>/dev/null || echo "NOT_AVAILABLE")
    if echo "$netbios" | grep -q "NOT_AVAILABLE"; then
        info "nmblookup not installed (NetBIOS test skipped)"
    elif echo "$netbios" | grep -q "name_query\|querying"; then
        warn "NetBIOS names found:"
        echo "    $(echo "$netbios" | head -3)"
    else
        info "No NetBIOS names found"
    fi

    # Test 14: ARP table (what can the VM see?)
    echo ""
    echo "Test 14: ARP table (visible hosts)"
    local arp_output
    arp_output=$(run_cmd "arp -a 2>/dev/null" 2>/dev/null || echo "FAILED")
    local arp_count
    arp_count=$(echo "$arp_output" | grep -c "at " || true)
    info "ARP entries visible: $arp_count"
    if [ "$arp_count" -gt 0 ]; then
        echo "    $(echo "$arp_output" | head -5)"
    fi

    # ── Summary ───────────────────────────────────────────────────

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo -e "  Scored:  ${GREEN}$test_pass passed${NC}, ${RED}$test_fail failed${NC}"
    echo -e "  Info:    $test_info informational results"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    if [ $test_fail -eq 0 ]; then
        echo -e "${GREEN}All scored tests passed!${NC}"
    else
        echo -e "${RED}Some scored tests failed.${NC}"
    fi

    echo ""
    echo "── Assessment ──"
    echo ""
    if [ "$smb445_open" = true ]; then
        echo "SMB port 445 is open on the gateway. Review mount test results above"
        echo "to determine if this is an actual exploitable risk or just an open port."
    else
        echo "SMB port 445 not reachable — SMB is not a concern on this host."
    fi
    echo ""

    return $test_fail
}

# ── Main ──────────────────────────────────────────────────────────────

case "${1:-help}" in
    info)
        do_info
        ;;
    start)
        SCENARIO="${2:-$SCENARIO}"
        do_start "$SCENARIO"
        ;;
    test)
        do_test "${2:-}"
        ;;
    all)
        SCENARIO="${2:-$SCENARIO}"
        do_info
        echo "─────────────────────────────────────────────"
        do_start "$SCENARIO"
        echo "─────────────────────────────────────────────"
        vm_ip=$("$TART" ip "$VM_DEV" 2>/dev/null || echo "")
        if [ -n "$vm_ip" ]; then
            echo "Waiting 5 seconds for VM to settle..."
            sleep 5
            do_test "$vm_ip"
        else
            echo "Cannot get VM IP for testing"
            exit 1
        fi
        ;;
    help|*)
        echo "Usage: $0 {info|start|test|all} [scenario]"
        echo ""
        echo "  info              System info and available scenarios"
        echo "  start [scenario]  Start VM with block rules"
        echo "  test <vm_ip>      Run network tests via SSH"
        echo "  all [scenario]    Run info + start + test"
        echo ""
        echo "Scenarios:"
        echo "  mdns       Block mDNS only (224.0.0.251/32)"
        echo "  multicast  Block all multicast (224.0.0.0/4) [default]"
        echo "  multi      Block multicast + link-local (224.0.0.0/4 + 169.254.0.0/16)"
        echo ""
        echo "Examples:"
        echo "  $0 all                  # Test with all-multicast block (default)"
        echo "  $0 all mdns             # Test with mDNS-only block"
        echo "  $0 all multi            # Test with multicast + link-local block"
        echo "  $0 start multicast      # Just start VM"
        echo "  $0 test 192.168.64.41   # Just run tests on running VM"
        ;;
esac
