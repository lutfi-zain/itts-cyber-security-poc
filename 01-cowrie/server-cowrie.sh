#!/bin/bash

# ============================================
# Lab 1: Cowrie Honeypot - Server Script
# Purpose: Install and run Cowrie SSH honeypot
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SERVER_IP="192.168.120.122"
COWRIE_PORT="2222"
COWRIE_DIR="/home/ubuntu/cowrie"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lab 1: Cowrie SSH Honeypot${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if Cowrie already exists
if [ -d "$COWRIE_DIR" ]; then
    print_info "Cowrie directory exists, removing old installation..."
    rm -rf "$COWRIE_DIR"
fi

# Clone Cowrie repository
print_info "Cloning Cowrie from GitHub..."
cd /home/ubuntu
git clone https://github.com/cowrie/cowrie.git
cd cowrie
print_status "Cowrie cloned"

# Create virtual environment
print_info "Creating Python virtual environment..."
python3 -m venv cowrie-env
source cowrie-env/bin/activate
print_status "Virtual environment created"

# Install dependencies
print_info "Installing Cowrie dependencies (this may take a few minutes)..."
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1
print_status "Dependencies installed"

# Configure Cowrie
print_info "Configuring Cowrie..."
cp etc/cowrie.cfg.dist etc/cowrie.cfg

# Set hostname
sed -i 's/^hostname = .*/hostname = ubuntu/' etc/cowrie.cfg

# Verify port configuration (default is 2222)
print_status "Cowrie configured (listening on port ${COWRIE_PORT})"

# Set proper permissions
print_info "Setting permissions..."
chown -R ubuntu:ubuntu "$COWRIE_DIR"
print_status "Permissions set"

# Start Cowrie
print_info "Starting Cowrie honeypot..."
sudo -u ubuntu bash << 'EOSU'
cd /home/ubuntu/cowrie
source cowrie-env/bin/activate
bin/cowrie start
EOSU

# Wait for Cowrie to start
sleep 3

# Check if Cowrie is running
if pgrep -f "cowrie" > /dev/null; then
    print_status "Cowrie is running"
else
    print_error "Cowrie failed to start"
    exit 1
fi

# Display status
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cowrie Status${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Status: ${GREEN}Running${NC}"
echo -e "SSH Honeypot Port: ${GREEN}${COWRIE_PORT}${NC}"
echo -e "Log Location: ${YELLOW}${COWRIE_DIR}/var/log/cowrie/${NC}"
echo ""
echo -e "${YELLOW}[READY]${NC} Cowrie is ready on port ${COWRIE_PORT}"
echo ""
echo -e "To monitor logs in real-time, open another terminal and run:"
echo -e "${YELLOW}  tail -f ${COWRIE_DIR}/var/log/cowrie/cowrie.log${NC}"
echo ""
echo -e "Next step: Run ${YELLOW}./01-cowrie/client-attack.sh${NC} on client VM"
echo ""