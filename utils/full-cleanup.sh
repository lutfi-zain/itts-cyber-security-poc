#!/bin/bash
# author lutfi

# ============================================
# Utility: Full System Cleanup
# Purpose: Emergency cleanup - stop all services
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED}  FULL SYSTEM CLEANUP${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}WARNING:${NC} This will:"
echo "  - Stop all Cowrie, Snort processes"
echo "  - Reset UFW firewall rules"
echo "  - Backup all logs"
echo "  - Reset system to clean state"
echo ""
echo -n "Are you sure? (yes/no): "
read CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

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

echo ""
echo -e "${BLUE}Starting full cleanup...${NC}"
echo ""

# 1. Stop Cowrie
print_info "Stopping Cowrie..."
if [ -d "/home/ubuntu/cowrie" ]; then
    sudo -u ubuntu bash -c "cd /home/ubuntu/cowrie && source cowrie-env/bin/activate && bin/cowrie stop" 2>/dev/null || true
    pkill -f cowrie 2>/dev/null || true
    print_status "Cowrie stopped"
else
    echo -e "${YELLOW}[SKIP]${NC} Cowrie not found"
fi

# 2. Stop Snort
print_info "Stopping Snort..."
pkill -9 snort 2>/dev/null || true
rm -f /tmp/snort.pid 2>/dev/null || true
print_status "Snort stopped"

# 3. Reset UFW
print_info "Resetting UFW firewall..."
ufw --force reset > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1
echo "y" | ufw enable > /dev/null 2>&1
print_status "UFW reset to default (SSH allowed)"

# 4. Backup all logs
print_info "Backing up all logs..."
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT="/home/ubuntu/logs/full-cleanup-${BACKUP_TIMESTAMP}"
mkdir -p "$BACKUP_ROOT"

# Cowrie
if [ -d "/home/ubuntu/cowrie/var/log" ]; then
    mkdir -p "${BACKUP_ROOT}/cowrie"
    cp -r /home/ubuntu/cowrie/var/log/cowrie/* "${BACKUP_ROOT}/cowrie/" 2>/dev/null || true
fi

# UFW
if [ -f "/var/log/ufw.log" ]; then
    mkdir -p "${BACKUP_ROOT}/ufw"
    cp /var/log/ufw.log "${BACKUP_ROOT}/ufw/" 2>/dev/null || true
fi

# Snort
if [ -d "/var/log/snort" ]; then
    mkdir -p "${BACKUP_ROOT}/snort"
    cp -r /var/log/snort/* "${BACKUP_ROOT}/snort/" 2>/dev/null || true
fi

chown -R ubuntu:ubuntu "$BACKUP_ROOT"
print_status "Logs backed up to ${BACKUP_ROOT}"

# 5. Clear current logs
print_info "Clearing current logs..."
> /var/log/ufw.log 2>/dev/null || true
> /var/log/snort/alert 2>/dev/null || true
print_status "Current logs cleared"

# 6. Check running processes
echo ""
echo -e "${YELLOW}=== Process Check ===${NC}"
if pgrep -f cowrie > /dev/null; then
    echo -e "${RED}[WARNING]${NC} Cowrie still running"
else
    echo -e "${GREEN}✓${NC} Cowrie stopped"
fi

if pgrep snort > /dev/null; then
    echo -e "${RED}[WARNING]${NC} Snort still running"
else
    echo -e "${GREEN}✓${NC} Snort stopped"
fi

# 7. Display UFW status
echo ""
echo -e "${YELLOW}=== UFW Status ===${NC}"
ufw status

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cleanup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Status: ${GREEN}All services stopped${NC}"
echo -e "Firewall: ${GREEN}Reset to default${NC}"
echo -e "Logs backed up: ${YELLOW}${BACKUP_ROOT}${NC}"
echo ""
echo -e "${GREEN}[DONE]${NC} Full system cleanup completed"
echo "System is ready for fresh lab session"
echo ""