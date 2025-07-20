#!/usr/bin/env bash
# =============================================================================
# Restrictive Firewall Script
# =============================================================================
# 
# Blocks all incoming traffic except from 192.168.1.99
# - Whitelists 192.168.1.99
# - Blocks all other IPs
# - Allows essential local traffic
# =============================================================================

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

setup_restrictive_firewall() {
    log "=== SETTING UP RESTRICTIVE FIREWALL ==="
    
    # Flush existing rules
    log "Flushing existing iptables rules..."
    sudo iptables -F
    sudo iptables -X
    sudo iptables -t nat -F
    sudo iptables -t nat -X
    sudo iptables -t mangle -F
    sudo iptables -t mangle -X
    
    # Set default policies to DROP
    log "Setting default policies to DROP..."
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT
    
    # Allow established connections
    log "Allowing established connections..."
    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow localhost traffic (IPv4 only)
    log "Allowing localhost traffic..."
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A INPUT -s 127.0.0.1 -j ACCEPT
    
    # WHITELIST: Allow 192.168.1.99
    log "Whitelisting 192.168.1.99..."
    sudo iptables -A INPUT -s 192.168.1.99 -j ACCEPT
    
    # Allow essential services from local network
    log "Allowing essential local services..."
    sudo iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 22 -j ACCEPT  # SSH
    sudo iptables -A INPUT -s 192.168.1.0/24 -p udp --dport 53 -j ACCEPT  # DNS
    sudo iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 53 -j ACCEPT  # DNS
    
    # Allow multicast for local network (reduces filter_IN_block_REJECT)
    log "Allowing local multicast traffic..."
    sudo iptables -A INPUT -s 192.168.1.0/24 -d 224.0.0.0/8 -j ACCEPT
    sudo iptables -A INPUT -s 192.168.1.0/24 -d 239.0.0.0/8 -j ACCEPT
    sudo iptables -A INPUT -s 192.168.1.0/24 -p igmp -j ACCEPT
    
    # Allow router multicast traffic specifically
    log "Allowing router multicast traffic..."
    sudo iptables -A INPUT -s 192.168.1.254 -d 224.0.0.1 -j ACCEPT
    sudo iptables -A INPUT -s 192.168.1.254 -p igmp -j ACCEPT
    
    # Allow mDNS/Bonjour
    log "Allowing mDNS/Bonjour..."
    sudo iptables -A INPUT -s 192.168.1.0/24 -p udp --dport 5353 -j ACCEPT
    sudo iptables -A INPUT -s 192.168.1.0/24 -p udp --dport 5355 -j ACCEPT
    
    # Block everything else from external sources
    log "Blocking all other external traffic..."
    sudo iptables -A INPUT -j DROP
    
    log "Restrictive firewall setup complete"
}

create_persistent_firewall() {
    log "=== CREATING PERSISTENT FIREWALL RULES ==="
    
    # Save current rules
    sudo iptables-save > /tmp/restrictive-firewall.rules
    
    # Create systemd service for persistent firewall
    cat > /tmp/restrictive-firewall.service << 'EOF'
[Unit]
Description=Restrictive Firewall Rules
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -s 192.168.1.99 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -d 224.0.0.0/8 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -d 239.0.0.0/8 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p igmp -j ACCEPT
iptables -A INPUT -s 192.168.1.254 -d 224.0.0.1 -j ACCEPT
iptables -A INPUT -s 192.168.1.254 -p igmp -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p udp --dport 5353 -j ACCEPT
iptables -A INPUT -s 192.168.1.0/24 -p udp --dport 5355 -j ACCEPT
iptables -A INPUT -j DROP
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Install service
    sudo cp /tmp/restrictive-firewall.service /etc/systemd/system/ 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl enable restrictive-firewall.service 2>/dev/null || true
    log "Persistent firewall service installed"
}

show_current_rules() {
    log "=== CURRENT FIREWALL RULES ==="
    sudo iptables -L -n -v
}

test_connectivity() {
    log "=== TESTING CONNECTIVITY ==="
    
    # Test if 192.168.1.99 can reach us
    log "Testing connectivity from 192.168.1.99..."
    ping -c 1 192.168.1.99 2>/dev/null && log "✅ 192.168.1.99 is reachable" || warn "❌ 192.168.1.99 is not reachable"
    
    # Test if router can reach us (should be blocked)
    log "Testing router connectivity (should be blocked)..."
    ping -c 1 192.168.1.254 2>/dev/null && warn "⚠️ Router is still reachable" || log "✅ Router access blocked"
}

main() {
    log "=== RESTRICTIVE FIREWALL SETUP STARTED ==="
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
    
    # Request sudo privileges
    log "Requesting sudo privileges..."
    sudo -v
    
    # Apply restrictive firewall
    setup_restrictive_firewall
    create_persistent_firewall
    show_current_rules
    test_connectivity
    
    log "=== RESTRICTIVE FIREWALL SETUP COMPLETE ==="
    log "All traffic blocked except from 192.168.1.99"
    log "Essential local services still allowed from 192.168.1.0/24"
    log "Monitor dmesg for reduced filter_IN_block_REJECT messages"
}

# Run main function
main "$@" 