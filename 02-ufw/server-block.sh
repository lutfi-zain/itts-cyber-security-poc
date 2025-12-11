#!/bin/bash

# ============================================
# Lab 2: UFW - Block Client IP
# Purpose: Block client IP to demonstrate firewall
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLIENT_IP="192.168.120.123"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Blocking Client IP: ${CLIENT_IP}${NC}"
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

# Block client IP
print_info "Adding UFW rule to block ${CLIENT_IP}..."
ufw insert 1 deny from "$CLIENT_IP" comment 'Blocked client for lab demo'
print_status "IP blocked: ${CLIENT_IP}"

# Reload UFW
print_info "Reloading UFW..."
ufw reload > /dev/null 2>&1
print_status "UFW reloaded"

# Show status
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Current UFW Rules${NC}"
echo -e "${BLUE}========================================${NC}"
ufw status numbered
echo ""

echo -e "${RED}[BLOCKED]${NC} Client IP ${RED}${CLIENT_IP}${NC} is now blocked!"
echo ""
echo -e "Next step: Test from client VM (should fail)"
echo -e "  ${YELLOW}./02-ufw/client-test-after.sh${NC}"
echo ""
