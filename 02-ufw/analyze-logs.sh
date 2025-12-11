#!/bin/bash

# ============================================
# Lab 2: Analyze UFW Logs
# Purpose: Display and analyze firewall logs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/var/log/ufw.log"
KERN_LOG="/var/log/kern.log"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  UFW Firewall Log Analysis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then 
    echo -e "${RED}[ERROR]${NC} Please run with sudo"
    exit 1
fi

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check which log file exists
if [ -f "$LOG_FILE" ]; then
    ACTIVE_LOG="$LOG_FILE"
elif grep -q "UFW BLOCK" "$KERN_LOG" 2>/dev/null; then
    ACTIVE_LOG="$KERN_LOG"
else
    echo -e "${RED}[ERROR]${NC} UFW logs not found"
    exit 1
fi

print_info "Using log file: $ACTIVE_LOG"
echo ""

# Count blocked packets
TOTAL_BLOCKS=$(grep -c "UFW BLOCK" "$ACTIVE_LOG" 2>/dev/null || echo "0")
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Firewall Statistics${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Total blocked packets: ${RED}${TOTAL_BLOCKS}${NC}"
echo ""

# Top blocked IPs
echo -e "${YELLOW}Top Blocked Source IPs:${NC}"
echo -e "${BLUE}---${NC}"
grep "UFW BLOCK" "$ACTIVE_LOG" | grep -oP "SRC=\K[^ ]+" | sort | uniq -c | sort -rn | head -10 | while read count ip; do
    echo -e "  ${RED}${ip}${NC} - ${count} blocked packets"
done
echo ""

# Top blocked ports
echo -e "${YELLOW}Top Blocked Destination Ports:${NC}"
echo -e "${BLUE}---${NC}"
grep "UFW BLOCK" "$ACTIVE_LOG" | grep -oP "DPT=\K[^ ]+" | sort | uniq -c | sort -rn | head -10 | while read count port; do
    echo -e "  Port ${RED}${port}${NC} - ${count} attempts"
done
echo ""

# Protocol breakdown
echo -e "${YELLOW}Blocked by Protocol:${NC}"
echo -e "${BLUE}---${NC}"
TCP_BLOCKS=$(grep "UFW BLOCK" "$ACTIVE_LOG" | grep -c "PROTO=TCP" || echo "0")
UDP_BLOCKS=$(grep "UFW BLOCK" "$ACTIVE_LOG" | grep -c "PROTO=UDP" || echo "0")
ICMP_BLOCKS=$(grep "UFW BLOCK" "$ACTIVE_LOG" | grep -c "PROTO=ICMP" || echo "0")
echo -e "  TCP:  ${RED}${TCP_BLOCKS}${NC}"
echo -e "  UDP:  ${RED}${UDP_BLOCKS}${NC}"
echo -e "  ICMP: ${RED}${ICMP_BLOCKS}${NC}"
echo ""

# Recent blocked attempts
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Recent Blocked Attempts (Last 15)${NC}"
echo -e "${YELLOW}========================================${NC}"
grep "UFW BLOCK" "$ACTIVE_LOG" | tail -15 | while read line; do
    echo -e "${RED}$line${NC}"
done
echo ""

# Current UFW status
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Current UFW Rules${NC}"
echo -e "${YELLOW}========================================${NC}"
ufw status numbered
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Analysis Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Full log location: ${YELLOW}${ACTIVE_LOG}${NC}"
echo -e "To view real-time: ${YELLOW}tail -f ${ACTIVE_LOG} | grep UFW${NC}"
echo ""
echo -e "Next step: Run ${YELLOW}./02-ufw/cleanup.sh${NC} to unblock client for next lab"
echo ""
