#!/bin/bash
# Cursor AppImage Manager
# Handles downloading, versioning, and selection of Cursor AppImages

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging functions
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

# Configuration
readonly DOWNLOADS_DIR="$HOME/Downloads"
readonly CURSOR_DIR="$HOME/.local/share/cursor-appimages"
readonly VERSIONS_FILE="$CURSOR_DIR/versions.json"

# Create directories if they don't exist
init_directories() {
    log "Initializing directories..."
    mkdir -p "$CURSOR_DIR"
    mkdir -p "$DOWNLOADS_DIR"
}

# Get latest Cursor version from GitHub
get_latest_version() {
    # Only log if not being called for variable assignment
    if [[ -t 1 ]]; then
        log "Fetching latest Cursor version..."
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required but not installed"
        return 1
    fi
    
    local latest_version
    local api_response
    api_response=$(curl -s https://api.github.com/repos/getcursor/cursor/releases/latest)
    
    if [[ -n "$api_response" ]]; then
        latest_version=$(echo "$api_response" | grep '"tag_name"' | cut -d'"' -f4)
    fi
    
    if [[ -z "$latest_version" ]]; then
        # Try alternative method
        latest_version=$(echo "$api_response" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [[ -z "$latest_version" ]]; then
        # Fallback to a known recent version
        if [[ -t 1 ]]; then
            warn "Failed to fetch latest version from GitHub API"
            warn "Using fallback version: 1.2.2"
        fi
        latest_version="1.2.2"
    fi
    
    if [[ -t 1 ]]; then
        log "Latest version: $latest_version"
    fi
    echo "$latest_version"
}

# Download Cursor AppImage
download_cursor() {
    local version="$1"
    local target_file="$2"
    
    log "Downloading Cursor version $version..."
    
    local download_url
    if [[ "$version" == "latest" ]]; then
        download_url="https://download.cursor.sh/linux/appImage/x64"
    else
        # Try the official download URL first
        download_url="https://download.cursor.sh/linux/appImage/x64"
    fi
    
    log "Download URL: $download_url"
    
    if curl -L -o "$target_file" "$download_url"; then
        chmod +x "$target_file"
        success "Downloaded Cursor $version to $target_file"
        return 0
    else
        error "Failed to download Cursor $version"
        return 1
    fi
}

# List available versions
list_versions() {
    log "Available Cursor versions:"
    
    if [[ ! -f "$VERSIONS_FILE" ]]; then
        warn "No versions file found. Run 'download' first."
        return 1
    fi
    
    if command -v jq >/dev/null 2>&1; then
        jq -r 'to_entries[] | "\(.key): \(.value.path) (\(.value.date))"' "$VERSIONS_FILE"
    else
        cat "$VERSIONS_FILE"
    fi
}

# Add version to tracking
add_version() {
    local version="$1"
    local file_path="$2"
    
    log "Adding version $version to tracking..."
    
    local temp_file
    temp_file=$(mktemp)
    
    if [[ -f "$VERSIONS_FILE" ]]; then
        cp "$VERSIONS_FILE" "$temp_file"
    else
        echo "{}" > "$temp_file"
    fi
    
    if command -v jq >/dev/null 2>&1; then
        jq --arg version "$version" --arg path "$file_path" --arg date "$(date -Iseconds)" \
           '. + {($version): {"path": $path, "date": $date}}' "$temp_file" > "$VERSIONS_FILE"
    else
        # Simple JSON manipulation without jq
        echo "{\"$version\": {\"path\": \"$file_path\", \"date\": \"$(date -Iseconds)\"}}" > "$VERSIONS_FILE"
    fi
    
    rm -f "$temp_file"
    success "Added version $version to tracking"
}

# Get current active version
get_current_version() {
    if [[ -L "$CURSOR_DIR/current" ]]; then
        readlink "$CURSOR_DIR/current"
    else
        echo ""
    fi
}

# Set active version
set_active_version() {
    local version="$1"
    local version_info
    
    if command -v jq >/dev/null 2>&1; then
        version_info=$(jq -r ".$version.path" "$VERSIONS_FILE" 2>/dev/null)
    else
        # Simple extraction without jq
        version_info=$(grep -A1 "\"$version\"" "$VERSIONS_FILE" | grep "path" | cut -d'"' -f4 2>/dev/null)
    fi
    
    if [[ -z "$version_info" || ! -f "$version_info" ]]; then
        error "Version $version not found or file missing"
        return 1
    fi
    
    ln -sf "$version_info" "$CURSOR_DIR/current"
    success "Set active version to $version"
}

# Interactive version selection
select_version() {
    log "Available versions:"
    
    if command -v jq >/dev/null 2>&1; then
        local versions
        versions=$(jq -r 'keys[]' "$VERSIONS_FILE" 2>/dev/null)
        
        if [[ -z "$versions" ]]; then
            error "No versions available. Run 'download' first."
            return 1
        fi
        
        local current_version
        current_version=$(get_current_version)
        
        echo "Available versions:"
        local i=1
        while IFS= read -r version; do
            local marker=""
            if [[ "$version" == "$current_version" ]]; then
                marker=" (current)"
            fi
            echo "$i) $version$marker"
            i=$((i+1))
        done <<< "$versions"
        
        echo "0) Download latest"
        echo "q) Quit"
        
        read -r -p "Select version (0-$((i-1)) or q): " choice
        
        case $choice in
            0)
                download_latest
                ;;
            q|Q)
                return 1
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le $((i-1)) ]]; then
                    local selected_version
                    selected_version=$(echo "$versions" | sed -n "${choice}p")
                    set_active_version "$selected_version"
                else
                    error "Invalid selection"
                    return 1
                fi
                ;;
        esac
    else
        warn "jq not available. Please install jq for interactive selection."
        list_versions
    fi
}

# Download latest version
download_latest() {
    local latest_version
    latest_version=$(get_latest_version 2>/dev/null)
    
    if [[ -z "$latest_version" ]]; then
        error "Failed to get latest version"
        return 1
    fi
    
    local target_file="$CURSOR_DIR/Cursor-$latest_version-x86_64.AppImage"
    
    if [[ -f "$target_file" ]]; then
        warn "Version $latest_version already exists"
        read -r -p "Overwrite? (y/N): " overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            return 0
        fi
    fi
    
    if download_cursor "$latest_version" "$target_file"; then
        add_version "$latest_version" "$target_file"
        set_active_version "$latest_version"
        success "Downloaded and set active version to $latest_version"
    fi
}

# Get current AppImage path
get_current_appimage() {
    local current_link="$CURSOR_DIR/current"
    
    if [[ -L "$current_link" ]]; then
        local target
        target=$(readlink "$current_link")
        if [[ -f "$target" ]]; then
            echo "$target"
            return 0
        fi
    fi
    
    # Fallback to Downloads directory
    local downloads_file
    downloads_file=$(find "$DOWNLOADS_DIR" -name "Cursor*.AppImage" -type f 2>/dev/null | head -1)
    
    if [[ -n "$downloads_file" ]]; then
        echo "$downloads_file"
        return 0
    fi
    
    return 1
}

# Show status
show_status() {
    log "Cursor AppImage Manager Status"
    echo "================================"
    
    local current_appimage
    current_appimage=$(get_current_appimage)
    
    if [[ -n "$current_appimage" ]]; then
        success "Current AppImage: $current_appimage"
        ls -la "$current_appimage"
    else
        error "No AppImage found"
    fi
    
    echo ""
    echo "Versions directory: $CURSOR_DIR"
    echo "Downloads directory: $DOWNLOADS_DIR"
    
    if [[ -f "$VERSIONS_FILE" ]]; then
        echo ""
        echo "Tracked versions:"
        list_versions
    fi
}

# Clean up old versions
cleanup_old_versions() {
    log "Cleaning up old versions..."
    
    if [[ ! -f "$VERSIONS_FILE" ]]; then
        warn "No versions file found"
        return 0
    fi
    
    # Keep last 5 versions
    
    if command -v jq >/dev/null 2>&1; then
        local old_versions
        old_versions=$(jq -r 'to_entries | sort_by(.value.date) | reverse | .[5:] | .[].key' "$VERSIONS_FILE" 2>/dev/null)
        
        while IFS= read -r version; do
            if [[ -n "$version" ]]; then
                local file_path
                file_path=$(jq -r ".$version.path" "$VERSIONS_FILE")
                if [[ -f "$file_path" ]]; then
                    rm -f "$file_path"
                    warn "Removed old version: $version"
                fi
            fi
        done <<< "$old_versions"
    else
        warn "jq not available. Manual cleanup required."
    fi
}

# Show help
show_help() {
    echo "Cursor AppImage Manager"
    echo "======================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  download     Download latest version"
    echo "  list         List available versions"
    echo "  select       Interactive version selection"
    echo "  current      Show current version"
    echo "  status       Show detailed status"
    echo "  cleanup      Remove old versions (keep last 5)"
    echo "  help         Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 download"
    echo "  $0 select"
    echo "  $0 status"
}

# Main function
main() {
    local command="${1:-help}"
    
    init_directories
    
    case $command in
        download)
            download_latest
            ;;
        list)
            list_versions
            ;;
        select)
            select_version
            ;;
        current)
            local current
            current=$(get_current_appimage)
            if [[ -n "$current" ]]; then
                echo "$current"
            else
                error "No current AppImage found"
                exit 1
            fi
            ;;
        status)
            show_status
            ;;
        cleanup)
            cleanup_old_versions
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 