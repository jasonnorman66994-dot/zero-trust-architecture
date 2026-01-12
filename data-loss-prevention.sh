#!/bin/bash
# Zero Trust Data Loss Prevention (DLP) System
# Monitors and prevents unauthorized data exfiltration

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DLP_LOG="/tmp/zero-trust-dlp.log"
SENSITIVE_DATA_DIR="/tmp/zero-trust-sensitive"
QUARANTINE_DIR="/tmp/zero-trust-quarantine"

echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Zero Trust Data Loss Prevention System      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Create directories
mkdir -p "$SENSITIVE_DATA_DIR"
mkdir -p "$QUARANTINE_DIR"

# Define sensitive data patterns
declare -A PATTERNS=(
    ["CREDIT_CARD"]="\\b[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}\\b"
    ["SSN"]="\\b[0-9]{3}-[0-9]{2}-[0-9]{4}\\b"
    ["EMAIL"]="\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b"
    ["API_KEY"]="\\b[A-Za-z0-9_-]{32,}\\b"
    ["AWS_KEY"]="AKIA[0-9A-Z]{16}"
    ["PRIVATE_KEY"]="-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----"
    ["PASSWORD"]="password['\"]?\\s*[:=]\\s*['\"]?[^\\s'\"]+"
)

scan_file() {
    local file="$1"
    local findings=0
    
    echo -n "Scanning: $(basename "$file")... "
    
    for pattern_name in "${!PATTERNS[@]}"; do
        pattern="${PATTERNS[$pattern_name]}"
        
        if grep -qiE "$pattern" "$file" 2>/dev/null; then
            echo -e "\n  ${RED}✗ DETECTED${NC}: $pattern_name"
            echo "[$(date)] SENSITIVE_DATA_FOUND: $pattern_name in $file" >> "$DLP_LOG"
            ((findings++))
        fi
    done
    
    if [ "$findings" -eq 0 ]; then
        echo -e "${GREEN}✓ Clean${NC}"
        return 0
    else
        echo -e "  ${RED}Total findings: $findings${NC}"
        return 1
    fi
}

monitor_network_traffic() {
    echo "Monitoring network traffic for data exfiltration..."
    
    # Check for large data transfers
    LARGE_TRANSFERS=$(netstat -i | awk 'NR>2 {total+=$4} END {print total}')
    
    if [ -n "$LARGE_TRANSFERS" ] && [ "$LARGE_TRANSFERS" -gt 1000000 ]; then
        echo -e "${YELLOW}WARNING${NC}: Large data transfer detected: $LARGE_TRANSFERS bytes"
        echo "[$(date)] LARGE_TRANSFER: $LARGE_TRANSFERS bytes" >> "$DLP_LOG"
    else
        echo -e "${GREEN}✓ Network traffic within normal limits${NC}"
    fi
}

check_clipboard() {
    echo -n "Checking clipboard for sensitive data... "
    
    # Note: Clipboard access varies by environment
    if command -v xclip >/dev/null 2>&1; then
        CLIPBOARD_CONTENT=$(xclip -o 2>/dev/null || echo "")
        
        for pattern_name in "${!PATTERNS[@]}"; do
            pattern="${PATTERNS[$pattern_name]}"
            if echo "$CLIPBOARD_CONTENT" | grep -qiE "$pattern" 2>/dev/null; then
                echo -e "${RED}ALERT${NC}: Sensitive data in clipboard: $pattern_name"
                echo "[$(date)] CLIPBOARD_ALERT: $pattern_name" >> "$DLP_LOG"
                return 1
            fi
        done
    fi
    
    echo -e "${GREEN}OK${NC}"
    return 0
}

monitor_usb_devices() {
    echo -n "Monitoring USB devices... "
    
    USB_DEVICES=$(lsusb 2>/dev/null | wc -l)
    
    if [ "$USB_DEVICES" -gt 0 ]; then
        echo -e "${YELLOW}INFO${NC}: $USB_DEVICES USB device(s) connected"
        lsusb 2>/dev/null | while read line; do
            echo "[$(date)] USB_DEVICE: $line" >> "$DLP_LOG"
        done
    else
        echo -e "${GREEN}None${NC}"
    fi
}

scan_outbound_email() {
    echo "Scanning outbound communications..."
    
    # Check for SMTP connections
    SMTP_CONN=$(netstat -ant | grep ":25 " | grep ESTABLISHED | wc -l)
    
    if [ "$SMTP_CONN" -gt 0 ]; then
        echo -e "${YELLOW}INFO${NC}: $SMTP_CONN active SMTP connection(s)"
        echo "[$(date)] SMTP_CONNECTION: $SMTP_CONN active" >> "$DLP_LOG"
    else
        echo -e "${GREEN}✓ No active email connections${NC}"
    fi
}

enforce_dlp_policies() {
    echo ""
    echo "DLP Policy Enforcement:"
    echo "═══════════════════════════════════════════════"
    
    # Policy 1: Block sensitive data in /tmp
    echo -n "Policy 1: Scanning /tmp for sensitive data... "
    SENSITIVE_IN_TMP=0
    
    for file in /tmp/*.txt /tmp/*.csv /tmp/*.json; do
        if [ -f "$file" ] 2>/dev/null; then
            if ! scan_file "$file"; then
                # Move to quarantine
                mv "$file" "$QUARANTINE_DIR/" 2>/dev/null || true
                ((SENSITIVE_IN_TMP++))
            fi
        fi
    done
    
    if [ "$SENSITIVE_IN_TMP" -eq 0 ]; then
        echo -e "${GREEN}✓ Passed${NC}"
    else
        echo -e "${RED}✗ $SENSITIVE_IN_TMP file(s) quarantined${NC}"
    fi
    
    # Policy 2: Prevent data to untrusted IPs
    echo -n "Policy 2: Checking connections to untrusted IPs... "
    
    TRUSTED_NETWORKS=("127.0.0.0/8" "10.0.0.0/8" "192.168.0.0/16")
    UNTRUSTED_CONN=0
    
    while read conn; do
        IP=$(echo "$conn" | awk '{print $5}' | cut -d: -f1)
        
        TRUSTED=0
        for network in "${TRUSTED_NETWORKS[@]}"; do
            if [[ "$IP" == "127."* ]] || [[ "$IP" == "10."* ]] || [[ "$IP" == "192.168."* ]]; then
                TRUSTED=1
                break
            fi
        done
        
        if [ "$TRUSTED" -eq 0 ] && [ -n "$IP" ]; then
            echo -e "\n  ${YELLOW}WARNING${NC}: Connection to untrusted IP: $IP"
            echo "[$(date)] UNTRUSTED_CONNECTION: $IP" >> "$DLP_LOG"
            ((UNTRUSTED_CONN++))
        fi
    done < <(netstat -ant | grep ESTABLISHED | grep -v "127.0.0.1" | grep -v "0.0.0.0")
    
    if [ "$UNTRUSTED_CONN" -eq 0 ]; then
        echo -e "${GREEN}✓ Passed${NC}"
    else
        echo -e "${YELLOW}WARNING${NC}: $UNTRUSTED_CONN untrusted connection(s)"
    fi
    
    # Policy 3: Encrypt sensitive data at rest
    echo -n "Policy 3: Checking encryption status... "
    
    if [ -d "$SENSITIVE_DATA_DIR" ]; then
        UNENCRYPTED=$(find "$SENSITIVE_DATA_DIR" -type f ! -name "*.enc" ! -name "*.gpg" 2>/dev/null | wc -l)
        
        if [ "$UNENCRYPTED" -gt 0 ]; then
            echo -e "${YELLOW}WARNING${NC}: $UNENCRYPTED unencrypted sensitive file(s)"
        else
            echo -e "${GREEN}✓ Passed${NC}"
        fi
    else
        echo -e "${GREEN}✓ Passed${NC}"
    fi
}

generate_report() {
    echo ""
    echo "═══════════════════════════════════════════════"
    echo "           DLP MONITORING REPORT"
    echo "═══════════════════════════════════════════════"
    echo ""
    
    if [ -f "$DLP_LOG" ]; then
        TOTAL_EVENTS=$(wc -l < "$DLP_LOG")
        echo "Total events logged: $TOTAL_EVENTS"
        
        echo ""
        echo "Recent events (last 10):"
        tail -10 "$DLP_LOG" | while read line; do
            echo "  • $line"
        done
    else
        echo "No events logged yet."
    fi
    
    echo ""
    echo "Quarantined files: $(ls -1 "$QUARANTINE_DIR" 2>/dev/null | wc -l)"
    
    if [ -d "$QUARANTINE_DIR" ] && [ "$(ls -A "$QUARANTINE_DIR")" ]; then
        echo "Files in quarantine:"
        ls -lh "$QUARANTINE_DIR" | tail -n +2 | while read line; do
            echo "  • $line"
        done
    fi
}

# Main Execution
echo "Initializing DLP scan..."
echo "[$(date)] DLP Scan Started" >> "$DLP_LOG"
echo ""

monitor_network_traffic
check_clipboard
monitor_usb_devices
scan_outbound_email
enforce_dlp_policies
generate_report

echo ""
echo "DLP scan complete. Log: $DLP_LOG"
