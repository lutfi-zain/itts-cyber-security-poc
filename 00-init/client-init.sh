#!/bin/bash
# author lutfi

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
if [ "$(id -u)" -ne 0 ]; then 
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

# Install bash first (if not already installed)
print_info "Ensuring bash is installed..."
apt-get update -qq
apt-get install -y -qq bash
print_status "Bash installed"

# Update system
print_info "Updating system packages..."
apt-get upgrade -y -qq
print_status "System updated"

# Install basic tools
print_info "Installing basic tools..."
apt-get install -y -qq \
    git \
    curl \
    wget \
    vim \
    nano \
    net-tools \
    iputils-ping \
    dnsutils \
    build-essential \
    sudo \
    netcat-openbsd
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

# netcat already installed in basic tools (netcat-openbsd)
print_status "netcat (nc) available"

# Create logs directory
print_info "Creating logs directory..."
LOGS_DIR="$HOME/logs"
if [ -n "$SUDO_USER" ]; then
    LOGS_DIR="/home/$SUDO_USER/logs"
    mkdir -p "$LOGS_DIR"
    chown "$SUDO_USER:$SUDO_USER" "$LOGS_DIR"
else
    mkdir -p "$LOGS_DIR"
fi
print_status "Logs directory created: $LOGS_DIR"

# Display system information
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Installation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Client IP: ${GREEN}${CLIENT_IP}${NC}"
echo -e "Server IP: ${GREEN}${SERVER_IP}${NC}"
echo ""
echo -e "Installed tools:"
echo -e "  ${GREEN}✓${NC} Git, Curl, Wget, Vim, Nano"
echo -e "  ${GREEN}✓${NC} Nmap (port scanner)"
echo -e "  ${GREEN}✓${NC} hping3 (packet crafting)"
echo -e "  ${GREEN}✓${NC} sshpass (SSH automation)"
echo -e "  ${GREEN}✓${NC} hydra (brute force)"
echo -e "  ${GREEN}✓${NC} netcat (network utility)"
echo ""
echo -e "${GREEN}[SUCCESS]${NC} Client initialization completed!"
echo ""
echo -e "Next steps:"
echo -e "  1. Test connectivity: ${YELLOW}ping ${SERVER_IP}${NC}"
echo -e "  2. Start labs: ${YELLOW}./01-cowrie/client-attack.sh${NC}"
echo ""