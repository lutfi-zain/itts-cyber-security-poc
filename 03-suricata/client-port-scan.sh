#!/bin/bash

# ============================================
# Lab 3: TCP Port Scan Attack
# Purpose: Trigger port scan detection alert
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="192.168.120.122"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  TCP Port Scan Attack${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_info() {
    echo -e "${BLUE}[ATTACK]${NC} $1"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Check if nmap is installed
if ! command -v nmap &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} nmap is not installed"
    echo "Run: sudo apt install nmap"
    exit 1
fi

# Port scan attack
print_info "Launching TCP port scan attack..."
print_info "Scanning first 100 ports on ${SERVER_IP}"

nmap -sS -p 1-100 -T4 "$SERVER_IP" > /dev/null 2>&1

print_status "Port scan attack completed"

echo ""
echo -e "${RED}[ALERT EXPECTED]${NC} Suricata should detect: TCP Port Scan"
echo ""
echo -e "Check server alerts with:"
echo -e "  ${YELLOW}tail -f /var/log/suricata/fast.log${NC}"
echo ""
echo -e "You should see: ${RED}TCP Port Scan Detected${NC}"
echo ""
