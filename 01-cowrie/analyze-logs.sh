#!/bin/bash
# author lutfi

# ============================================
# Lab 1: Analyze Cowrie Logs
# Purpose: Display and analyze honeypot attack logs
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get actual user
if [ -n "$SUDO_USER" ]; then
    USER_HOME="/home/$SUDO_USER"
else
    USER_HOME="$HOME"
fi

COWRIE_DIR="${USER_HOME}/cowrie"
LOG_FILE="${COWRIE_DIR}/var/log/cowrie/cowrie.json"
TEXT_LOG="${COWRIE_DIR}/var/log/cowrie/cowrie.log"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Cowrie Honeypot Log Analysis${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if log exists
if [ ! -f "$TEXT_LOG" ]; then
    echo -e "${RED}[ERROR]${NC} Cowrie log not found: $TEXT_LOG"
    exit 1
fi

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Count total login attempts
print_info "Analyzing attack patterns..."
echo ""

# SSH connection attempts
TOTAL_ATTEMPTS=$(grep -c "login attempt" "$TEXT_LOG" 2>/dev/null || echo "0")
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Attack Statistics${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Total login attempts: ${RED}${TOTAL_ATTEMPTS}${NC}"
echo ""

# Top usernames tried
echo -e "${YELLOW}Top 10 Usernames Attempted:${NC}"
echo -e "${BLUE}---${NC}"
grep "login attempt" "$TEXT_LOG" | grep -oP "username: \K[^ ,]+" | sort | uniq -c | sort -rn | head -10 | while read count user; do
    echo -e "  ${RED}${user}${NC} - ${count} attempts"
done
echo ""

# Top passwords tried
echo -e "${YELLOW}Top 10 Passwords Attempted:${NC}"
echo -e "${BLUE}---${NC}"
grep "login attempt" "$TEXT_LOG" | grep -oP "password: \K[^ ,]+" | sort | uniq -c | sort -rn | head -10 | while read count pass; do
    echo -e "  ${RED}${pass}${NC} - ${count} attempts"
done
echo ""

# Commands executed
echo -e "${YELLOW}Commands Executed by Attackers:${NC}"
echo -e "${BLUE}---${NC}"
grep "CMD:" "$TEXT_LOG" | tail -20 | while read line; do
    echo -e "${YELLOW}$line${NC}"
done
echo ""

# Connection sources
echo -e "${YELLOW}Connection Sources:${NC}"
echo -e "${BLUE}---${NC}"
grep "New connection" "$TEXT_LOG" | grep -oP "\d+\.\d+\.\d+\.\d+" | sort | uniq -c | sort -rn | while read count ip; do
    echo -e "  ${RED}${ip}${NC} - ${count} connections"
done
echo ""

# Session duration
TOTAL_SESSIONS=$(grep -c "connection lost" "$TEXT_LOG" 2>/dev/null || echo "0")
echo -e "Total sessions: ${RED}${TOTAL_SESSIONS}${NC}"
echo ""

# Recent activity
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Recent Activity (Last 15 lines)${NC}"
echo -e "${YELLOW}========================================${NC}"
tail -15 "$TEXT_LOG" | while read line; do
    if [[ $line == *"login attempt"* ]] || [[ $line == *"CMD:"* ]]; then
        echo -e "${RED}$line${NC}"
    else
        echo "$line"
    fi
done
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Analysis Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Full log location: ${YELLOW}${TEXT_LOG}${NC}"
echo -e "JSON log for detailed analysis: ${YELLOW}${LOG_FILE}${NC}"
echo ""
echo -e "Next step: Run ${YELLOW}./01-cowrie/cleanup.sh${NC} to backup logs and stop Cowrie"
echo ""
