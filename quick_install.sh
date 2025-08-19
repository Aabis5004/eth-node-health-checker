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

print_step() {
    echo -e "\n${BLUE}[STEP]${NC} $1"
}

# Check requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    if command -v python3 &> /dev/null; then
        print_status "✅ Python 3 found"
    else
        print_error "❌ Python 3 required. Install with:"
        print_error "  Ubuntu/Debian: sudo apt install python3 python3-pip"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    print_step "Installing dependencies..."
    pip3 install --user requests colorama tabulate 2>/dev/null || {
        print_error "Failed to install dependencies"
        exit 1
    }
    print_status "✅ Dependencies installed"
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
    
    # Get the GitHub raw URL (replace YOUR-USERNAME with actual username)
    GITHUB_USER=$(echo "$0" | grep -o 'github.com/[^/]*' | cut -d'/' -f2 || echo "YOUR-USERNAME")
    SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/eth-node-health-checker/main/eth_health_check.py"
    
    # Try to download from GitHub first
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/eth_health_check.py" 2>/dev/null || create_embedded_script
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/eth_health_check.py" 2>/dev/null || create_embedded_script
    else
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

try:
    from colorama import init, Fore, Style
    init()
    HAS_COLOR = True
except ImportError:
    HAS_COLOR = False

class NodeHealthChecker:
    def __init__(self, timeout=15):
        self.timeout = timeout
        
    def colored_print(self, message, color="white"):
        if not HAS_COLOR:
            print(message)
            return
        colors = {"red": Fore.RED, "green": Fore.GREEN, "yellow": Fore.YELLOW, "blue": Fore.BLUE, "white": Fore.WHITE}
        print(f"{colors.get(color, Fore.WHITE)}{message}{Style.RESET_ALL}")
    
    def log_result(self, message, status="info"):
        timestamp = datetime.now().strftime("%H:%M:%S")
        icons = {"success": "✅", "error": "❌", "warning": "⚠️", "info": "ℹ️"}
        colors = {"success": "green", "error": "red", "warning": "yellow", "info": "blue"}
        icon = icons.get(status, "•")
        color = colors.get(status, "white")
        self.colored_print(f"[{timestamp}] {icon} {message}", color)
    
    def test_connection(self, host, port):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.timeout)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except:
            return False
    
    def check_beacon_node(self, url):
        self.colored_print("\n📋 BEACON CHAIN NODE", "yellow")
        self.colored_print("-" * 20, "yellow")
        
        try:
            if "://" in url:
                host = url.split("://")[1].split(":")[0]
                port = int(url.split(":")[-1].split("/")[0])
            else:
                host, port = url.split(":") if ":" in url else (url, 5052)
                port = int(port)
        except:
            self.log_result(f"Invalid URL format: {url}", "error")
            return False
        
        if not self.test_connection(host, port):
            self.log_result(f"Cannot connect to {host}:{port}", "error")
            return False
        
        self.log_result(f"Port {port} is open on {host}", "success")
        
        try:
            response = requests.get(f"{url}/eth/v1/node/health", timeout=self.timeout)
            if response.status_code == 200:
                self.log_result("Beacon node is healthy", "success")
                return True
            else:
                self.log_result(f"Beacon node health check failed", "error")
                return False
        except Exception as e:
            self.log_result(f"Beacon node error: {str(e)}", "error")
            return False
    
    def check_sepolia_rpc(self, url):
        self.colored_print("\n📋 SEPOLIA RPC NODE", "yellow")
        self.colored_print("-" * 18, "yellow")
        
        try:
            if "://" in url:
                host = url.split("://")[1].split(":")[0]
                port = int(url.split(":")[-1].split("/")[0])
            else:
                host, port = url.split(":") if ":" in url else (url, 8545)
                port = int(port)
        except:
            self.log_result(f"Invalid URL format: {url}", "error")
            return False
        
        if not self.test_connection(host, port):
            self.log_result(f"Cannot connect to {host}:{port}", "error")
            return False
        
        self.log_result(f"Port {port} is open on {host}", "success")
        
        try:
            payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
            response = requests.post(url, json=payload, timeout=self.timeout)
            if response.status_code == 200:
                chain_id = int(response.json().get("result", "0x0"), 16)
                if chain_id == 11155111:
                    self.log_result("Confirmed Sepolia testnet", "success")
                    return True
                else:
                    self.log_result(f"Unexpected chain ID: {chain_id}", "warning")
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
    checker.colored_print("🚀 ETHEREUM NODE HEALTH CHECKER", "blue")
    checker.colored_print("="*50, "blue")
    
    beacon_ok = checker.check_beacon_node(args.beacon)
    sepolia_ok = checker.check_sepolia_rpc(args.sepolia)
    
    checker.colored_print("\n📊 SUMMARY", "blue")
    checker.colored_print("-" * 10, "blue")
    
    if beacon_ok and sepolia_ok:
        checker.colored_print("🎉 All systems healthy!", "green")
        sys.exit(0)
    else:
        checker.colored_print("⚠️ Issues detected", "yellow")
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

# Main installation
main() {
    check_requirements
    install_dependencies
    create_install_dir
    download_script
    create_wrapper
    
    print_step "Installation Complete! 🎉"
    echo ""
    print_status "🎯 QUICK START:"
    echo "1. Restart your terminal (or run: source ~/.bashrc)"
    echo "2. Run: check-nodes"
    echo "3. For remote nodes: check-nodes --beacon http://IP:5052 --sepolia http://IP:8545"
    echo ""
    print_status "📁 Installed to: $INSTALL_DIR"
    echo ""
    print_status "🚀 Ready to monitor your Ethereum nodes!"
}

main "$@"
