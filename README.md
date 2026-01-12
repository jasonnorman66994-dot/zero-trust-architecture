# Zero Trust Architecture - Complete Implementation

A comprehensive, hands-on implementation of Zero Trust security principles using Linux CLI tools.

## 🎯 Overview

This repository contains a complete Zero Trust Architecture implementation demonstrating:
- **Never trust, always verify** - Every request is authenticated and authorized
- **Least privilege access** - Users and services have minimal necessary permissions
- **Micro-segmentation** - Network isolation using namespaces
- **Continuous monitoring** - Real-time security posture visibility
- **Encrypted communication** - Mutual TLS (mTLS) for all connections

## 🚀 Quick Start

```bash
# Run the complete interactive demo
./run-zero-trust-demo.sh

# Or test individual components:
./zero-trust-policy.sh alice database 127.0.0.1
./security-monitoring.sh
sudo ./network-namespace-demo.sh
```

## 📦 Components

### 1. Policy Enforcement Engine (`zero-trust-policy.sh`)
Validates every access request based on:
- User authorization (authorized-users.txt)
- Source IP whitelisting (trusted-ips.txt)
- Time-based access control (configurable)

```bash
./zero-trust-policy.sh <user> <resource> <source_ip>
```

### 2. Security Monitoring Dashboard (`security-monitoring.sh`)
Real-time visibility into:
- Network connections and listening services
- User activity and login history
- Process security (root vs user processes)
- SSH key verification
- Policy engine status
- Network namespace health
- Certificate infrastructure status
- System resource utilization

### 3. Network Micro-Segmentation (`network-namespace-demo.sh`)
Creates isolated network environments:
- Separate network namespace (`secure-zone`)
- Virtual ethernet pair for controlled connectivity
- Independent network stack (10.100.0.0/24)
- Complete isolation demonstration

**Requires sudo access**

### 4. Mutual TLS Infrastructure (`certs/`)
Complete certificate chain for encrypted, authenticated communication:
- Certificate Authority (CA)
- Server certificate (server.local)
- Client certificate (client.local)
- All certificates valid for 365 days

Verify certificates:
```bash
openssl verify -CAfile certs/ca-cert.pem certs/server-cert.pem
openssl verify -CAfile certs/ca-cert.pem certs/client-cert.pem
```

### 5. Identity Management
Strong cryptographic authentication:
- SSH ED25519 key pair (`~/.ssh/zero_trust_demo`)
- Modern, secure cryptographic algorithms
- Certificate-based authentication ready

## 📖 Documentation

See [`zero-trust-cli-guide.md`](zero-trust-cli-guide.md) for:
- Detailed explanations of each component
- Step-by-step implementation guides
- Alternative approaches (iptables/nftables, MFA, etc.)
- Troubleshooting and verification commands
- Advanced configurations

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Zero Trust Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐   ┌──────────────┐ │
│  │   Identity   │──────│    Policy    │───│   Network    │ │
│  │  Management  │      │    Engine    │   │ Segmentation │ │
│  │  (SSH Keys)  │      │ (Validation) │   │ (Namespaces) │ │
│  └──────────────┘      └──────────────┘   └──────────────┘ │
│         │                      │                   │         │
│         │                      │                   │         │
│  ┌──────┴──────────────────────┴───────────────────┴──────┐ │
│  │                 Policy Enforcement Point                │ │
│  │              (Authentication + Authorization)           │ │
│  └─────────────────────────────────────────────────────────┘ │
│         │                      │                   │         │
│  ┌──────┴──────┐      ┌───────┴──────┐   ┌────────┴──────┐ │
│  │     mTLS    │      │  Continuous  │   │   Security    │ │
│  │Certificates │      │  Monitoring  │   │   Analytics   │ │
│  │  (Crypto)   │      │  (Auditing)  │   │ (Visibility)  │ │
│  └─────────────┘      └──────────────┘   └───────────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 Zero Trust Principles

| Principle | Implementation |
|-----------|----------------|
| **Verify Explicitly** | Policy engine validates user, IP, and time for every request |
| **Least Privilege** | Users whitelisted explicitly, default deny on network |
| **Assume Breach** | Network segmentation isolates components |
| **Micro-segmentation** | Network namespaces create isolated environments |
| **Continuous Monitoring** | Real-time security dashboard tracks all activity |
| **Encrypt Everything** | mTLS certificates for authenticated encryption |

## 🛠️ Requirements

- Linux operating system (Ubuntu/Debian recommended)
- Root/sudo access (for network namespaces)
- OpenSSL
- Standard Linux networking tools (ip, netstat/ss)

## 📊 Testing & Validation

The implementation includes comprehensive testing:

### Policy Engine Tests
```bash
# Should GRANT access (authorized user, trusted IP, correct time)
./zero-trust-policy.sh alice database 127.0.0.1

# Should DENY access (unauthorized user)
./zero-trust-policy.sh eve database 127.0.0.1

# Should DENY access (untrusted IP)
./zero-trust-policy.sh alice database 192.168.99.99
```

### Certificate Validation
```bash
# Verify all certificates
cd certs/
openssl verify -CAfile ca-cert.pem server-cert.pem
openssl verify -CAfile ca-cert.pem client-cert.pem

# View certificate details
openssl x509 -in client-cert.pem -text -noout
```

### Network Isolation
```bash
# Create and test namespace
sudo ./network-namespace-demo.sh

# List namespaces
sudo ip netns list

# Execute in isolated environment
sudo ip netns exec secure-zone bash
```

## 📝 Configuration

### Policy Files
Located in `/tmp/zero-trust/`:
- `authorized-users.txt` - List of authorized users (one per line)
- `trusted-ips.txt` - Whitelisted IP addresses (one per line)

Modify these files to customize access control:
```bash
echo "newuser" | sudo tee -a /tmp/zero-trust/authorized-users.txt
echo "10.0.0.5" | sudo tee -a /tmp/zero-trust/trusted-ips.txt
```

### Time-Based Access
Edit `zero-trust-policy.sh` function `check_time_window()` to modify allowed hours.

## 🎯 Use Cases

- **Security Training** - Hands-on Zero Trust concepts
- **Development Environment** - Secure development practices
- **Proof of Concept** - Demonstrate Zero Trust to stakeholders
- **Security Auditing** - Template for security assessments
- **Compliance** - Meet zero-trust requirements

## 🤝 Contributing

This is a demonstration/educational project. Feel free to:
- Fork and extend with additional components
- Add support for other platforms
- Enhance monitoring capabilities
- Improve documentation

## 📄 License

Educational and demonstration purposes. Based on open-source tools and standards.

## 🔗 Resources

- [NIST Zero Trust Architecture (SP 800-207)](https://csrc.nist.gov/publications/detail/sp/800-207/final)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Linux Network Namespaces](https://man7.org/linux/man-pages/man7/network_namespaces.7.html)

## 📞 Support

For issues or questions:
1. Check [`zero-trust-cli-guide.md`](zero-trust-cli-guide.md) for detailed documentation
2. Review the interactive demo: `./run-zero-trust-demo.sh`
3. Inspect component scripts for implementation details

---

**Built with ❤️ for cybersecurity education and awareness**
