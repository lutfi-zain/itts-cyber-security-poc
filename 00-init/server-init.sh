#!/bin/bash

# ============================================
# Server Initialization Script
# Purpose: Install all required tools for labs
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
echo -e "${BLUE}  Server Initialization Script${NC}"
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
    sudo
print_status "Basic tools installed"

# Install Python and dependencies
print_info "Installing Python3 and dependencies..."
apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-virtualenv
print_status "Python3 installed"

# Install Apache2 (for UFW lab)
print_info "Installing Apache2 web server..."
apt-get install -y -qq apache2
systemctl enable apache2
systemctl start apache2
print_status "Apache2 installed and running"

# Install UFW
print_info "Installing UFW firewall..."
apt-get install -y -qq ufw
# Don't enable yet, will be done in lab
print_status "UFW installed"

# Install Suricata IDS (modern alternative to Snort for Debian)
print_info "Installing Suricata IDS..."
apt-get install -y -qq \
    suricata \
    jq \
    || print_error "Suricata installation failed"
print_status "Suricata IDS installed"

# Install Cowrie dependencies
print_info "Installing Cowrie dependencies..."
apt-get install -y -qq \
    libssl-dev \
    libffi-dev \
    python3-setuptools \
    openssh-client
print_status "Cowrie dependencies installed"

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
echo -e "Server IP: ${GREEN}${SERVER_IP}${NC}"
echo -e "Client IP: ${GREEN}${CLIENT_IP}${NC}"
echo ""
echo -e "Installed tools:"
echo -e "  ${GREEN}✓${NC} Git, Curl, Wget, Vim, Nano"
echo -e "  ${GREEN}✓${NC} Python3 + pip + venv"
echo -e "  ${GREEN}✓${NC} Apache2"
echo -e "  ${GREEN}✓${NC} UFW"
echo -e "  ${GREEN}✓${NC} Suricata IDS"
echo -e "  ${GREEN}✓${NC} Cowrie dependencies"
echo ""
echo -e "${GREEN}[SUCCESS]${NC} Server initialization completed!"
echo ""
echo -e "Next steps:"
echo -e "  1. Run ${YELLOW}./00-init/client-init.sh${NC} on client VM"
echo -e "  2. Test connectivity: ${YELLOW}ping ${CLIENT_IP}${NC}"
echo -e "  3. Start labs: ${YELLOW}./01-cowrie/server-cowrie.sh${NC}"
echo ""