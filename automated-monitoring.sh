#!/bin/bash
# automated-monitoring.sh - Continuous Zero Trust monitoring service

MONITOR_INTERVAL=60  # seconds
LOG_FILE="/tmp/zero-trust-monitoring.log"
ALERT_FILE="/tmp/zero-trust-alerts.log"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Zero Trust - Automated Monitoring Service            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Starting continuous monitoring..."
echo "Interval: ${MONITOR_INTERVAL} seconds"
echo "Log: $LOG_FILE"
echo "Alerts: $ALERT_FILE"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Initialize log files
echo "=== Zero Trust Automated Monitoring Started: $(date) ===" > "$LOG_FILE"
echo "=== Zero Trust Security Alerts ===" > "$ALERT_FILE"

# Alert thresholds
MAX_CONNECTIONS=50
MAX_LISTENING_PORTS=20
MAX_ROOT_PROCESSES=20

monitor_cycle() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check network connections
    CONNECTIONS=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)
    LISTENING=$(netstat -tuln 2>/dev/null | grep LISTEN | wc -l)
    
    # Check processes
    ROOT_PROCS=$(ps aux 2>/dev/null | grep -v grep | grep "^root" | wc -l)
    
    # Check namespace
    NAMESPACES=$(sudo ip netns list 2>/dev/null | wc -l)
    
    # Check certificates
    if [ -f /workspaces/git/certs/ca-cert.pem ]; then
        CERT_STATUS="✓"
    else
        CERT_STATUS="✗"
    fi
    
    # Log current state
    echo "[$TIMESTAMP] Connections: $CONNECTIONS | Listening: $LISTENING | Root Procs: $ROOT_PROCS | Namespaces: $NAMESPACES | Certs: $CERT_STATUS" >> "$LOG_FILE"
    
    # Check for alerts
    ALERT=false
    
    if [ $CONNECTIONS -gt $MAX_CONNECTIONS ]; then
        echo "[$TIMESTAMP] ALERT: High connection count: $CONNECTIONS (threshold: $MAX_CONNECTIONS)" >> "$ALERT_FILE"
        ALERT=true
    fi
    
    if [ $LISTENING -gt $MAX_LISTENING_PORTS ]; then
        echo "[$TIMESTAMP] ALERT: Too many listening ports: $LISTENING (threshold: $MAX_LISTENING_PORTS)" >> "$ALERT_FILE"
        ALERT=true
    fi
    
    if [ $ROOT_PROCS -gt $MAX_ROOT_PROCESSES ]; then
        echo "[$TIMESTAMP] ALERT: High root process count: $ROOT_PROCS (threshold: $MAX_ROOT_PROCESSES)" >> "$ALERT_FILE"
        ALERT=true
    fi
    
    if [ $NAMESPACES -eq 0 ]; then
        echo "[$TIMESTAMP] ALERT: No network namespaces detected!" >> "$ALERT_FILE"
        ALERT=true
    fi
    
    # Display status
    if $ALERT; then
        echo -e "[$TIMESTAMP] ⚠️  ALERT - Check $ALERT_FILE"
    else
        echo "[$TIMESTAMP] ✓ All checks passed - Connections: $CONNECTIONS, Listening: $LISTENING, Namespaces: $NAMESPACES"
    fi
}

# Trap Ctrl+C
trap 'echo ""; echo "Monitoring stopped."; echo "Log: $LOG_FILE"; echo "Alerts: $ALERT_FILE"; exit 0' INT

# Main monitoring loop
while true; do
    monitor_cycle
    sleep $MONITOR_INTERVAL
done
