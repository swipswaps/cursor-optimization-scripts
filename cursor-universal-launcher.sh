#!/bin/bash
# Universal Cursor Launcher with Hardware Detection
# Works on any Linux system with automatic optimization

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root (should not be)
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
}

# Hardware detection functions with error handling
detect_system() {
    log "Detecting system hardware..."
    
    # CPU Detection
    if [[ ! -f /proc/cpuinfo ]]; then
        error "Cannot read /proc/cpuinfo"
        return 1
    fi
    
    if grep -q "AMD" /proc/cpuinfo; then
        CPU_TYPE="AMD"
        CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        CPU_CORES=$(nproc)
        success "CPU: $CPU_MODEL ($CPU_CORES cores)"
    elif grep -q "Intel" /proc/cpuinfo; then
        CPU_TYPE="Intel"
        CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
        CPU_CORES=$(nproc)
        success "CPU: $CPU_MODEL ($CPU_CORES cores)"
    else
        CPU_TYPE="Unknown"
        CPU_CORES=$(nproc 2>/dev/null || echo "unknown")
        warn "CPU: Unknown type ($CPU_CORES cores)"
    fi
    
    # GPU Detection
    if ! command -v lspci >/dev/null 2>&1; then
        error "lspci command not found"
        return 1
    fi
    
    if lspci | grep -i "amd" | grep -i "vga" > /dev/null; then
        GPU_TYPE="AMD"
        GPU_MODEL=$(lspci | grep -i "amd" | grep -i "vga" | head -1)
        success "GPU: $GPU_MODEL"
    elif lspci | grep -i "nvidia" | grep -i "vga" > /dev/null; then
        GPU_TYPE="NVIDIA"
        GPU_MODEL=$(lspci | grep -i "nvidia" | grep -i "vga" | head -1)
        success "GPU: $GPU_MODEL"
    elif lspci | grep -i "intel" | grep -i "vga" > /dev/null; then
        GPU_TYPE="Intel"
        GPU_MODEL=$(lspci | grep -i "intel" | grep -i "vga" | head -1)
        success "GPU: $GPU_MODEL"
    else
        GPU_TYPE="Unknown"
        warn "GPU: Unknown type"
    fi
    
    # Memory Detection
    if ! command -v free >/dev/null 2>&1; then
        error "free command not found"
        return 1
    fi
    
    TOTAL_RAM=$(free -m | grep "Mem:" | awk '{print $2}' 2>/dev/null || echo "0")
    AVAILABLE_RAM=$(free -m | grep "Mem:" | awk '{print $7}' 2>/dev/null || echo "0")
    
    if [[ "$TOTAL_RAM" -eq 0 ]]; then
        error "Cannot determine memory size"
        return 1
    fi
    
    log "Memory: ${TOTAL_RAM}MB total, ${AVAILABLE_RAM}MB available"
    
    # Determine memory profile
    if [[ "$TOTAL_RAM" -ge 16384 ]]; then
        MEMORY_PROFILE="high"
        JS_MEMORY="4096"
        success "High memory system (16GB+) - using 4GB JS heap"
    elif [[ "$TOTAL_RAM" -ge 8192 ]]; then
        MEMORY_PROFILE="medium"
        JS_MEMORY="2048"
        success "Medium memory system (8GB+) - using 2GB JS heap"
    else
        MEMORY_PROFILE="low"
        JS_MEMORY="1024"
        warn "Low memory system (<8GB) - using 1GB JS heap"
    fi
}

check_system_health() {
    log "Checking system health..."
    
    # CPU Temperature
    if command -v sensors >/dev/null 2>&1; then
        CPU_TEMP=$(sensors 2>/dev/null | grep "Core" | head -1 | awk '{print $3}' | sed 's/+//' | sed 's/°C//' || echo "")
        if [[ -n "$CPU_TEMP" && "$CPU_TEMP" -gt 80 ]]; then
            warn "High CPU temperature: ${CPU_TEMP}°C"
        elif [[ -n "$CPU_TEMP" ]]; then
            success "CPU temperature: ${CPU_TEMP}°C"
        fi
    fi
    
    # Disk Space
    if command -v df >/dev/null 2>&1; then
        DISK_USAGE=$(df / 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")
        if [[ "$DISK_USAGE" -gt 90 ]]; then
            warn "Low disk space: ${DISK_USAGE}% used"
        else
            success "Disk space: ${DISK_USAGE}% used"
        fi
    fi
    
    # System Load
    if command -v uptime >/dev/null 2>&1 && command -v bc >/dev/null 2>&1; then
        LOAD_AVG=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' || echo "0")
        if (( $(echo "$LOAD_AVG > 2.0" | bc -l 2>/dev/null || echo "0") )); then
            warn "High system load: $LOAD_AVG"
        else
            success "System load: $LOAD_AVG"
        fi
    fi
    
    # Available Memory
    if [[ "$AVAILABLE_RAM" -lt 1024 ]]; then
        warn "Low available memory: ${AVAILABLE_RAM}MB"
    else
        success "Available memory: ${AVAILABLE_RAM}MB"
    fi
}

optimize_for_hardware() {
    log "Optimizing for detected hardware..."
    
    # CPU-specific optimizations
    case $CPU_TYPE in
        "AMD")
            success "Applying AMD optimizations..."
            # AMD Ryzen benefits from performance governor
            if command -v cpupower >/dev/null 2>&1; then
                if sudo cpupower frequency-set -g performance >/dev/null 2>&1; then
                    log "Set CPU governor to performance"
                else
                    warn "Failed to set CPU governor (may need sudo privileges)"
                fi
            fi
            ;;
        "Intel")
            success "Applying Intel optimizations..."
            # Intel CPUs work well with default settings
            ;;
        *)
            warn "Unknown CPU - using standard optimizations"
            ;;
    esac
    
    # GPU-specific optimizations
    case $GPU_TYPE in
        "AMD")
            success "Applying AMD GPU optimizations..."
            GPU_FLAGS="--disable-gpu-sandbox --disable-software-rasterizer"
            ;;
        "NVIDIA")
            success "Applying NVIDIA GPU optimizations..."
            GPU_FLAGS="--disable-gpu --disable-gpu-sandbox"
            ;;
        "Intel")
            success "Applying Intel GPU optimizations..."
            GPU_FLAGS="--disable-gpu"
            ;;
        *)
            warn "Unknown GPU - using standard GPU flags"
            GPU_FLAGS="--disable-gpu"
            ;;
    esac
    
    # Memory-based optimizations
    case $MEMORY_PROFILE in
        "high")
            success "High memory system - aggressive optimizations"
            ADDITIONAL_FLAGS="--disable-background-timer-throttling --disable-renderer-backgrounding --disable-backgrounding-occluded-windows --disable-ipc-flooding-protection"
            ;;
        "medium")
            success "Medium memory system - balanced optimizations"
            ADDITIONAL_FLAGS="--disable-background-timer-throttling --disable-renderer-backgrounding"
            ;;
        "low")
            warn "Low memory system - conservative optimizations"
            ADDITIONAL_FLAGS=""
            ;;
        *)
            warn "Unknown memory profile - using conservative settings"
            ADDITIONAL_FLAGS=""
            ;;
    esac
    
    # System health-based adjustments
    if [[ "$AVAILABLE_RAM" -lt 1024 ]]; then
        warn "Low memory detected - reducing JS heap"
        JS_MEMORY="512"
        ADDITIONAL_FLAGS=""
    fi
}

find_cursor_appimage() {
    log "Finding Cursor AppImage..."
    
    local cursor_app=""
    local possible_paths=(
        "$HOME/Downloads/Cursor-1.2.2-x86_64.AppImage.zs-old"
        "$HOME/Downloads/Cursor-1.2.2-x86_64.AppImage"
        "$HOME/Downloads/Cursor*.AppImage"
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            cursor_app="$path"
            break
        fi
    done
    
    # If no specific file found, try to find any Cursor AppImage
    if [[ -z "$cursor_app" ]]; then
        cursor_app=$(find "$HOME/Downloads" -name "Cursor*.AppImage" -type f 2>/dev/null | head -1)
    fi
    
    if [[ -z "$cursor_app" ]]; then
        error "Cursor AppImage not found in Downloads"
        error "Please download Cursor AppImage to ~/Downloads/"
        return 1
    fi
    
    if [[ ! -x "$cursor_app" ]]; then
        log "Making AppImage executable..."
        chmod +x "$cursor_app"
    fi
    
    log "Using Cursor at: $cursor_app"
    echo "$cursor_app"
}

clear_safe_caches() {
    log "Clearing safe caches..."
    
    local cache_dirs=(
        "$HOME/.cache/fontconfig"
        "$HOME/.config/Cursor/Cache"
        "$HOME/.config/Cursor/CachedData"
        "$HOME/.config/Cursor/Code Cache"
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir" 2>/dev/null || warn "Failed to clear $dir"
        fi
    done
}

main() {
    echo "🚀 Starting Cursor with universal hardware detection..."
    
    # Check not running as root
    check_not_root
    
    # Run detection and optimization
    detect_system || error "System detection failed"
    check_system_health
    optimize_for_hardware
    
    # Clear caches
    clear_safe_caches
    
    # Find Cursor AppImage
    CURSOR_APP=$(find_cursor_appimage) || exit 1
    
    # Launch with hardware-optimized flags
    log "Launching Cursor with universal hardware optimizations..."
    
    if ! "$CURSOR_APP" \
        $GPU_FLAGS \
        --no-sandbox \
        --disable-dev-shm-usage \
        --disable-features=VizDisplayCompositor \
        --js-flags="--max-old-space-size=$JS_MEMORY" \
        $ADDITIONAL_FLAGS \
        "$@"; then
        error "Failed to launch Cursor"
        exit 1
    fi
    
    success "Cursor launched with universal hardware optimizations!"
    echo "📊 Final Summary:"
    echo "   CPU: $CPU_TYPE ($CPU_CORES cores)"
    echo "   GPU: $GPU_TYPE"
    echo "   Memory: ${TOTAL_RAM}MB total (${MEMORY_PROFILE} profile)"
    echo "   JS Heap: ${JS_MEMORY}MB"
    echo "   Available: ${AVAILABLE_RAM}MB"
}

# Run main function
main "$@" 