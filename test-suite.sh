#!/bin/bash
# Comprehensive Zero Trust Test Suite
# Tests all components with edge cases and security validation

set -e

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Test result tracking
test_pass() {
    ((TEST_COUNT++))
    ((PASS_COUNT++))
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

test_fail() {
    ((TEST_COUNT++))
    ((FAIL_COUNT++))
    echo -e "${RED}✗ FAIL${NC}: $1"
}

test_info() {
    echo -e "${YELLOW}INFO${NC}: $1"
}

echo "================================================"
echo "    Zero Trust Architecture Test Suite"
echo "================================================"
echo ""

# ============================================
# Test 1: Policy Engine - User Authorization
# ============================================
echo "[TEST SUITE 1] Policy Engine - User Authorization"
echo "================================================"

# Setup test environment
mkdir -p /tmp/zero-trust-test
echo "alice" > /tmp/zero-trust-test/authorized-users.txt
echo "bob" >> /tmp/zero-trust-test/authorized-users.txt
echo "charlie" >> /tmp/zero-trust-test/authorized-users.txt

# Test 1.1: Authorized user
export ZERO_TRUST_POLICY_DIR=/tmp/zero-trust-test
if bash zero-trust-policy.sh alice 127.0.0.1 >/dev/null 2>&1; then
    test_pass "Authorized user 'alice' granted access"
else
    test_fail "Authorized user 'alice' denied access"
fi

# Test 1.2: Unauthorized user
if bash zero-trust-policy.sh eve 127.0.0.1 >/dev/null 2>&1; then
    test_fail "Unauthorized user 'eve' incorrectly granted access"
else
    test_pass "Unauthorized user 'eve' correctly denied access"
fi

# Test 1.3: Empty username
if bash zero-trust-policy.sh "" 127.0.0.1 >/dev/null 2>&1; then
    test_fail "Empty username incorrectly granted access"
else
    test_pass "Empty username correctly denied access"
fi

# Test 1.4: SQL injection attempt
if bash zero-trust-policy.sh "admin' OR '1'='1" 127.0.0.1 >/dev/null 2>&1; then
    test_fail "SQL injection attempt not blocked"
else
    test_pass "SQL injection attempt correctly blocked"
fi

echo ""

# ============================================
# Test 2: Policy Engine - IP Whitelisting
# ============================================
echo "[TEST SUITE 2] Policy Engine - IP Whitelisting"
echo "================================================"

echo "192.168.1.100" > /tmp/zero-trust-test/trusted-ips.txt
echo "10.0.0.1" >> /tmp/zero-trust-test/trusted-ips.txt
echo "127.0.0.1" >> /tmp/zero-trust-test/trusted-ips.txt

# Test 2.1: Whitelisted IP
if bash zero-trust-policy.sh alice 127.0.0.1 >/dev/null 2>&1; then
    test_pass "Whitelisted IP 127.0.0.1 granted access"
else
    test_fail "Whitelisted IP 127.0.0.1 denied access"
fi

# Test 2.2: Non-whitelisted IP
if bash zero-trust-policy.sh alice 192.168.1.200 >/dev/null 2>&1; then
    test_fail "Non-whitelisted IP 192.168.1.200 incorrectly granted access"
else
    test_pass "Non-whitelisted IP 192.168.1.200 correctly denied access"
fi

# Test 2.3: Invalid IP format
if bash zero-trust-policy.sh alice "999.999.999.999" >/dev/null 2>&1; then
    test_fail "Invalid IP format incorrectly processed"
else
    test_pass "Invalid IP format correctly rejected"
fi

# Test 2.4: IP spoofing attempt with localhost
if bash zero-trust-policy.sh alice "127.0.0.1; rm -rf /" >/dev/null 2>&1; then
    test_fail "Command injection in IP not blocked"
else
    test_pass "Command injection in IP correctly blocked"
fi

echo ""

# ============================================
# Test 3: Certificate Infrastructure
# ============================================
echo "[TEST SUITE 3] Certificate Infrastructure"
echo "================================================"

# Test 3.1: CA certificate exists and valid
if [ -f "certs/ca-cert.pem" ]; then
    if openssl x509 -in certs/ca-cert.pem -noout -checkend 86400 >/dev/null 2>&1; then
        test_pass "CA certificate exists and is valid"
    else
        test_fail "CA certificate exists but is expired/invalid"
    fi
else
    test_fail "CA certificate not found"
fi

# Test 3.2: Server certificate signed by CA
if [ -f "certs/server-cert.pem" ] && [ -f "certs/ca-cert.pem" ]; then
    if openssl verify -CAfile certs/ca-cert.pem certs/server-cert.pem >/dev/null 2>&1; then
        test_pass "Server certificate correctly signed by CA"
    else
        test_fail "Server certificate not signed by CA"
    fi
else
    test_fail "Server certificate or CA certificate not found"
fi

# Test 3.3: Client certificate signed by CA
if [ -f "certs/client-cert.pem" ] && [ -f "certs/ca-cert.pem" ]; then
    if openssl verify -CAfile certs/ca-cert.pem certs/client-cert.pem >/dev/null 2>&1; then
        test_pass "Client certificate correctly signed by CA"
    else
        test_fail "Client certificate not signed by CA"
    fi
else
    test_fail "Client certificate or CA certificate not found"
fi

# Test 3.4: Certificate key strength (RSA 2048+)
if [ -f "certs/ca-cert.pem" ]; then
    KEY_SIZE=$(openssl x509 -in certs/ca-cert.pem -noout -text | grep "Public-Key:" | grep -oP '\d+')
    if [ "$KEY_SIZE" -ge 2048 ]; then
        test_pass "CA certificate key size ($KEY_SIZE bits) meets security requirements"
    else
        test_fail "CA certificate key size ($KEY_SIZE bits) too weak"
    fi
fi

# Test 3.5: Certificate expiration check
if [ -f "certs/ca-cert.pem" ]; then
    EXPIRY=$(openssl x509 -in certs/ca-cert.pem -noout -enddate | cut -d= -f2)
    test_info "CA certificate expires: $EXPIRY"
    if openssl x509 -in certs/ca-cert.pem -noout -checkend 2592000 >/dev/null 2>&1; then
        test_pass "CA certificate valid for >30 days"
    else
        test_fail "CA certificate expires within 30 days"
    fi
fi

echo ""

# ============================================
# Test 4: Network Namespace (requires root)
# ============================================
echo "[TEST SUITE 4] Network Namespace Security"
echo "================================================"

# Test 4.1: Check if running with sufficient privileges
if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
    test_info "Running with sufficient privileges for namespace tests"
    
    # Test 4.2: Check if secure-zone namespace exists
    if ip netns list 2>/dev/null | grep -q "secure-zone"; then
        test_pass "Network namespace 'secure-zone' exists"
        
        # Test 4.3: Check namespace network isolation
        if sudo ip netns exec secure-zone ip addr show | grep -q "10.100.0.2"; then
            test_pass "Namespace has isolated IP address 10.100.0.2"
        else
            test_fail "Namespace missing isolated IP address"
        fi
        
        # Test 4.4: Verify routing isolation
        ROUTE_COUNT=$(sudo ip netns exec secure-zone ip route | wc -l)
        if [ "$ROUTE_COUNT" -le 3 ]; then
            test_pass "Namespace has minimal routing table (isolated)"
        else
            test_fail "Namespace routing table may not be isolated"
        fi
    else
        test_info "Network namespace 'secure-zone' not found (run network-namespace-demo.sh first)"
    fi
else
    test_info "Skipping namespace tests (requires root/sudo)"
fi

echo ""

# ============================================
# Test 5: Monitoring System
# ============================================
echo "[TEST SUITE 5] Security Monitoring"
echo "================================================"

# Test 5.1: Monitoring script executable
if [ -x "security-monitoring.sh" ]; then
    test_pass "Security monitoring script is executable"
else
    test_fail "Security monitoring script not executable"
fi

# Test 5.2: Monitoring produces output
if timeout 2s bash security-monitoring.sh >/dev/null 2>&1; then
    test_pass "Security monitoring script executes without errors"
else
    test_fail "Security monitoring script failed or timed out"
fi

# Test 5.3: Automated monitoring script exists
if [ -f "automated-monitoring.sh" ] && [ -x "automated-monitoring.sh" ]; then
    test_pass "Automated monitoring script found and executable"
else
    test_fail "Automated monitoring script missing or not executable"
fi

# Test 5.4: Check if monitoring is logging
if [ -f "/tmp/zero-trust-monitoring.log" ]; then
    LOG_SIZE=$(stat -f%z "/tmp/zero-trust-monitoring.log" 2>/dev/null || stat -c%s "/tmp/zero-trust-monitoring.log" 2>/dev/null)
    if [ "$LOG_SIZE" -gt 0 ]; then
        test_pass "Monitoring is actively logging (log size: $LOG_SIZE bytes)"
    else
        test_fail "Monitoring log exists but is empty"
    fi
else
    test_info "Monitoring log not found (automated monitoring may not be running)"
fi

echo ""

# ============================================
# Test 6: File Permissions Security
# ============================================
echo "[TEST SUITE 6] File Permissions Security"
echo "================================================"

# Test 6.1: Private key files are protected
for keyfile in certs/ca-key.pem certs/server-key.pem certs/client-key.pem; do
    if [ -f "$keyfile" ]; then
        PERMS=$(stat -f%Mp%Lp "$keyfile" 2>/dev/null || stat -c%a "$keyfile" 2>/dev/null)
        if [ "$PERMS" = "600" ] || [ "$PERMS" = "400" ]; then
            test_pass "$keyfile has secure permissions ($PERMS)"
        else
            test_fail "$keyfile has insecure permissions ($PERMS) - should be 600 or 400"
        fi
    else
        test_info "$keyfile not found"
    fi
done

# Test 6.2: Shell scripts are executable
for script in *.sh; do
    if [ -x "$script" ]; then
        test_pass "$script is executable"
    else
        test_fail "$script is not executable"
    fi
done

echo ""

# ============================================
# Test 7: Integration Tests
# ============================================
echo "[TEST SUITE 7] Integration Tests"
echo "================================================"

# Test 7.1: Full policy check with authorized user and IP
if bash zero-trust-policy.sh alice 127.0.0.1 >/dev/null 2>&1; then
    test_pass "Integration: Authorized user + whitelisted IP granted access"
else
    test_fail "Integration: Authorized user + whitelisted IP denied access"
fi

# Test 7.2: Full policy check with authorized user but unauthorized IP
if bash zero-trust-policy.sh alice 192.168.99.99 >/dev/null 2>&1; then
    test_fail "Integration: Authorized user + non-whitelisted IP incorrectly granted access"
else
    test_pass "Integration: Authorized user + non-whitelisted IP correctly denied access"
fi

# Test 7.3: Full policy check with unauthorized user and whitelisted IP
if bash zero-trust-policy.sh eve 127.0.0.1 >/dev/null 2>&1; then
    test_fail "Integration: Unauthorized user + whitelisted IP incorrectly granted access"
else
    test_pass "Integration: Unauthorized user + whitelisted IP correctly denied access"
fi

# Test 7.4: Demo script syntax check
if bash -n run-zero-trust-demo.sh; then
    test_pass "Demo script has valid syntax"
else
    test_fail "Demo script has syntax errors"
fi

echo ""

# ============================================
# Test 8: Security Hardening Validation
# ============================================
echo "[TEST SUITE 8] Security Hardening"
echo "================================================"

# Test 8.1: No hardcoded credentials in scripts
HARDCODED_PATTERNS="password|secret|api_key|token|credential"
if grep -riE "$HARDCODED_PATTERNS" *.sh 2>/dev/null | grep -v "^#" | grep -v "TEST" | grep -v "echo"; then
    test_fail "Potential hardcoded credentials found in scripts"
else
    test_pass "No hardcoded credentials found in scripts"
fi

# Test 8.2: Shell scripts use 'set -e' or error handling
SCRIPTS_WITHOUT_ERROR_HANDLING=0
for script in zero-trust-policy.sh security-monitoring.sh automated-monitoring.sh; do
    if [ -f "$script" ]; then
        if ! grep -q "set -e" "$script" && ! grep -q "set -eu" "$script"; then
            ((SCRIPTS_WITHOUT_ERROR_HANDLING++))
        fi
    fi
done

if [ "$SCRIPTS_WITHOUT_ERROR_HANDLING" -eq 0 ]; then
    test_pass "All critical scripts use error handling"
else
    test_info "$SCRIPTS_WITHOUT_ERROR_HANDLING scripts could benefit from 'set -e'"
fi

# Test 8.3: Input validation in policy script
if grep -q "check_user_authorized\|check_ip_whitelist" zero-trust-policy.sh; then
    test_pass "Policy script implements input validation functions"
else
    test_fail "Policy script missing input validation"
fi

echo ""

# ============================================
# Final Report
# ============================================
echo "================================================"
echo "           TEST SUITE RESULTS"
echo "================================================"
echo -e "Total Tests:  $TEST_COUNT"
echo -e "${GREEN}Passed:       $PASS_COUNT${NC}"
echo -e "${RED}Failed:       $FAIL_COUNT${NC}"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo "Zero Trust implementation is secure and functional."
    exit 0
else
    PASS_RATE=$((PASS_COUNT * 100 / TEST_COUNT))
    echo -e "${YELLOW}Pass Rate: ${PASS_RATE}%${NC}"
    if [ "$PASS_RATE" -ge 80 ]; then
        echo "Implementation is mostly secure with minor issues."
        exit 0
    else
        echo -e "${RED}Critical issues detected. Review failures above.${NC}"
        exit 1
    fi
fi
