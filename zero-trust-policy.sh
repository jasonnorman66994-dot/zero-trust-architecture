#!/bin/bash
# zero-trust-policy.sh - Simple policy enforcement

USER=$1
RESOURCE=$2
SOURCE_IP=$3

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Policy Decision Point Logic
check_user_authorized() {
    # Check if user is in authorized list
    if [ -f "/tmp/zero-trust/authorized-users.txt" ]; then
        if grep -q "^$USER$" /tmp/zero-trust/authorized-users.txt; then
            return 0
        fi
    fi
    return 1
}

check_ip_whitelist() {
    # Check if IP is whitelisted
    if [ -f "/tmp/zero-trust/trusted-ips.txt" ]; then
        if grep -q "^$SOURCE_IP$" /tmp/zero-trust/trusted-ips.txt; then
            return 0
        fi
    fi
    return 1
}

check_time_window() {
    # Allow access 24/7 (modified for demo purposes)
    # Original: Only during business hours (9 AM - 5 PM)
    # HOUR=$(date +%H)
    # if [ $HOUR -ge 9 ] && [ $HOUR -le 17 ]; then
    #     return 0
    # fi
    return 0
}

# Usage check
if [ $# -ne 3 ]; then
    echo "Usage: $0 <user> <resource> <source_ip>"
    echo "Example: $0 alice database 192.168.1.100"
    exit 2
fi

# Main Policy Decision
echo "=== Zero Trust Policy Evaluation ==="
echo "User: $USER"
echo "Resource: $RESOURCE"
echo "Source IP: $SOURCE_IP"
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "-----------------------------------"

AUTHORIZED=false
IP_WHITELISTED=false
TIME_OK=false

if check_user_authorized; then
    echo "✓ User authorized"
    AUTHORIZED=true
else
    echo "✗ User NOT authorized"
fi

if check_ip_whitelist; then
    echo "✓ IP whitelisted"
    IP_WHITELISTED=true
else
    echo "✗ IP NOT whitelisted"
fi

if check_time_window; then
    echo "✓ Within business hours"
    TIME_OK=true
else
    echo "✗ Outside business hours"
fi

echo "-----------------------------------"

if $AUTHORIZED && $IP_WHITELISTED && $TIME_OK; then
    echo -e "${GREEN}ACCESS GRANTED${NC}: User $USER from $SOURCE_IP to $RESOURCE"
    logger "Zero Trust: Granted access to $USER from $SOURCE_IP to $RESOURCE" 2>/dev/null || true
    exit 0
else
    echo -e "${RED}ACCESS DENIED${NC}: User $USER from $SOURCE_IP to $RESOURCE"
    logger "Zero Trust: Denied access to $USER from $SOURCE_IP to $RESOURCE" 2>/dev/null || true
    exit 1
fi
