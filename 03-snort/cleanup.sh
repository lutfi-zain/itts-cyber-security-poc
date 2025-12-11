#!/bin/bash

# ============================================
# Lab 3: Snort Cleanup Script
# Purpose: Stop Snort and backup logs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="/home/ubuntu/logs/snort-$(date +%Y%m%d-%H%M%S)"
ALERT_FILE="/var/log/snort/alert"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lab 3: Snort Cleanup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[ERROR]${NC} Please run with sudo"
    exit 1
fi

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Stop Snort
print_info "Stopping Snort IDS..."

# Try to get PID from file
if [ -f /tmp/snort.pid ]; then
    SNORT_PID=$(cat /tmp/snort.pid)
    if ps -p "$SNORT_PID" > /dev/null 2>&1; then
        kill "$SNORT_PID"
        sleep 2
        print_status "Snort stopped (PID: ${SNORT_PID})"
    fi
    rm /tmp/snort.pid
fi

# Force kill any remaining Snort processes
if pgrep -x "snort" > /dev/null; then
    print_info "Force stopping remaining Snort processes..."
    pkill -9 snort
    sleep 1
fi

# Verify stopped
if pgrep -x "snort" > /dev/null; then
    echo -e "${RED}[WARNING]${NC} Some Snort processes may still be running"
else
    print_status "All Snort processes stopped"
fi

# Backup logs
print_info "Backing up Snort logs..."
mkdir -p "$BACKUP_DIR"

# Copy alert file
if [ -f "$ALERT_FILE" ]; then
    cp "$ALERT_FILE" "$BACKUP_DIR/"
    print_status "Alert file backed up"
else
    print_info "No alert file found to backup"
fi

# Copy other log files
cp -r /var/log/snort/* "$BACKUP_DIR/" 2>/dev/null || true

# Set permissions
chown -R ubuntu:ubuntu "$BACKUP_DIR"
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
if [ -f "${BACKUP_DIR}/alert" ]; then
    ALERT_COUNT=$(grep -c "^\[" "${BACKUP_DIR}/alert" 2>/dev/null || echo "0")
    echo -e "Total alerts captured: ${RED}${ALERT_COUNT}${NC}"
fi

echo ""
echo -e "${GREEN}[DONE]${NC} Snort lab cleanup completed"
echo -e "${GREEN}[SUCCESS]${NC} All three labs (Cowrie, UFW, Snort) completed!"
echo ""
echo -e "Backed up logs locations:"
echo -e "  ${YELLOW}~/logs/cowrie-*/${NC}"
echo -e "  ${YELLOW}~/logs/ufw-*/${NC}"
echo -e "  ${YELLOW}~/logs/snort-*/${NC}"
echo ""