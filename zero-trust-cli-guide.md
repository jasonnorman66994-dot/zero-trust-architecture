# Zero Trust Architecture - Hands-On CLI Implementation

## 🚀 Components You Can Run Right Now

-----

## 1. Policy Enforcement Point (PEP) - Network Level

### Option A: Using iptables (Linux)

Create a simple "default deny" firewall rule - the foundation of Zero Trust:
```bash
# Block all incoming traffic by default
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP

# Allow only established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow specific service (example: SSH from specific IP)
sudo iptables -A INPUT -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT

# View your rules
sudo iptables -L -v

# Save rules (Ubuntu/Debian)
sudo iptables-save > /etc/iptables/rules.v4
```

### Option B: Using nftables (Modern Linux)
```bash
# Create a basic Zero Trust table
sudo nft add table inet filter
sudo nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }

# Allow established connections
sudo nft add rule inet filter input ct state established,related accept

# Allow from specific source
sudo nft add rule inet filter input ip saddr 192.168.1.100 tcp dport 22 accept

# List rules
sudo nft list ruleset
```

-----

## 2. Identity & Access Management - Authentication

### Option A: SSH with Certificate-Based Authentication
```bash
# Generate SSH key pair (if you don't have one)
ssh-keygen -t ed25519 -C "zero-trust-demo"

# Copy public key to remote server
ssh-copy-id user@remote-server

# Disable password authentication on server (edit /etc/ssh/sshd_config)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Set: PubkeyAuthentication yes

sudo systemctl restart sshd
```

### Option B: Multi-Factor Authentication (MFA) for SSH
```bash
# Install Google Authenticator PAM module
sudo apt-get install libpam-google-authenticator  # Debian/Ubuntu
# or
sudo yum install google-authenticator              # RHEL/CentOS

# Configure for your user
google-authenticator

# Edit PAM configuration
sudo nano /etc/pam.d/sshd
# Add: auth required pam_google_authenticator.so

# Edit SSH config
sudo nano /etc/ssh/sshd_config
# Set: ChallengeResponseAuthentication yes

sudo systemctl restart sshd
```

-----

## 3. Endpoint Security - Device Trust Verification

### Check System Security Posture
```bash
# Check if firewall is active
sudo ufw status          # Ubuntu
sudo firewall-cmd --state # RHEL/CentOS

# Check for rootkits
sudo apt-get install rkhunter
sudo rkhunter --check

# Check open ports and listening services
sudo netstat -tulpn
# or
sudo ss -tulpn

# Check for unauthorized users
who
last

# Review failed login attempts
sudo grep "Failed password" /var/log/auth.log | tail -20
```

-----

## 4. Policy Engine - Simple Rule-Based Access Control

### Create a Basic Policy Script
```bash
#!/bin/bash
# zero-trust-policy.sh - Simple policy enforcement

USER=$1
RESOURCE=$2
SOURCE_IP=$3

# Policy Decision Point Logic
check_user_authorized() {
    # Check if user is in authorized list
    if grep -q "^$USER$" /etc/zero-trust/authorized-users.txt; then
        return 0
    fi
    return 1
}

check_ip_whitelist() {
    # Check if IP is whitelisted
    if grep -q "^$SOURCE_IP$" /etc/zero-trust/trusted-ips.txt; then
        return 0
    fi
    return 1
}

check_time_window() {
    # Only allow access during business hours
    HOUR=$(date +%H)
    if [ $HOUR -ge 9 ] && [ $HOUR -le 17 ]; then
        return 0
    fi
    return 1
}

# Main Policy Decision
if check_user_authorized && check_ip_whitelist && check_time_window; then
    echo "ACCESS GRANTED: User $USER from $SOURCE_IP to $RESOURCE"
    exit 0
else
    echo "ACCESS DENIED: User $USER from $SOURCE_IP to $RESOURCE"
    logger "Zero Trust: Denied access to $USER from $SOURCE_IP"
    exit 1
fi
```

Setup:
```bash
# Create policy directory
sudo mkdir -p /etc/zero-trust

# Create authorized users list
echo "alice" | sudo tee -a /etc/zero-trust/authorized-users.txt
echo "bob" | sudo tee -a /etc/zero-trust/authorized-users.txt

# Create trusted IPs list
echo "192.168.1.100" | sudo tee -a /etc/zero-trust/trusted-ips.txt

# Make script executable
chmod +x zero-trust-policy.sh

# Test it
./zero-trust-policy.sh alice database 192.168.1.100
```

-----

## 5. Security Analytics - Real-Time Monitoring

### Monitor Access Attempts
```bash
# Watch authentication logs in real-time
sudo tail -f /var/log/auth.log

# Monitor network connections
watch -n 2 'netstat -an | grep ESTABLISHED'

# Track sudo usage
sudo grep sudo /var/log/auth.log | tail -20

# Monitor file access (requires auditd)
sudo apt-get install auditd
sudo auditctl -w /etc/passwd -p wa -k passwd_changes
sudo ausearch -k passwd_changes
```

-----

## 6. Micro-Segmentation with Network Namespaces

### Create Isolated Network Environments
```bash
# Create a network namespace (isolated network stack)
sudo ip netns add secure-zone

# List namespaces
sudo ip netns list

# Execute command in namespace
sudo ip netns exec secure-zone bash

# Inside namespace - completely isolated network
ip addr show
ping google.com  # Will fail - no network yet

# Create virtual network between namespaces
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth1 netns secure-zone
sudo ip addr add 10.0.0.1/24 dev veth0
sudo ip link set veth0 up

sudo ip netns exec secure-zone ip addr add 10.0.0.2/24 dev veth1
sudo ip netns exec secure-zone ip link set veth1 up

# Test connectivity
ping 10.0.0.2
```

-----

## 7. TLS/mTLS - Encrypted & Authenticated Communication

### Generate Certificates for Mutual TLS
```bash
# Create Certificate Authority
openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca-key.pem -out ca-cert.pem

# Create Server Certificate
openssl genrsa -out server-key.pem 4096
openssl req -new -key server-key.pem -out server-req.pem
openssl x509 -req -in server-req.pem -CA ca-cert.pem -CAkey ca-key.pem \
    -CAcreateserial -out server-cert.pem -days 365

# Create Client Certificate
openssl genrsa -out client-key.pem 4096
openssl req -new -key client-key.pem -out client-req.pem
openssl x509 -req -in client-req.pem -CA ca-cert.pem -CAkey ca-key.pem \
    -CAcreateserial -out client-cert.pem -days 365

# Test with curl (requires mTLS)
curl --cert client-cert.pem --key client-key.pem \
     --cacert ca-cert.pem https://your-server.com
```

-----

## 8. Quick Zero Trust Demo with Docker

### Run a Complete Mini Zero Trust Setup
```bash
# Create a simple policy-enforced service
cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN apk add --no-cache nginx openssl
COPY policy-check.sh /usr/local/bin/
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
EOF

# Build and run
docker build -t zero-trust-demo .
docker run -p 8443:443 zero-trust-demo

# Access requires client certificate
curl --cert client.pem --key key.pem https://localhost:8443
```

-----

## 🎯 Quick Start Recommendation

Start here (5 minutes):

1. Set up SSH key authentication (Section 2A)
1. Create a simple firewall rule (Section 1A)
1. Monitor your auth logs (Section 5)

Next level (30 minutes):
4. Implement the policy script (Section 4)
5. Add MFA to SSH (Section 2B)
6. Set up certificate-based authentication (Section 7)

Advanced (1+ hours):
7. Network namespaces for micro-segmentation (Section 6)
8. Full Docker demo (Section 8)

-----

## 📚 What Each Component Represents in ZTA

|CLI Component      |ZTA Architecture Component    |
|-------------------|------------------------------|
|iptables/nftables  |Policy Enforcement Point      |
|SSH keys/MFA       |Identity & Credential Mgmt    |
|Certificates (mTLS)|Endpoint Security + Identity  |
|Policy script      |Policy Engine + Decision Point|
|Log monitoring     |Security Analytics            |
|Network namespaces |Micro-segmentation            |
|auditd             |Data Security + Analytics     |

-----

## 🔍 Verification Commands

After implementing any component:
```bash
# Check what's listening
sudo netstat -tlnp

# Verify firewall rules
sudo iptables -L -n -v

# Check authentication methods
sudo sshd -T | grep -i auth

# Review security logs
sudo journalctl -u ssh -n 50

# Test your policies
./zero-trust-policy.sh testuser resource 1.2.3.4
```
