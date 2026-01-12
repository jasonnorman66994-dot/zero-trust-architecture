#!/bin/bash
# security-monitoring.sh - Zero Trust continuous monitoring

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║        Zero Trust Security Monitoring Dashboard          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📊 System Security Posture - $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 1. Network Connections
echo "🌐 ACTIVE NETWORK CONNECTIONS"
echo "───────────────────────────────────────────────────────────"
ESTABLISHED=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)
LISTENING=$(netstat -tuln 2>/dev/null | grep LISTEN | wc -l)
echo "  Established connections: $ESTABLISHED"
echo "  Listening ports: $LISTENING"
echo ""
echo "  Top 5 listening services:"
ss -tulpn 2>/dev/null | grep LISTEN | head -5 | awk '{print "    - " $1 " on port " $5}'
echo ""

# 2. User Activity
echo "👥 USER ACTIVITY"
echo "───────────────────────────────────────────────────────────"
echo "  Currently logged in:"
who | awk '{print "    - " $1 " from " $5 " at " $3 " " $4}' || echo "    (none)"
echo ""
echo "  Recent logins (last 5):"
last -n 5 2>/dev/null | head -5 | awk '{print "    - " $1 " " $3 " " $4 " " $5}' || echo "    (no data)"
echo ""

# 3. Process Security
echo "⚙️  PROCESS SECURITY"
echo "───────────────────────────────────────────────────────────"
ROOT_PROCS=$(ps aux 2>/dev/null | grep -v grep | grep "^root" | wc -l)
USER_PROCS=$(ps aux 2>/dev/null | grep -v grep | grep -v "^root" | wc -l)
echo "  Root processes: $ROOT_PROCS"
echo "  User processes: $USER_PROCS"
echo ""

# 4. SSH Security
echo "🔐 SSH SECURITY STATUS"
echo "───────────────────────────────────────────────────────────"
if [ -f ~/.ssh/zero_trust_demo.pub ]; then
    echo "  ✓ Zero Trust SSH key exists"
    echo "  Key fingerprint: $(ssh-keygen -lf ~/.ssh/zero_trust_demo.pub 2>/dev/null | awk '{print $2}')"
else
    echo "  ✗ Zero Trust SSH key not found"
fi
echo ""

# 5. Zero Trust Policy Status
echo "📋 ZERO TRUST POLICY ENGINE"
echo "───────────────────────────────────────────────────────────"
if [ -f /tmp/zero-trust/authorized-users.txt ]; then
    USERS=$(wc -l < /tmp/zero-trust/authorized-users.txt)
    echo "  ✓ Policy engine configured"
    echo "  Authorized users: $USERS"
    echo "    $(cat /tmp/zero-trust/authorized-users.txt | tr '\n' ', ' | sed 's/,$//')"
else
    echo "  ✗ Policy engine not configured"
fi

if [ -f /tmp/zero-trust/trusted-ips.txt ]; then
    IPS=$(wc -l < /tmp/zero-trust/trusted-ips.txt)
    echo "  Trusted IPs: $IPS"
    echo "    $(cat /tmp/zero-trust/trusted-ips.txt | tr '\n' ', ' | sed 's/,$//')"
fi
echo ""

# 6. Network Segmentation
echo "🏗️  NETWORK SEGMENTATION"
echo "───────────────────────────────────────────────────────────"
NAMESPACES=$(sudo ip netns list 2>/dev/null | wc -l)
if [ $NAMESPACES -gt 0 ]; then
    echo "  ✓ Network namespaces active: $NAMESPACES"
    sudo ip netns list 2>/dev/null | sed 's/^/    - /'
else
    echo "  ○ No network namespaces configured"
fi
echo ""

# 7. Certificate Status
echo "🔒 CERTIFICATE INFRASTRUCTURE"
echo "───────────────────────────────────────────────────────────"
if [ -f /workspaces/git/certs/ca-cert.pem ]; then
    echo "  ✓ Certificate Authority configured"
    CA_EXPIRE=$(openssl x509 -in /workspaces/git/certs/ca-cert.pem -noout -enddate 2>/dev/null | cut -d= -f2)
    echo "  CA expires: $CA_EXPIRE"
    
    if [ -f /workspaces/git/certs/server-cert.pem ]; then
        echo "  ✓ Server certificate present"
    fi
    
    if [ -f /workspaces/git/certs/client-cert.pem ]; then
        echo "  ✓ Client certificate present"
    fi
else
    echo "  ✗ Certificate infrastructure not configured"
fi
echo ""

# 8. System Resources
echo "💻 SYSTEM RESOURCES"
echo "───────────────────────────────────────────────────────────"
echo "  Load average: $(uptime | awk -F'load average:' '{print $2}')"
MEM_USED=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')
MEM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')
echo "  Memory: $MEM_USED / $MEM_TOTAL"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "✅ Security monitoring scan complete"
echo ""
echo "💡 TIP: Run this script periodically to monitor your"
echo "   Zero Trust architecture health"
echo "═══════════════════════════════════════════════════════════"
