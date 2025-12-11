#!/bin/bash
# author lutfi

# ============================================
# SSH Setup Script for Server & Client VMs
# Purpose: Configure SSH key authentication between VMs
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
CLIENT_IP="192.168.120.123"
SSH_USER=$(whoami)
SSH_PORT=22

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  SSH Setup Between VMs${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

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

# Detect which VM we're on
CURRENT_IP=$(hostname -I | awk '{print $1}')

if [[ "$CURRENT_IP" == "$SERVER_IP" ]]; then
    VM_ROLE="Server"
    REMOTE_IP="$CLIENT_IP"
    REMOTE_ROLE="Client"
elif [[ "$CURRENT_IP" == "$CLIENT_IP" ]]; then
    VM_ROLE="Client"
    REMOTE_IP="$SERVER_IP"
    REMOTE_ROLE="Server"
else
    echo -e "${RED}[ERROR]${NC} Cannot detect VM IP. Expected: $SERVER_IP or $CLIENT_IP"
    echo "Current IP: $CURRENT_IP"
    exit 1
fi

echo -e "Current VM: ${GREEN}${VM_ROLE}${NC} (${CURRENT_IP})"
echo -e "Remote VM: ${YELLOW}${REMOTE_ROLE}${NC} (${REMOTE_IP})"
echo ""

# Function to setup SSH on current VM
setup_local_ssh() {
    print_info "Setting up SSH on ${VM_ROLE}..."

    # Install SSH if not present
    if ! command -v ssh &> /dev/null; then
        print_info "Installing OpenSSH client..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq openssh-client
    fi

    # Install SSH server if not present
    if ! command -v sshd &> /dev/null; then
        print_info "Installing OpenSSH server..."
        sudo apt-get install -y -qq openssh-server
        sudo systemctl enable ssh
        sudo systemctl start ssh
        print_status "SSH server started"
    fi

    # Create SSH directory if not exists
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # Generate SSH key if not exists
    if [ ! -f ~/.ssh/id_rsa ]; then
        print_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q
        print_status "SSH key generated"
    fi

    print_status "Local SSH setup completed"
}

# Function to setup passwordless SSH to remote VM
setup_remote_ssh() {
    print_info "Setting up passwordless SSH to ${REMOTE_ROLE}..."

    # Test SSH connectivity first
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$REMOTE_IP" "echo 'SSH connection test'" &> /dev/null; then
        print_info "Attempting to copy SSH key to ${REMOTE_ROLE}..."

        # Try to copy SSH key (will ask for password)
        if ssh-copy-id -i ~/.ssh/id_rsa.pub "$SSH_USER@$REMOTE_IP" &> /dev/null; then
            print_status "SSH key copied to ${REMOTE_ROLE}"
        else
            print_error "Failed to copy SSH key automatically"
            echo ""
            echo "Manual setup required on ${REMOTE_ROLE}:"
            echo "1. Copy this public key:"
            echo "---"
            cat ~/.ssh/id_rsa.pub
            echo "---"
            echo ""
            echo "2. On ${REMOTE_ROLE} (${REMOTE_IP}), run:"
            echo "   mkdir -p ~/.ssh"
            echo "   chmod 700 ~/.ssh"
            echo "   echo 'PASTE_THE_KEY_ABOVE' >> ~/.ssh/authorized_keys"
            echo "   chmod 600 ~/.ssh/authorized_keys"
            echo ""
            echo "3. Then run this script again"
            exit 1
        fi
    fi

    # Test SSH connection
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$REMOTE_IP" "echo 'SSH connection successful'" &> /dev/null; then
        print_status "Passwordless SSH to ${REMOTE_ROLE} is working!"
    else
        print_error "SSH connection test failed"
        exit 1
    fi
}

# Function to create SSH config file
create_ssh_config() {
    print_info "Creating SSH config..."

    if ! grep -q "Host ${REMOTE_ROLE,,}" ~/.ssh/config 2>/dev/null; then
        cat >> ~/.ssh/config << EOF

# Auto-generated config for ${REMOTE_ROLE} VM
Host ${REMOTE_ROLE,,}
    HostName $REMOTE_IP
    User $SSH_USER
    Port $SSH_PORT
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF
        print_status "SSH config created for ${REMOTE_ROLE}"
    fi

    chmod 600 ~/.ssh/config
}

# Execute setup
echo -e "${YELLOW}=== Local SSH Setup ===${NC}"
setup_local_ssh

echo ""
echo -e "${YELLOW}=== Remote SSH Setup ===${NC}"
setup_remote_ssh

echo ""
echo -e "${YELLOW}=== SSH Configuration ===${NC}"
create_ssh_config

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  SSH Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "You can now connect to ${REMOTE_ROLE} using:"
echo -e "${GREEN}ssh ${REMOTE_ROLE,,}${NC}"
echo ""
echo "Or use the IP directly:"
echo -e "${GREEN}ssh $SSH_USER@$REMOTE_IP${NC}"
echo ""
echo "Test connection:"
echo -e "${GREEN}ssh ${REMOTE_ROLE,,} 'hostname && whoami'${NC}"