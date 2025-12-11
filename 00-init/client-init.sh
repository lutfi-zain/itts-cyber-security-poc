#!/bin/bash

# ============================================
# Client Initialization Script
# Purpose: Install attack/testing tools
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="192.168.120.122"
CLIENT_IP="192.168.120.123"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Client Initialization Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[ERROR]${NC} Please run with sudo"
    exit 1
fi

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Update system
print_info "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq
print_status "System updated"

# Install basic tools
print_info "Installing basic tools..."
apt-get install -y -qq \
    git \
    curl \
    wget \
    vim \
    net-tools \
    iputils-ping \
    dnsutils
print_status "Basic tools installed"

# Install Nmap
print_info "Installing Nmap..."
apt-get install -y -qq nmap
print_status "Nmap installed"

# Install hping3 (for ICMP flood)
print_info "Installing hping3..."
apt-get install -y -qq hping3
print_status "hping3 installed"

# Install sshpass (for automated SSH login attempts)
print_info "Installing sshpass..."
apt-get install -y -qq sshpass
print_status "sshpass installed"

# Install hydra (for brute force testing)
print_info "Installing hydra..."
apt-get install -y -qq hydra
print_status "hydra installed"

# Install netcat
print_info "Installing netcat..."
apt-get install -y -qq netcat
print_status "netcat installed"

# Configure static IP (if not already done)
print_info "Checking network configuration..."
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
if [ -f "$NETPLAN_FILE" ]; then
    print_info "Network configuration file found"
    # Backup original
    cp "$NETPLAN_FILE" "${NETPLAN_FILE}.backup"
    print_status "Network config backed up"
else
    print_info "Creating network configuration..."
    cat > "$NETPLAN_FILE" << EOF
network:
  version: 2
  ethernets:
    enp0s3:
      addresses:
        - ${CLIENT_IP}/24
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
      routes:
        - to: default
          via: 192.168.120.1
EOF
    netplan apply
    print_status "Static IP configured: ${CLIENT_IP}"
fi

# Create logs directory
print_info "Creating logs directory..."
mkdir -p /home/ubuntu/logs
chown ubuntu:ubuntu /home/ubuntu/logs
print_status "Logs directory created"

# Test connectivity
print_info "Testing connectivity..."
if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
    print_status "Internet connectivity: OK"
else
    print_error "Internet connectivity: FAILED"
fi

if ping -c 2 "$SERVER_IP" > /dev/null 2>&1; then
    print_status "Server connectivity: OK"
else
    print_error "Server connectivity: FAILED (Server may not be ready yet)"
fi

# Display system information
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Installation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Client IP: ${GREEN}${CLIENT_IP}${NC}"
echo -e "Server IP: ${GREEN}${SERVER_IP}${NC}"
echo ""
echo -e "Installed tools:"
echo -e "  ${GREEN}✓${NC} Git, Curl, Wget, Vim"
echo -e "  ${GREEN}✓${NC} Nmap (port scanner)"
echo -e "  ${GREEN}✓${NC} hping3 (packet crafting)"
echo -e "  ${GREEN}✓${NC} sshpass (SSH automation)"
echo -e "  ${GREEN}✓${NC} hydra (brute force)"
echo -e "  ${GREEN}✓${NC} netcat (network utility)"
echo ""
echo -e "${GREEN}[SUCCESS]${NC} Client initialization completed!"
echo -e "Next step: Start with ${YELLOW}Lab 1 - Cowrie Honeypot${NC}"
echo ""