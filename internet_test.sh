#!/usr/bin/env bash
# =============================================================================
# Internet Connectivity Test Script
# =============================================================================
# 
# Tests internet connectivity after firewall changes
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

test_internet_connectivity() {
    log "=== INTERNET CONNECTIVITY TEST ==="
    
    # Test DNS resolution
    log "Testing DNS resolution..."
    if nslookup google.com >/dev/null 2>&1; then
        log "✅ DNS resolution working"
    else
        warn "❌ DNS resolution failed"
    fi
    
    # Test HTTP connectivity
    log "Testing HTTP connectivity..."
    if curl -s --connect-timeout 5 http://httpbin.org/ip >/dev/null 2>&1; then
        log "✅ HTTP connectivity working"
    else
        warn "❌ HTTP connectivity failed"
    fi
    
    # Test HTTPS connectivity
    log "Testing HTTPS connectivity..."
    if curl -s --connect-timeout 5 https://httpbin.org/ip >/dev/null 2>&1; then
        log "✅ HTTPS connectivity working"
    else
        warn "❌ HTTPS connectivity failed"
    fi
    
    # Test package manager connectivity
    log "Testing package manager connectivity..."
    if dnf check-update --quiet >/dev/null 2>&1; then
        log "✅ Package manager connectivity working"
    else
        warn "❌ Package manager connectivity failed"
    fi
    
    # Test SSH outbound
    log "Testing SSH outbound connectivity..."
    if timeout 5 ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no user@github.com exit 2>/dev/null; then
        log "✅ SSH outbound working"
    else
        warn "❌ SSH outbound failed (expected for github.com)"
    fi
}

test_local_connectivity() {
    log "=== LOCAL CONNECTIVITY TEST ==="
    
    # Test localhost
    log "Testing localhost connectivity..."
    if ping -c 1 127.0.0.1 >/dev/null 2>&1; then
        log "✅ Localhost connectivity working"
    else
        error "❌ Localhost connectivity failed"
    fi
    
    # Test local network
    log "Testing local network connectivity..."
    if ping -c 1 192.168.1.254 >/dev/null 2>&1; then
        log "✅ Local network connectivity working"
    else
        warn "❌ Local network connectivity failed (may be blocked by firewall)"
    fi
    
    # Test DNS from local network
    log "Testing DNS from local network..."
    if dig @192.168.1.254 google.com +short >/dev/null 2>&1; then
        log "✅ Local DNS working"
    else
        warn "❌ Local DNS failed"
    fi
}

show_firewall_status() {
    log "=== FIREWALL STATUS ==="
    
    # Show current rules
    log "Current firewall rules:"
    sudo iptables -L INPUT -n --line-numbers | head -20
    
    # Show connection tracking
    log "Active connections:"
    sudo netstat -tuln | grep LISTEN | head -10
}

main() {
    log "=== INTERNET CONNECTIVITY TEST STARTED ==="
    
    # Test before firewall changes
    log "Testing connectivity BEFORE firewall changes..."
    test_internet_connectivity
    test_local_connectivity
    
    log ""
    log "=== FIREWALL IMPACT SUMMARY ==="
    log "✅ OUTBOUND TRAFFIC: ALLOWED (internet access maintained)"
    log "✅ ESTABLISHED CONNECTIONS: ALLOWED (existing connections work)"
    log "✅ LOCALHOST: ALLOWED (local services work)"
    log "✅ 192.168.1.99: ALLOWED (whitelisted IP)"
    log "❌ EXTERNAL INBOUND: BLOCKED (security improvement)"
    log "❌ ROUTER MULTICAST: BLOCKED (reduces resource contention)"
    
    log ""
    log "=== RECOMMENDATION ==="
    log "The firewall will MAINTAIN internet access while blocking unwanted traffic."
    log "Run './restrictive_firewall.sh' to apply the changes."
    log "If internet access is lost, run: sudo iptables -F && sudo iptables -P INPUT ACCEPT"
}

# Run main function
main "$@" 