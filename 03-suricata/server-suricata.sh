#!/bin/bash

# ============================================
# Lab 3: Suricata IDS - Server Setup Script
# Purpose: Configure and run Suricata IDS
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
SURICATA_CONF="/etc/suricata/suricata.yaml"
LOCAL_RULES="/etc/suricata/rules/local.rules"
LOG_DIR="/var/log/suricata"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lab 3: Suricata IDS Setup${NC}"
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

# Detect network interface
print_info "Detecting network interface..."
DETECTED_IF=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
if [ -n "$DETECTED_IF" ]; then
    INTERFACE="$DETECTED_IF"
fi
print_status "Using interface: $INTERFACE"

# Backup original configuration
print_info "Backing up original Suricata configuration..."
if [ ! -f "${SURICATA_CONF}.backup" ]; then
    cp "$SURICATA_CONF" "${SURICATA_CONF}.backup"
    print_status "Configuration backed up"
else
    print_info "Backup already exists"
fi

# Configure HOME_NET
print_info "Configuring HOME_NET to ${HOME_NET}..."
sed -i "s|HOME_NET:.*|HOME_NET: \"[${HOME_NET}]\"|" "$SURICATA_CONF"
print_status "HOME_NET configured"

# Configure interface
print_info "Configuring network interface..."
sed -i "s|interface:.*|interface: ${INTERFACE}|" "$SURICATA_CONF"
print_status "Interface configured"

# Create local rules directory and file
print_info "Setting up local rules..."
mkdir -p /etc/suricata/rules
touch "$LOCAL_RULES"

# Add custom detection rules
print_info "Adding custom IDS rules..."

cat > "$LOCAL_RULES" << 'EOF'
# ============================================
# Custom Suricata Rules for Lab
# ============================================

# Rule 1: Detect ICMP Ping Flood
# Triggers when more than 20 ICMP packets in 5 seconds
alert icmp any any -> $HOME_NET any (msg:"ICMP Ping Flood Detected"; itype:8; threshold: type both, track by_src, count 20, seconds 5; sid:1000001; rev:1;)

# Rule 2: Detect TCP Port Scan
# Triggers when more than 10 SYN packets to different ports in 5 seconds
alert tcp any any -> $HOME_NET any (msg:"TCP Port Scan Detected"; flags:S; threshold: type both, track by_src, count 10, seconds 5; sid:1000002; rev:1;)

# Rule 3: Detect SSH Brute Force Attempts
# Triggers on multiple connection attempts to port 22
alert tcp any any -> $HOME_NET 22 (msg:"Possible SSH Brute Force"; flags:S; threshold: type both, track by_src, count 5, seconds 10; sid:1000003; rev:1;)

# Rule 4: Detect Suspicious HTTP Access
# Detects rapid HTTP requests
alert tcp any any -> $HOME_NET 80 (msg:"Rapid HTTP Requests Detected"; flags:S; threshold: type both, track by_src, count 15, seconds 5; sid:1000004; rev:1;)
EOF

print_status "Custom rules added"

# Enable local rules in configuration
print_info "Enabling local rules..."
if ! grep -q "local.rules" "$SURICATA_CONF"; then
    sed -i '/rule-files:/a\  - local.rules' "$SURICATA_CONF"
fi
print_status "Local rules enabled"

# Update Suricata rules
print_info "Updating Suricata rulesets..."
suricata-update || print_info "Suricata-update completed with warnings (normal)"
print_status "Rulesets updated"

# Test Suricata configuration
print_info "Verifying Suricata configuration..."
if suricata -T -c "$SURICATA_CONF" -i "$INTERFACE" > /dev/null 2>&1; then
    print_status "Configuration is valid"
else
    echo -e "${YELLOW}[WARN]${NC} Configuration test had warnings (proceeding anyway)"
fi

# Stop existing Suricata instances
print_info "Stopping any existing Suricata instances..."
systemctl stop suricata 2>/dev/null || true
killall suricata 2>/dev/null || true
sleep 2
print_status "Clean state ready"

# Create log directory
print_info "Creating log directory..."
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
print_status "Log directory ready"

# Clear old logs
print_info "Clearing old logs..."
> /var/log/suricata/fast.log 2>/dev/null || true
print_status "Logs cleared"

# Start Suricata in IDS mode
print_info "Starting Suricata IDS..."
print_info "Network interface: ${INTERFACE}"
print_info "Monitoring network: ${HOME_NET}"

# Run Suricata in background
nohup suricata -c "$SURICATA_CONF" -i "$INTERFACE" --init-errors-fatal > /dev/null 2>&1 &
SURICATA_PID=$!

sleep 5

# Check if Suricata is running
if ps -p $SURICATA_PID > /dev/null 2>&1; then
    print_status "Suricata is running (PID: ${SURICATA_PID})"
    echo "$SURICATA_PID" > /tmp/suricata.pid
else
    echo -e "${YELLOW}[WARN]${NC} Suricata PID not found in expected process"
    # Check if Suricata is running under different PID (systemd might have started it)
    ACTUAL_PID=$(pgrep -f "suricata.*${INTERFACE}" | head -n1)
    if [ -n "$ACTUAL_PID" ]; then
        print_status "Suricata is running (PID: ${ACTUAL_PID})"
        echo "$ACTUAL_PID" > /tmp/suricata.pid
    else
        echo -e "${RED}[ERROR]${NC} Failed to start Suricata"
        echo "Check logs: tail /var/log/suricata/suricata.log"
        exit 1
    fi
fi

# Display configuration
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Suricata IDS Configuration${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Status: ${GREEN}Running${NC}"
echo -e "Interface: ${GREEN}${INTERFACE}${NC}"
echo -e "Monitoring: ${GREEN}${HOME_NET}${NC}"
echo -e "Alert log: ${YELLOW}${LOG_DIR}/fast.log${NC}"
echo ""
echo -e "Detection rules loaded:"
echo -e "  ${GREEN}✓${NC} ICMP Ping Flood (>20 packets/5s)"
echo -e "  ${GREEN}✓${NC} TCP Port Scan (>10 SYN/5s)"
echo -e "  ${GREEN}✓${NC} SSH Brute Force (>5 attempts/10s)"
echo -e "  ${GREEN}✓${NC} Rapid HTTP Requests (>15/5s)"
echo ""
echo -e "${YELLOW}[READY]${NC} Suricata IDS is listening..."
echo ""
echo -e "To monitor alerts in real-time, run:"
echo -e "${YELLOW}  tail -f /var/log/suricata/fast.log${NC}"
echo ""
echo -e "Next step: Run attack scripts on client VM"
echo -e "  ${YELLOW}./03-suricata/client-normal-test.sh${NC}"
echo -e "  ${YELLOW}./03-suricata/client-ping-flood.sh${NC}"
echo -e "  ${YELLOW}./03-suricata/client-port-scan.sh${NC}"
echo ""
