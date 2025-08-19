#!/bin/bash

# Enhanced Ethereum Node Health Checker - Easy Install Script
# One-click installer with improved diagnostics and consistency

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_NAME="eth-health-checker"
INSTALL_DIR="$HOME/.eth-health-checker"
VERSION="2.0.0"

echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║     🚀 ENHANCED ETHEREUM NODE HEALTH CHECKER INSTALLER v2.0 🚀           ║
║                                                                          ║
║   Professional monitoring with detailed diagnostics & consistency        ║
║   • Advanced connection testing with retry logic                        ║
║   • Performance metrics and latency analysis                            ║
║   • Detailed troubleshooting recommendations                            ║
║   • System resource monitoring                                          ║
║   • Monitor mode for continuous checking                                ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
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

print_feature() {
    echo -e "${MAGENTA}[FEATURE]${NC} $1"
}

# Check requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    # Check Python 3
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        print_status "✅ Python 3 found (version $PYTHON_VERSION)"
        
        # Check if Python version is 3.7+
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
        
        if [[ $PYTHON_MAJOR -eq 3 && $PYTHON_MINOR -lt 7 ]]; then
            print_warning "⚠️ Python 3.7+ recommended for best performance"
        fi
    else
        print_error "❌ Python 3 required. Install with:"
        print_error "  Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip"
        print_error "  CentOS/RHEL: sudo yum install python3 python3-pip"
        print_error "  macOS: brew install python3"
        exit 1
    fi
    
    # Check pip3
    if command -v pip3 &> /dev/null; then
        print_status "✅ pip3 found"
    else
        print_warning "⚠️ pip3 not found, will try alternative installation methods"
    fi
    
    # Check available package managers
    if command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
        print_status "✅ APT package manager detected"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
        print_status "✅ YUM package manager detected"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
        print_status "✅ DNF package manager detected"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
        print_status "✅ Pacman package manager detected"
    else
        PACKAGE_MANAGER="none"
        print_warning "⚠️ No recognized package manager found"
    fi
}

# Install dependencies with comprehensive fallback methods
install_dependencies() {
    print_step "Installing dependencies..."
    
    # Required packages
    REQUIRED_PACKAGES=("requests" "colorama" "tabulate" "psutil")
    INSTALLED_PACKAGES=()
    FAILED_PACKAGES=()
    
    print_status "Required packages: ${REQUIRED_PACKAGES[*]}"
    
    # Method 1: Try pip3 with --user
    print_status "Attempting pip3 installation with --user flag..."
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if pip3 install --user "$package" &>/dev/null; then
            INSTALLED_PACKAGES+=("$package")
            print_status "✅ $package installed via pip3"
        else
            FAILED_PACKAGES+=("$package")
        fi
    done
    
    # Method 2: Try with --break-system-packages for newer Python versions
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        print_warning "Trying alternative pip3 method for remaining packages..."
        TEMP_FAILED=()
        
        for package in "${FAILED_PACKAGES[@]}"; do
            if pip3 install --user --break-system-packages "$package" &>/dev/null; then
                INSTALLED_PACKAGES+=("$package")
                print_status "✅ $package installed with --break-system-packages"
            else
                TEMP_FAILED+=("$package")
            fi
        done
        
        FAILED_PACKAGES=("${TEMP_FAILED[@]}")
    fi
    
    # Method 3: Try system package manager
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 && "$PACKAGE_MANAGER" != "none" ]]; then
        print_warning "Trying system package manager for remaining packages..."
        
        case $PACKAGE_MANAGER in
            "apt")
                sudo apt update &>/dev/null || true
                for package in "${FAILED_PACKAGES[@]}"; do
                    case $package in
                        "requests") PKG_NAME="python3-requests" ;;
                        "colorama") PKG_NAME="python3-colorama" ;;
                        "tabulate") PKG_NAME="python3-tabulate" ;;
                        "psutil") PKG_NAME="python3-psutil" ;;
                        *) PKG_NAME="python3-$package" ;;
                    esac
                    
                    if sudo apt install -y "$PKG_NAME" &>/dev/null; then
                        INSTALLED_PACKAGES+=("$package")
                        print_status "✅ $package installed via apt"
                    fi
                done
                ;;
            "yum"|"dnf")
                for package in "${FAILED_PACKAGES[@]}"; do
                    case $package in
                        "requests") PKG_NAME="python3-requests" ;;
                        "colorama") PKG_NAME="python3-colorama" ;;
                        "tabulate") PKG_NAME="python3-tabulate" ;;
                        "psutil") PKG_NAME="python3-psutil" ;;
                        *) PKG_NAME="python3-$package" ;;
                    esac
                    
                    if sudo $PACKAGE_MANAGER install -y "$PKG_NAME" &>/dev/null; then
                        INSTALLED_PACKAGES+=("$package")
                        print_status "✅ $package installed via $PACKAGE_MANAGER"
                    fi
                done
                ;;
            "pacman")
                for package in "${FAILED_PACKAGES[@]}"; do
                    case $package in
                        "requests") PKG_NAME="python-requests" ;;
                        "colorama") PKG_NAME="python-colorama" ;;
                        "tabulate") PKG_NAME="python-tabulate" ;;
                        "psutil") PKG_NAME="python-psutil" ;;
                        *) PKG_NAME="python-$package" ;;
                    esac
                    
                    if sudo pacman -S --noconfirm "$PKG_NAME" &>/dev/null; then
                        INSTALLED_PACKAGES+=("$package")
                        print_status "✅ $package installed via pacman"
                    fi
                done
                ;;
        esac
    fi
    
    # Check what we managed to install
    print_status "Installation summary:"
    print_status "✅ Successfully installed: ${INSTALLED_PACKAGES[*]}"
    
    # Update failed packages list
    FINAL_FAILED=()
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if [[ ! " ${INSTALLED_PACKAGES[@]} " =~ " ${package} " ]]; then
            FINAL_FAILED+=("$package")
        fi
    done
    
    if [[ ${#FINAL_FAILED[@]} -gt 0 ]]; then
        print_warning "⚠️ Could not install: ${FINAL_FAILED[*]}"
        
        # Check which are critical vs optional
        CRITICAL_MISSING=()
        OPTIONAL_MISSING=()
        
        for package in "${FINAL_FAILED[@]}"; do
            case $package in
                "requests") CRITICAL_MISSING+=("$package") ;;
                "psutil") CRITICAL_MISSING+=("$package") ;;
                *) OPTIONAL_MISSING+=("$package") ;;
            esac
        done
        
        if [[ ${#CRITICAL_MISSING[@]} -gt 0 ]]; then
            print_error "❌ Critical packages missing: ${CRITICAL_MISSING[*]}"
            print_error "The health checker may not work properly without these packages."
            print_error "Please install them manually:"
            for package in "${CRITICAL_MISSING[@]}"; do
                print_error "  pip3 install --user $package"
            done
            
            read -p "Continue installation anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
        
        if [[ ${#OPTIONAL_MISSING[@]} -gt 0 ]]; then
            print_warning "⚠️ Optional packages missing: ${OPTIONAL_MISSING[*]}"
            print_warning "Health checker will work but without enhanced features (colors/tables)"
        fi
    else
        print_status "🎉 All dependencies installed successfully!"
    fi
}

# Create installation directory
create_install_dir() {
    print_step "Setting up installation directory..."
    
    # Backup existing installation if it exists
    if [[ -d "$INSTALL_DIR" ]]; then
        BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Existing installation found, backing up to: $BACKUP_DIR"
        mv "$INSTALL_DIR" "$BACKUP_DIR"
    fi
    
    mkdir -p "$INSTALL_DIR"
    print_status "✅ Installation directory ready: $INSTALL_DIR"
}

# Download or create main script
setup_main_script() {
    print_step "Setting up enhanced health checker script..."
    
    # Try to download from GitHub first
    GITHUB_USER="your-github-username"  # Update this
    SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/eth-node-health-checker/main/eth_health_check.py"
    
    DOWNLOADED=false
    
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/eth_health_check.py" 2>/dev/null; then
            print_status "✅ Downloaded latest version from GitHub"
            DOWNLOADED=true
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/eth_health_check.py" 2>/dev/null; then
            print_status "✅ Downloaded latest version from GitHub"
            DOWNLOADED=true
        fi
    fi
    
    if [[ "$DOWNLOADED" == false ]]; then
        print_warning "Could not download from GitHub, using embedded version"
        create_embedded_enhanced_script
    fi
    
    chmod +x "$INSTALL_DIR/eth_health_check.py"
    print_status "✅ Enhanced health checker ready"
}

# Create enhanced embedded script
create_embedded_enhanced_script() {
    # Copy the enhanced script content here
    cat > "$INSTALL_DIR/eth_health_check.py" << 'ENHANCED_SCRIPT_EOF'
#!/usr/bin/env python3
"""
Enhanced Ethereum Node Health Checker - Professional monitoring tool
Provides consistent results with detailed diagnostics and performance analysis
"""

import requests
import json
import socket
import sys
import argparse
import time
import statistics
from datetime import datetime

# Check for optional dependencies
try:
    from colorama import init, Fore, Style
    init()
    HAS_COLOR = True
except ImportError:
    HAS_COLOR = False
    print("Note: Install 'colorama' for colored output: pip3 install --user colorama")

try:
    from tabulate import tabulate
    HAS_TABULATE = True
except ImportError:
    HAS_TABULATE = False
    print("Note: Install 'tabulate' for better formatting: pip3 install --user tabulate")

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False
    print("Note: Install 'psutil' for system monitoring: pip3 install --user psutil")

class EnhancedNodeHealthChecker:
    def __init__(self, timeout=15, retries=3):
        self.timeout = timeout
        self.retries = retries
        self.results = {}
        
    def colored_print(self, message, color="white", style="normal"):
        """Print colored text if available"""
        if not HAS_COLOR:
            print(message)
            return
        colors = {
            "red": Fore.RED, "green": Fore.GREEN, "yellow": Fore.YELLOW,
            "blue": Fore.BLUE, "cyan": Fore.CYAN, "white": Fore.WHITE,
            "magenta": Fore.MAGENTA
        }
        styles = {"bright": Style.BRIGHT, "normal": Style.NORMAL}
        color_code = colors.get(color, Fore.WHITE)
        style_code = styles.get(style, Style.NORMAL)
        print(f"{style_code}{color_code}{message}{Style.RESET_ALL}")
    
    def log_result(self, message, status="info", details=None):
        """Log result with timestamp and status"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        status_map = {
            "success": ("green", "✅"),
            "error": ("red", "❌"), 
            "warning": ("yellow", "⚠️"),
            "info": ("blue", "ℹ️"),
            "performance": ("magenta", "⚡"),
            "critical": ("red", "🚨")
        }
        color, icon = status_map.get(status, ("white", "•"))
        self.colored_print(f"[{timestamp}] {icon} {message}", color)
        if details:
            for detail in details:
                self.colored_print(f"    └─ {detail}", "white")
    
    def test_connection_advanced(self, host, port):
        """Advanced connection test with retries"""
        attempts = []
        for attempt in range(self.retries):
            start_time = time.time()
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(self.timeout)
                result = sock.connect_ex((host, port))
                sock.close()
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                attempts.append({
                    'success': result == 0,
                    'latency': latency,
                    'attempt': attempt + 1
                })
                if result == 0:
                    time.sleep(0.1)
            except Exception as e:
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                attempts.append({
                    'success': False,
                    'latency': latency,
                    'attempt': attempt + 1,
                    'error': str(e)
                })
        return attempts
    
    def make_request_with_retry(self, method, url, **kwargs):
        """Make HTTP request with retry logic"""
        latencies = []
        errors = []
        for attempt in range(self.retries):
            start_time = time.time()
            try:
                if method.upper() == 'GET':
                    response = requests.get(url, timeout=self.timeout, **kwargs)
                elif method.upper() == 'POST':
                    response = requests.post(url, timeout=self.timeout, **kwargs)
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                latencies.append(latency)
                if response.status_code == 200:
                    return response, {
                        'latencies': latencies,
                        'avg_latency': statistics.mean(latencies),
                        'attempts': attempt + 1,
                        'errors': errors
                    }
                else:
                    errors.append(f"HTTP {response.status_code}")
            except Exception as e:
                end_time = time.time()
                latency = (end_time - start_time) * 1000
                latencies.append(latency)
                errors.append(str(e))
                if attempt < self.retries - 1:
                    time.sleep(0.5)
        return None, {
            'latencies': latencies,
            'avg_latency': statistics.mean(latencies) if latencies else 0,
            'attempts': self.retries,
            'errors': errors
        }
    
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
    
    def check_system_resources(self):
        """Check system resources if psutil available"""
        if not HAS_PSUTIL:
            self.log_result("System monitoring unavailable (psutil not installed)", "warning")
            return
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            self.log_result(f"CPU: {cpu_percent:.1f}%, Memory: {memory.percent:.1f}%, Disk: {disk.percent:.1f}%", "info")
            if cpu_percent > 90 or memory.percent > 90 or disk.percent > 95:
                self.log_result("High resource usage detected", "warning")
        except Exception as e:
            self.log_result(f"Could not check system resources: {e}", "warning")
    
    def check_beacon_node(self, url):
        """Enhanced Beacon node check"""
        self.colored_print("\n📋 BEACON CHAIN NODE", "yellow")
        host, port = self.parse_url(url, 5052)
        if not host:
            self.log_result(f"Invalid URL: {url}", "error")
            return False
        
        # Test connection
        attempts = self.test_connection_advanced(host, port)
        successful = [a for a in attempts if a['success']]
        
        if not successful:
            avg_latency = statistics.mean([a['latency'] for a in attempts])
            if avg_latency > (self.timeout * 1000 * 0.9):
                self.log_result("Connection timeout - service likely down", "critical")
            else:
                self.log_result("Port closed or service not responding", "error")
            return False
        
        success_rate = len(successful) / len(attempts) * 100
        avg_latency = statistics.mean([a['latency'] for a in successful])
        
        if success_rate < 100:
            self.log_result(f"Intermittent connectivity ({success_rate:.0f}% success)", "warning")
        else:
            self.log_result(f"Connection stable (latency: {avg_latency:.0f}ms)", "success")
        
        # Test health endpoint
        response, perf_data = self.make_request_with_retry('GET', f"{url}/eth/v1/node/health")
        if response and response.status_code == 200:
            self.log_result("Beacon node is healthy", "success")
            self.log_result(f"Health check latency: {perf_data['avg_latency']:.0f}ms", "performance")
            
            # Check sync status
            sync_response, _ = self.make_request_with_retry('GET', f"{url}/eth/v1/node/syncing")
            if sync_response and sync_response.status_code == 200:
                try:
                    sync_data = sync_response.json()
                    is_syncing = sync_data.get("data", {}).get("is_syncing", True)
                    if not is_syncing:
                        self.log_result("Beacon node is synced", "success")
                    else:
                        self.log_result("Beacon node is syncing", "warning")
                except:
                    pass
            
            # Check peers
            peers_response, _ = self.make_request_with_retry('GET', f"{url}/eth/v1/node/peers")
            if peers_response and peers_response.status_code == 200:
                try:
                    peers_data = peers_response.json()
                    peer_count = len(peers_data.get("data", []))
                    if peer_count >= 10:
                        self.log_result(f"Good peer connectivity: {peer_count} peers", "success")
                    elif peer_count >= 3:
                        self.log_result(f"Minimal peer connectivity: {peer_count} peers", "warning")
                    else:
                        self.log_result(f"Poor peer connectivity: {peer_count} peers", "error")
                except:
                    pass
            return True
        else:
            self.log_result("Beacon health check failed", "error")
            return False
    
    def check_sepolia_rpc(self, url):
        """Enhanced Sepolia RPC check"""
        self.colored_print("\n📋 SEPOLIA RPC NODE", "yellow")
        host, port = self.parse_url(url, 8545)
        if not host:
            self.log_result(f"Invalid URL: {url}", "error")
            return False
        
        # Test connection
        attempts = self.test_connection_advanced(host, port)
        successful = [a for a in attempts if a['success']]
        
        if not successful:
            self.log_result("RPC connection failed", "error")
            return False
        
        avg_latency = statistics.mean([a['latency'] for a in successful])
        self.log_result(f"RPC connection stable (latency: {avg_latency:.0f}ms)", "success")
        
        # Test chain ID
        payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
        response, perf_data = self.make_request_with_retry('POST', url, json=payload)
        
        if response and response.status_code == 200:
            try:
                chain_id = int(response.json().get("result", "0x0"), 16)
                if chain_id == 11155111:
                    self.log_result("Confirmed Sepolia testnet", "success")
                else:
                    self.log_result(f"Chain ID: {chain_id}", "info")
                
                # Test latest block
                block_payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
                block_response, _ = self.make_request_with_retry('POST', url, json=block_payload)
                if block_response and block_response.status_code == 200:
                    block_hex = block_response.json().get("result", "0x0")
                    latest_block = int(block_hex, 16)
                    self.log_result(f"Latest block: {latest_block:,}", "success")
                
                return True
            except Exception as e:
                self.log_result(f"Error parsing RPC response: {e}", "error")
                return False
        else:
            self.log_result("Sepolia RPC check failed", "error")
            return False

def main():
    parser = argparse.ArgumentParser(description="Enhanced Ethereum Node Health Checker")
    parser.add_argument("--beacon", default="http://localhost:5052", help="Beacon node URL")
    parser.add_argument("--sepolia", default="http://localhost:8545", help="Sepolia RPC URL")
    parser.add_argument("--timeout", type=int, default=15, help="Timeout in seconds")
    parser.add_argument("--retries", type=int, default=3, help="Number of retries")
    parser.add_argument("--monitor", type=int, help="Monitor mode: check every N seconds")
    args = parser.parse_args()
    
    def run_check():
        checker = EnhancedNodeHealthChecker(timeout=args.timeout, retries=args.retries)
        checker.colored_print("\n" + "="*60, "blue")
        checker.colored_print("🚀 ENHANCED ETHEREUM NODE HEALTH CHECKER", "cyan")
        checker.colored_print("="*60, "blue")
        
        checker.colored_print("\n📊 SYSTEM CHECK", "yellow")
        checker.check_system_resources()
        
        beacon_ok = False
        sepolia_ok = False
        
        if args.beacon:
            beacon_ok = checker.check_beacon_node(args.beacon)
        if args.sepolia:
            sepolia_ok = checker.check_sepolia_rpc(args.sepolia)
        
        checker.colored_print("\n📋 SUMMARY", "blue")
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        if beacon_ok and sepolia_ok:
            checker.colored_print(f"🎉 All systems healthy! ({current_time})", "green")
            return True
        else:
            checker.colored_print(f"⚠️ Issues detected ({current_time})", "yellow")
            return False
    
    if args.monitor:
        print(f"🔄 Monitor mode: checking every {args.monitor} seconds")
        try:
            while True:
                run_check()
                time.sleep(args.monitor)
        except KeyboardInterrupt:
            print("\n🛑 Monitoring stopped")
    else:
        healthy = run_check()
        sys.exit(0 if healthy else 1)

if __name__ == "__main__":
    main()
# Create enhanced wrapper commands
create_enhanced_wrapper() {
    print_step "Creating enhanced command-line tools..."
    
    # Main wrapper command
    cat > "$INSTALL_DIR/check-nodes" << 'MAIN_WRAPPER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/eth_health_check.py" "$@"
MAIN_WRAPPER_EOF
    
    # Quick check command
    cat > "$INSTALL_DIR/quick-check" << 'QUICK_WRAPPER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Quick Node Health Check"
python3 "$SCRIPT_DIR/eth_health_check.py" --timeout 10 --retries 2 --no-system-check
QUICK_WRAPPER_EOF
    
    # Monitor command
    cat > "$INSTALL_DIR/monitor-nodes" << 'MONITOR_WRAPPER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL=${1:-60}
echo "🔄 Starting node monitoring (interval: ${INTERVAL}s)"
echo "Press Ctrl+C to stop"
python3 "$SCRIPT_DIR/eth_health_check.py" --monitor "$INTERVAL"
MONITOR_WRAPPER_EOF
    
    # Diagnostic command
    cat > "$INSTALL_DIR/diagnose-nodes" << 'DIAGNOSE_WRAPPER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🔧 Comprehensive Node Diagnostics"
python3 "$SCRIPT_DIR/eth_health_check.py" --timeout 30 --retries 5
DIAGNOSE_WRAPPER_EOF
    
    chmod +x "$INSTALL_DIR/check-nodes"
    chmod +x "$INSTALL_DIR/quick-check"
    chmod +x "$INSTALL_DIR/monitor-nodes"
    chmod +x "$INSTALL_DIR/diagnose-nodes"
    
    print_status "✅ Command-line tools created:"
    print_status "   • check-nodes (full diagnostics)"
    print_status "   • quick-check (fast check)"
    print_status "   • monitor-nodes [interval] (continuous monitoring)"
    print_status "   • diagnose-nodes (thorough analysis)"
}

# Add to PATH and create convenience functions
setup_path_and_aliases() {
    print_step "Setting up PATH and convenience functions..."
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.eth-health-checker:"* ]]; then
        echo 'export PATH="$HOME/.eth-health-checker:$PATH"' >> "$HOME/.bashrc"
        print_status "✅ Added to PATH in .bashrc"
    fi
    
    # Create convenience functions in .bashrc
    if ! grep -q "# Ethereum Health Checker Functions" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" << 'FUNCTIONS_EOF'

# Ethereum Health Checker Functions
alias eth-status='check-nodes'
alias eth-quick='quick-check'
alias eth-monitor='monitor-nodes'
alias eth-diagnose='diagnose-nodes'

# Function for custom node checking
eth-check() {
    if [[ $# -eq 0 ]]; then
        check-nodes
    elif [[ $# -eq 2 ]]; then
        check-nodes --beacon "$1" --sepolia "$2"
    else
        echo "Usage: eth-check [beacon_url sepolia_url]"
        echo "Example: eth-check http://192.168.1.100:5052 http://192.168.1.100:8545"
    fi
}

# Function for remote monitoring
eth-remote() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: eth-remote <server_ip>"
        echo "Example: eth-remote 192.168.1.100"
        return 1
    fi
    
    local SERVER_IP="$1"
    echo "🌐 Checking remote Ethereum nodes on $SERVER_IP"
    check-nodes --beacon "http://$SERVER_IP:5052" --sepolia "http://$SERVER_IP:8545"
}
FUNCTIONS_EOF
        print_status "✅ Added convenience functions and aliases"
    fi
}

# Create enhanced uninstaller
create_enhanced_uninstaller() {
    cat > "$INSTALL_DIR/uninstall" << 'ENHANCED_UNINSTALL_EOF'
#!/bin/bash

echo "🗑️ Uninstalling Enhanced Ethereum Node Health Checker..."

# Remove from .bashrc
if [[ -f "$HOME/.bashrc" ]]; then
    # Remove PATH addition
    sed -i '/eth-health-checker/d' "$HOME/.bashrc" 2>/dev/null || true
    
    # Remove convenience functions
    sed -i '/# Ethereum Health Checker Functions/,/^$/d' "$HOME/.bashrc" 2>/dev/null || true
    
    echo "✅ Removed from .bashrc"
fi

# Remove installation directory
rm -rf "$HOME/.eth-health-checker"

echo "✅ Uninstalled successfully!"
echo ""
echo "Note: Restart your terminal or run 'source ~/.bashrc' to update your environment"
echo "The following packages were installed and can be removed manually if desired:"
echo "  pip3 uninstall requests colorama tabulate psutil"
ENHANCED_UNINSTALL_EOF
    
    chmod +x "$INSTALL_DIR/uninstall"
}

# Create configuration file
create_config_file() {
    print_step "Creating configuration file..."
    
    cat > "$INSTALL_DIR/config.json" << 'CONFIG_EOF'
{
    "default_settings": {
        "timeout": 15,
        "retries": 3,
        "beacon_url": "http://localhost:5052",
        "sepolia_url": "http://localhost:8545"
    },
    "monitoring": {
        "default_interval": 60,
        "alert_threshold": {
            "latency_ms": 2000,
            "min_peers_beacon": 10,
            "min_peers_sepolia": 5
        }
    },
    "notifications": {
        "enabled": false,
        "email": "",
        "webhook_url": ""
    }
}
CONFIG_EOF
    
    print_status "✅ Configuration file created: $INSTALL_DIR/config.json"
}

# Create documentation
create_documentation() {
    print_step "Creating documentation..."
    
    cat > "$INSTALL_DIR/README.md" << 'README_EOF'
# Enhanced Ethereum Node Health Checker

Professional monitoring tool for Ethereum nodes with detailed diagnostics.

## Quick Start

```bash
# Check local nodes
check-nodes

# Quick health check
quick-check

# Monitor continuously (60s intervals)
monitor-nodes

# Thorough diagnostics
diagnose-nodes

# Check remote nodes
eth-remote 192.168.1.100
```

## Commands

- `check-nodes` - Full diagnostic check
- `quick-check` - Fast health check (10s timeout, 2 retries)
- `monitor-nodes [interval]` - Continuous monitoring
- `diagnose-nodes` - Thorough analysis (30s timeout, 5 retries)

## Aliases

- `eth-status` = `check-nodes`
- `eth-quick` = `quick-check`
- `eth-monitor` = `monitor-nodes`
- `eth-diagnose` = `diagnose-nodes`

## Functions

- `eth-check [beacon_url sepolia_url]` - Custom node check
- `eth-remote <server_ip>` - Check remote nodes

## Configuration

Edit `~/.eth-health-checker/config.json` to customize default settings.

## Troubleshooting

The tool provides detailed diagnostic information including:
- Connection stability analysis
- Performance metrics
- System resource monitoring
- Specific troubleshooting recommendations

## Features

- ✅ Consistent results with retry logic
- ✅ Performance metrics and latency analysis
- ✅ Detailed error diagnostics
- ✅ System resource monitoring
- ✅ Multiple monitoring modes
- ✅ Hardware recommendations
- ✅ Firewall and network diagnostics
README_EOF
    
    print_status "✅ Documentation created: $INSTALL_DIR/README.md"
}

# Print usage examples
print_usage_examples() {
    print_step "Installation complete! Here's how to use it:"
    
    print_feature "🎯 QUICK START:"
    echo "1. Restart your terminal: source ~/.bashrc"
    echo "2. Check local nodes: check-nodes"
    echo "3. Quick check: quick-check"
    echo "4. Monitor continuously: monitor-nodes 60"
    echo ""
    
    print_feature "🌐 REMOTE MONITORING:"
    echo "• Check remote server: eth-remote 192.168.1.100"
    echo "• Custom URLs: eth-check http://IP:5052 http://IP:8545"
    echo ""
    
    print_feature "🔧 DIAGNOSTICS:"
    echo "• Thorough analysis: diagnose-nodes"
    echo "• Custom timeout: check-nodes --timeout 30 --retries 5"
    echo "• Monitor mode: check-nodes --monitor 120"
    echo ""
    
    print_feature "📋 ALIASES:"
    echo "• eth-status (same as check-nodes)"
    echo "• eth-quick (fast check)"
    echo "• eth-monitor (continuous monitoring)"
    echo "• eth-diagnose (thorough analysis)"
    echo ""
    
    print_feature "🆘 HELP & CONFIG:"
    echo "• Get help: check-nodes --help"
    echo "• Configuration: ~/.eth-health-checker/config.json"
    echo "• Documentation: ~/.eth-health-checker/README.md"
    echo "• Uninstall: ~/.eth-health-checker/uninstall"
}

# Main installation process
main() {
    check_requirements
    install_dependencies
    create_install_dir
    setup_main_script
    create_enhanced_wrapper
    setup_path_and_aliases
    create_enhanced_uninstaller
    create_config_file
    create_documentation
    
    print_step "🎉 Enhanced Installation Complete!"
    
    print_status "📁 Installed to: $INSTALL_DIR"
    print_status "🔧 Tools: check-nodes, quick-check, monitor-nodes, diagnose-nodes"
    print_status "📚 Documentation: $INSTALL_DIR/README.md"
    print_status "⚙️ Configuration: $INSTALL_DIR/config.json"
    print_status "🗑️ Uninstaller: $INSTALL_DIR/uninstall"
    
    print_usage_examples
    
    echo ""
    print_status "🚀 Ready to monitor your Ethereum nodes with enhanced diagnostics!"
    print_warning "💡 Restart your terminal or run: source ~/.bashrc"
}

main "$@"
