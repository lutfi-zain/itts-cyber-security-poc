#!/bin/bash

# ============================================
# Lab 2: UFW - Client Test After Blocking
# Purpose: Test connectivity after IP is blocked
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="192.168.120.122"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Testing Server Access (After Block)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓ UNEXPECTED]${NC} $1"
}

print_fail() {
    echo -e "${RED}[✓ EXPECTED]${NC} $1"
}

# Test 1: Ping
print_test "Testing ICMP (ping)..."
if ping -c 3 -W 2 "$SERVER_IP" > /dev/null 2>&1; then
    print_success "Ping successful (firewall not blocking?)"
else
    print_fail "Ping blocked by firewall"
fi
echo ""

# Test 2: HTTP
print_test "Testing HTTP (port 80)..."
if curl -s --connect-timeout 3 "http://${SERVER_IP}/" > /dev/null 2>&1; then
    print_success "HTTP connection successful (firewall not blocking?)"
else
    print_fail "HTTP connection blocked by firewall"
fi
echo ""

# Test 3: SSH
print_test "Testing SSH (port 22)..."
if timeout 3 nc -zv "$SERVER_IP" 22 2>&1 | grep -q succeeded; then
    print_success "SSH port is open (firewall not blocking?)"
else
    print_fail "SSH port blocked by firewall"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Tests Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${RED}All connections should be blocked by UFW!${NC}"
echo ""
echo -e "On server, view firewall logs:"
echo -e "  ${YELLOW}./02-ufw/analyze-logs.sh${NC}"
echo ""
