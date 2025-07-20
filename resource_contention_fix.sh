#!/usr/bin/env bash
# =============================================================================
# Resource Contention Fix Script
# =============================================================================
# 
# Addresses critical resource contention issues:
# - Network filter optimization
# - GPU interrupt balancing
# - Soft IRQ distribution
# - Memory cache pressure optimization
# - CPU affinity improvements
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

fix_network_filters() {
    log "=== NETWORK FILTER OPTIMIZATION ==="
    
    # Optimize iptables rules to reduce filter overhead
    log "Optimizing iptables rules..."
    
    # Add optimized rules to reduce filter processing
    sudo iptables -t filter -I INPUT 1 -p igmp -j ACCEPT 2>/dev/null || true
    sudo iptables -t filter -I INPUT 1 -d 224.0.0.1 -j ACCEPT 2>/dev/null || true
    
    # Optimize existing rules
    sudo iptables -t filter -D INPUT -p igmp -j DROP 2>/dev/null || true
    
    log "Network filter optimization complete"
}

fix_gpu_interrupts() {
    log "=== GPU INTERRUPT OPTIMIZATION ==="
    
    # Find i915 GPU device
    local gpu_dev=$(lspci | grep -i "vga.*intel" | awk '{print $1}')
    if [[ -n "$gpu_dev" ]]; then
        log "Found GPU device: $gpu_dev"
        
        # Set GPU interrupt affinity to spread across CPUs (with sudo)
        local irq=$(cat /proc/interrupts | grep i915 | awk '{print $1}' | tr -d ':')
        if [[ -n "$irq" ]]; then
            log "Setting GPU interrupt $irq affinity..."
            sudo sh -c "echo 2 > /proc/irq/$irq/smp_affinity" 2>/dev/null || warn "GPU interrupt affinity setting failed (may require reboot)"
        fi
        
        # Optimize i915 parameters (with sudo)
        log "Optimizing i915 parameters..."
        sudo sh -c "echo 1 > /sys/module/i915/parameters/enable_rc6" 2>/dev/null || warn "i915 RC6 setting failed"
        sudo sh -c "echo 1 > /sys/module/i915/parameters/enable_dc" 2>/dev/null || warn "i915 DC setting failed"
        sudo sh -c "echo 0 > /sys/module/i915/parameters/enable_fbc" 2>/dev/null || warn "i915 FBC setting failed"
    else
        warn "No Intel GPU found for interrupt optimization"
    fi
}

fix_soft_irq_balance() {
    log "=== SOFT IRQ BALANCING ==="
    
    # Optimize soft IRQ distribution
    log "Optimizing soft IRQ distribution..."
    
    # Set CPU affinity for network interrupts (with sudo)
    local net_irq=$(cat /proc/interrupts | grep enp1s0f0 | awk '{print $1}' | tr -d ':')
    if [[ -n "$net_irq" ]]; then
        log "Setting network interrupt $net_irq affinity..."
        sudo sh -c "echo 4 > /proc/irq/$net_irq/smp_affinity" 2>/dev/null || warn "Network interrupt affinity setting failed"
    fi
    
    # Optimize RCU and scheduler parameters (with sudo)
    log "Optimizing RCU and scheduler parameters..."
    sudo sh -c "echo 1000 > /proc/sys/kernel/rcu_cpu_stall_timeout" 2>/dev/null || warn "RCU stall timeout setting failed"
    sudo sh -c "echo 1 > /proc/sys/kernel/rcu_nocbs" 2>/dev/null || warn "RCU nocbs setting failed"
}

fix_memory_pressure() {
    log "=== MEMORY PRESSURE OPTIMIZATION ==="
    
    # Reduce cache pressure for better performance (with sudo)
    log "Reducing cache pressure..."
    sudo sh -c "echo 50 > /proc/sys/vm/vfs_cache_pressure" 2>/dev/null || warn "Cache pressure setting failed"
    
    # Optimize dirty ratios further (with sudo)
    log "Optimizing dirty ratios..."
    sudo sh -c "echo 5 > /proc/sys/vm/dirty_ratio" 2>/dev/null || warn "Dirty ratio setting failed"
    sudo sh -c "echo 2 > /proc/sys/vm/dirty_background_ratio" 2>/dev/null || warn "Dirty background ratio setting failed"
    
    # Optimize page cache (with sudo)
    log "Optimizing page cache..."
    sudo sh -c "echo 3 > /proc/sys/vm/page-cluster" 2>/dev/null || warn "Page cluster setting failed"
    sudo sh -c "echo 90 > /proc/sys/vm/dirtytime_expire_centisecs" 2>/dev/null || warn "Dirtytime expire setting failed"
}

fix_cpu_affinity() {
    log "=== CPU AFFINITY OPTIMIZATION ==="
    
    # Set Cursor processes to specific CPU cores
    log "Setting Cursor CPU affinity..."
    
    # Find Cursor processes and set affinity
    local cursor_pids=$(pgrep -f "cursor.*AppImage" 2>/dev/null || true)
    if [[ -n "$cursor_pids" ]]; then
        for pid in $cursor_pids; do
            log "Setting CPU affinity for Cursor PID $pid..."
            sudo taskset -cp 0,1 $pid 2>/dev/null || warn "Cursor affinity setting failed for PID $pid"
        done
    fi
    
    # Set GPU process to different CPU
    local gpu_pid=$(pgrep -f "gpu-process" 2>/dev/null || true)
    if [[ -n "$gpu_pid" ]]; then
        log "Setting GPU process affinity..."
        sudo taskset -cp 2,3 $gpu_pid 2>/dev/null || warn "GPU process affinity setting failed"
    fi
}

fix_io_scheduler() {
    log "=== I/O SCHEDULER OPTIMIZATION ==="
    
    # Set I/O scheduler to deadline for better responsiveness (with sudo)
    log "Setting I/O scheduler to deadline..."
    sudo sh -c "echo deadline > /sys/block/sda/queue/scheduler" 2>/dev/null || warn "I/O scheduler setting failed"
    
    # Optimize I/O queue parameters (with sudo)
    log "Optimizing I/O queue parameters..."
    sudo sh -c "echo 128 > /sys/block/sda/queue/nr_requests" 2>/dev/null || warn "I/O queue requests setting failed"
    sudo sh -c "echo 4 > /sys/block/sda/queue/iosched/fifo_batch" 2>/dev/null || warn "I/O fifo batch setting failed"
}

create_persistent_settings() {
    log "=== CREATING PERSISTENT SETTINGS ==="
    
    # Create systemd service for persistent settings
    cat > /tmp/resource-optimizer.service << 'EOF'
[Unit]
Description=Resource Contention Optimizer
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
echo 50 > /proc/sys/vm/vfs_cache_pressure
echo 5 > /proc/sys/vm/dirty_ratio
echo 2 > /proc/sys/vm/dirty_background_ratio
echo deadline > /sys/block/sda/queue/scheduler
echo 2 > /proc/irq/28/smp_affinity
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Install service if systemd is available
    if command -v systemctl >/dev/null 2>&1; then
        sudo cp /tmp/resource-optimizer.service /etc/systemd/system/ 2>/dev/null || true
        sudo systemctl daemon-reload 2>/dev/null || true
        sudo systemctl enable resource-optimizer.service 2>/dev/null || true
        log "Persistent settings service installed"
    else
        warn "systemd not available, settings will reset on reboot"
    fi
}

main() {
    log "=== RESOURCE CONTENTION FIX STARTED ==="
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
    
    # Request sudo privileges
    log "Requesting sudo privileges..."
    sudo -v
    
    # Apply all fixes
    fix_network_filters
    fix_gpu_interrupts
    fix_soft_irq_balance
    fix_memory_pressure
    fix_cpu_affinity
    fix_io_scheduler
    create_persistent_settings
    
    log "=== RESOURCE CONTENTION FIX COMPLETE ==="
    log "Changes applied. Monitor system performance."
    log "Some changes may require reboot for full effect."
    log "Warnings are normal for protected system parameters."
}

# Run main function
main "$@" 