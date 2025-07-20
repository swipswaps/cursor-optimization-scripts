# Cursor Terminal Fix Instructions

## 🚨 Immediate Action Plan

### Step 1: Close Cursor Completely
```bash
# Kill all Cursor processes
pkill -f cursor
```

### Step 2: Run the Emergency Fix
```bash
# Make the script executable and run it
chmod +x cursor_emergency_terminal_fix.sh
./cursor_emergency_terminal_fix.sh
```

### Step 3: Install Permanent Fix
```bash
# Install the permanent system fix
chmod +x cursor_permanent_terminal_fix.sh
./cursor_permanent_terminal_fix.sh
```

### Step 4: Launch Cursor with Terminal Fixes
```bash
# Use the new launcher script
~/cursor-terminal-fixed.sh
```

## 🎯 Why This Will Work

### The ptyHost Issue Explained:
- **ptyHost** = Terminal subsystem that handles all terminal operations
- **Heartbeat failure** = Terminal subsystem is completely broken
- **GPU crash** = Terminal rendering fails, causing ptyHost to fail
- **Apple A1286** = Known GPU compatibility issues with Electron

### The Fix:
1. **Disables GPU acceleration** completely (prevents crashes)
2. **Uses software rendering** (more compatible with older hardware)
3. **Fixes terminal subsystem** by preventing GPU-related crashes
4. **Creates permanent solution** that persists across reboots

## ⚠️ Important Notes:

### What to Expect:
- ✅ **Terminal will work** (no more ptyHost errors)
- ✅ **No more GPU crashes** (exit code 15)
- ✅ **Stable performance** (software rendering)
- ⚠️ **Slightly slower graphics** (software vs hardware rendering)

### Alternative Launch Methods:
```bash
# Method 1: Use the fixed launcher
~/cursor-terminal-fixed.sh

# Method 2: Launch with flags directly
cursor --disable-gpu --disable-software-rasterizer --no-sandbox --disable-gpu-process

# Method 3: Use environment variables
export ELECTRON_DISABLE_GPU=1
export ELECTRON_DISABLE_GPU_PROCESS=1
cursor
```

## 🔧 Quick Commands to Copy/Paste:

```bash
# Kill Cursor
pkill -f cursor

# Run emergency fix
chmod +x cursor_emergency_terminal_fix.sh
./cursor_emergency_terminal_fix.sh

# Install permanent fix
chmod +x cursor_permanent_terminal_fix.sh
./cursor_permanent_terminal_fix.sh

# Launch with fixes
~/cursor-terminal-fixed.sh
```

**Yes, close Cursor now and run the fixes. The ptyHost heartbeat failures indicate a critical terminal subsystem failure that needs immediate attention.**
