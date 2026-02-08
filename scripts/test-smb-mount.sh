#!/bin/zsh

# Test script for SMB mount bypass detection
# Run this INSIDE the VM after mounting a share via Finder

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo "${BLUE}║  SMB Mount Bypass Detection Test              ║${NC}"
echo "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# Test 1: Check mounted filesystems
# ============================================
echo "${BLUE}━━━ Test 1: Mounted Filesystems ━━━${NC}"
echo ""
echo "Looking for SMB/CIFS/AFP mounts:"
mount | grep -E '(smb|afp|cifs)' || echo "${YELLOW}No SMB/AFP mounts found via 'mount' command${NC}"
echo ""

# ============================================
# Test 2: List /Volumes
# ============================================
echo "${BLUE}━━━ Test 2: /Volumes Directory ━━━${NC}"
echo ""
echo "Mounted volumes:"
ls -la /Volumes/
echo ""

# ============================================
# Test 3: Find and test SMB shares
# ============================================
echo "${BLUE}━━━ Test 3: Testing Network Share Access ━━━${NC}"
echo ""

# Find non-system volumes (exclude Macintosh HD variants)
found_share=false
for vol in /Volumes/*; do
    if [[ -d "$vol" && "$vol" != "/Volumes/Macintosh HD"* ]]; then
        found_share=true
        echo "${YELLOW}Found volume: $vol${NC}"
        echo ""

        # Test read access
        echo "Testing READ access:"
        if ls -la "$vol" 2>/dev/null | head -10; then
            echo "${GREEN}✓ Can list directory contents${NC}"
        else
            echo "${RED}✗ Cannot list directory${NC}"
        fi
        echo ""

        # Test write access
        echo "Testing WRITE access:"
        test_file="$vol/test-from-calf-vm-$(date +%s).txt"
        if echo "Test write from CALF VM at $(date)" > "$test_file" 2>/dev/null; then
            echo "${GREEN}✓ Can write files${NC}"
            echo "Test file created: $test_file"
            echo "Content:"
            cat "$test_file"
            echo ""

            # Clean up test file
            rm -f "$test_file" 2>/dev/null && echo "${YELLOW}Test file removed${NC}" || echo "${YELLOW}Could not remove test file${NC}"
        else
            echo "${RED}✗ Cannot write files (may be read-only or permission issue)${NC}"
        fi
        echo ""
        echo "────────────────────────────────────────"
        echo ""
    fi
done

if [ "$found_share" = false ]; then
    echo "${YELLOW}No network shares found in /Volumes/${NC}"
    echo "${YELLOW}Please mount a share via Finder first:${NC}"
    echo "  1. Open Finder"
    echo "  2. Go to Network or use Cmd+K"
    echo "  3. Connect to a share (e.g., smb://server/share)"
    echo "  4. Run this script again"
    echo ""
fi

# ============================================
# Test 4: Active network connections
# ============================================
echo "${BLUE}━━━ Test 4: Active Network Connections ━━━${NC}"
echo ""
echo "SMB ports (139, 445) - using lsof:"
lsof -i | grep -E '(139|445)' || echo "${YELLOW}No active connections on SMB ports${NC}"
echo ""

echo "SMB ports (139, 445) - using netstat:"
netstat -an | grep -E '(\.139|\.445)' | grep ESTABLISHED || echo "${YELLOW}No ESTABLISHED connections on SMB ports${NC}"
echo ""

# ============================================
# Test 5: Detailed connection info
# ============================================
echo "${BLUE}━━━ Test 5: All Network Connections ━━━${NC}"
echo ""
echo "All ESTABLISHED connections (excluding localhost):"
netstat -an | grep ESTABLISHED | grep -v '127.0.0.1' | grep -v '::1' || echo "${YELLOW}No external connections${NC}"
echo ""

# ============================================
# Summary
# ============================================
echo "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo "${BLUE}║  Test Complete                                 ║${NC}"
echo "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo "${YELLOW}CRITICAL SECURITY FINDING:${NC}"
echo "If you could read/write files on a network share,"
echo "this means Finder is bypassing softnet isolation!"
echo ""
echo "Save this output and share it for analysis."
echo ""
