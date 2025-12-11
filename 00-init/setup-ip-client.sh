#!/bin/bash
# author lutfi

# ============================================
# Client IP Configuration Script (Debian/Ubuntu)
# Purpose: Configure static IP for Client VM
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLIENT_IP="192.168.120.123"
NETMASK="255.255.255.0"
GATEWAY="192.168.120.1"
DNS1="8.8.8.8"
DNS2="8.8.4.4"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Client IP Configuration${NC}"
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

# Detect network interface
print_info "Detecting network interface..."
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)

if [ -z "$INTERFACE" ]; then
    # If no default route, get first available interface
    INTERFACE=$(ip link show | grep -E "^[0-9]+: (eth|ens|enp)" | head -n1 | cut -d: -f2 | tr -d ' ')
fi

if [ -z "$INTERFACE" ]; then
    print_error "Could not detect network interface"
    print_info "Available interfaces:"
    ip link show
    exit 1
fi

print_status "Network interface detected: $INTERFACE"

# Backup original configuration
print_info "Backing up network configuration..."
if [ -f /etc/network/interfaces ]; then
    cp /etc/network/interfaces /etc/network/interfaces.backup.$(date +%Y%m%d_%H%M%S)
    print_status "Backup created"
fi

# Configure static IP for Debian
if [ -f /etc/network/interfaces ]; then
    print_info "Configuring static IP (Debian style)..."
    
    cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto $INTERFACE
iface $INTERFACE inet static
    address $CLIENT_IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS1 $DNS2
EOF
    
    print_status "Network configuration file updated"
fi

# Configure DNS
print_info "Configuring DNS..."
cat > /etc/resolv.conf << EOF
nameserver $DNS1
nameserver $DNS2
EOF
print_status "DNS configured"

# Show current configuration
print_info "Current IP configuration:"
ip addr show $INTERFACE

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Configuration Summary${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Interface:  ${GREEN}$INTERFACE${NC}"
echo -e "IP Address: ${GREEN}$CLIENT_IP${NC}"
echo -e "Netmask:    ${GREEN}$NETMASK${NC}"
echo -e "Gateway:    ${GREEN}$GATEWAY${NC}"
echo -e "DNS:        ${GREEN}$DNS1, $DNS2${NC}"
echo ""

# Ask to apply changes
echo -e "${YELLOW}[!] Network configuration updated!${NC}"
echo -e "${YELLOW}[!] Choose how to apply changes:${NC}"
echo -e "  1) Restart network service (recommended)"
echo -e "  2) Reboot system (if restart fails)"
echo -e "  3) Apply manually later"
echo ""
read -p "Select option [1-3]: " OPTION

case $OPTION in
    1)
        print_info "Restarting network service..."
        systemctl restart networking || service networking restart
        sleep 2
        print_status "Network service restarted"
        
        # Verify new IP
        NEW_IP=$(ip addr show $INTERFACE | grep "inet " | awk '{print $2}' | cut -d/ -f1)
        if [ "$NEW_IP" == "$CLIENT_IP" ]; then
            print_status "IP configuration applied successfully!"
            echo -e "${GREEN}New IP: $NEW_IP${NC}"
        else
            print_error "IP not applied yet. Current IP: $NEW_IP"
            echo -e "${YELLOW}You may need to reboot: sudo reboot${NC}"
        fi
        ;;
    2)
        print_info "Rebooting system..."
        echo -e "${YELLOW}System will reboot in 5 seconds...${NC}"
        sleep 5
        reboot
        ;;
    3)
        print_info "Configuration saved. Apply manually with:"
        echo -e "  ${GREEN}sudo systemctl restart networking${NC}"
        echo -e "  or"
        echo -e "  ${GREEN}sudo reboot${NC}"
        ;;
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Configuration Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Test connectivity with:"
echo -e "  ${BLUE}ping 192.168.120.122${NC}  # Ping server"
echo -e "  ${BLUE}ping 8.8.8.8${NC}          # Test internet"
echo ""
