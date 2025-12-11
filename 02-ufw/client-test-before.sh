#!/bin/bash

# ============================================
# Lab 2: UFW - Client Test Before Blocking
# Purpose: Test connectivity before IP is blocked
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="192.168.120.122"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Testing Server Access (Before Block)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
}

# Test 1: Ping
print_test "Testing ICMP (ping)..."
if ping -c 3 "$SERVER_IP" > /dev/null 2>&1; then
    print_success "Ping successful"
else
    print_fail "Ping failed"
fi
echo ""

# Test 2: HTTP
print_test "Testing HTTP (port 80)..."
if curl -s --connect-timeout 3 "http://${SERVER_IP}/" > /dev/null 2>&1; then
    print_success "HTTP connection successful"
else
    print_fail "HTTP connection failed"
fi
echo ""

# Test 3: SSH
print_test "Testing SSH (port 22)..."
if timeout 3 nc -zv "$SERVER_IP" 22 2>&1 | grep -q succeeded; then
    print_success "SSH port is open"
else
    print_fail "SSH port is closed"
fi
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Tests Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}All services should be accessible at this point.${NC}"
echo ""
echo -e "Next step: Block this client IP on server"
echo -e "  ${YELLOW}./02-ufw/server-block.sh${NC}"
echo ""
