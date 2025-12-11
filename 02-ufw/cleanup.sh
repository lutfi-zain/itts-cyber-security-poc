#!/bin/bash

# ============================================
# Lab 2: UFW Cleanup Script
# Purpose: Unblock client and backup logs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CLIENT_IP="192.168.120.123"
BACKUP_DIR="/home/ubuntu-server/logs/ufw-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lab 2: UFW Cleanup${NC}"
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

# Backup logs
print_info "Backing up UFW logs..."
mkdir -p "$BACKUP_DIR"
cp /var/log/ufw.log "$BACKUP_DIR/" 2>/dev/null || true
chown -R ubuntu-server:ubuntu-server "$BACKUP_DIR"
print_status "Logs backed up to ${BACKUP_DIR}"

# Remove client block rule
print_info "Removing block rule for ${CLIENT_IP}..."
ufw delete deny from "$CLIENT_IP" 2>/dev/null || print_info "Rule not found or already removed"
print_status "Block rule removed"

# Reload UFW
print_info "Reloading UFW..."
ufw reload > /dev/null 2>&1
print_status "UFW reloaded"

# Display current rules
echo ""
echo -e "${YELLOW}=== Current UFW Rules ===${NC}"
ufw status numbered
echo ""

# Verify client can connect again
print_info "Verifying client access is restored..."
if timeout 5 ping -c 2 "$CLIENT_IP" > /dev/null 2>&1; then
    print_status "Client is now accessible"
else
    echo -e "${YELLOW}[NOTE]${NC} Cannot ping client (client may be inactive)"
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cleanup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Client IP unblocked: ${GREEN}${CLIENT_IP}${NC}"
echo -e "Logs backed up to: ${YELLOW}${BACKUP_DIR}${NC}"
echo -e "UFW Status: ${GREEN}Active (default rules only)${NC}"
echo ""
echo -e "${GREEN}[DONE]${NC} UFW lab cleanup completed"
echo -e "Next lab: ${YELLOW}Lab 3 - Snort IDS${NC}"
echo ""