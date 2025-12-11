# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a cyber security training lab environment for ITTS (Institut Teknologi Telkom Surabaya) that teaches practical security concepts through hands-on exercises. The project consists of three main labs: Honeypot (Cowrie), Firewall (UFW), and IDS (Suricata), designed to run on two VirtualBox VMs in a controlled network environment.

## Network Architecture

The project requires two VMs with specific static IP configuration:
- **Server VM**: `192.168.120.122` (runs security tools)
- **Client VM**: `192.168.120.123` (simulates attacks)
- **Network**: `192.168.120.0/24` using VirtualBox NAT Network or Internal Network

## Common Development Commands

### Initial Setup
```bash
# Make all scripts executable
chmod +x **/*.sh

# Setup IP configuration (run once per VM)
sudo ./00-init/setup-ip-server.sh    # On Server VM
sudo ./00-init/setup-ip-client.sh    # On Client VM

# Initialize systems (install dependencies)
sudo ./00-init/server-init.sh        # On Server VM
sudo ./00-init/client-init.sh        # On Client VM
```

### Testing and Troubleshooting
```bash
# Check network connectivity between VMs
./utils/check-connectivity.sh

# Emergency cleanup of all services
./utils/full-cleanup.sh

# Backup all logs
./utils/backup-all-logs.sh
```

### Lab Execution Pattern
Each lab follows the same pattern:
1. Server setup script (requires sudo)
2. Client attack/test scripts
3. Log analysis
4. Cleanup script (required before next lab)

## Project Structure

```
├── 00-init/          # Initial VM setup and dependency installation
├── 01-cowrie/        # SSH Honeypot lab (attacks on port 2222)
├── 02-ufw/           # Firewall configuration lab
├── 03-suricata/      # Intrusion Detection System lab
└── utils/            # Common utility scripts
```

## Key Technical Details

### Security Tools Used
- **Cowrie**: SSH honeypot running on port 2222, logs to `/home/user/cowrie/var/log/cowrie/`
- **UFW**: Uncomplicated Firewall for packet filtering
- **Suricata**: Network IDS with custom rules in `/etc/suricata/rules/local.rules`

### Script Conventions
- All scripts use color-coded output functions: `print_status()`, `print_info()`, `print_error()`
- Server scripts require sudo privileges and include root checks
- Configuration is hardcoded (IP addresses, ports, paths)
- All scripts include `set -e` to exit on errors
- Cleanup scripts are provided for each lab and must be run before proceeding

### Log Management
- Logs are automatically backed up to `~/logs/` with timestamps
- Each lab has specific log analysis scripts
- Suricata logs are in `/var/log/suricata/`
- Cowrie logs are in user's home directory under `cowrie/var/log/cowrie/`

## Important Notes

- This is an educational project with simulated attacks for learning purposes only
- All attack simulations are controlled and target the honeypot/test environment
- Scripts are designed for Ubuntu/Debian systems and use apt-get for package management
- Network interface detection is automatic but defaults to `enp0s3` for VirtualBox
- Always run cleanup scripts after each lab to ensure clean state for next exercises