#!/bin/bash

# ============================================
# Lab 1: Cowrie Cleanup Script
# Purpose: Stop Cowrie and backup logs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
COWRIE_DIR="/home/ubuntu-server/cowrie"
BACKUP_DIR="/home/ubuntu-server/logs/cowrie-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lab 1: Cowrie Cleanup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Stop Cowrie
print_info "Stopping Cowrie honeypot..."
sudo -u ubuntu-server bash << 'EOSU'
cd /home/ubuntu-server/cowrie
source cowrie-env/bin/activate
bin/cowrie stop
EOSU

sleep 2

# Check if stopped
if pgrep -f "cowrie" > /dev/null; then
    echo -e "${RED}[WARNING]${NC} Cowrie still running, force killing..."
    pkill -f cowrie
    sleep 1
fi

print_status "Cowrie stopped"

# Backup logs
print_info "Backing up logs to ${BACKUP_DIR}..."
mkdir -p "$BACKUP_DIR"
cp -r "${COWRIE_DIR}/var/log/cowrie/"* "$BACKUP_DIR/" 2>/dev/null || true
chown -R ubuntu-server:ubuntu-server "$BACKUP_DIR"
print_status "Logs backed up"

# Display backup location
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cleanup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Status: ${GREEN}Stopped${NC}"
echo -e "Logs backed up to: ${YELLOW}${BACKUP_DIR}${NC}"
echo ""
echo -e "${GREEN}[DONE]${NC} Cowrie lab cleanup completed"
echo -e "Next lab: ${YELLOW}Lab 2 - UFW Firewall${NC}"
echo ""