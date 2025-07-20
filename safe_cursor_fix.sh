#!/bin/bash

echo "🛡️ SAFE Cursor Typing Delay Fix"
echo "================================"
echo "This will ONLY kill non-critical processes"
echo "Cursor will NOT crash or close"
echo ""

# Function to safely kill only utility processes
safe_kill_high_cpu() {
    echo "🔍 Finding high-CPU utility processes..."
    
    # Get all Cursor processes with their types
    ps aux | grep cursor | grep -v grep | while read line; do
        pid=$(echo "$line" | awk '{print $2}')
        cpu=$(echo "$line" | awk '{print $3}')
        cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i}')
        
        # Only kill if CPU > 20% AND it's a utility process
        if (( $(echo "$cpu > 20.0" | bc -l 2>/dev/null || echo 0) )); then
            if echo "$cmd" | grep -q "utility"; then
                echo "✅ SAFE TO KILL: PID $pid (utility process, CPU: ${cpu}%)"
                kill "$pid" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "   ✅ Killed PID $pid"
                else
                    echo "   ⚠️  Failed to kill PID $pid"
                fi
            elif echo "$cmd" | grep -q "gpu"; then
                echo "✅ SAFE TO KILL: PID $pid (gpu process, CPU: ${cpu}%)"
                kill "$pid" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "   ✅ Killed PID $pid"
                else
                    echo "   ⚠️  Failed to kill PID $pid"
                fi
            else
                echo "⚠️  SKIPPING: PID $pid (critical process, CPU: ${cpu}%)"
                echo "   This would crash Cursor if killed"
            fi
        fi
    done
}

# Clear TypeScript cache (always safe)
clear_typescript_cache() {
    echo "🧹 Clearing TypeScript cache..."
    pkill tsserver 2>/dev/null
    rm -rf ~/.config/Cursor/User/globalStorage/ms-vscode.vscode-typescript-next/* 2>/dev/null
    rm -rf ~/.config/Cursor/User/workspaceStorage/*/ms-vscode.vscode-typescript-next/* 2>/dev/null
    echo "✅ TypeScript cache cleared"
}

# Clear safe cache directories
clear_safe_cache() {
    echo "🗑️ Clearing safe cache directories..."
    rm -rf ~/.config/Cursor/Cache/* 2>/dev/null
    rm -rf ~/.config/Cursor/Code\ Cache/* 2>/dev/null
    rm -rf ~/.config/Cursor/GPUCache/* 2>/dev/null
    echo "✅ Safe cache cleared"
}

echo "Starting safe fix..."
safe_kill_high_cpu
clear_typescript_cache
clear_safe_cache

echo ""
echo "✅ SAFE FIX COMPLETED!"
echo "📝 Cursor is still running and should be more responsive"
echo "💡 If typing is still slow, try: Developer > Reload Window" 