#!/bin/bash

# ============================================
# Lab 3: Analyze Suricata Alerts
# Purpose: Display and analyze IDS alerts
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ALERT_FILE="/var/log/suricata/fast.log"
EVE_FILE="/var/log/suricata/eve.json"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Suricata IDS Alert Analysis${NC}"
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

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Check if alert file exists
if [ ! -f "$ALERT_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Alert file not found: $ALERT_FILE"
    exit 1
fi

# Count total alerts
TOTAL_ALERTS=$(grep -c "^\[" "$ALERT_FILE" 2>/dev/null || echo "0")

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Alert Statistics${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Total Alerts: ${RED}${TOTAL_ALERTS}${NC}"
echo ""

# Count alerts by type
echo -e "${YELLOW}Alerts by Type:${NC}"
echo -e "${BLUE}---${NC}"

ICMP_FLOOD=$(grep -c "ICMP Ping Flood" "$ALERT_FILE" 2>/dev/null || echo "0")
PORT_SCAN=$(grep -c "Port Scan" "$ALERT_FILE" 2>/dev/null || echo "0")
SSH_BRUTE=$(grep -c "SSH Brute Force" "$ALERT_FILE" 2>/dev/null || echo "0")
HTTP_RAPID=$(grep -c "Rapid HTTP" "$ALERT_FILE" 2>/dev/null || echo "0")

echo -e "ICMP Ping Flood:     ${RED}${ICMP_FLOOD}${NC}"
echo -e "TCP Port Scan:       ${RED}${PORT_SCAN}${NC}"
echo -e "SSH Brute Force:     ${RED}${SSH_BRUTE}${NC}"
echo -e "Rapid HTTP Requests: ${RED}${HTTP_RAPID}${NC}"
echo ""

# Display recent alerts
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Recent Alerts (Last 10)${NC}"
echo -e "${YELLOW}========================================${NC}"
tail -n 10 "$ALERT_FILE" | while read -r line; do
    if [[ $line == *"ICMP Ping Flood"* ]]; then
        echo -e "${RED}$line${NC}"
    elif [[ $line == *"Port Scan"* ]]; then
        echo -e "${YELLOW}$line${NC}"
    elif [[ $line == *"SSH Brute Force"* ]]; then
        echo -e "${BLUE}$line${NC}"
    else
        echo "$line"
    fi
done
echo ""

# Top attacking IPs
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Top 5 Attacking IP Addresses${NC}"
echo -e "${YELLOW}========================================${NC}"
grep -oP '\d+\.\d+\.\d+\.\d+:\d+ ->' "$ALERT_FILE" | \
    sed 's/:\d* ->//' | \
    sort | uniq -c | sort -rn | head -5 | \
    while read count ip; do
        echo -e "${RED}${ip}${NC} - ${count} alerts"
    done || echo "No IP data found"
echo ""

# Alert timeline
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Alert Timeline${NC}"
echo -e "${YELLOW}========================================${NC}"
if [ -f "$ALERT_FILE" ]; then
    echo "First alert: $(head -n 1 "$ALERT_FILE" | grep -oP '\d{2}/\d{2}/\d{4}-\d{2}:\d{2}:\d{2}' || echo 'N/A')"
    echo "Last alert:  $(tail -n 1 "$ALERT_FILE" | grep -oP '\d{2}/\d{2}/\d{4}-\d{2}:\d{2}:\d{2}' || echo 'N/A')"
fi
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Analysis Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "$TOTAL_ALERTS" -gt 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Suricata IDS successfully detected ${TOTAL_ALERTS} attacks!"
    echo ""
    echo -e "Expected detections:"
    if [ "$ICMP_FLOOD" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} ICMP Ping Flood detected"
    else
        echo -e "  ${YELLOW}✗${NC} ICMP Ping Flood NOT detected"
    fi
    
    if [ "$PORT_SCAN" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} TCP Port Scan detected"
    else
        echo -e "  ${YELLOW}✗${NC} TCP Port Scan NOT detected"
    fi
else
    echo -e "${YELLOW}[INFO]${NC} No alerts recorded yet"
    echo "Make sure you ran the attack scripts from the client VM"
fi

echo ""
echo -e "Full alert log: ${YELLOW}${ALERT_FILE}${NC}"
echo -e "To view in real-time: ${YELLOW}tail -f ${ALERT_FILE}${NC}"
echo ""
