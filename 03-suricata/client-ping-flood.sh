#!/bin/bash

# ============================================
# Lab 3: ICMP Ping Flood Attack
# Purpose: Trigger ICMP flood detection alert
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="192.168.120.122"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ICMP Ping Flood Attack${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_info() {
    echo -e "${BLUE}[ATTACK]${NC} $1"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Ping flood attack
print_info "Launching ICMP ping flood attack..."
print_info "Sending 50 rapid ping packets to ${SERVER_IP}"

ping -c 50 -i 0.1 "$SERVER_IP" > /dev/null 2>&1

print_status "ICMP flood attack completed"

echo ""
echo -e "${RED}[ALERT EXPECTED]${NC} Suricata should detect: ICMP Ping Flood"
echo ""
echo -e "Check server alerts with:"
echo -e "  ${YELLOW}tail -f /var/log/suricata/fast.log${NC}"
echo ""
echo -e "You should see: ${RED}ICMP Ping Flood Detected${NC}"
echo ""
