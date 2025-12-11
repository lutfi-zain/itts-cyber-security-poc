#!/bin/bash
# author lutfi

# ============================================
# Utility: Network Connectivity Checker
# Purpose: Quick connectivity test between VMs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Network Connectivity Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Detect which VM we're on based on hostname or IP
CURRENT_IP=$(hostname -I | awk '{print $1}')

if [[ "$CURRENT_IP" == "192.168.120.122" ]]; then
    VM_ROLE="Server"
    REMOTE_IP="192.168.120.123"
    REMOTE_ROLE="Client"
elif [[ "$CURRENT_IP" == "192.168.120.123" ]]; then
    VM_ROLE="Client"
    REMOTE_IP="192.168.120.122"
    REMOTE_ROLE="Server"
else
    VM_ROLE="Unknown"
    REMOTE_IP=""
fi

echo -e "Current VM: ${GREEN}${VM_ROLE}${NC} (${CURRENT_IP})"
if [ -n "$REMOTE_IP" ]; then
    echo -e "Remote VM: ${YELLOW}${REMOTE_ROLE}${NC} (${REMOTE_IP})"
fi
echo ""

# Test 1: Check network interface
echo -e "${YELLOW}=== Network Interface ===${NC}"
ip addr show | grep -E "inet |enp0s3|eth0" | head -5
echo ""

# Test 2: Check default gateway
echo -e "${YELLOW}=== Default Gateway ===${NC}"
ip route | grep default
echo ""

# Test 3: Test internet connectivity
echo -e "${YELLOW}=== Internet Connectivity ===${NC}"
if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
    print_status "Internet connection: OK"
else
    print_error "Internet connection: FAILED"
fi
echo ""

# Test 4: Test DNS
echo -e "${YELLOW}=== DNS Resolution ===${NC}"
if nslookup google.com > /dev/null 2>&1; then
    print_status "DNS resolution: OK"
else
    print_error "DNS resolution: FAILED"
fi
echo ""

# Test 5: Test remote VM connectivity (if detected)
if [ -n "$REMOTE_IP" ]; then
    echo -e "${YELLOW}=== Remote VM Connectivity ===${NC}"
    print_info "Testing connection to ${REMOTE_ROLE} at ${REMOTE_IP}..."
    
    if ping -c 3 "$REMOTE_IP" > /dev/null 2>&1; then
        print_status "Can reach ${REMOTE_ROLE}"
    else
        print_error "Cannot reach ${REMOTE_ROLE}"
    fi
    echo ""
fi

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Connectivity Summary${NC}"
echo -e "${BLUE}========================================${NC}"

ISSUES=0

if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} No internet connection"
    ((ISSUES++))
fi

if [ -n "$REMOTE_IP" ] && ! ping -c 1 "$REMOTE_IP" > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Cannot reach remote VM"
    ((ISSUES++))
fi

if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}[ALL CHECKS PASSED]${NC} Network is properly configured"
else
    echo -e "${RED}[ISSUES FOUND]${NC} $ISSUES problem(s) detected"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check VirtualBox network settings (NAT Network/Internal)"
    echo "2. Verify static IP configuration in /etc/netplan/"
    echo "3. Run: sudo netplan apply"
    echo "4. Check firewall rules: sudo ufw status"
fi
echo ""