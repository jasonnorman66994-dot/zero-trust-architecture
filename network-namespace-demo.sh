#!/bin/bash
# network-namespace-demo.sh - Micro-segmentation with network namespaces

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Zero Trust: Network Namespace Micro-Segmentation Demo   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root or with sudo"
    exit 1
fi

NAMESPACE="secure-zone"
VETH_HOST="veth-host"
VETH_NS="veth-secure"
HOST_IP="10.100.0.1"
NS_IP="10.100.0.2"

echo "🔧 Creating isolated network namespace: $NAMESPACE"
ip netns add $NAMESPACE 2>/dev/null || echo "  (namespace already exists, cleaning up...)" && ip netns del $NAMESPACE 2>/dev/null; ip netns add $NAMESPACE

echo "✓ Network namespace created"
echo ""

echo "🔗 Creating virtual ethernet pair"
ip link add $VETH_HOST type veth peer name $VETH_NS
echo "✓ Virtual ethernet pair created: $VETH_HOST <-> $VETH_NS"
echo ""

echo "📦 Moving $VETH_NS into $NAMESPACE"
ip link set $VETH_NS netns $NAMESPACE
echo "✓ Interface moved to namespace"
echo ""

echo "🌐 Configuring network interfaces"
# Configure host side
ip addr add ${HOST_IP}/24 dev $VETH_HOST
ip link set $VETH_HOST up
echo "  Host side: $VETH_HOST -> $HOST_IP"

# Configure namespace side
ip netns exec $NAMESPACE ip addr add ${NS_IP}/24 dev $VETH_NS
ip netns exec $NAMESPACE ip link set $VETH_NS up
ip netns exec $NAMESPACE ip link set lo up
echo "  Namespace side: $VETH_NS -> $NS_IP"
echo "✓ Network configuration complete"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "📊 NETWORK ISOLATION VERIFICATION"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "1️⃣  Host network interfaces:"
ip addr show $VETH_HOST | grep -E "inet |link"
echo ""

echo "2️⃣  Namespace network interfaces:"
ip netns exec $NAMESPACE ip addr show | grep -E "inet |link"
echo ""

echo "3️⃣  Testing connectivity from host to namespace:"
if ping -c 2 -W 1 $NS_IP > /dev/null 2>&1; then
    echo "✓ Ping successful: Host can reach $NS_IP"
else
    echo "✗ Cannot reach namespace"
fi
echo ""

echo "4️⃣  Testing connectivity from namespace to host:"
ip netns exec $NAMESPACE ping -c 2 -W 1 $HOST_IP > /dev/null 2>&1 && echo "✓ Ping successful: Namespace can reach $HOST_IP" || echo "✗ Cannot reach host"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "🎯 DEMONSTRATION COMMANDS"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  # List all network namespaces:"
echo "  sudo ip netns list"
echo ""
echo "  # Execute command in namespace:"
echo "  sudo ip netns exec $NAMESPACE bash"
echo ""
echo "  # View namespace routing table:"
echo "  sudo ip netns exec $NAMESPACE ip route"
echo ""
echo "  # Check namespace processes:"
echo "  sudo ip netns exec $NAMESPACE ps aux"
echo ""
echo "  # Clean up (delete namespace):"
echo "  sudo ip netns del $NAMESPACE"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Micro-segmentation demo complete!"
echo "   Two isolated network segments created with controlled connectivity"
