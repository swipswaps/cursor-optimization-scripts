#!/bin/bash
# Setup Cursor AppImage Manager with existing AppImage

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
readonly CURSOR_DIR="$HOME/.local/share/cursor-appimages"
readonly VERSIONS_FILE="$CURSOR_DIR/versions.json"

# Find existing Cursor AppImage
find_existing_appimage() {
    local possible_paths=(
        "$HOME/Downloads/Cursor-1.2.2-x86_64.AppImage"
        "$HOME/Downloads/Cursor*.AppImage"
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    # Try to find any Cursor AppImage
    local found
    found=$(find "$HOME/Downloads" -name "Cursor*.AppImage" -type f 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        echo "$found"
        return 0
    fi
    
    return 1
}

# Setup AppImage manager
setup_appimage_manager() {
    log "Setting up Cursor AppImage Manager..."
    
    # Create directories
    mkdir -p "$CURSOR_DIR"
    
    # Find existing AppImage
    local existing_appimage
    existing_appimage=$(find_existing_appimage)
    
    if [[ -z "$existing_appimage" ]]; then
        error "No Cursor AppImage found in Downloads"
        error "Please download Cursor AppImage to ~/Downloads/ first"
        return 1
    fi
    
    log "Found existing AppImage: $existing_appimage"
    
    # Get file info
    local file_size
    local file_date
    file_size=$(stat -c%s "$existing_appimage" 2>/dev/null || echo "0")
    file_date=$(stat -c%y "$existing_appimage" 2>/dev/null || date -Iseconds)
    
    # Determine version from filename or use default
    local version
    if [[ "$existing_appimage" =~ Cursor-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        version="${BASH_REMATCH[1]}"
    else
        version="1.2.2"
    fi
    
    log "Detected version: $version"
    
    # Copy to managed location
    local target_file="$CURSOR_DIR/Cursor-$version-x86_64.AppImage"
    if [[ "$existing_appimage" != "$target_file" ]]; then
        log "Copying AppImage to managed location..."
        cp "$existing_appimage" "$target_file"
        chmod +x "$target_file"
    fi
    
    # Create versions.json
    log "Creating versions tracking..."
    cat > "$VERSIONS_FILE" << EOF
{
  "$version": {
    "path": "$target_file",
    "date": "$file_date",
    "size": "$file_size"
  }
}
EOF
    
    # Set as current version
    log "Setting as current version..."
    ln -sf "$target_file" "$CURSOR_DIR/current"
    
    success "Setup complete!"
    success "Current AppImage: $target_file"
    success "Version: $version"
    
    # Show status
    echo ""
    log "AppImage Manager Status:"
    echo "======================="
    echo "Versions directory: $CURSOR_DIR"
    echo "Current version: $version"
    echo "File size: $((file_size / 1024 / 1024))MB"
    echo ""
    echo "You can now use:"
    echo "  ./cursor-appimage-manager.sh status"
    echo "  ./cursor-appimage-manager.sh select"
    echo "  ./cursor-universal-launcher.sh"
    echo "  ./cursor-amd-ryzen-launcher.sh"
}

# Main function
main() {
    if [[ $# -eq 0 ]]; then
        setup_appimage_manager
    else
        case $1 in
            help|--help|-h)
                echo "Setup Cursor AppImage Manager"
                echo "============================"
                echo ""
                echo "Usage: $0 [COMMAND]"
                echo ""
                echo "Commands:"
                echo "  setup    Setup AppImage manager with existing AppImage"
                echo "  help     Show this help"
                echo ""
                echo "This script will:"
                echo "  1. Find existing Cursor AppImage in Downloads"
                echo "  2. Copy it to managed location"
                echo "  3. Set up version tracking"
                echo "  4. Set as current version"
                ;;
            setup)
                setup_appimage_manager
                ;;
            *)
                error "Unknown command: $1"
                echo "Use '$0 help' for usage information"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@" 