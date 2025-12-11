#!/bin/bash

# ============================================
# Lab 3: Snort IDS - Server Setup Script
# Purpose: Configure and run Snort IDS
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
HOME_NET="192.168.120.0/24"
SERVER_IP="192.168.120.122"
INTERFACE="enp0s3"  # Change if different
SNORT_CONF="/etc/snort/snort.conf"
LOCAL_RULES="/etc/snort/rules/local.rules"
LOG_DIR="/var/log/snort"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lab 3: Snort IDS Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[ERROR]${NC} Please run with sudo"
    exit 1
fi

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Backup original configuration
print_info "Backing up original Snort configuration..."
if [ ! -f "${SNORT_CONF}.backup" ]; then
    cp "$SNORT_CONF" "${SNORT_CONF}.backup"
    print_status "Configuration backed up"
else
    print_info "Backup already exists"
fi

# Configure HOME_NET
print_info "Configuring HOME_NET to ${HOME_NET}..."
sed -i "s|^ipvar HOME_NET .*|ipvar HOME_NET ${HOME_NET}|" "$SNORT_CONF"
print_status "HOME_NET configured"

# Configure EXTERNAL_NET
print_info "Configuring EXTERNAL_NET..."
sed -i "s|^ipvar EXTERNAL_NET .*|ipvar EXTERNAL_NET !${HOME_NET}|" "$SNORT_CONF"
print_status "EXTERNAL_NET configured"

# Create local rules file if doesn't exist
print_info "Setting up local rules..."
touch "$LOCAL_RULES"

# Add custom detection rules
print_info "Adding custom IDS rules..."

cat > "$LOCAL_RULES" << 'EOF'
# ============================================
# Custom Snort Rules for Lab
# ============================================

# Rule 1: Detect ICMP Ping Flood
# Triggers when more than 20 ICMP packets in 5 seconds
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Flood Detected"; itype:8; detection_filter:track by_src, count 20, seconds 5; sid:1000001; rev:1;)

# Rule 2: Detect TCP Port Scan
# Triggers when more than 10 SYN packets to different ports in 5 seconds
alert tcp any any -> $HOME_NET any (msg:"TCP Port Scan Detected"; flags:S; detection_filter:track by_src, count 10, seconds 5; sid:1000002; rev:1;)

# Rule 3: Detect SSH Brute Force Attempts
# Triggers on multiple connection attempts to port 22
alert tcp any any -> $HOME_NET 22 (msg:"Possible SSH Brute Force"; flags:S; detection_filter:track by_src, count 5, seconds 10; sid:1000003; rev:1;)

# Rule 4: Detect Suspicious HTTP Access
# Detects rapid HTTP requests
alert tcp any any -> $HOME_NET 80 (msg:"Rapid HTTP Requests Detected"; flags:S; detection_filter:track by_src, count 15, seconds 5; sid:1000004; rev:1;)
EOF

print_status "Custom rules added"

# Verify Snort configuration
print_info "Verifying Snort configuration..."
if snort -T -c "$SNORT_CONF" > /dev/null 2>&1; then
    print_status "Configuration is valid"
else
    echo -e "${RED}[ERROR]${NC} Configuration validation failed"
    echo "Run: snort -T -c $SNORT_CONF"
    exit 1
fi

# Create log directory
print_info "Creating log directory..."
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
print_status "Log directory ready"

# Clear old logs
print_info "Clearing old alert logs..."
> /var/log/snort/alert
print_status "Alert log cleared"

# Start Snort in IDS mode
print_info "Starting Snort IDS..."
print_info "Network interface: ${INTERFACE}"
print_info "Monitoring network: ${HOME_NET}"

# Run Snort in background
nohup snort -A fast -b -d -i "$INTERFACE" -c "$SNORT_CONF" -l "$LOG_DIR" > /dev/null 2>&1 &
SNORT_PID=$!

sleep 3

# Check if Snort is running
if ps -p $SNORT_PID > /dev/null 2>&1; then
    print_status "Snort is running (PID: ${SNORT_PID})"
    echo "$SNORT_PID" > /tmp/snort.pid
else
    echo -e "${RED}[ERROR]${NC} Failed to start Snort"
    exit 1
fi

# Display configuration
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Snort IDS Configuration${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Status: ${GREEN}Running${NC}"
echo -e "PID: ${GREEN}${SNORT_PID}${NC}"
echo -e "Interface: ${GREEN}${INTERFACE}${NC}"
echo -e "Monitoring: ${GREEN}${HOME_NET}${NC}"
echo -e "Alert log: ${YELLOW}${LOG_DIR}/alert${NC}"
echo ""
echo -e "Detection rules loaded:"
echo -e "  ${GREEN}✓${NC} ICMP Ping Flood (>20 packets/5s)"
echo -e "  ${GREEN}✓${NC} TCP Port Scan (>10 SYN/5s)"
echo -e "  ${GREEN}✓${NC} SSH Brute Force (>5 attempts/10s)"
echo -e "  ${GREEN}✓${NC} Rapid HTTP Requests (>15/5s)"
echo ""
echo -e "${YELLOW}[READY]${NC} Snort IDS is listening..."
echo ""
echo -e "To monitor alerts in real-time, run:"
echo -e "${YELLOW}  tail -f /var/log/snort/alert${NC}"
echo ""
echo -e "Next step: Run attack scripts on client VM"
echo -e "  ${YELLOW}./03-snort/client-normal-test.sh${NC}"
echo -e "  ${YELLOW}./03-snort/client-ping-flood.sh${NC}"
echo -e "  ${YELLOW}./03-snort/client-port-scan.sh${NC}"
echo ""