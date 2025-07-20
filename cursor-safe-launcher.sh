#!/bin/bash
# Safe Cursor launcher - based on working minimal script
# NO process killing, NO terminal interference

echo "🚀 Starting Cursor safely (no process killing)..."

# Clear only safe caches (no process interference)
rm -rf ~/.cache/fontconfig 2>/dev/null
rm -rf ~/.config/Cursor/Cache 2>/dev/null
rm -rf ~/.config/Cursor/CachedData 2>/dev/null
rm -rf ~/.config/Cursor/Code\ Cache 2>/dev/null

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

# Launch with safe flags (NO process killing, NO backgrounding)
"$CURSOR_APP" \
  --disable-gpu \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-features=VizDisplayCompositor \
  --js-flags="--max-old-space-size=1024" \
  "$@"

echo "✅ Cursor launched safely!" 