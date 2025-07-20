#!/usr/bin/env bash
# =============================================================================
# Network Filter Optimization Script
# =============================================================================
# 
# Aggressively optimizes network filtering to eliminate
# filter_IN_block_REJECT overhead that's causing resource contention
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

fix_network_filters() {
    log "=== AGGRESSIVE NETWORK FILTER OPTIMIZATION ==="
    
    # Remove problematic rules that cause filter_IN_block_REJECT
    log "Removing problematic network filter rules..."
    
    # Remove rules that block IGMP and multicast
    sudo iptables -t filter -D INPUT -p igmp -j DROP 2>/dev/null || true
    sudo iptables -t filter -D INPUT -d 224.0.0.0/8 -j DROP 2>/dev/null || true
    sudo iptables -t filter -D INPUT -d 239.0.0.0/8 -j DROP 2>/dev/null || true
    
    # Add optimized rules to allow common traffic
    log "Adding optimized network filter rules..."
    sudo iptables -t filter -I INPUT 1 -p igmp -j ACCEPT 2>/dev/null || true
    sudo iptables -t filter -I INPUT 1 -d 224.0.0.0/8 -j ACCEPT 2>/dev/null || true
    sudo iptables -t filter -I INPUT 1 -d 239.0.0.0/8 -j ACCEPT 2>/dev/null || true
    sudo iptables -t filter -I INPUT 1 -p udp --dport 5353 -j ACCEPT 2>/dev/null || true  # mDNS
    
    # Optimize firewall rules for better performance
    log "Optimizing firewall rule order..."
    sudo iptables -t filter -I INPUT 1 -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
    
    log "Network filter optimization complete"
}

check_firewall_status() {
    log "=== FIREWALL STATUS CHECK ==="
    
    # Check if firewalld is running
    if systemctl is-active --quiet firewalld; then
        log "firewalld is active - optimizing..."
        sudo firewall-cmd --permanent --add-service=mdns 2>/dev/null || true
        sudo firewall-cmd --permanent --add-protocol=igmp 2>/dev/null || true
        sudo firewall-cmd --reload 2>/dev/null || true
    else
        log "firewalld not active"
    fi
    
    # Check if ufw is running
    if systemctl is-active --quiet ufw; then
        log "ufw is active - optimizing..."
        sudo ufw allow igmp 2>/dev/null || true
        sudo ufw allow 224.0.0.0/8 2>/dev/null || true
    else
        log "ufw not active"
    fi
}

optimize_network_interfaces() {
    log "=== NETWORK INTERFACE OPTIMIZATION ==="
    
    # Optimize network interface parameters
    local interfaces=$(ip link show | grep -E "^[0-9]+:" | awk -F: '{print $2}' | tr -d ' ')
    
    for iface in $interfaces; do
        if [[ -n "$iface" && "$iface" != "lo" ]]; then
            log "Optimizing interface: $iface"
            
            # Optimize interface parameters
            sudo ethtool -G $iface rx 4096 tx 4096 2>/dev/null || true
            sudo ethtool -C $iface adaptive-rx on adaptive-tx on 2>/dev/null || true
        fi
    done
}

create_persistent_network_settings() {
    log "=== CREATING PERSISTENT NETWORK SETTINGS ==="
    
    # Create systemd service for network optimizations
    cat > /tmp/network-optimizer.service << 'EOF'
[Unit]
Description=Network Filter Optimizer
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
iptables -t filter -I INPUT 1 -p igmp -j ACCEPT
iptables -t filter -I INPUT 1 -d 224.0.0.0/8 -j ACCEPT
iptables -t filter -I INPUT 1 -d 239.0.0.0/8 -j ACCEPT
iptables -t filter -I INPUT 1 -p udp --dport 5353 -j ACCEPT
iptables -t filter -I INPUT 1 -m state --state ESTABLISHED,RELATED -j ACCEPT
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Install service
    sudo cp /tmp/network-optimizer.service /etc/systemd/system/ 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl enable network-optimizer.service 2>/dev/null || true
    log "Persistent network settings installed"
}

main() {
    log "=== NETWORK FILTER FIX STARTED ==="
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
    
    # Request sudo privileges
    log "Requesting sudo privileges..."
    sudo -v
    
    # Apply network optimizations
    fix_network_filters
    check_firewall_status
    optimize_network_interfaces
    create_persistent_network_settings
    
    log "=== NETWORK FILTER FIX COMPLETE ==="
    log "Network optimizations applied. Monitor dmesg for filter_IN_block_REJECT reduction."
}

# Run main function
main "$@" 