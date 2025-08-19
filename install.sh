#!/bin/bash

# Ethereum Node Health Checker - Easy Install Script
# One-click installer for Ethereum node health monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_NAME="eth-health-checker"
INSTALL_DIR="$HOME/.eth-health-checker"
VERSION="1.0.0"

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        🚀 ETHEREUM NODE HEALTH CHECKER INSTALLER 🚀          ║
║                                                              ║
║   Professional monitoring for your Ethereum infrastructure  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
}

# Check requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        print_status "✅ Python 3 found (version $PYTHON_VERSION)"
    else
        print_error "❌ Python 3 required. Install with:"
        print_error "  Ubuntu/Debian: sudo apt install python3 python3-pip"
        print_error "  CentOS/RHEL: sudo yum install python3 python3-pip"
        exit 1
    fi
}

# Install dependencies with multiple fallback methods
install_dependencies() {
    print_step "Installing dependencies..."
    
    # Method 1: Try pip3 with --user
    if pip3 install --user requests colorama tabulate &>/dev/null; then
        print_status "✅ Dependencies installed via pip3"
        return 0
    fi
    
    # Method 2: Try with --break-system-packages (for newer Python versions)
    print_warning "Trying alternative installation method..."
    if pip3 install --user --break-system-packages requests colorama tabulate &>/dev/null; then
        print_status "✅ Dependencies installed (with --break-system-packages)"
        return 0
    fi
    
    # Method 3: Try system package manager
    print_warning "Trying system package manager..."
    if command -v apt &>/dev/null; then
        if sudo apt update &>/dev/null && sudo apt install -y python3-requests python3-colorama &>/dev/null; then
            print_status "✅ Dependencies installed via apt"
            return 0
        fi
    elif command -v yum &>/dev/null; then
        if sudo yum install -y python3-requests &>/dev/null; then
            print_status "✅ Dependencies installed via yum"
            return 0
        fi
    fi
    
    # Method 4: Continue without optional dependencies
    print_warning "⚠️ Could not install colorama/tabulate (optional dependencies)"
    print_warning "⚠️ Health checker will work but without colors/tables"
    print_status "✅ Continuing installation..."
    return 0
}

# Create installation directory
create_install_dir() {
    print_step "Setting up installation..."
    rm -rf "$INSTALL_DIR" 2>/dev/null || true
    mkdir -p "$INSTALL_DIR"
    print_status "✅ Installation directory ready"
}

# Download main script from GitHub
download_script() {
    print_step "Downloading health checker..."
    
    # Try to detect GitHub username from the download URL
    SCRIPT_URL=""
    if [ -n "$BASH_SOURCE" ]; then
        # Try to extract from how this script was called
        GITHUB_USER=$(echo "$0" | grep -o 'github.com/[^/]*' | cut -d'/' -f2 2>/dev/null || echo "")
    fi
    
    # Fallback to hardcoded URL (update this with your username)
    if [ -z "$GITHUB_USER" ]; then
        GITHUB_USER="Aabis5004"  # Your GitHub username
    fi
    
    SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/eth-node-health-checker/main/eth_health_check.py"
    
    # Try to download from GitHub
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/eth_health_check.py" 2>/dev/null; then
            print_status "✅ Downloaded from GitHub"
        else
            print_warning "GitHub download failed, using embedded script"
            create_embedded_script
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/eth_health_check.py" 2>/dev/null; then
            print_status "✅ Downloaded from GitHub"
        else
            print_warning "GitHub download failed, using embedded script"
            create_embedded_script
        fi
    else
        print_warning "curl/wget not found, using embedded script"
        create_embedded_script
    fi
    
    chmod +x "$INSTALL_DIR/eth_health_check.py"
    print_status "✅ Health checker ready"
}

# Embedded script as fallback
create_embedded_script() {
    cat > "$INSTALL_DIR/eth_health_check.py" << 'SCRIPT_EOF'
#!/usr/bin/env python3
"""Ethereum Node Health Checker - Professional monitoring tool"""

import requests
import json
import socket
import sys
import argparse
from datetime import datetime

# Check for optional dependencies
try:
    from colorama import init, Fore, Style
    init()
    HAS_COLOR = True
except ImportError:
    HAS_COLOR = False

try:
    from tabulate import tabulate
    HAS_TABULATE = True
except ImportError:
    HAS_TABULATE = False

class NodeHealthChecker:
    def __init__(self, timeout=15):
        self.timeout = timeout
        
    def colored_print(self, message, color="white"):
        """Print colored text if available, otherwise plain text"""
        if not HAS_COLOR:
            print(message)
            return
        colors = {
            "red": Fore.RED, 
            "green": Fore.GREEN, 
            "yellow": Fore.YELLOW, 
            "blue": Fore.BLUE, 
            "cyan": Fore.CYAN,
            "white": Fore.WHITE
        }
        print(f"{colors.get(color, Fore.WHITE)}{message}{Style.RESET_ALL}")
    
    def log_result(self, message, status="info"):
        """Log a result with timestamp and status"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        icons = {"success": "✅", "error": "❌", "warning": "⚠️", "info": "ℹ️"}
        colors = {"success": "green", "error": "red", "warning": "yellow", "info": "blue"}
        
        icon = icons.get(status, "•") if HAS_COLOR else {"success": "[OK]", "error": "[ERR]", "warning": "[WARN]", "info": "[INFO]"}.get(status, "")
        color = colors.get(status, "white")
        
        self.colored_print(f"[{timestamp}] {icon} {message}", color)
    
    def test_connection(self, host, port):
        """Test TCP connection to host:port"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.timeout)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except Exception:
            return False
    
    def parse_url(self, url, default_port):
        """Parse URL to extract host and port"""
        try:
            if "://" in url:
                protocol, rest = url.split("://", 1)
                if ":" in rest:
                    host, port_part = rest.split(":", 1)
                    port = int(port_part.split("/")[0])
                else:
                    host = rest.split("/")[0]
                    port = 443 if protocol == "https" else default_port
            else:
                if ":" in url:
                    host, port = url.split(":")
                    port = int(port)
                else:
                    host = url
                    port = default_port
            return host, port
        except Exception:
            return None, None
    
    def check_beacon_node(self, url):
        """Check Beacon node health"""
        self.colored_print("\n📋 BEACON CHAIN NODE", "yellow")
        self.colored_print("-" * 20, "yellow")
        
        host, port = self.parse_url(url, 5052)
        if not host:
            self.log_result(f"Invalid Beacon URL: {url}", "error")
            return False
        
        # Test port
        if not self.test_connection(host, port):
            self.log_result(f"Cannot connect to {host}:{port}", "error")
            self.log_result("Check: Is beacon node running? Firewall open?", "warning")
            return False
        
        self.log_result(f"Port {port} is open on {host}", "success")
        
        # Test health endpoint
        try:
            response = requests.get(f"{url}/eth/v1/node/health", timeout=self.timeout)
            if response.status_code == 200:
                self.log_result("Beacon node is healthy", "success")
                
                # Check sync status
                try:
                    sync_response = requests.get(f"{url}/eth/v1/node/syncing", timeout=self.timeout)
                    if sync_response.status_code == 200:
                        sync_data = sync_response.json()
                        is_syncing = sync_data.get("data", {}).get("is_syncing", True)
                        if not is_syncing:
                            self.log_result("Beacon node is synced", "success")
                        else:
                            self.log_result("Beacon node is syncing", "warning")
                except:
                    pass
                
                # Check peers
                try:
                    peers_response = requests.get(f"{url}/eth/v1/node/peers", timeout=self.timeout)
                    if peers_response.status_code == 200:
                        peers_data = peers_response.json()
                        peer_count = len(peers_data.get("data", []))
                        self.log_result(f"Connected to {peer_count} peers", "success" if peer_count > 0 else "warning")
                except:
                    pass
                    
                return True
            else:
                self.log_result(f"Beacon health check failed (HTTP {response.status_code})", "error")
                return False
        except Exception as e:
            self.log_result(f"Beacon node error: {str(e)}", "error")
            return False
    
    def check_sepolia_rpc(self, url):
        """Check Sepolia RPC health"""
        self.colored_print("\n📋 SEPOLIA RPC NODE", "yellow")
        self.colored_print("-" * 18, "yellow")
        
        host, port = self.parse_url(url, 8545)
        if not host:
            self.log_result(f"Invalid Sepolia URL: {url}", "error")
            return False
        
        # Test port
        if not self.test_connection(host, port):
            self.log_result(f"Cannot connect to {host}:{port}", "error")
            self.log_result("Check: Is Sepolia node running? Firewall open?", "warning")
            return False
        
        self.log_result(f"Port {port} is open on {host}", "success")
        
        # Test RPC
        try:
            # Check chain ID
            payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
            response = requests.post(url, json=payload, timeout=self.timeout)
            if response.status_code == 200:
                chain_id = int(response.json().get("result", "0x0"), 16)
                if chain_id == 11155111:
                    self.log_result("Confirmed Sepolia testnet", "success")
                else:
                    self.log_result(f"Chain ID: {chain_id}", "info")
                
                # Check latest block
                payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
                block_response = requests.post(url, json=payload, timeout=self.timeout)
                if block_response.status_code == 200:
                    block_hex = block_response.json().get("result", "0x0")
                    latest_block = int(block_hex, 16)
                    self.log_result(f"Latest block: {latest_block:,}", "success")
                
                return True
            else:
                self.log_result("Sepolia RPC check failed", "error")
                return False
        except Exception as e:
            self.log_result(f"Sepolia RPC error: {str(e)}", "error")
            return False

def main():
    parser = argparse.ArgumentParser(description="Ethereum Node Health Checker")
    parser.add_argument("--beacon", default="http://localhost:5052", help="Beacon node URL")
    parser.add_argument("--sepolia", default="http://localhost:8545", help="Sepolia RPC URL")
    parser.add_argument("--timeout", type=int, default=15, help="Timeout in seconds")
    args = parser.parse_args()
    
    checker = NodeHealthChecker(timeout=args.timeout)
    
    checker.colored_print("\n" + "="*50, "blue")
    checker.colored_print("🚀 ETHEREUM NODE HEALTH CHECKER", "cyan")
    checker.colored_print("="*50, "blue")
    
    beacon_ok = False
    sepolia_ok = False
    
    if args.beacon:
        beacon_ok = checker.check_beacon_node(args.beacon)
    
    if args.sepolia:
        sepolia_ok = checker.check_sepolia_rpc(args.sepolia)
    
    checker.colored_print("\n📊 SUMMARY", "blue")
    checker.colored_print("-" * 10, "blue")
    
    if beacon_ok and sepolia_ok:
        checker.colored_print("🎉 All systems healthy!", "green")
        sys.exit(0)
    elif beacon_ok or sepolia_ok:
        checker.colored_print("⚠️ Partial success - some issues detected", "yellow")
        sys.exit(1)
    else:
        checker.colored_print("❌ Issues detected", "red")
        sys.exit(1)

if __name__ == "__main__":
    main()
SCRIPT_EOF
}

# Create wrapper command
create_wrapper() {
    print_step "Creating easy command..."
    
    cat > "$INSTALL_DIR/check-nodes" << 'WRAPPER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/eth_health_check.py" "$@"
WRAPPER_EOF
    
    chmod +x "$INSTALL_DIR/check-nodes"
    
    # Add to PATH
    if [[ ":$PATH:" != *":$HOME/.eth-health-checker:"* ]]; then
        echo 'export PATH="$HOME/.eth-health-checker:$PATH"' >> "$HOME/.bashrc"
        print_status "✅ Added to PATH"
    fi
}

# Create uninstaller
create_uninstaller() {
    cat > "$INSTALL_DIR/uninstall" << 'UNINSTALL_EOF'
#!/bin/bash
echo "🗑️ Uninstalling Ethereum Node Health Checker..."
sed -i '/eth-health-checker/d' "$HOME/.bashrc" 2>/dev/null || true
rm -rf "$HOME/.eth-health-checker"
echo "✅ Uninstalled successfully!"
echo "Please restart your terminal or run: source ~/.bashrc"
UNINSTALL_EOF
    
    chmod +x "$INSTALL_DIR/uninstall"
}

# Main installation
main() {
    check_requirements
    install_dependencies
    create_install_dir
    download_script
    create_wrapper
    create_uninstaller
    
    print_step "Installation Complete! 🎉"
    echo ""
    print_status "🎯 QUICK START:"
    echo "1. Restart your terminal (or run: source ~/.bashrc)"
    echo "2. Test local nodes: check-nodes"
    echo "3. Test remote nodes: check-nodes --beacon http://IP:5052 --sepolia http://IP:8545"
    echo "4. Get help: check-nodes --help"
    echo ""
    print_status "📁 Installed to: $INSTALL_DIR"
    print_status "🗑️ To uninstall: $INSTALL_DIR/uninstall"
    echo ""
    print_status "🚀 Ready to monitor your Ethereum nodes!"
}

main "$@"
