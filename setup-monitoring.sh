#!/bin/bash
# setup-monitoring.sh - Configure automated Zero Trust monitoring

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Zero Trust - Automated Monitoring Setup                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Option 1: Run in background with nohup
echo "Option 1: Background Process (Recommended for dev environments)"
echo "──────────────────────────────────────────────────────────"
echo "  Start: nohup ./automated-monitoring.sh &"
echo "  Stop:  pkill -f automated-monitoring.sh"
echo "  View:  tail -f /tmp/zero-trust-monitoring.log"
echo ""

# Option 2: Cron job
echo "Option 2: Cron Job (Periodic monitoring)"
echo "──────────────────────────────────────────────────────────"
echo "  Add to crontab:"
echo "  */5 * * * * cd /workspaces/git && ./security-monitoring.sh >> /tmp/zero-trust-cron.log 2>&1"
echo ""
echo "  Install: (crontab -l 2>/dev/null; echo '*/5 * * * * cd /workspaces/git && ./security-monitoring.sh >> /tmp/zero-trust-cron.log 2>&1') | crontab -"
echo ""

# Option 3: Systemd service
echo "Option 3: Systemd Service (Production environments)"
echo "──────────────────────────────────────────────────────────"
echo "  sudo cp /tmp/zero-trust-monitor.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable zero-trust-monitor"
echo "  sudo systemctl start zero-trust-monitor"
echo "  sudo systemctl status zero-trust-monitor"
echo ""

# Option 4: Watch command
echo "Option 4: Watch Command (Simple terminal-based)"
echo "──────────────────────────────────────────────────────────"
echo "  watch -n 60 './security-monitoring.sh'"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo ""
read -p "Choose an option to set up now (1-4, or 'skip'): " choice

case $choice in
    1)
        echo ""
        echo "Starting background monitoring..."
        nohup ./automated-monitoring.sh > /tmp/zero-trust-monitor-nohup.log 2>&1 &
        PID=$!
        echo "✓ Monitoring started in background (PID: $PID)"
        echo "  View logs: tail -f /tmp/zero-trust-monitoring.log"
        echo "  View alerts: tail -f /tmp/zero-trust-alerts.log"
        echo "  Stop: kill $PID"
        echo ""
        sleep 2
        tail -n 5 /tmp/zero-trust-monitoring.log
        ;;
    2)
        echo ""
        echo "Installing cron job..."
        (crontab -l 2>/dev/null; echo "*/5 * * * * cd /workspaces/git && ./security-monitoring.sh >> /tmp/zero-trust-cron.log 2>&1") | crontab -
        echo "✓ Cron job installed (runs every 5 minutes)"
        echo "  View: crontab -l"
        echo "  Logs: tail -f /tmp/zero-trust-cron.log"
        echo "  Remove: crontab -r"
        ;;
    3)
        echo ""
        if [ "$EUID" -ne 0 ]; then
            echo "Installing systemd service (requires sudo)..."
            sudo cp /tmp/zero-trust-monitor.service /etc/systemd/system/
            sudo systemctl daemon-reload
            sudo systemctl enable zero-trust-monitor
            sudo systemctl start zero-trust-monitor
            echo "✓ Systemd service installed and started"
            echo ""
            sudo systemctl status zero-trust-monitor --no-pager
        else
            echo "Please run as non-root user and it will request sudo when needed"
        fi
        ;;
    4)
        echo ""
        echo "Starting watch command (Press Ctrl+C to exit)..."
        sleep 2
        watch -n 60 './security-monitoring.sh'
        ;;
    *)
        echo "Skipping automated setup. You can run any option manually later."
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✓ Monitoring setup complete!"
