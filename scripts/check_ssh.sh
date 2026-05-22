#!/bin/bash
# ==============================================================================
# Script: check_ssh.sh
# Purpose: Watchdog daemon to monitor and auto-recover the SSH service.
# Trigger: Executed via system crontab (e.g., every 5 minutes).
# ==============================================================================

SERVICE="ssh"
TELEGRAM_BOT_TOKEN="<YOUR_TELEGRAM_TOKEN>"
TELEGRAM_CHAT_ID="<YOUR_CHAT_ID>"

# Check if the service is running quietly
if ! systemctl is-active --quiet $SERVICE; then
    
    # Attempt to restart the service
    systemctl restart $SERVICE
    
    # Build the alert message
    MESSAGE="⚠️ [Watchdog Alert] The $SERVICE service went down on the Linux VM. Auto-recovery triggered and service restarted."
    
    # Send notification via Telegram API (Silent failure if API is unreachable)
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${MESSAGE}" > /dev/null
        
    # Log to local syslog
    logger "Watchdog: $SERVICE was down and has been restarted. Telegram alert sent."
fi
