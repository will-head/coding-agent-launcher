#!/bin/zsh

# Opencode VM Testing Script
# Tests opencode in various configurations to identify issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_MESSAGE="Hello, this is a test message"
TIMEOUT_SECONDS=15
LOG_DIR="$HOME/.local/share/opencode/test-results"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/test_${TIMESTAMP}.log"

# Helper functions
log() {
    echo "[$(date +'%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "$1" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
}

test_result() {
    local test_name="$1"
    local test_status="$2"
    local details="$3"
    
    if [ "$test_status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name: PASS" | tee -a "$LOG_FILE"
    elif [ "$test_status" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $test_name: FAIL" | tee -a "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠${NC} $test_name: $test_status" | tee -a "$LOG_FILE"
    fi
    
    if [ -n "$details" ]; then
        echo "  $details" | tee -a "$LOG_FILE"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"
    
    if ! command -v opencode &>/dev/null; then
        log "ERROR: opencode not found in PATH"
        exit 1
    fi
    test_result "opencode installed" "PASS" "$(which opencode)"
    
    OPENCODE_VERSION=$(opencode --version 2>&1 | tail -1)
    test_result "opencode version" "PASS" "$OPENCODE_VERSION"
    
    # Check if we're in VM
    if [ "$CALF_VM" = "true" ]; then
        test_result "VM environment" "PASS" "Running in CALF VM"
    else
        test_result "VM environment" "WARN" "Not in CALF VM (CALF_VM not set)"
    fi
    
    # Check tmux
    if [ -n "$TMUX" ]; then
        test_result "tmux session" "INFO" "Inside tmux: $TMUX"
    else
        test_result "tmux session" "INFO" "Not in tmux"
    fi
    
    # Check terminal
    test_result "TERM variable" "INFO" "$TERM"
    test_result "SSH connection" "INFO" "${SSH_CONNECTION:-Not SSH}"
}

# Test 1: Environment Information
test_environment() {
    log_section "Environment Information"
    
    echo "Environment Variables:" | tee -a "$LOG_FILE"
    env | grep -iE "(TERM|TMUX|SSH|DISPLAY|COLOR|TTY|CAL)" | sort | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
    echo "Terminal Settings:" | tee -a "$LOG_FILE"
    if [ -t 0 ]; then
        stty -a 2>/dev/null | head -1 | tee -a "$LOG_FILE" || echo "stty not available" | tee -a "$LOG_FILE"
    else
        echo "Not a TTY" | tee -a "$LOG_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
    echo "Resource Limits:" | tee -a "$LOG_FILE"
    ulimit -a 2>/dev/null | tee -a "$LOG_FILE" || echo "ulimit not available" | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
    echo "Network Status:" | tee -a "$LOG_FILE"
    if pgrep -f sshuttle >/dev/null 2>&1; then
        echo "  Proxy (sshuttle): Running" | tee -a "$LOG_FILE"
    else
        echo "  Proxy (sshuttle): Not running" | tee -a "$LOG_FILE"
    fi
    
    # Test connectivity
    if curl -s --connect-timeout 5 -I https://github.com 2>&1 | grep -q 'HTTP'; then
        echo "  Network: Working" | tee -a "$LOG_FILE"
    else
        echo "  Network: Not working" | tee -a "$LOG_FILE"
    fi
}

# Test 2: Opencode serve (known working)
test_opencode_serve() {
    log_section "Test: opencode serve (baseline - known working)"
    
    local test_name="opencode serve"
    local output_file="$LOG_DIR/serve_${TIMESTAMP}.log"
    
    log "Starting opencode serve in background..."
    opencode serve > "$output_file" 2>&1 &
    local serve_pid=$!
    
    # Wait a bit for it to start
    sleep 3
    
    # Check if process is still running
    if ps -p $serve_pid >/dev/null 2>&1; then
        test_result "$test_name" "PASS" "Started successfully (PID: $serve_pid)"
        
        # Check if server is listening
        if lsof -i :4096 >/dev/null 2>&1 || netstat -an | grep -q "4096"; then
            test_result "$test_name listening" "PASS" "Server listening on port 4096"
        else
            test_result "$test_name listening" "WARN" "Port 4096 not detected (may be normal)"
        fi
        
        # Kill it
        kill $serve_pid 2>/dev/null || true
        wait $serve_pid 2>/dev/null || true
        log "Stopped opencode serve"
    else
        test_result "$test_name" "FAIL" "Process died immediately"
        cat "$output_file" | tee -a "$LOG_FILE"
    fi
}

# Test 3: Opencode run with timeout
test_opencode_run_timeout() {
    log_section "Test: opencode run (with timeout detection)"
    
    local test_name="opencode run timeout test"
    local output_file="$LOG_DIR/run_${TIMESTAMP}.log"
    
    log "Testing opencode run with message: '$TEST_MESSAGE'"
    log "This test will timeout after $TIMEOUT_SECONDS seconds if it hangs"
    
    # Start opencode run in background
    (opencode run "$TEST_MESSAGE" > "$output_file" 2>&1) &
    local run_pid=$!
    
    # Monitor for completion or timeout
    local elapsed=0
    local completed=false
    
    while [ $elapsed -lt $TIMEOUT_SECONDS ]; do
        sleep 1
        elapsed=$((elapsed + 1))
        
        # Check if process is still running
        if ! ps -p $run_pid >/dev/null 2>&1; then
            completed=true
            break
        fi
        
        # Check if output file has grown (indicates activity)
        if [ -f "$output_file" ]; then
            local size=$(wc -c < "$output_file" 2>/dev/null || echo 0)
            if [ $size -gt 0 ]; then
                log "  Output detected (${size} bytes after ${elapsed}s)"
            fi
        fi
    done
    
    # Check results
    if [ "$completed" = true ]; then
        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            test_result "$test_name" "PASS" "Completed in ${elapsed}s"
            log "Output preview:"
            head -20 "$output_file" | tee -a "$LOG_FILE"
        else
            test_result "$test_name" "WARN" "Completed but no output (${elapsed}s)"
        fi
    else
        test_result "$test_name" "FAIL" "HUNG - No completion after ${TIMEOUT_SECONDS}s"
        log "Killing hung process..."
        kill -9 $run_pid 2>/dev/null || true
        wait $run_pid 2>/dev/null || true
        
        log "Output captured:"
        cat "$output_file" | tee -a "$LOG_FILE"
    fi
}

# Test 4: Opencode run with different TERM values
test_opencode_run_term() {
    log_section "Test: opencode run with different TERM values"
    
    local terms=("xterm-256color" "screen-256color" "vt100" "xterm")
    
    for term in "${terms[@]}"; do
        log "Testing with TERM=$term"
        local output_file="$LOG_DIR/run_term_${term}_${TIMESTAMP}.log"
        
        # Test with timeout
        (TERM="$term" opencode run "$TEST_MESSAGE" > "$output_file" 2>&1) &
        local run_pid=$!
        
        sleep 5
        
        if ps -p $run_pid >/dev/null 2>&1; then
            test_result "opencode run TERM=$term" "FAIL" "Still running after 5s (likely hung)"
            kill -9 $run_pid 2>/dev/null || true
        else
            test_result "opencode run TERM=$term" "PASS" "Completed"
            if [ -s "$output_file" ]; then
                log "  Output: $(head -1 "$output_file")"
            fi
        fi
        
        wait $run_pid 2>/dev/null || true
    done
}

# Test 5: Opencode run without color variables
test_opencode_run_no_color() {
    log_section "Test: opencode run without color environment variables"
    
    local output_file="$LOG_DIR/run_no_color_${TIMESTAMP}.log"
    
    log "Testing with FORCE_COLOR and NO_COLOR unset"
    
    (unset FORCE_COLOR NO_COLOR; opencode run "$TEST_MESSAGE" > "$output_file" 2>&1) &
    local run_pid=$!
    
    sleep 5
    
    if ps -p $run_pid >/dev/null 2>&1; then
        test_result "opencode run (no color vars)" "FAIL" "Still running after 5s (likely hung)"
        kill -9 $run_pid 2>/dev/null || true
    else
        test_result "opencode run (no color vars)" "PASS" "Completed"
        if [ -s "$output_file" ]; then
            log "  Output: $(head -1 "$output_file")"
        fi
    fi
    
    wait $run_pid 2>/dev/null || true
}

# Test 6: Opencode run with proxy off
test_opencode_run_no_proxy() {
    log_section "Test: opencode run with proxy disabled"
    
    # Check if proxy is running
    if ! pgrep -f sshuttle >/dev/null 2>&1; then
        test_result "opencode run (no proxy)" "SKIP" "Proxy not running, test not applicable"
        return
    fi
    
    log "Stopping proxy..."
    proxy-stop 2>/dev/null || pkill -f sshuttle 2>/dev/null || true
    sleep 2
    
    local output_file="$LOG_DIR/run_no_proxy_${TIMESTAMP}.log"
    
    log "Testing opencode run without proxy"
    
    (opencode run "$TEST_MESSAGE" > "$output_file" 2>&1) &
    local run_pid=$!
    
    sleep 5
    
    if ps -p $run_pid >/dev/null 2>&1; then
        test_result "opencode run (no proxy)" "FAIL" "Still running after 5s (likely hung)"
        kill -9 $run_pid 2>/dev/null || true
    else
        test_result "opencode run (no proxy)" "PASS" "Completed"
        if [ -s "$output_file" ]; then
            log "  Output: $(head -1 "$output_file")"
        fi
    fi
    
    wait $run_pid 2>/dev/null || true
    
    # Restart proxy
    log "Restarting proxy..."
    proxy-start >/dev/null 2>&1 || true
    sleep 2
}

# Test 7: Opencode TUI mode
test_opencode_tui() {
    log_section "Test: opencode TUI mode (default)"
    
    local output_file="$LOG_DIR/tui_${TIMESTAMP}.log"
    
    log "Testing opencode TUI mode (just 'opencode' command)"
    
    # TUI mode might hang too, so test with timeout
    (opencode > "$output_file" 2>&1) &
    local tui_pid=$!
    
    sleep 5
    
    if ps -p $tui_pid >/dev/null 2>&1; then
        test_result "opencode TUI" "INFO" "Still running after 5s (may be normal for TUI)"
        kill -9 $tui_pid 2>/dev/null || true
    else
        test_result "opencode TUI" "PASS" "Exited"
        if [ -s "$output_file" ]; then
            log "  Output: $(head -1 "$output_file")"
        fi
    fi
    
    wait $tui_pid 2>/dev/null || true
}

# Test 8: Check opencode logs
test_opencode_logs() {
    log_section "Test: Analyzing opencode logs"
    
    local log_dir="$HOME/.local/share/opencode/log"
    
    if [ ! -d "$log_dir" ]; then
        test_result "opencode logs" "WARN" "Log directory not found: $log_dir"
        return
    fi
    
    local log_files=$(find "$log_dir" -name "*.log" -type f 2>/dev/null | head -5)
    
    if [ -z "$log_files" ]; then
        test_result "opencode logs" "WARN" "No log files found"
        return
    fi
    
    test_result "opencode logs" "INFO" "Found log files"
    
    # Show recent log entries
    log "Recent log entries:"
    for log_file in $log_files; do
        echo "  $log_file:" | tee -a "$LOG_FILE"
        tail -10 "$log_file" 2>/dev/null | sed 's/^/    /' | tee -a "$LOG_FILE" || true
    done
}

# Test 9: Check opencode storage
test_opencode_storage() {
    log_section "Test: Checking opencode storage"
    
    local storage_dir="$HOME/.local/share/opencode"
    
    if [ ! -d "$storage_dir" ]; then
        test_result "opencode storage" "WARN" "Storage directory not found"
        return
    fi
    
    test_result "opencode storage" "INFO" "Storage directory exists"
    
    # Check for lock files
    local lock_files=$(find "$storage_dir" -name "*.lock" -o -name "*.pid" 2>/dev/null)
    if [ -n "$lock_files" ]; then
        test_result "opencode locks" "WARN" "Found lock files:"
        echo "$lock_files" | sed 's/^/    /' | tee -a "$LOG_FILE"
    else
        test_result "opencode locks" "PASS" "No lock files found"
    fi
    
    # Check storage structure
    log "Storage structure:"
    ls -la "$storage_dir" 2>/dev/null | tee -a "$LOG_FILE" || true
}

# Test 10: Network connectivity tests
test_network_connectivity() {
    log_section "Test: Network connectivity for opencode"
    
    # Test DNS resolution
    log "Testing DNS resolution..."
    if nslookup api.zhipu.ai >/dev/null 2>&1; then
        test_result "DNS: api.zhipu.ai" "PASS"
    else
        test_result "DNS: api.zhipu.ai" "FAIL"
    fi
    
    if nslookup open.bigmodel.cn >/dev/null 2>&1; then
        test_result "DNS: open.bigmodel.cn" "PASS"
    else
        test_result "DNS: open.bigmodel.cn" "FAIL"
    fi
    
    # Test API connectivity
    log "Testing API connectivity..."
    if curl -s --connect-timeout 5 -I https://open.bigmodel.cn 2>&1 | grep -q 'HTTP'; then
        test_result "API: open.bigmodel.cn" "PASS"
    else
        test_result "API: open.bigmodel.cn" "FAIL"
    fi
}

# Main execution
main() {
    echo "========================================"
    echo "Opencode VM Testing Script"
    echo "========================================"
    echo ""
    echo "Log file: $LOG_FILE"
    echo ""
    
    log "Starting opencode VM tests..."
    log "Timestamp: $(date)"
    log "Test message: $TEST_MESSAGE"
    log ""
    
    # Run all tests
    check_prerequisites
    test_environment
    test_opencode_storage
    test_opencode_logs
    test_network_connectivity
    test_opencode_serve
    test_opencode_run_timeout
    test_opencode_run_term
    test_opencode_run_no_color
    test_opencode_run_no_proxy
    test_opencode_tui
    
    log_section "Test Summary"
    log "All tests completed. Check log file for details: $LOG_FILE"
    log ""
    log "Test output files saved in: $LOG_DIR"
    log ""
    log "To view full results:"
    log "  cat $LOG_FILE"
    log ""
    log "To view specific test output:"
    log "  ls -la $LOG_DIR"
    
    echo ""
    echo "========================================"
    echo "Tests complete! Check $LOG_FILE for details"
    echo "========================================"
}

# Run main function
main "$@"
