#!/bin/bash
# author lutfi

# ============================================
# Lab 3: Suricata Cleanup Script
# Purpose: Stop Suricata and backup logs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="$HOME/logs/suricata-$(date +%Y%m%d-%H%M%S)"
ALERT_FILE="/var/log/suricata/fast.log"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lab 3: Suricata Cleanup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then 
    echo -e "${RED}[ERROR]${NC} Please run with sudo"
    exit 1
fi

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Stop Suricata
print_info "Stopping Suricata IDS..."

# Try to get PID from file
if [ -f /tmp/suricata.pid ]; then
    SURICATA_PID=$(cat /tmp/suricata.pid)
    if ps -p "$SURICATA_PID" > /dev/null 2>&1; then
        kill "$SURICATA_PID"
        sleep 2
        print_status "Suricata stopped (PID: ${SURICATA_PID})"
    fi
    rm /tmp/suricata.pid
fi

# Force kill any remaining Suricata processes
if pgrep -x "suricata" > /dev/null; then
    print_info "Force stopping remaining Suricata processes..."
    pkill -9 suricata
    sleep 1
fi

# Stop systemd service if running
systemctl stop suricata 2>/dev/null || true

# Verify stopped
if pgrep -x "suricata" > /dev/null; then
    echo -e "${RED}[WARNING]${NC} Some Suricata processes may still be running"
else
    print_status "All Suricata processes stopped"
fi

# Backup logs
print_info "Backing up Suricata logs..."
mkdir -p "$BACKUP_DIR"

# Copy alert file
if [ -f "$ALERT_FILE" ]; then
    cp "$ALERT_FILE" "$BACKUP_DIR/"
    print_status "Alert file backed up"
else
    print_info "No alert file found to backup"
fi

# Copy other log files
cp -r /var/log/suricata/* "$BACKUP_DIR/" 2>/dev/null || true

# Set permissions for regular user
if [ -n "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$BACKUP_DIR"
fi
print_status "Logs backed up to ${BACKUP_DIR}"

# Clear current logs for next lab session
print_info "Clearing current alert logs..."
> "$ALERT_FILE" 2>/dev/null || true
print_status "Alert logs cleared"

# Display summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cleanup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Status: ${GREEN}Stopped${NC}"
echo -e "Logs backed up to: ${YELLOW}${BACKUP_DIR}${NC}"
echo ""

# Display backed up alerts count
if [ -f "${BACKUP_DIR}/fast.log" ]; then
    ALERT_COUNT=$(grep -c "^\[" "${BACKUP_DIR}/fast.log" 2>/dev/null || echo "0")
    echo -e "Total alerts captured: ${RED}${ALERT_COUNT}${NC}"
fi

echo ""
echo -e "${GREEN}[DONE]${NC} Suricata lab cleanup completed"
echo -e "${GREEN}[SUCCESS]${NC} All three labs (Cowrie, UFW, Suricata) completed!"
echo ""
echo -e "Backed up logs locations:"
echo -e "  ${YELLOW}~/logs/cowrie-*/${NC}"
echo -e "  ${YELLOW}~/logs/ufw-*/${NC}"
echo -e "  ${YELLOW}~/logs/suricata-*/${NC}"
echo ""