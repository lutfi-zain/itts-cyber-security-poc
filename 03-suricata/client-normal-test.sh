#!/bin/bash

# ============================================
# Lab 3: Normal Traffic Test (Should NOT trigger alerts)
# Purpose: Generate normal network traffic
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="192.168.120.122"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Normal Traffic Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Test 1: Normal ping (just a few packets)
print_info "Sending normal ping to server..."
ping -c 5 "$SERVER_IP" > /dev/null 2>&1
print_status "Normal ping completed (5 packets)"

# Test 2: Normal HTTP request
print_info "Making normal HTTP request..."
curl -s "http://${SERVER_IP}/" > /dev/null 2>&1
print_status "Normal HTTP request completed"

# Test 3: SSH connection attempt (just one)
print_info "Testing SSH connection..."
timeout 2 nc -zv "$SERVER_IP" 22 2>/dev/null
print_status "Normal SSH connection test completed"

echo ""
echo -e "${GREEN}[COMPLETE]${NC} Normal traffic test finished"
echo -e "${YELLOW}[INFO]${NC} These actions should NOT trigger any IDS alerts"
echo ""
echo -e "Next: Check server alerts with:"
echo -e "  ${YELLOW}tail /var/log/suricata/fast.log${NC}"
echo ""
