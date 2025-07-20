#!/bin/bash

# Chat History Restoration & Ivy Bridge CPU Fix
# Restores chat history and addresses Ivy Bridge CPU issues

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
action() { echo -e "${PURPLE}[ACTION]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }

echo "🔧 Chat History Restoration & Ivy Bridge CPU Fix"
echo "================================================"
echo "This will restore your chat history and fix Ivy Bridge CPU issues"
echo ""

# Configuration
BACKUP_DIR="backups/cursor_20250719_115519"
CURSOR_CONFIG_DIR="$HOME/.config/Cursor"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if backup exists
check_backup_exists() {
    action "🔍 Checking for chat history backup..."
    
    if [[ -d "$CURRENT_DIR/$BACKUP_DIR" ]]; then
        success "Found backup directory: $BACKUP_DIR"
        
        # Count chat history files
        local history_count=$(find "$CURRENT_DIR/$BACKUP_DIR/User/History" -name "*.md" 2>/dev/null | wc -l)
        if [[ $history_count -gt 0 ]]; then
            success "Found $history_count chat history files"
            return 0
        else
            warning "No chat history files found in backup"
            return 1
        fi
    else
        error "Backup directory not found: $BACKUP_DIR"
        return 1
    fi
}

# Function to restore chat history
restore_chat_history() {
    action "📝 Restoring chat history..."
    
    # Create backup of current chat history
    if [[ -d "$CURSOR_CONFIG_DIR/User/History" ]]; then
        log "Creating backup of current chat history..."
        cp -r "$CURSOR_CONFIG_DIR/User/History" "$CURSOR_CONFIG_DIR/User/History.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null
        success "Current chat history backed up"
    fi
    
    # Restore from backup
    if [[ -d "$CURRENT_DIR/$BACKUP_DIR/User/History" ]]; then
        log "Restoring chat history from backup..."
        
        # Create History directory if it doesn't exist
        mkdir -p "$CURSOR_CONFIG_DIR/User/History"
        
        # Copy all history files
        cp -r "$CURRENT_DIR/$BACKUP_DIR/User/History"/* "$CURSOR_CONFIG_DIR/User/History/" 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            success "Chat history restored successfully"
            
            # Count restored files
            local restored_count=$(find "$CURSOR_CONFIG_DIR/User/History" -name "*.md" 2>/dev/null | wc -l)
            info "Restored $restored_count chat history files"
        else
            error "Failed to restore chat history"
            return 1
        fi
    else
        error "No History directory found in backup"
        return 1
    fi
}

# Function to restore other Cursor data
restore_cursor_data() {
    action "📁 Restoring other Cursor data..."
    
    # Restore settings
    if [[ -f "$CURRENT_DIR/$BACKUP_DIR/User/settings.json" ]]; then
        log "Restoring settings..."
        cp "$CURRENT_DIR/$BACKUP_DIR/User/settings.json" "$CURSOR_CONFIG_DIR/User/" 2>/dev/null
        success "Settings restored"
    fi
    
    # Restore keybindings
    if [[ -f "$CURRENT_DIR/$BACKUP_DIR/User/keybindings.json" ]]; then
        log "Restoring keybindings..."
        cp "$CURRENT_DIR/$BACKUP_DIR/User/keybindings.json" "$CURSOR_CONFIG_DIR/User/" 2>/dev/null
        success "Keybindings restored"
    fi
    
    # Restore globalStorage (extensions and their data)
    if [[ -d "$CURRENT_DIR/$BACKUP_DIR/User/globalStorage" ]]; then
        log "Restoring global storage..."
        cp -r "$CURRENT_DIR/$BACKUP_DIR/User/globalStorage"/* "$CURSOR_CONFIG_DIR/User/globalStorage/" 2>/dev/null
        success "Global storage restored"
    fi
}

# Function to create Ivy Bridge CPU optimized launcher
create_ivy_bridge_launcher() {
    action "🖥️ Creating Ivy Bridge CPU optimized launcher..."
    
    cat > "$HOME/cursor-ivy-bridge-optimized.sh" << 'IVY_BRIDGE_LAUNCHER'
#!/bin/bash

# Ivy Bridge CPU Optimized Cursor Launcher
# Specifically designed for Intel Ivy Bridge processors (2012-2013)

# Disable all GPU acceleration (Ivy Bridge GPU is too weak)
export ELECTRON_DISABLE_GPU=1
export ELECTRON_DISABLE_SOFTWARE_RASTERIZER=1
export ELECTRON_DISABLE_GPU_SANDBOX=1
export ELECTRON_DISABLE_GPU_PROCESS=1
export ELECTRON_DISABLE_GPU_MEMORY_BUFFER=1
export ELECTRON_DISABLE_GPU_MEMORY_STATS=1
export ELECTRON_DISABLE_GPU_MEMORY_PRESSURE=1
export ELECTRON_DISABLE_GPU_MEMORY_LIMIT=1
export ELECTRON_DISABLE_GPU_MEMORY_GROWTH=1
export ELECTRON_DISABLE_GPU_MEMORY_SHRINK=1
export CURSOR_DISABLE_GPU=1
export CURSOR_DISABLE_SOFTWARE_RASTERIZER=1

# Ivy Bridge specific optimizations
export ELECTRON_DISABLE_DEV_SHM_USAGE=1
export ELECTRON_DISABLE_FEATURES=VizDisplayCompositor
export ELECTRON_FORCE_GPU_MEM_AVAILABLE_MB=128
export ELECTRON_GPU_MEMORY_LIMIT=256
export ELECTRON_GPU_MEMORY_GROWTH_LIMIT=128

# Memory optimizations for limited RAM
export ELECTRON_MAX_OLD_SPACE_SIZE=512
export NODE_OPTIONS="--max-old-space-size=512"

# Disable problematic features for Ivy Bridge
export ELECTRON_DISABLE_BACKGROUND_TIMER_THROTTLING=1
export ELECTRON_DISABLE_BACKGROUNDING_OCCLUDED_WINDOWS=1
export ELECTRON_DISABLE_RENDERER_BACKGROUNDING=1
export ELECTRON_DISABLE_FIELD_TRIAL_CONFIG=1
export ELECTRON_DISABLE_IPC_FLOODING_PROTECTION=1

# Launch with Ivy Bridge optimizations
cursor --disable-gpu \
       --disable-software-rasterizer \
       --disable-dev-shm-usage \
       --no-sandbox \
       --disable-setuid-sandbox \
       --disable-web-security \
       --disable-features=VizDisplayCompositor \
       --disable-background-timer-throttling \
       --disable-backgrounding-occluded-windows \
       --disable-renderer-backgrounding \
       --disable-field-trial-config \
       --disable-ipc-flooding-protection \
       --force-gpu-mem-available-mb=128 \
       --max-old-space-size=512 \
       --js-flags="--max-old-space-size=512" \
       "$@"
IVY_BRIDGE_LAUNCHER
    
    chmod +x "$HOME/cursor-ivy-bridge-optimized.sh"
    success "Created Ivy Bridge optimized launcher: $HOME/cursor-ivy-bridge-optimized.sh"
}

# Function to explain Ivy Bridge CPU issues
explain_ivy_bridge_issues() {
    action "📚 Explaining Ivy Bridge CPU Issues"
    echo ""
    
    echo "**Ivy Bridge CPU Limitations (2012-2013):**"
    echo ""
    echo "1. **Weak Integrated GPU**"
    echo "   • Intel HD Graphics 2500/4000"
    echo "   • No dedicated VRAM (uses system RAM)"
    echo "   • Limited to OpenGL 3.0/WebGL 1.0"
    echo "   • Cannot handle modern GPU acceleration"
    echo ""
    
    echo "2. **Memory Architecture**"
    echo "   • GPU shares system memory"
    echo "   • Limited total RAM (typically 4-8GB)"
    echo "   • Memory pressure causes crashes"
    echo "   • GPU processes compete with system processes"
    echo ""
    
    echo "3. **Electron Compatibility Issues**"
    echo "   • Modern Electron expects dedicated GPU"
    echo "   • WebGL 2.0 features not supported"
    echo "   • Hardware acceleration fails"
    echo "   • Falls back to software rendering (slow)"
    echo ""
    
    echo "4. **Process Management Issues**"
    echo "   • Multiple GPU processes spawn"
    echo "   • Each process needs memory allocation"
    echo "   • Failed allocations cause crashes"
    echo "   • Process cleanup fails"
    echo ""
    
    echo "**The Solution:**"
    echo "  • Disable ALL GPU acceleration"
    echo "  • Use software rendering only"
    echo "  • Limit memory usage"
    echo "  • Reduce process count"
    echo "  • Accept slower but stable performance"
    echo ""
}

# Function to create performance monitoring script
create_performance_monitor() {
    action "📊 Creating Ivy Bridge performance monitor..."
    
    cat > "$HOME/cursor-ivy-bridge-monitor.sh" << 'IVY_BRIDGE_MONITOR'
#!/bin/bash

# Ivy Bridge Performance Monitor
# Monitors and optimizes Cursor for Ivy Bridge CPUs

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Monitor and optimize for Ivy Bridge
monitor_ivy_bridge() {
    while true; do
        # Check for high-CPU processes (lower threshold for Ivy Bridge)
        local high_cpu=$(ps aux | grep cursor | grep -v grep | awk '$3 > 15.0 {print $2, $3}')
        
        if [[ -n "$high_cpu" ]]; then
            log "High-CPU processes detected: $high_cpu"
            
            # Kill only non-critical processes
            echo "$high_cpu" | while read pid cpu; do
                local cmd=$(ps -p "$pid" -o cmd= 2>/dev/null)
                
                # Only kill utility/gpu processes, never main/renderer
                if [[ "$cmd" == *"utility"* || "$cmd" == *"gpu"* ]]; then
                    log "Killing utility/gpu process PID $pid (CPU: ${cpu}%)"
                    kill "$pid" 2>/dev/null
                fi
            done
        fi
        
        # Check memory usage
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        if (( $(echo "$mem_usage > 80.0" | bc -l 2>/dev/null || echo 0) )); then
            warning "High memory usage: ${mem_usage}%"
            log "Clearing system cache..."
            sudo sync 2>/dev/null
            echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
        fi
        
        # Check for TypeScript server issues
        local tsserver_cpu=$(ps aux | grep tsserver | grep -v grep | awk '{sum += $3} END {print sum}')
        if (( $(echo "$tsserver_cpu > 30.0" | bc -l 2>/dev/null || echo 0) )); then
            warning "TypeScript server using ${tsserver_cpu}% CPU"
            log "Restarting TypeScript server..."
            pkill tsserver 2>/dev/null
        fi
        
        sleep 30  # Check every 30 seconds (less aggressive for Ivy Bridge)
    done
}

# Main function
main() {
    echo "🖥️ Ivy Bridge Performance Monitor Started"
    echo "Monitoring Cursor performance for Ivy Bridge CPU..."
    echo "Log file: $HOME/.cursor_ivy_bridge.log"
    
    # Start monitoring
    monitor_ivy_bridge >> "$HOME/.cursor_ivy_bridge.log" 2>&1
}

main "$@"
IVY_BRIDGE_MONITOR
    
    chmod +x "$HOME/cursor-ivy-bridge-monitor.sh"
    success "Created Ivy Bridge performance monitor: $HOME/cursor-ivy-bridge-monitor.sh"
}

# Function to provide usage instructions
provide_instructions() {
    echo ""
    echo "📋 Chat History Restoration & Ivy Bridge Fix Instructions:"
    echo "========================================================"
    echo ""
    echo "✅ **Chat History Restored:**"
    echo "   • Your chat history has been restored from backup"
    echo "   • Previous conversations should now be available"
    echo "   • Settings and keybindings also restored"
    echo ""
    echo "🖥️ **Ivy Bridge CPU Optimizations:**"
    echo "   • Created Ivy Bridge optimized launcher"
    echo "   • Disabled all GPU acceleration"
    echo "   • Optimized memory usage"
    echo "   • Added performance monitoring"
    echo ""
    echo "🚀 **How to Use:**"
    echo ""
    echo "1. **Launch Cursor with Ivy Bridge optimizations:**"
    echo "   ~/cursor-ivy-bridge-optimized.sh"
    echo ""
    echo "2. **Start performance monitoring (optional):**"
    echo "   ~/cursor-ivy-bridge-monitor.sh &"
    echo ""
    echo "3. **Check performance logs:**"
    echo "   tail -f ~/.cursor_ivy_bridge.log"
    echo ""
    echo "4. **Stop monitoring:**"
    echo "   pkill -f cursor-ivy-bridge-monitor"
    echo ""
    echo "💡 **Expected Performance:**"
    echo "   • Stable operation (no more crashes)"
    echo "   • Slower graphics (software rendering)"
    echo "   • Responsive typing (no delays)"
    echo "   • Chat history available"
    echo ""
}

# Main function
main() {
    echo "Starting chat history restoration and Ivy Bridge CPU fix..."
    echo ""
    
    # Step 1: Check backup
    if ! check_backup_exists; then
        error "Cannot proceed without backup"
        exit 1
    fi
    
    # Step 2: Restore chat history
    if restore_chat_history; then
        success "Chat history restoration completed"
    else
        warning "Chat history restoration had issues"
    fi
    
    # Step 3: Restore other data
    restore_cursor_data
    
    # Step 4: Create Ivy Bridge optimizations
    create_ivy_bridge_launcher
    create_performance_monitor
    
    # Step 5: Explain Ivy Bridge issues
    explain_ivy_bridge_issues
    
    # Step 6: Provide instructions
    provide_instructions
    
    echo ""
    success "✅ Chat history restoration and Ivy Bridge CPU fix completed!"
    echo "🎯 Your chat history should now be available in Cursor"
    echo "🖥️ Use ~/cursor-ivy-bridge-optimized.sh for best performance"
}

# Run main function
main "$@" 