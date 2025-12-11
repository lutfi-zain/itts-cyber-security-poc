#!/bin/bash

# ============================================
# SSH Connection Test Script
# Purpose: Test SSH connectivity between VMs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVER_IP="192.168.120.122"
CLIENT_IP="192.168.120.123"
SSH_USER=$(whoami)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  SSH Connection Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Detect which VM we're on
CURRENT_IP=$(hostname -I | awk '{print $1}')

if [[ "$CURRENT_IP" == "$SERVER_IP" ]]; then
    VM_ROLE="Server"
    REMOTE_IP="$CLIENT_IP"
    REMOTE_ROLE="Client"
elif [[ "$CURRENT_IP" == "$CLIENT_IP" ]]; then
    VM_ROLE="Client"
    REMOTE_IP="$SERVER_IP"
    REMOTE_ROLE="Server"
else
    print_error "Cannot detect VM IP. Expected: $SERVER_IP or $CLIENT_IP"
    exit 1
fi

echo -e "Current VM: ${GREEN}${VM_ROLE}${NC} (${CURRENT_IP})"
echo -e "Testing connection to: ${YELLOW}${REMOTE_ROLE}${NC} (${REMOTE_IP})"
echo ""

# Test 1: Check if SSH client is available
echo -e "${YELLOW}=== SSH Client Check ===${NC}"
if command -v ssh &> /dev/null; then
    print_status "SSH client is installed"
    SSH_VERSION=$(ssh -V 2>&1 | cut -d',' -f1)
    echo "  Version: $SSH_VERSION"
else
    print_error "SSH client not found. Run: sudo apt-get install openssh-client"
    exit 1
fi

# Test 2: Check SSH key
echo ""
echo -e "${YELLOW}=== SSH Key Check ===${NC}"
if [ -f ~/.ssh/id_rsa ]; then
    print_status "SSH private key exists"
    if [ -f ~/.ssh/id_rsa.pub ]; then
        print_status "SSH public key exists"
    fi
else
    print_error "SSH key not found. Run ./utils/setup-ssh.sh first"
    exit 1
fi

# Test 3: Test basic connectivity
echo ""
echo -e "${YELLOW}=== Network Connectivity ===${NC}"
if ping -c 2 "$REMOTE_IP" > /dev/null 2>&1; then
    print_status "Can ping ${REMOTE_ROLE}"
else
    print_error "Cannot ping ${REMOTE_ROLE} - check network"
    exit 1
fi

# Test 4: Check if SSH port is open
echo ""
echo -e "${YELLOW}=== SSH Port Check ===${NC}"
if nc -z -w3 "$REMOTE_IP" 22 2>/dev/null; then
    print_status "SSH port 22 is open on ${REMOTE_ROLE}"
else
    print_error "SSH port 22 is closed on ${REMOTE_ROLE}"
    print_info "Run: sudo systemctl status ssh"
    exit 1
fi

# Test 5: Test SSH authentication
echo ""
echo -e "${YELLOW}=== SSH Authentication Test ===${NC}"
print_info "Testing SSH connection..."

if ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$SSH_USER@$REMOTE_IP" "echo 'Connection successful'" 2>/dev/null; then
    print_status "SSH authentication successful!"
else
    print_error "SSH authentication failed"
    echo ""
    echo "Possible solutions:"
    echo "1. Run ./utils/setup-ssh.sh to configure SSH keys"
    echo "2. Check if SSH service is running on ${REMOTE_ROLE}:"
    echo "   ssh $SSH_USER@$REMOTE_IP 'sudo systemctl status ssh'"
    echo "3. Manual key copy may be required"
    exit 1
fi

# Test 6: Test remote commands
echo ""
echo -e "${YELLOW}=== Remote Command Test ===${NC}"
print_info "Testing remote command execution..."

REMOTE_HOSTNAME=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$SSH_USER@$REMOTE_IP" "hostname" 2>/dev/null)
REMOTE_USER=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$SSH_USER@$REMOTE_IP" "whoami" 2>/dev/null)
REMOTE_UPTIME=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no "$SSH_USER@$REMOTE_IP" "uptime -p" 2>/dev/null)

if [ -n "$REMOTE_HOSTNAME" ] && [ -n "$REMOTE_USER" ]; then
    print_status "Remote commands working!"
    echo "  Remote hostname: $REMOTE_HOSTNAME"
    echo "  Remote user: $REMOTE_USER"
    echo "  Remote uptime: $REMOTE_UPTIME"
else
    print_error "Remote command execution failed"
    exit 1
fi

# Test 7: Test SSH config (if exists)
echo ""
echo -e "${YELLOW}=== SSH Config Test ===${NC}"
if [ -f ~/.ssh/config ] && grep -q "Host ${REMOTE_ROLE,,}" ~/.ssh/config; then
    print_status "SSH config for ${REMOTE_ROLE} found"
    print_info "Testing config-based connection..."

    if ssh -o BatchMode=yes "${REMOTE_ROLE,,}" "echo 'Config-based SSH working'" 2>/dev/null; then
        print_status "Config-based SSH working!"
        echo "  You can use: ssh ${REMOTE_ROLE,,}"
    else
        print_error "Config-based SSH failed"
    fi
else
    print_info "No SSH config found for ${REMOTE_ROLE}"
    echo "  You can use: ssh $SSH_USER@$REMOTE_IP"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  All SSH Tests Passed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "SSH connection from ${VM_ROLE} to ${REMOTE_ROLE} is fully functional."
echo ""
echo "Usage examples:"
echo -e "${GREEN}ssh $SSH_USER@$REMOTE_IP${NC}                    # Direct IP"
if [ -f ~/.ssh/config ] && grep -q "Host ${REMOTE_ROLE,,}" ~/.ssh/config; then
    echo -e "${GREEN}ssh ${REMOTE_ROLE,,}${NC}                         # Using config"
fi
echo -e "${GREEN}ssh $SSH_USER@$REMOTE_IP 'ls -la'${NC}           # Remote command"
echo -e "${GREEN}scp file.txt $SSH_USER@$REMOTE_IP:~/${NC}        # Copy file"