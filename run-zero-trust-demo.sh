#!/bin/bash
# run-zero-trust-demo.sh - Complete Zero Trust demonstration

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          ZERO TRUST ARCHITECTURE - COMPLETE DEMO             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "This demo will showcase all implemented Zero Trust components"
echo ""
read -p "Press ENTER to begin the demonstration..."
clear

# Demo 1: Security Monitoring
echo "══════════════════════════════════════════════════════════════"
echo "DEMO 1: Security Monitoring Dashboard"
echo "══════════════════════════════════════════════════════════════"
echo ""
./security-monitoring.sh
echo ""
read -p "Press ENTER to continue to next demo..."
clear

# Demo 2: Policy Engine
echo "══════════════════════════════════════════════════════════════"
echo "DEMO 2: Policy Enforcement Engine"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Testing Zero Trust policy with different scenarios..."
echo ""

echo "Test 1: Authorized user from trusted IP"
echo "─────────────────────────────────────────"
./zero-trust-policy.sh alice database 127.0.0.1
echo ""

echo "Test 2: Unauthorized user"
echo "─────────────────────────────────────────"
./zero-trust-policy.sh mallory database 127.0.0.1 || true
echo ""

echo "Test 3: Authorized user from untrusted IP"
echo "─────────────────────────────────────────"
./zero-trust-policy.sh bob database 192.168.99.99 || true
echo ""

read -p "Press ENTER to continue to next demo..."
clear

# Demo 3: Certificates
echo "══════════════════════════════════════════════════════════════"
echo "DEMO 3: Mutual TLS Certificate Infrastructure"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Certificate Authority (CA):"
echo "─────────────────────────────────────────"
openssl x509 -in certs/ca-cert.pem -noout -subject -issuer -dates
echo ""

echo "Server Certificate:"
echo "─────────────────────────────────────────"
openssl x509 -in certs/server-cert.pem -noout -subject -issuer -dates
echo ""

echo "Client Certificate:"
echo "─────────────────────────────────────────"
openssl x509 -in certs/client-cert.pem -noout -subject -issuer -dates
echo ""

echo "Certificate Verification:"
echo "─────────────────────────────────────────"
openssl verify -CAfile certs/ca-cert.pem certs/server-cert.pem
openssl verify -CAfile certs/ca-cert.pem certs/client-cert.pem
echo ""

read -p "Press ENTER to continue to next demo..."
clear

# Demo 4: Network Namespaces
echo "══════════════════════════════════════════════════════════════"
echo "DEMO 4: Network Micro-Segmentation (requires sudo)"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Current network namespaces:"
sudo ip netns list 2>/dev/null || echo "No namespaces (will create one)"
echo ""

if [ ! -f /var/run/netns/secure-zone ]; then
    echo "Creating network namespace demonstration..."
    sudo ./network-namespace-demo.sh
else
    echo "Network namespace 'secure-zone' already exists"
    echo ""
    echo "Namespace details:"
    echo "─────────────────────────────────────────"
    sudo ip netns exec secure-zone ip addr show
fi
echo ""

read -p "Press ENTER to continue to next demo..."
clear

# Demo 5: SSH Keys
echo "══════════════════════════════════════════════════════════════"
echo "DEMO 5: Identity & Access Management"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Zero Trust SSH Key:"
echo "─────────────────────────────────────────"
if [ -f ~/.ssh/zero_trust_demo.pub ]; then
    echo "✓ Key Type: ED25519 (modern, secure)"
    echo "✓ Fingerprint:"
    ssh-keygen -lf ~/.ssh/zero_trust_demo.pub
    echo ""
    echo "Public Key:"
    cat ~/.ssh/zero_trust_demo.pub
else
    echo "✗ SSH key not found"
fi
echo ""

read -p "Press ENTER to view final summary..."
clear

# Final Summary
echo "══════════════════════════════════════════════════════════════"
echo "DEMONSTRATION COMPLETE - SUMMARY"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "✅ Components Demonstrated:"
echo ""
echo "  1. 📊 Security Monitoring Dashboard"
echo "     - Real-time security posture visibility"
echo "     - Network, user, and process monitoring"
echo ""
echo "  2. 📋 Policy Enforcement Engine"
echo "     - User authorization"
echo "     - IP whitelisting"
echo "     - Time-based access control"
echo ""
echo "  3. 🔒 Mutual TLS Infrastructure"
echo "     - Certificate Authority (CA)"
echo "     - Server and client certificates"
echo "     - Certificate verification"
echo ""
echo "  4. 🏗️  Network Micro-Segmentation"
echo "     - Isolated network namespaces"
echo "     - Virtual ethernet pairs"
echo "     - Network isolation validation"
echo ""
echo "  5. 🔐 Identity Management"
echo "     - Strong cryptographic keys (ED25519)"
echo "     - Certificate-based authentication"
echo ""
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "🎯 Zero Trust Principles Implemented:"
echo ""
echo "  ✓ Never trust, always verify"
echo "  ✓ Least privilege access"
echo "  ✓ Assume breach mentality"
echo "  ✓ Verify explicitly"
echo "  ✓ Micro-segmentation"
echo "  ✓ Continuous monitoring"
echo ""
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Thank you for viewing this Zero Trust Architecture demonstration!"
echo ""
