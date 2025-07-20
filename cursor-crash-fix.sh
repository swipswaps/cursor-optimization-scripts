#!/bin/bash
# Cursor Crash Fix - Addresses "Render frame was disposed" errors
# Based on the working cursor-safe-launcher.sh

echo "🚨 Cursor Crash Fix - Addressing 'Render frame was disposed' errors"

# Kill any existing Cursor processes
echo "🔄 Stopping existing Cursor processes..."
pkill -f "Cursor" 2>/dev/null
sleep 2

# Clear ALL Cursor caches (more aggressive than safe launcher)
echo "🧹 Clearing Cursor caches..."
rm -rf ~/.cache/fontconfig 2>/dev/null
rm -rf ~/.config/Cursor/Cache 2>/dev/null
rm -rf ~/.config/Cursor/CachedData 2>/dev/null
rm -rf ~/.config/Cursor/Code\ Cache 2>/dev/null
rm -rf ~/.config/Cursor/GPUCache 2>/dev/null
rm -rf ~/.config/Cursor/Service\ Worker 2>/dev/null
rm -rf ~/.config/Cursor/User/workspaceStorage 2>/dev/null

# Clear Electron-specific caches
echo "🔧 Clearing Electron caches..."
rm -rf ~/.config/Cursor/logs 2>/dev/null
rm -rf ~/.config/Cursor/User/globalStorage 2>/dev/null

# Find Cursor AppImage
CURSOR_APP=""
if [ -f ~/Downloads/Cursor-1.2.2-x86_64.AppImage.zs-old ]; then
    CURSOR_APP=~/Downloads/Cursor-1.2.2-x86_64.AppImage.zs-old
elif [ -f ~/Downloads/Cursor-1.2.2-x86_64.AppImage ]; then
    CURSOR_APP=~/Downloads/Cursor-1.2.2-x86_64.AppImage
elif [ -f ~/Downloads/Cursor*.AppImage ]; then
    CURSOR_APP=$(ls ~/Downloads/Cursor*.AppImage | head -1)
else
    echo "❌ Cursor AppImage not found in Downloads"
    echo "Please download Cursor AppImage to ~/Downloads/"
    exit 1
fi

echo "📁 Using Cursor at: $CURSOR_APP"

# Launch with crash-prevention flags
echo "🚀 Launching Cursor with crash prevention..."
"$CURSOR_APP" \
  --disable-gpu \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-features=VizDisplayCompositor \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  --disable-backgrounding-occluded-windows \
  --disable-ipc-flooding-protection \
  --js-flags="--max-old-space-size=1024" \
  --memory-pressure-off \
  --disable-features=TranslateUI \
  --disable-features=BlinkGenPropertyTrees \
  "$@"

echo "✅ Cursor launched with crash prevention!" 