# 🔐 ITTS Cyber Security Practice - Lab Automation

Automation scripts untuk praktikum keamanan jaringan: Honeypot (Cowrie), Firewall (UFW), dan IDS (Snort).

## 📋 Prerequisites

### Hardware & Software
- **Oracle VirtualBox** sudah terinstall
- **2 Virtual Machines:**
  - **Server VM** (ubuntu-server): Ubuntu Server 22.04 Mini ISO (~80MB)
  - **Client VM** (ubuntu-client): Ubuntu Server 22.04 Mini ISO (~80MB)

### Network Configuration
- **Network Mode:** NAT Network / Internal Network
- **IP Configuration:**
  - Server: `192.168.120.122`
  - Client: `192.168.120.123`
  - Subnet: `192.168.120.0/24`

### VM Specifications
```
Server VM:
- RAM: 2GB
- Disk: 20GB
- Username: ubuntu-server

Client VM:
- RAM: 2GB
- Disk: 20GB
- Username: ubuntu-client
```

## 🚀 Quick Start

### Step 1: Setup VMs
1. Create 2 VMs in VirtualBox with NAT Network mode
2. Install Debian/Ubuntu Server on both VMs
3. Clone this repository on both VMs:
```bash
git clone https://github.com/lutfi-zain/itts-cyber-security-poc.git
cd itts-cyber-security-poc
chmod +x **/*.sh
```
4. Configure static IPs:
```bash
# On Server VM:
sudo ./00-init/setup-ip-server.sh

# On Client VM:
sudo ./00-init/setup-ip-client.sh
```

### Step 2: Initialize (Run Once)
```bash
# On Server VM (Terminal Right):
./00-init/server-init.sh

# On Client VM (Terminal Left):
./00-init/client-init.sh
```

### Step 3: Run Labs in Order

#### 🍯 Lab 1: Honeypot (Cowrie)
```bash
# Server (Right):
./01-cowrie/server-cowrie.sh
# Wait for "Cowrie is ready on port 2222"

# Client (Left):
./01-cowrie/client-attack.sh

# Server (Right):
./01-cowrie/analyze-logs.sh
./01-cowrie/cleanup.sh
```

#### 🛡️ Lab 2: Firewall (UFW)
```bash
# Server (Right):
./02-ufw/server-ufw.sh

# Client (Left):
./02-ufw/client-test-before.sh  # Should succeed

# Server (Right):
./02-ufw/server-block.sh

# Client (Left):
./02-ufw/client-test-after.sh   # Should fail

# Server (Right):
./02-ufw/analyze-logs.sh
./02-ufw/cleanup.sh             # Unblock for next lab
```

#### 🚨 Lab 3: IDS (Snort)
```bash
# Server (Right):
./03-snort/server-snort.sh
# Wait for "Snort is listening..."

# Client (Left):
./03-snort/client-normal-test.sh   # No alert
./03-snort/client-ping-flood.sh    # Should trigger alert
./03-snort/client-port-scan.sh     # Should trigger alert

# Server (Right):
./03-snort/analyze-logs.sh
./03-snort/cleanup.sh
```

## 📂 Repository Structure

```
itts-cyber-security-poc/
├── 00-init/              # Initial setup scripts
│   ├── setup-ip-server.sh  # Configure server static IP
│   ├── setup-ip-client.sh  # Configure client static IP
│   ├── server-init.sh      # Install server tools
│   ├── client-init.sh      # Install client tools
│   └── README.md
├── 01-cowrie/            # Honeypot lab
│   ├── server-cowrie.sh
│   ├── client-attack.sh
│   ├── analyze-logs.sh
│   └── cleanup.sh
├── 02-ufw/               # Firewall lab
│   ├── server-ufw.sh
│   ├── client-test-before.sh
│   ├── server-block.sh
│   ├── client-test-after.sh
│   ├── analyze-logs.sh
│   └── cleanup.sh
├── 03-snort/             # IDS lab
│   ├── server-snort.sh
│   ├── client-normal-test.sh
│   ├── client-ping-flood.sh
│   ├── client-port-scan.sh
│   ├── analyze-logs.sh
│   └── cleanup.sh
├── utils/                # Utility scripts
│   ├── check-connectivity.sh
│   ├── backup-all-logs.sh
│   └── full-cleanup.sh
└── README.md
```

## 🎯 Learning Objectives

### Lab 1: Honeypot (Cowrie)
- Understand honeypot concepts
- Deploy SSH honeypot
- Analyze attacker behavior from logs
- Learn about deception-based security

### Lab 2: Firewall (UFW)
- Configure basic firewall rules
- Allow/deny specific services
- Block IP addresses
- Analyze firewall logs

### Lab 3: IDS (Snort)
- Deploy network-based IDS
- Create custom detection rules
- Detect ICMP flood attacks
- Detect TCP port scanning

## 🔧 Troubleshooting

### Network Issues
```bash
# Check connectivity
./utils/check-connectivity.sh

# Check IP configuration
ip addr show
```

### Permission Issues
```bash
# Make all scripts executable
chmod +x **/*.sh
```

### Reset Everything
```bash
# Emergency cleanup
./utils/full-cleanup.sh
```

## 📝 Notes

- **Always run cleanup.sh** after each lab to prepare for the next one
- **Logs are backed up** in `~/logs/` directory with timestamps
- **Server scripts** require sudo privileges
- **Client scripts** are automated attacks for learning purposes only

## ⚠️ Disclaimer

These scripts are for **educational purposes only** in a controlled lab environment. Do not use these tools on networks you don't own or have explicit permission to test.

## 📚 References

- [Cowrie SSH Honeypot](https://github.com/cowrie/cowrie)
- [Ubuntu UFW Documentation](https://help.ubuntu.com/community/UFW)
- [Snort IDS Documentation](https://www.snort.org/documents)

## 👤 Author

**Lutfi Zain**
- GitHub: [@lutfi-zain](https://github.com/lutfi-zain)

## 📄 License

MIT License - Feel free to use for educational purposes.

---

**Happy Learning! 🎓**