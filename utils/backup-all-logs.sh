#!/bin/bash
# author lutfi

# ============================================
# Utility: Backup All Logs
# Purpose: Backup logs from all labs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get actual user
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
    USER_HOME="/home/$SUDO_USER"
else
    ACTUAL_USER="$(whoami)"
    USER_HOME="$HOME"
fi

BACKUP_ROOT="${USER_HOME}/logs-backup"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${BACKUP_ROOT}/all-labs-${TIMESTAMP}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Backup All Lab Logs${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Create backup directory
print_info "Creating backup directory..."
mkdir -p "$BACKUP_DIR"/{cowrie,ufw,suricata}
print_status "Backup directory created: $BACKUP_DIR"

# Backup Cowrie logs
print_info "Backing up Cowrie logs..."
if [ -d "${USER_HOME}/cowrie/var/log" ]; then
    cp -r "${USER_HOME}/cowrie/var/log/cowrie" "$BACKUP_DIR/cowrie/" 2>/dev/null
    print_status "Cowrie logs backed up"
else
    print_info "No Cowrie logs found"
fi

# Backup UFW logs
print_info "Backing up UFW logs..."
if [ -f "/var/log/ufw.log" ]; then
    sudo cp /var/log/ufw.log "$BACKUP_DIR/ufw/" 2>/dev/null
    print_status "UFW logs backed up"
elif grep -q "UFW" /var/log/kern.log 2>/dev/null; then
    sudo grep "UFW" /var/log/kern.log > "$BACKUP_DIR/ufw/ufw.log"
    print_status "UFW logs extracted from kern.log"
else
    print_info "No UFW logs found"
fi

# Backup Suricata logs
print_info "Backing up Suricata logs..."
if [ -d "/var/log/suricata" ]; then
    sudo cp -r /var/log/suricata/* "$BACKUP_DIR/suricata/" 2>/dev/null
    print_status "Suricata logs backed up"
else
    print_info "No Suricata logs found"
fi

# Set permissions
sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" "$BACKUP_DIR"
print_status "Permissions set"

# Create summary
print_info "Creating backup summary..."
cat > "$BACKUP_DIR/README.txt" << EOF
Lab Logs Backup
===============
Date: $(date)
User: $ACTUAL_USER

Contents:
- cowrie/   : SSH Honeypot logs
- ufw/      : Firewall logs
- suricata/ : IDS logs

Total size: $(du -sh "$BACKUP_DIR" | cut -f1)
EOF
print_status "Summary created"

# Display summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Backup Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Backup location: ${YELLOW}${BACKUP_DIR}${NC}"
echo -e "Total size: ${YELLOW}$(du -sh "$BACKUP_DIR" | cut -f1)${NC}"
echo ""
echo "Contents:"
ls -lh "$BACKUP_DIR"
echo ""
