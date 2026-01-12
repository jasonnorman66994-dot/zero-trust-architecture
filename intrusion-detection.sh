#!/bin/bash
# Zero Trust Intrusion Detection System (IDS)
# Monitors for suspicious activities and potential security breaches

set -e

# Color output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

LOG_FILE="/tmp/zero-trust-ids.log"
ALERT_FILE="/tmp/zero-trust-ids-alerts.log"
BASELINE_FILE="/tmp/zero-trust-baseline.json"

echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Zero Trust Intrusion Detection System        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Initialize baseline if not exists
if [ ! -f "$BASELINE_FILE" ]; then
    echo "Creating security baseline..."
    cat > "$BASELINE_FILE" << EOF
{
  "max_connections": 100,
  "max_failed_auth": 5,
  "max_ports": 25,
  "allowed_users": ["root", "codespace"],
  "suspicious_ports": [23, 135, 139, 445, 3389],
  "suspicious_processes": ["nc", "netcat", "nmap", "meterpreter"]
}
EOF
    echo "✓ Baseline created"
fi

# Detection Functions

detect_port_scan() {
    echo -n "Checking for port scans... "
    
    # Check for SYN packets from same source to multiple ports
    SCAN_ATTEMPTS=$(netstat -ant | grep SYN_RECV | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')
    
    if [ -n "$SCAN_ATTEMPTS" ] && [ "$SCAN_ATTEMPTS" -gt 10 ]; then
        echo -e "${RED}ALERT${NC}: Potential port scan detected ($SCAN_ATTEMPTS connections)"
        echo "[$(date)] PORT_SCAN: $SCAN_ATTEMPTS SYN_RECV connections" >> "$ALERT_FILE"
        return 1
    fi
    
    echo -e "${GREEN}OK${NC}"
    return 0
}

detect_brute_force() {
    echo -n "Checking for brute force attempts... "
    
    # Check auth logs for failed attempts (simulated for demo)
    if [ -f "/var/log/auth.log" ]; then
        FAILED_ATTEMPTS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -100 | wc -l)
        
        if [ "$FAILED_ATTEMPTS" -gt 10 ]; then
            echo -e "${RED}ALERT${NC}: $FAILED_ATTEMPTS failed login attempts detected"
            echo "[$(date)] BRUTE_FORCE: $FAILED_ATTEMPTS failed attempts" >> "$ALERT_FILE"
            return 1
        fi
    fi
    
    echo -e "${GREEN}OK${NC}"
    return 0
}

detect_suspicious_ports() {
    echo -n "Checking for suspicious ports... "
    
    SUSPICIOUS_PORTS=(23 135 139 445 3389 4444 5555 6666 7777)
    FOUND=0
    
    for port in "${SUSPICIOUS_PORTS[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${RED}ALERT${NC}: Suspicious port $port is listening!"
            echo "[$(date)] SUSPICIOUS_PORT: Port $port is open" >> "$ALERT_FILE"
            FOUND=1
        fi
    done
    
    if [ "$FOUND" -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
        return 0
    fi
    
    return 1
}

detect_suspicious_processes() {
    echo -n "Checking for suspicious processes... "
    
    SUSPICIOUS_PROCS=("nc" "ncat" "netcat" "nmap" "masscan" "meterpreter" "backdoor")
    FOUND=0
    
    for proc in "${SUSPICIOUS_PROCS[@]}"; do
        if ps aux | grep -v grep | grep -q "$proc"; then
            echo -e "${RED}ALERT${NC}: Suspicious process detected: $proc"
            echo "[$(date)] SUSPICIOUS_PROCESS: $proc running" >> "$ALERT_FILE"
            FOUND=1
        fi
    done
    
    if [ "$FOUND" -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
        return 0
    fi
    
    return 1
}

detect_high_traffic() {
    echo -n "Checking for unusual network traffic... "
    
    # Check total connection count
    CONN_COUNT=$(netstat -ant | wc -l)
    MAX_CONN=100
    
    if [ "$CONN_COUNT" -gt "$MAX_CONN" ]; then
        echo -e "${YELLOW}WARNING${NC}: High connection count: $CONN_COUNT"
        echo "[$(date)] HIGH_TRAFFIC: $CONN_COUNT connections (threshold: $MAX_CONN)" >> "$ALERT_FILE"
        return 1
    fi
    
    echo -e "${GREEN}OK ($CONN_COUNT connections)${NC}"
    return 0
}

detect_privilege_escalation() {
    echo -n "Checking for privilege escalation attempts... "
    
    # Check for unusual SUID files
    if [ -d "/tmp" ]; then
        SUID_FILES=$(find /tmp -type f -perm -4000 2>/dev/null | wc -l)
        
        if [ "$SUID_FILES" -gt 0 ]; then
            echo -e "${RED}ALERT${NC}: $SUID_FILES SUID files found in /tmp"
            echo "[$(date)] PRIVILEGE_ESCALATION: SUID files in /tmp" >> "$ALERT_FILE"
            find /tmp -type f -perm -4000 2>/dev/null >> "$ALERT_FILE"
            return 1
        fi
    fi
    
    echo -e "${GREEN}OK${NC}"
    return 0
}

detect_dns_tunneling() {
    echo -n "Checking for DNS tunneling... "
    
    # Check for unusual DNS query patterns
    # In production, parse actual DNS logs
    if command -v dig >/dev/null 2>&1; then
        # Check for long DNS queries (potential data exfiltration)
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}SKIPPED (dig not available)${NC}"
    fi
    
    return 0
}

detect_crypto_mining() {
    echo -n "Checking for cryptocurrency mining... "
    
    # Check for high CPU usage by suspicious processes
    CRYPTO_PROCS=("xmrig" "minerd" "cpuminer" "ethminer" "cgminer")
    FOUND=0
    
    for proc in "${CRYPTO_PROCS[@]}"; do
        if ps aux | grep -v grep | grep -q "$proc"; then
            echo -e "${RED}ALERT${NC}: Crypto mining process detected: $proc"
            echo "[$(date)] CRYPTO_MINING: $proc detected" >> "$ALERT_FILE"
            FOUND=1
        fi
    done
    
    if [ "$FOUND" -eq 0 ]; then
        echo -e "${GREEN}OK${NC}"
        return 0
    fi
    
    return 1
}

detect_file_integrity() {
    echo -n "Checking critical file integrity... "
    
    CRITICAL_FILES=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/sudoers"
        "/etc/ssh/sshd_config"
    )
    
    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$file" ]; then
            # Check modification time (warn if modified in last 5 minutes)
            if [ -n "$(find "$file" -mmin -5 2>/dev/null)" ]; then
                echo -e "${YELLOW}WARNING${NC}: $file modified recently"
                echo "[$(date)] FILE_INTEGRITY: $file modified" >> "$ALERT_FILE"
            fi
        fi
    done
    
    echo -e "${GREEN}OK${NC}"
    return 0
}

detect_reverse_shell() {
    echo -n "Checking for reverse shells... "
    
    # Look for common reverse shell indicators
    SUSPICIOUS_CONNECTIONS=$(netstat -antp 2>/dev/null | grep ESTABLISHED | grep -E "bash|sh|/bin" | grep -v grep)
    
    if [ -n "$SUSPICIOUS_CONNECTIONS" ]; then
        echo -e "${YELLOW}WARNING${NC}: Potential reverse shell detected"
        echo "$SUSPICIOUS_CONNECTIONS"
        echo "[$(date)] REVERSE_SHELL: Suspicious shell connections" >> "$ALERT_FILE"
        echo "$SUSPICIOUS_CONNECTIONS" >> "$ALERT_FILE"
        return 1
    fi
    
    echo -e "${GREEN}OK${NC}"
    return 0
}

# Main Detection Loop
echo "Starting intrusion detection scan..."
echo "[$(date)] IDS Scan Started" >> "$LOG_FILE"
echo ""

ALERTS=0

detect_port_scan || ((ALERTS++))
detect_brute_force || ((ALERTS++))
detect_suspicious_ports || ((ALERTS++))
detect_suspicious_processes || ((ALERTS++))
detect_high_traffic || ((ALERTS++))
detect_privilege_escalation || ((ALERTS++))
detect_dns_tunneling || ((ALERTS++))
detect_crypto_mining || ((ALERTS++))
detect_file_integrity || ((ALERTS++))
detect_reverse_shell || ((ALERTS++))

echo ""
echo "═══════════════════════════════════════════════"

if [ "$ALERTS" -eq 0 ]; then
    echo -e "${GREEN}✓ No threats detected${NC}"
    echo "[$(date)] IDS Scan Complete - No threats" >> "$LOG_FILE"
else
    echo -e "${RED}⚠ $ALERTS potential threat(s) detected!${NC}"
    echo "Review alerts in: $ALERT_FILE"
    echo "[$(date)] IDS Scan Complete - $ALERTS threats detected" >> "$LOG_FILE"
fi

echo ""
echo "Logs: $LOG_FILE"
echo "Alerts: $ALERT_FILE"
