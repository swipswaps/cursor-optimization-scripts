# Cursor Performance Optimization Scripts

Optimized scripts for Cursor IDE performance on Apple A1286 (Ivy Bridge) systems running Fedora 42.

## 🚀 Quick Start

### For Normal Use
```bash
./cursor-safe-launcher.sh
```

### For Crashes ("Render frame was disposed")
```bash
./cursor-crash-fix.sh
```

### For System Optimization
```bash
./resource_contention_fix.sh
```

### For Network Issues
```bash
./network_filter_fix.sh
```

## 📁 Scripts Overview

### Core Cursor Scripts
- **`cursor-safe-launcher.sh`** - Proven working launcher (no process killing)
- **`cursor-crash-fix.sh`** - Addresses "Render frame was disposed" errors
- **`safe_cursor_fix.sh`** - Alternative safe fix approach

### System Optimization
- **`resource_contention_fix.sh`** - Optimizes CPU, GPU, memory, and I/O
- **`network_filter_fix.sh`** - Reduces network filter overhead
- **`restrictive_firewall.sh`** - Blocks all but trusted IPs
- **`internet_test.sh`** - Tests connectivity after firewall changes

### n8n Integration
- **`start-n8n.sh`** - Launches n8n with optimizations
- **`start-n8n-mcp.sh`** - Launches n8n with MCP integration
- **`view-logs.sh`** - View n8n logs
- **`verify_docker_images.sh`** - Verify Docker images

## 🛠️ System Requirements

- **Hardware:** Apple A1286 (Ivy Bridge CPU)
- **OS:** Fedora 42
- **Cursor:** AppImage in ~/Downloads/
- **Dependencies:** Docker, Node.js

## 🔧 Installation

1. Clone this repository
2. Make scripts executable: `chmod +x *.sh`
3. Run system optimization: `./resource_contention_fix.sh`
4. Launch Cursor: `./cursor-safe-launcher.sh`

## 📊 Performance Features

- **GPU Optimization:** Disables problematic GPU features
- **Memory Management:** Reduces memory pressure and swapping
- **Network Filtering:** Reduces multicast spam and resource contention
- **Cache Management:** Clears safe caches without process interference
- **Terminal Stability:** Prevents ptyHost heartbeat failures

## 🚨 Troubleshooting

### Cursor Crashes
- Use `./cursor-crash-fix.sh` for "Render frame was disposed" errors
- Clear caches: `rm -rf ~/.config/Cursor/Cache`

### Typing Delays
- Run system optimization: `./resource_contention_fix.sh`
- Check network filters: `./network_filter_fix.sh`

### Terminal Issues
- Restore terminal: `./cursor-safe-launcher.sh`
- Check ptyHost processes: `ps aux | grep ptyHost`

## 📝 Notes

- All scripts are tested on Apple A1286 with Fedora 42
- Scripts avoid killing terminal processes
- Focus on safe cache clearing and system optimization
- Backup scripts available in `~/Documents/n8n-mcp-docker-deployment-cursor/old-cursor-scripts/`

## 🔒 Security

- Scripts use minimal sudo privileges
- No external dependencies or network calls
- All scripts are shellcheck compliant
- No sensitive data collection

## 📄 License

MIT License - see LICENSE file for details.
