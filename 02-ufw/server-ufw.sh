#!/bin/bash

# ============================================
# Lab 2: UFW Firewall - Server Setup Script
# Purpose: Configure UFW firewall
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Lab 2: UFW Firewall Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then 
    echo -e "${RED}[ERROR]${NC} Please run with sudo"
    exit 1
fi

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Reset UFW to clean state
print_info "Resetting UFW to default state..."
ufw --force reset > /dev/null 2>&1
print_status "UFW reset"

# Set default policies
print_info "Setting default policies..."
ufw default deny incoming
ufw default allow outgoing
print_status "Default policies set (deny incoming, allow outgoing)"

# Allow SSH (important!)
print_info "Allowing SSH (port 22)..."
ufw allow 22/tcp
print_status "SSH allowed"

# Allow HTTP
print_info "Allowing HTTP (port 80)..."
ufw allow 80/tcp
print_status "HTTP allowed"

# Allow HTTPS (optional)
print_info "Allowing HTTPS (port 443)..."
ufw allow 443/tcp
print_status "HTTPS allowed"

# Enable logging
print_info "Enabling UFW logging..."
ufw logging on
print_status "Logging enabled"

# Enable UFW
print_info "Enabling UFW firewall..."
echo "y" | ufw enable > /dev/null 2>&1
print_status "UFW enabled"

# Check Apache2 status
print_info "Checking Apache2 web server..."
if systemctl is-active --quiet apache2; then
    print_status "Apache2 is running"
else
    print_info "Starting Apache2..."
    systemctl start apache2
    print_status "Apache2 started"
fi

# Create a simple test page
print_info "Creating test web page..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>UFW Lab - Server</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        h1 { color: #2c3e50; }
        .info { background: #ecf0f1; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🛡️ UFW Firewall Lab</h1>
    <div class="info">
        <h2>Server is Running!</h2>
        <p>This page is served by Apache2 on Ubuntu Server</p>
        <p>Protected by UFW Firewall</p>
    </div>
</body>
</html>
EOF
print_status "Test page created"

# Display current rules
echo ""
echo -e "${YELLOW}=== Current UFW Rules ===${NC}"
ufw status verbose
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  UFW Configuration Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Status: ${GREEN}Active${NC}"
echo -e "Default policy: ${GREEN}Deny incoming, Allow outgoing${NC}"
echo ""
echo -e "Allowed services:"
echo -e "  ${GREEN}✓${NC} SSH (22/tcp)"
echo -e "  ${GREEN}✓${NC} HTTP (80/tcp)"
echo -e "  ${GREEN}✓${NC} HTTPS (443/tcp)"
echo ""
echo -e "Logging: ${GREEN}Enabled${NC}"
echo -e "Log location: ${YELLOW}/var/log/ufw.log${NC}"
echo ""
echo -e "${GREEN}[READY]${NC} UFW firewall is configured"
echo -e "Next step: Run ${YELLOW}./02-ufw/client-test-before.sh${NC} on client"
echo ""